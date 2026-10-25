import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../controllers/robot_controller.dart';
import '../models/servo_id.dart';

class ServoControlCard extends StatelessWidget {
  final ServoId servoId;

  const ServoControlCard({
    super.key,
    required this.servoId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RobotController>();
    final state = controller.getServo(servoId);
    final isStopped = controller.isStopped;
    final isEnabled = state.isEnabled;

    final confirmedStr = state.lastSerialConfirmedAngle != null
        ? '${state.lastSerialConfirmedAngle}°'
        : 'Unconfirmed';

    final confirmedColor = state.isDispatchedConfirmed
        ? AppTheme.statusGreen
        : AppTheme.textDim;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? AppTheme.electricBlue.withValues(alpha: 0.2)
                        : AppTheme.border.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isEnabled ? AppTheme.primaryCyan : AppTheme.border,
                    ),
                  ),
                  child: Text(
                    'SERVO ${servoId.code}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: isEnabled ? AppTheme.primaryCyan : AppTheme.textDim,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        servoId.jointName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.textMain,
                        ),
                      ),
                      Text(
                        'Pin ${servoId.pinName} • Limits: ${state.minAngle}° - ${state.maxAngle}°',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textDim,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? AppTheme.statusGreen.withValues(alpha: 0.15)
                        : AppTheme.textDim.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(
                      color: isEnabled ? AppTheme.statusGreen : AppTheme.textDim,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isEnabled ? 'ENABLED' : 'DISABLED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isEnabled ? AppTheme.statusGreen : AppTheme.textDim,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Angles status row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COMMANDED TARGET',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDim,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${state.commandedAngle}°',
                      style: AppTheme.tabularNumbers.copyWith(
                        fontSize: 22,
                        color: isEnabled ? AppTheme.primaryCyan : AppTheme.textDim,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'HARDWARE SERIAL DISPATCH',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDim,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: confirmedColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          confirmedStr,
                          style: AppTheme.tabularNumbers.copyWith(
                            fontSize: 16,
                            color: confirmedColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Slider
            Slider(
              value: state.commandedAngle.toDouble().clamp(
                    state.minAngle.toDouble(),
                    state.maxAngle.toDouble(),
                  ),
              min: state.minAngle.toDouble(),
              max: state.maxAngle.toDouble(),
              divisions: (state.maxAngle - state.minAngle) > 0
                  ? (state.maxAngle - state.minAngle)
                  : 1,
              onChanged: (!isEnabled || isStopped)
                  ? null
                  : (double val) {
                      controller.setServoAngle(servoId, val.round());
                    },
            ),

            // Quick Angle Buttons
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [0, 45, 90, 135, 180].map((quickAngle) {
                final isWithinLimits =
                    quickAngle >= state.minAngle && quickAngle <= state.maxAngle;
                final isCurrent = state.commandedAngle == quickAngle;

                return OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    backgroundColor: isCurrent && isEnabled
                        ? AppTheme.primaryCyan.withValues(alpha: 0.2)
                        : null,
                    side: BorderSide(
                      color: isCurrent && isEnabled
                          ? AppTheme.primaryCyan
                          : AppTheme.border,
                    ),
                  ),
                  onPressed: (!isEnabled || isStopped || !isWithinLimits)
                      ? null
                      : () {
                          controller.setServoAngle(servoId, quickAngle);
                        },
                  child: Text(
                    '$quickAngle°',
                    style: TextStyle(
                      fontSize: 12,
                      color: isWithinLimits && isEnabled
                          ? AppTheme.textMain
                          : AppTheme.textDim.withValues(alpha: 0.4),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
