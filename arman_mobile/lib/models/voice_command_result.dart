import 'servo_id.dart';

class VoiceCommandResult {
  final String transcript;
  final String intent;
  final ServoId? servoId;
  final int? targetAngle;
  final bool executed;
  final String message;

  const VoiceCommandResult({
    required this.transcript,
    required this.intent,
    this.servoId,
    this.targetAngle,
    this.executed = false,
    required this.message,
  });

  factory VoiceCommandResult.fromJson(Map<String, dynamic> json) {
    final transcript = json['transcript'] as String? ?? '';
    final intent = json['intent'] as String? ?? 'UNKNOWN';
    final servoStr = json['servo'] as String?;
    final servoId = ServoId.fromString(servoStr);
    final targetAngle = json['angle'] as int?;
    final executed = json['executed'] as bool? ?? false;
    final message = json['message'] as String? ?? '';

    return VoiceCommandResult(
      transcript: transcript,
      intent: intent,
      servoId: servoId,
      targetAngle: targetAngle,
      executed: executed,
      message: message,
    );
  }
}
