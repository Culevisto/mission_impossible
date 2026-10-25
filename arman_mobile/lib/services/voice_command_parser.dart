import '../models/servo_id.dart';
import '../models/voice_command_result.dart';

class VoiceCommandParser {
  static final RegExp _movePattern = RegExp(
    r'(?:move|rotate|turn|set)?\s*(?:servo\s+)?([A-Ga-g])\s*(?:to|at)?\s*(\d+)(?:\s*deg|\s*degrees)?',
    caseSensitive: false,
  );

  static VoiceCommandResult parse(String transcript) {
    final clean = transcript.trim();
    if (clean.isEmpty) {
      return const VoiceCommandResult(
        transcript: '',
        intent: 'UNKNOWN',
        message: 'Empty transcript',
      );
    }

    final lower = clean.toLowerCase();

    // STOP intent
    if (lower == 'stop' ||
        lower.contains('emergency stop') ||
        lower.contains('halt') ||
        lower.contains('abort')) {
      return VoiceCommandResult(
        transcript: clean,
        intent: 'STOP',
        message: 'Halt all outgoing robot commands',
      );
    }

    // OPEN_GRIPPER / OPEN_CLAW intent -> mapped to Servo G
    if (lower.contains('open gripper') ||
        lower.contains('release gripper') ||
        lower.contains('open claw') ||
        lower.contains('release claw') ||
        lower.contains('open hand')) {
      return VoiceCommandResult(
        transcript: clean,
        intent: 'OPEN_GRIPPER',
        servoId: ServoId.G,
        targetAngle: 30,
        message: 'Open claw (Servo G, 30°)',
      );
    }

    // CLOSE_GRIPPER / CLOSE_CLAW intent -> mapped to Servo G
    if (lower.contains('close gripper') ||
        lower.contains('grip') ||
        lower.contains('grab') ||
        lower.contains('close claw') ||
        lower.contains('capture')) {
      return VoiceCommandResult(
        transcript: clean,
        intent: 'CLOSE_GRIPPER',
        servoId: ServoId.G,
        targetAngle: 150,
        message: 'Close claw (Servo G, 150°)',
      );
    }

    // HOME_ALL intent
    if (lower.contains('home all') ||
        lower.contains('center all') ||
        lower.contains('reset position') ||
        lower == 'home') {
      return VoiceCommandResult(
        transcript: clean,
        intent: 'HOME_ALL',
        targetAngle: 90,
        message: 'Move all enabled servos to 90° center',
      );
    }

    // MOVE_SERVO intent (Servos A through G)
    final match = _movePattern.firstMatch(clean);
    if (match != null) {
      final servoCode = match.group(1);
      final angleStr = match.group(2);
      final servoId = ServoId.fromString(servoCode);

      if (servoId != null && angleStr != null) {
        final parsedAngle = int.tryParse(angleStr) ?? 90;
        final clamped = parsedAngle.clamp(0, 180);
        return VoiceCommandResult(
          transcript: clean,
          intent: 'MOVE_SERVO',
          servoId: servoId,
          targetAngle: clamped,
          message: 'Move Servo ${servoId.code} (${servoId.jointName}) to $clamped°',
        );
      }
    }

    return VoiceCommandResult(
      transcript: clean,
      intent: 'UNKNOWN',
      message: 'Unrecognized robotics voice command',
    );
  }
}
