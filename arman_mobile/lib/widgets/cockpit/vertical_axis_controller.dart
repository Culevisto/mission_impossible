import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../controllers/robot_controller.dart';
import '../../models/servo_id.dart';

/// Precision direct-position console fader for robotic joints (Servos B, C, D, F).
/// The fader cap directly reflects and controls the joint angle from 0° (bottom) to 180° (top).
class VerticalAxisController extends StatelessWidget {
  final ServoId servoId;
  final double trackHeight;
  final double width;

  const VerticalAxisController({
    super.key,
    required this.servoId,
    this.trackHeight = 92,
    this.width = 54,
  });

  void _updateAngleFromY(
    BuildContext context,
    double localY,
    double height,
    int minAngle,
    int maxAngle,
  ) {
    final controller = context.read<RobotController>();
    final state = controller.getServo(servoId);
    if (!state.isEnabled || controller.isStopped) return;

    final clampedY = localY.clamp(0.0, height);
    // Invert: 0 at bottom, 1 at top
    final fraction = (1.0 - (clampedY / height)).clamp(0.0, 1.0);
    final targetAngle = (minAngle + fraction * (maxAngle - minAngle)).round();

    controller.setServoAngle(servoId, targetAngle);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RobotController>();
    final state = controller.getServo(servoId);
    final isEnabled = state.isEnabled;
    final isStopped = controller.isStopped;

    final minAngle = state.minAngle;
    final maxAngle = state.maxAngle;
    final span = (maxAngle - minAngle) > 0 ? (maxAngle - minAngle) : 180;
    final fraction = ((state.commandedAngle - minAngle) / span).clamp(0.0, 1.0);

    const capHeight = 22.0;
    final usableHeight = trackHeight - capHeight;
    // Top offset: when fraction = 1.0 (180°), offset = 0. When fraction = 0.0 (0°), offset = usableHeight.
    final capTopOffset = (1.0 - fraction) * usableHeight;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isEnabled
              ? AppTheme.primaryCyan.withValues(alpha: 0.35)
              : AppTheme.border,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Joint Code & Pin Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: isEnabled
                  ? AppTheme.primaryCyan.withValues(alpha: 0.2)
                  : AppTheme.border,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${servoId.code} • ${servoId.pinName}',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: isEnabled ? AppTheme.primaryCyan : AppTheme.textDim,
              ),
            ),
          ),
          const SizedBox(height: 2),

          // Joint Name Abbreviation
          Text(
            _shortJointName(servoId),
            style: const TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMain,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),

          // Live Degree Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(
              '${state.commandedAngle}°',
              style: AppTheme.tabularNumbers.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isEnabled ? AppTheme.primaryCyan : AppTheme.textDim,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Direct-Position Drag Track
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragStart: isEnabled && !isStopped
                ? (details) => _updateAngleFromY(
                      context,
                      details.localPosition.dy,
                      trackHeight,
                      minAngle,
                      maxAngle,
                    )
                : null,
            onVerticalDragUpdate: isEnabled && !isStopped
                ? (details) => _updateAngleFromY(
                      context,
                      details.localPosition.dy,
                      trackHeight,
                      minAngle,
                      maxAngle,
                    )
                : null,
            onTapDown: isEnabled && !isStopped
                ? (details) => _updateAngleFromY(
                      context,
                      details.localPosition.dy,
                      trackHeight,
                      minAngle,
                      maxAngle,
                    )
                : null,
            child: SizedBox(
              width: width - 4,
              height: trackHeight,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Outer Fader Slot Track
                  Container(
                    width: 14,
                    height: trackHeight,
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border, width: 1.2),
                    ),
                  ),

                  // Center Reference Groove & Tick Marks
                  Positioned(
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: AppTheme.border.withValues(alpha: 0.6),
                    ),
                  ),

                  // 90° Midpoint Detent Tick
                  Positioned(
                    top: trackHeight / 2 - 0.75,
                    child: Container(
                      width: 18,
                      height: 1.5,
                      color: AppTheme.primaryCyan.withValues(alpha: 0.5),
                    ),
                  ),

                  // Active Fill Level inside Slot (up to current position)
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: (trackHeight * fraction).clamp(0.0, trackHeight),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? AppTheme.primaryCyan.withValues(alpha: 0.25)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  // Tactile Fader Cap (Handle)
                  Positioned(
                    top: capTopOffset.clamp(0.0, usableHeight),
                    child: Container(
                      width: width - 8,
                      height: capHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isEnabled
                              ? [
                                  AppTheme.electricBlue,
                                  const Color(0xFF152A4A),
                                ]
                              : [
                                  AppTheme.surface,
                                  AppTheme.background,
                                ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isEnabled
                              ? AppTheme.primaryCyan
                              : AppTheme.textDim,
                          width: 1.5,
                        ),
                        boxShadow: [
                          if (isEnabled)
                            BoxShadow(
                              color: AppTheme.primaryCyan.withValues(alpha: 0.35),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 16,
                            height: 1.5,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 16,
                            height: 1.5,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (!isEnabled)
                    Container(
                      width: width - 4,
                      height: trackHeight,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.lock_outline_rounded,
                          color: AppTheme.textDim,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),

          // Bottom Label
          Text(
            isEnabled ? '0°–180°' : 'LOCKED',
            style: const TextStyle(
              fontSize: 6.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDim,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  String _shortJointName(ServoId id) {
    switch (id) {
      case ServoId.B:
        return 'Shoulder';
      case ServoId.C:
        return 'Elbow';
      case ServoId.D:
        return 'Forearm';
      case ServoId.F:
        return 'Wrist Tilt';
      default:
        return id.jointName;
    }
  }
}
