import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_settings_model.dart';
import '../models/health_status_model.dart';
import '../models/servo_id.dart';
import '../models/servo_state_model.dart';
import '../models/voice_command_result.dart';
import '../services/arman_api_service.dart';
import '../services/settings_storage_service.dart';

class RobotController extends ChangeNotifier {
  final ArmanApiService _apiService;
  final SettingsStorageService _storageService;

  AppSettingsModel _settings = const AppSettingsModel();
  HealthStatusModel _health = const HealthStatusModel();
  bool _isStopped = false;
  bool _isInitialized = false;

  final Map<ServoId, ServoStateModel> _servoStates = {};
  final List<String> _logs = [];
  Timer? _healthPollTimer;

  RobotController({
    ArmanApiService? apiService,
    SettingsStorageService? storageService,
  })  : _apiService = apiService ?? ArmanApiService(),
        _storageService = storageService ?? SettingsStorageService() {
    _initializeServoStates();
    _apiService.onCommandDispatched = _handleCommandDispatched;
  }

  // Getters
  AppSettingsModel get settings => _settings;
  HealthStatusModel get health => _health;
  bool get isStopped => _isStopped;
  bool get isInitialized => _isInitialized;
  Map<ServoId, ServoStateModel> get servoStates => Map.unmodifiable(_servoStates);
  List<String> get logs => List.unmodifiable(_logs);

  ServoStateModel getServo(ServoId id) {
    return _servoStates[id] ?? ServoStateModel(id: id);
  }

  void _initializeServoStates() {
    for (final id in ServoId.values) {
      _servoStates[id] = ServoStateModel(
        id: id,
        isEnabled: _settings.enabledServos[id] ?? id.defaultEnabled,
        minAngle: _settings.minAngles[id] ?? 0,
        maxAngle: _settings.maxAngles[id] ?? 180,
        commandedAngle: id.isGripper ? _settings.gripperOpenAngle : 90,
      );
    }
  }

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      _settings = await _storageService.loadSettings();
      _syncServoStatesWithSettings();
      _isInitialized = true;
      notifyListeners();

      await checkHealth();

