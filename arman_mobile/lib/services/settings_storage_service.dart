import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings_model.dart';
import '../models/servo_id.dart';

class SettingsStorageService {
  static const String _keyServerUrl = 'arman_server_url';
  static const String _keyCameraUrl = 'arman_camera_url';
  static const String _keyJoystickDeadzone = 'arman_joystick_deadzone';
  static const String _keyJoystickSpeed = 'arman_joystick_speed';
  static const String _keyGripperOpen = 'arman_gripper_open';
  static const String _keyGripperClose = 'arman_gripper_close';
  static const String _keyVoiceEnabled = 'arman_voice_enabled';

  Future<AppSettingsModel> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final serverUrl = prefs.getString(_keyServerUrl) ?? 'http://192.168.1.100:5000';
    final cameraUrl = prefs.getString(_keyCameraUrl) ?? '';
    final deadzone = prefs.getDouble(_keyJoystickDeadzone) ?? 0.15;
    final speed = prefs.getDouble(_keyJoystickSpeed) ?? 60.0;
    final gripperOpen = prefs.getInt(_keyGripperOpen) ?? 30;
    final gripperClose = prefs.getInt(_keyGripperClose) ?? 150;
    final voiceEnabled = prefs.getBool(_keyVoiceEnabled) ?? true;

    final Map<ServoId, bool> enabledMap = {};
    final Map<ServoId, int> minMap = {};
    final Map<ServoId, int> maxMap = {};

    for (final id in ServoId.values) {
      enabledMap[id] = prefs.getBool('arman_enabled_${id.name}') ?? id.defaultEnabled;
      minMap[id] = prefs.getInt('arman_min_${id.name}') ?? 0;
      maxMap[id] = prefs.getInt('arman_max_${id.name}') ?? 180;
    }

    return AppSettingsModel(
      serverUrl: serverUrl,
      cameraStreamUrl: cameraUrl,
      enabledServos: enabledMap,
      minAngles: minMap,
      maxAngles: maxMap,
      joystickDeadzone: deadzone,
      joystickMaxSpeedDegPerSec: speed,
      gripperOpenAngle: gripperOpen,
      gripperCloseAngle: gripperClose,
      isVoiceControlEnabled: voiceEnabled,
    );
  }

  Future<void> saveSettings(AppSettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_keyServerUrl, settings.serverUrl);
    await prefs.setString(_keyCameraUrl, settings.cameraStreamUrl);
    await prefs.setDouble(_keyJoystickDeadzone, settings.joystickDeadzone);
    await prefs.setDouble(_keyJoystickSpeed, settings.joystickMaxSpeedDegPerSec);
    await prefs.setInt(_keyGripperOpen, settings.gripperOpenAngle);
    await prefs.setInt(_keyGripperClose, settings.gripperCloseAngle);
    await prefs.setBool(_keyVoiceEnabled, settings.isVoiceControlEnabled);

    for (final entry in settings.enabledServos.entries) {
      await prefs.setBool('arman_enabled_${entry.key.name}', entry.value);
    }
    for (final entry in settings.minAngles.entries) {
      await prefs.setInt('arman_min_${entry.key.name}', entry.value);
    }
    for (final entry in settings.maxAngles.entries) {
      await prefs.setInt('arman_max_${entry.key.name}', entry.value);
    }
  }
}
