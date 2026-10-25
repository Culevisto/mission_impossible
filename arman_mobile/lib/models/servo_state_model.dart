import 'servo_id.dart';

class ServoStateModel {
  final ServoId id;
  final bool isEnabled;
  final int minAngle;
  final int maxAngle;
  final int commandedAngle;
  final int? lastSerialConfirmedAngle;
  final bool isDispatchedConfirmed;

  const ServoStateModel({
    required this.id,
    this.isEnabled = false,
    this.minAngle = 0,
    this.maxAngle = 180,
    this.commandedAngle = 90,
    this.lastSerialConfirmedAngle,
    this.isDispatchedConfirmed = false,
  });

  ServoStateModel copyWith({
    bool? isEnabled,
    int? minAngle,
    int? maxAngle,
    int? commandedAngle,
    int? lastSerialConfirmedAngle,
    bool? isDispatchedConfirmed,
    bool clearConfirmed = false,
  }) {
    return ServoStateModel(
      id: id,
      isEnabled: isEnabled ?? this.isEnabled,
      minAngle: minAngle ?? this.minAngle,
      maxAngle: maxAngle ?? this.maxAngle,
      commandedAngle: commandedAngle ?? this.commandedAngle,
      lastSerialConfirmedAngle: clearConfirmed
          ? null
          : (lastSerialConfirmedAngle ?? this.lastSerialConfirmedAngle),
      isDispatchedConfirmed: clearConfirmed
          ? false
          : (isDispatchedConfirmed ?? this.isDispatchedConfirmed),
    );
  }

  int clampAngle(int angle) {
    if (angle < minAngle) return minAngle;
    if (angle > maxAngle) return maxAngle;
    return angle;
  }
}
