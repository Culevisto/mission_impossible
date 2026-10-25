import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../controllers/robot_controller.dart';
import '../../models/servo_id.dart';

/// Tactical Claw Controller featuring large round "R" (Release) and "C" (Capture) buttons
/// with real-time radial contour progress animations and instant tap or hold actuation.
class ClawContourController extends StatefulWidget {
  final ServoId servoId;

  const ClawContourController({
    super.key,
    this.servoId = ServoId.G,
  });

  @override
  State<ClawContourController> createState() => _ClawContourControllerState();
}

class _ClawContourControllerState extends State<ClawContourController> {
  Timer? _holdTimer;
  bool _isReleasing = false;
  bool _isCapturing = false;

  void _triggerSnap({required bool isRelease}) {
    final controller = context.read<RobotController>();
    final state = controller.getServo(widget.servoId);
    if (!state.isEnabled || controller.isStopped) return;

    final target = isRelease
        ? controller.settings.gripperOpenAngle
        : controller.settings.gripperCloseAngle;
    controller.setServoAngle(widget.servoId, target);
  }

  void _startHolding({required bool isRelease}) {
    _stopHolding();

    setState(() {
      if (isRelease) {
        _isReleasing = true;
      } else {
        _isCapturing = true;
      }
    });

    // 40ms tick = 25 Hz update rate
    _holdTimer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!mounted) return;
      final controller = context.read<RobotController>();
      final state = controller.getServo(widget.servoId);
      if (!state.isEnabled || controller.isStopped) {
        _stopHolding();
        return;
      }

      final openAngle = controller.settings.gripperOpenAngle;
      final closeAngle = controller.settings.gripperCloseAngle;
      final currentAngle = state.commandedAngle;