      // Poll server health every 6 seconds
      _healthPollTimer?.cancel();
      _healthPollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
        checkHealth();
      });
    } catch (e) {
      _addLog('Initialization error: $e');
    }
  }

  @override
  void dispose() {
    _healthPollTimer?.cancel();
    super.dispose();
  }

  void _syncServoStatesWithSettings() {
    for (final id in ServoId.values) {
      final current = _servoStates[id] ?? ServoStateModel(id: id);
      final isEnabled = _settings.enabledServos[id] ?? id.defaultEnabled;
      final minAngle = _settings.minAngles[id] ?? 0;
      final maxAngle = _settings.maxAngles[id] ?? 180;
      final clampedAngle = current.commandedAngle.clamp(minAngle, maxAngle);

      _servoStates[id] = current.copyWith(
        isEnabled: isEnabled,
        minAngle: minAngle,
        maxAngle: maxAngle,
        commandedAngle: clampedAngle,
      );
    }
  }

  Future<void> updateSettings(AppSettingsModel newSettings) async {
    _settings = newSettings;
    _syncServoStatesWithSettings();
    notifyListeners();
    await _storageService.saveSettings(newSettings);
  }

  /// Sets angle for an individual servo
  void setServoAngle(ServoId id, int requestedAngle) {
    if (_isStopped) {
      _addLog('Blocked: Software Stop is active. Cannot move Servo ${id.code}.');
      return;
    }

    final state = _servoStates[id];
    if (state == null || !state.isEnabled) {
      _addLog('Blocked: Servo ${id.code} (${id.jointName}) is disabled.');
      return;
    }

    final clamped = state.clampAngle(requestedAngle);
    _servoStates[id] = state.copyWith(commandedAngle: clamped);
    notifyListeners();

    _apiService.dispatchServoAngle(
      serverUrl: _settings.serverUrl,
      servoId: id,
      angle: clamped,
      isEnabled: true,
      isStopped: _isStopped,
    );
  }

  /// Velocity integration from virtual joystick deflection
  void applyJoystickVelocity(ServoId id, double normalizedOffset, double dtSeconds) {
    if (_isStopped) return;

    final state = _servoStates[id];
    if (state == null || !state.isEnabled) return;

    final deadzone = _settings.joystickDeadzone;
    final absOffset = normalizedOffset.abs();

    if (absOffset < deadzone) {
      // In deadzone -> 0 velocity
      return;
    }

    // Rescale linearly from 0.0 to 1.0 outside deadzone
    final sign = normalizedOffset >= 0 ? 1.0 : -1.0;
    final rescaled = sign * ((absOffset - deadzone) / (1.0 - deadzone));

    final delta = rescaled * _settings.joystickMaxSpeedDegPerSec * dtSeconds;
    final newAngle = (state.commandedAngle + delta).round();
    final clamped = state.clampAngle(newAngle);

    if (clamped != state.commandedAngle) {
      setServoAngle(id, clamped);
    }
  }

  /// Software Command Stop
  void stopAllCommands() {
    _isStopped = true;
    _apiService.clearQueue();
    _addLog(
      'Software Command Stop Active: Outgoing app commands are halted. '
      'Does not cut 5V hardware power to servos.',
    );
    notifyListeners();
  }

  /// Resumes normal control
  void resumeControl() {
    _isStopped = false;
    _addLog('Control resumed. Outgoing commands enabled.');
    notifyListeners();
  }

  /// Global positioning: sends command only to currently enabled servos
  void setAllActiveTo(int angle) {
    if (_isStopped) {
      _addLog('Blocked: Software Stop is active.');
      return;
    }

    for (final id in ServoId.values) {
      final state = _servoStates[id];
      if (state != null && state.isEnabled) {
        setServoAngle(id, angle);
      }
    }
  }

  /// Gripper / Claw Open
  void openGripper() {
    final gripperState = _servoStates[ServoId.G];
    if (gripperState == null || !gripperState.isEnabled) {
      _addLog('Blocked: Claw (Servo G) is disabled in settings.');
      return;
    }
    setServoAngle(ServoId.G, _settings.gripperOpenAngle);
  }

  /// Gripper / Claw Close
  void closeGripper() {
    final gripperState = _servoStates[ServoId.G];
    if (gripperState == null || !gripperState.isEnabled) {
      _addLog('Blocked: Claw (Servo G) is disabled in settings.');
      return;
    }
    setServoAngle(ServoId.G, _settings.gripperCloseAngle);
  }

  /// Voice command dispatcher
  void executeVoiceCommand(VoiceCommandResult result) {
    if (_isStopped && result.intent != 'STOP') {
      _addLog('Blocked: Cannot execute voice command while Stopped.');
      return;
    }

    switch (result.intent) {
      case 'STOP':
        stopAllCommands();
        break;
      case 'OPEN_GRIPPER':
        openGripper();
        break;
      case 'CLOSE_GRIPPER':
        closeGripper();
        break;
      case 'HOME_ALL':
        setAllActiveTo(90);
        break;
      case 'MOVE_SERVO':
        if (result.servoId != null && result.targetAngle != null) {
          setServoAngle(result.servoId!, result.targetAngle!);
        }
        break;
      default:
        _addLog('Ignored unknown voice intent: ${result.intent}');
        break;
    }
  }

  /// Refreshes health status from Spring Boot server
  Future<void> checkHealth() async {
    final newHealth = await _apiService.checkHealth(_settings.serverUrl);
    _health = newHealth;
    notifyListeners();
  }

  /// Triggers serial reconnect on backend
  Future<void> reconnectSerial() async {
    _addLog('Requesting backend serial port reconnect...');
    final newHealth = await _apiService.triggerSerialReconnect(_settings.serverUrl);
    _health = newHealth;
    _addLog(
      newHealth.isSerialConnected
          ? 'Serial reconnected: ${newHealth.serialPort}'
          : 'Serial reconnect failed / disconnected',
    );
    notifyListeners();
  }

  void _handleCommandDispatched(
      ServoId servoId, int angle, bool serialDispatched, String message) {
    final current = _servoStates[servoId];
    if (current != null) {
      if (serialDispatched) {
        _servoStates[servoId] = current.copyWith(
          lastSerialConfirmedAngle: angle,
          isDispatchedConfirmed: true,
        );
        _addLog('Dispatched: Servo ${servoId.code} -> $angle° [Confirmed]');
      } else {
        _servoStates[servoId] = current.copyWith(
          isDispatchedConfirmed: false,
        );
        _addLog('Unconfirmed: Servo ${servoId.code} -> $angle° ($message)');
      }
      notifyListeners();
    }
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    _logs.insert(0, '[$timestamp] $message');
    if (_logs.length > 50) {
      _logs.removeLast();
    }
    notifyListeners();
  }
}
