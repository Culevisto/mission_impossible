import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/health_status_model.dart';
import '../models/servo_id.dart';
import '../models/voice_command_result.dart';

class ArmanCommandResult {
  final bool isHttpSuccess;
  final bool isSerialDispatched;
  final int statusCode;
  final String status;
  final String message;
  final ServoId servoId;
  final int targetAngle;

  const ArmanCommandResult({
    required this.isHttpSuccess,
    required this.isSerialDispatched,
    required this.statusCode,
    required this.status,
    required this.message,
    required this.servoId,
    required this.targetAngle,
  });
}

typedef OnCommandDispatchedCallback = void Function(
    ServoId servoId, int angle, bool serialDispatched, String message);

class ArmanApiService {
  final http.Client _client;

  // Single-flight throttling state per servo
  final Map<ServoId, bool> _inFlight = {};
  final Map<ServoId, int?> _queuedAngle = {};
  final Map<ServoId, int> _lastSentAngle = {};

  OnCommandDispatchedCallback? onCommandDispatched;

  ArmanApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Clears in-flight and queued states (e.g., when Software Stop is pressed)
  void clearQueue() {
    _queuedAngle.clear();
    _inFlight.clear();
  }

  /// Sends a servo angle command with single-flight throttling.
  /// If an HTTP call is currently running for this servo, the new angle is queued
  /// and dispatched immediately after the in-flight request finishes.
  void dispatchServoAngle({
    required String serverUrl,
    required ServoId servoId,
    required int angle,
    required bool isEnabled,
    required bool isStopped,
  }) {
    if (!isEnabled || isStopped) {
      return;
    }

    // Minimum 1-degree change check compared to last sent
    final lastSent = _lastSentAngle[servoId];
    if (lastSent != null && lastSent == angle && _queuedAngle[servoId] == null) {
      return;
    }

    if (_inFlight[servoId] == true) {
      // Overwrite queue with newest angle
      _queuedAngle[servoId] = angle;
      return;
    }

    _executeSingleFlight(
      serverUrl: serverUrl,
      servoId: servoId,
      targetAngle: angle,
      isStoppedCheck: () => isStopped,
    );
  }

  Future<void> _executeSingleFlight({
    required String serverUrl,
    required ServoId servoId,
    required int targetAngle,
    required bool Function() isStoppedCheck,
  }) async {
    _inFlight[servoId] = true;
    _lastSentAngle[servoId] = targetAngle;

    ArmanCommandResult result;
    try {
      result = await sendControlCommand(
        serverUrl: serverUrl,
        servoId: servoId,
        angle: targetAngle,
      );
    } catch (e) {
      result = ArmanCommandResult(
        isHttpSuccess: false,
        isSerialDispatched: false,
        statusCode: 0,
        status: 'error',
        message: 'Network error: $e',
        servoId: servoId,
        targetAngle: targetAngle,
      );
    } finally {
      _inFlight[servoId] = false;
    }

    if (onCommandDispatched != null) {
      onCommandDispatched!(
        result.servoId,
        result.targetAngle,
        result.isSerialDispatched,
        result.message,
      );
    }

    // Process queued angle if one arrived during flight and system is not stopped
    final nextAngle = _queuedAngle[servoId];
    if (nextAngle != null) {
      _queuedAngle[servoId] = null;
      if (!isStoppedCheck() && nextAngle != _lastSentAngle[servoId]) {
        _executeSingleFlight(
          serverUrl: serverUrl,
          servoId: servoId,
          targetAngle: nextAngle,
          isStoppedCheck: isStoppedCheck,
        );
      }
    }
  }

  /// Direct POST /control endpoint call
  Future<ArmanCommandResult> sendControlCommand({
    required String serverUrl,
    required ServoId servoId,
    required int angle,
  }) async {
    final cleanUrl = _normalizeBaseUrl(serverUrl);
    final uri = Uri.parse('$cleanUrl/control');

    final body = jsonEncode({
      'servo': servoId.code,
      'angle': angle,
    });

    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      final Map<String, dynamic> data = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : {};

      final isSuccessHttp = response.statusCode == 200;
      final isDispatched = (data['serial_dispatched'] ?? data['serialDispatched']) as bool? ?? false;
      final status = data['status'] as String? ?? (isSuccessHttp ? 'success' : 'error');
      final message = data['message'] as String? ?? (isSuccessHttp ? 'Command OK' : 'HTTP ${response.statusCode}');

      return ArmanCommandResult(
        isHttpSuccess: isSuccessHttp,
        isSerialDispatched: isDispatched,
        statusCode: response.statusCode,
        status: status,
        message: message,
        servoId: servoId,
        targetAngle: angle,
      );
    } catch (e) {
      return ArmanCommandResult(
        isHttpSuccess: false,
        isSerialDispatched: false,
        statusCode: 0,
        status: 'error',
        message: 'Connection failed: $e',
        servoId: servoId,
        targetAngle: angle,
      );
    }
  }

  /// Queries GET /api/health
  Future<HealthStatusModel> checkHealth(String serverUrl) async {
    final cleanUrl = _normalizeBaseUrl(serverUrl);
    final uri = Uri.parse('$cleanUrl/api/health');

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return HealthStatusModel.fromJson(data);
      } else {
        return HealthStatusModel.offline(
          message: 'Server returned HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      return HealthStatusModel.offline(message: e.toString());
    }
  }

  /// Triggers POST /api/serial/reconnect
  Future<HealthStatusModel> triggerSerialReconnect(String serverUrl) async {
    final cleanUrl = _normalizeBaseUrl(serverUrl);
    final uri = Uri.parse('$cleanUrl/api/serial/reconnect');

    try {
      final response = await _client.post(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return HealthStatusModel.fromJson(data);
      } else {
        return HealthStatusModel.offline(
          message: 'Reconnect failed with HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      return HealthStatusModel.offline(message: 'Reconnect error: $e');
    }
  }

  /// Calls POST /api/voice-command
  Future<VoiceCommandResult?> sendVoiceCommand({
    required String serverUrl,
    required String transcript,
    bool executeImmediately = false,
  }) async {
    final cleanUrl = _normalizeBaseUrl(serverUrl);
    final uri = Uri.parse('$cleanUrl/api/voice-command');

    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'transcript': transcript,
          'executeImmediately': executeImmediately,
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return VoiceCommandResult.fromJson(data);
      }
    } catch (e) {
      debugPrint('Voice command remote call failed: $e');
    }
    return null;
  }

  String _normalizeBaseUrl(String url) {
    var trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'http://$trimmed';
    }
    return trimmed;
  }
}