      if (isRelease) {
        // Move towards open angle (usually smaller, e.g. 30°)
        if (currentAngle > openAngle) {
          final nextAngle = math.max(openAngle, currentAngle - 2);
          controller.setServoAngle(widget.servoId, nextAngle);
        } else if (currentAngle < openAngle) {
          final nextAngle = math.min(openAngle, currentAngle + 2);
          controller.setServoAngle(widget.servoId, nextAngle);
        }
      } else {
        // Move towards close angle (usually larger, e.g. 150°)
        if (currentAngle < closeAngle) {
          final nextAngle = math.min(closeAngle, currentAngle + 2);
          controller.setServoAngle(widget.servoId, nextAngle);
        } else if (currentAngle > closeAngle) {
          final nextAngle = math.max(closeAngle, currentAngle - 2);
          controller.setServoAngle(widget.servoId, nextAngle);
        }
      }
    });
  }

  void _stopHolding() {
    _holdTimer?.cancel();
    _holdTimer = null;
    if (_isReleasing || _isCapturing) {
      setState(() {
        _isReleasing = false;
        _isCapturing = false;
      });
    }
  }

  @override
  void dispose() {
    _stopHolding();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RobotController>();
    final state = controller.getServo(widget.servoId);
    final isEnabled = state.isEnabled;
    final isStopped = controller.isStopped;

    final openAngle = controller.settings.gripperOpenAngle;
    final closeAngle = controller.settings.gripperCloseAngle;
    final totalSpan = (closeAngle - openAngle).abs() > 0 ? (closeAngle - openAngle).abs() : 1;

    // Progress fractions for contour rings (0.0 to 1.0)
    final captureFraction =
        ((state.commandedAngle - math.min(openAngle, closeAngle)) / totalSpan)
            .clamp(0.0, 1.0);
    final releaseFraction = (1.0 - captureFraction).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
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
          // Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? AppTheme.primaryCyan.withValues(alpha: 0.2)
                      : AppTheme.border,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${widget.servoId.code} • ${widget.servoId.pinName}',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: isEnabled ? AppTheme.primaryCyan : AppTheme.textDim,
                  ),
                ),
              ),
              Text(
                isEnabled ? 'CLAW' : 'LOCKED',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: isEnabled ? AppTheme.statusGreen : AppTheme.textDim,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),

          // Upper Live Degree Readout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(
              'CLAW: ${state.commandedAngle}°',
              style: AppTheme.tabularNumbers.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isEnabled ? AppTheme.primaryCyan : AppTheme.textDim,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Two Round R and C Buttons matching user sketch
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // R (RELEASE) Button (Left)
              _buildRoundTactileButton(
                letter: 'R',
                subLabel: 'RELEASE',
                isHolding: _isReleasing,
                progressFraction: releaseFraction,
                accentColor: AppTheme.primaryCyan,
                isEnabled: isEnabled && !isStopped,
                onTap: () => _triggerSnap(isRelease: true),
                onHoldStart: () => _startHolding(isRelease: true),
                onHoldStop: _stopHolding,
              ),
              const SizedBox(width: 12),
              // C (CAPTURE) Button (Right)
              _buildRoundTactileButton(
                letter: 'C',
                subLabel: 'CAPTURE',
                isHolding: _isCapturing,
                progressFraction: captureFraction,
                accentColor: AppTheme.electricBlue,
                isEnabled: isEnabled && !isStopped,
                onTap: () => _triggerSnap(isRelease: false),
                onHoldStart: () => _startHolding(isRelease: false),
                onHoldStop: _stopHolding,
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text(
            'TAP SNAP • HOLD GLIDE',
            style: TextStyle(
              fontSize: 6.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDim,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundTactileButton({
    required String letter,
    required String subLabel,
    required bool isHolding,
    required double progressFraction,
    required Color accentColor,
    required bool isEnabled,
    required VoidCallback onTap,
    required VoidCallback onHoldStart,
    required VoidCallback onHoldStop,
  }) {
    const double buttonSize = 46.0;

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      onLongPressStart: isEnabled ? (_) => onHoldStart() : null,
      onLongPressEnd: (_) => onHoldStop(),
      onLongPressCancel: onHoldStop,
      child: Column(
        children: [
          CustomPaint(
            painter: _ContourRingPainter(
              progress: progressFraction,
              isHolding: isHolding,
              color: accentColor,
              isEnabled: isEnabled,
            ),
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isHolding
                      ? [
                          accentColor,
                          accentColor.withValues(alpha: 0.6),
                        ]
                      : [
                          AppTheme.surface,
                          AppTheme.background,
                        ],
                ),
                border: Border.all(
                  color: isEnabled ? accentColor : AppTheme.border,
                  width: 1.5,
                ),
                boxShadow: [
                  if (isEnabled)
                    BoxShadow(
                      color: isHolding
                          ? accentColor.withValues(alpha: 0.6)
                          : accentColor.withValues(alpha: 0.15),
                      blurRadius: isHolding ? 10 : 4,
                      spreadRadius: isHolding ? 2 : 0,
                    ),
                ],
              ),
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: isEnabled
                        ? (isHolding ? Colors.black : accentColor)
                        : AppTheme.textDim,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subLabel,
            style: TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isEnabled
                  ? (isHolding ? Colors.white : AppTheme.textMain)
                  : AppTheme.textDim,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContourRingPainter extends CustomPainter {
  final double progress;
  final bool isHolding;
  final Color color;
  final bool isEnabled;

  _ContourRingPainter({
    required this.progress,
    required this.isHolding,
    required this.color,
    required this.isEnabled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) + 3;

    // Track Background
    final trackPaint = Paint()
      ..color = AppTheme.border.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius, trackPaint);

    if (isEnabled && progress > 0.0) {
      final sweepAngle = 2 * math.pi * progress;
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHolding ? 3.5 : 2.5
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ContourRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isHolding != isHolding ||
        oldDelegate.isEnabled != isEnabled ||
        oldDelegate.color != color;
  }
}
