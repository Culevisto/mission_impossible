import 'servo_id.dart';

class AppSettingsModel {
  final String serverUrl;
  final String cameraStreamUrl;
  final Map<ServoId, bool> enabledServos;
  final Map<ServoId, int> minAngles;
  final Map<ServoId, int> maxAngles;
  final double joystickDeadzone;
  final double joystickMaxSpeedDegPerSec;
  final int gripperOpenAngle;
  final int gripperCloseAngle;
  final bool isVoiceControlEnabled;

  const AppSettingsModel({
    this.serverUrl = 'http://192.168.1.100:5000',
    this.cameraStreamUrl = '',
    this.enabledServos = const {
      ServoId.A: true,
      ServoId.B: true,
      ServoId.C: true,
      ServoId.D: true,
      ServoId.E: true,
      ServoId.F: true,
      ServoId.G: true,
    },
    this.minAngles = const {
      ServoId.A: 0,
      ServoId.B: 0,
      ServoId.C: 0,
      ServoId.D: 0,
      ServoId.E: 0,
      ServoId.F: 0,
      ServoId.G: 0,
    },
    this.maxAngles = const {
      ServoId.A: 180,
      ServoId.B: 180,
      ServoId.C: 180,
      ServoId.D: 180,
      ServoId.E: 180,
      ServoId.F: 180,
      ServoId.G: 180,
    },
    this.joystickDeadzone = 0.15,
    this.joystickMaxSpeedDegPerSec = 60.0,
    this.gripperOpenAngle = 30,
    this.gripperCloseAngle = 150,
    this.isVoiceControlEnabled = true,
  });

  AppSettingsModel copyWith({
    String? serverUrl,
    String? cameraStreamUrl,
    Map<ServoId, bool>? enabledServos,
    Map<ServoId, int>? minAngles,
    Map<ServoId, int>? maxAngles,
    double? joystickDeadzone,
    double? joystickMaxSpeedDegPerSec,
    int? gripperOpenAngle,
    int? gripperCloseAngle,
    bool? isVoiceControlEnabled,
  }) {
    return AppSettingsModel(
      serverUrl: serverUrl ?? this.serverUrl,
      cameraStreamUrl: cameraStreamUrl ?? this.cameraStreamUrl,
      enabledServos: enabledServos != null
          ? Map.unmodifiable(enabledServos)
          : this.enabledServos,
      minAngles: minAngles != null ? Map.unmodifiable(minAngles) : this.minAngles,
      maxAngles: maxAngles != null ? Map.unmodifiable(maxAngles) : this.maxAngles,
      joystickDeadzone: joystickDeadzone ?? this.joystickDeadzone,
      joystickMaxSpeedDegPerSec:
          joystickMaxSpeedDegPerSec ?? this.joystickMaxSpeedDegPerSec,
      gripperOpenAngle: gripperOpenAngle ?? this.gripperOpenAngle,
      gripperCloseAngle: gripperCloseAngle ?? this.gripperCloseAngle,
      isVoiceControlEnabled:
          isVoiceControlEnabled ?? this.isVoiceControlEnabled,
    );
  }
}
