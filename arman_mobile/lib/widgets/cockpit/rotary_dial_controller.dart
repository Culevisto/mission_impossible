import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../controllers/robot_controller.dart';
import '../../models/servo_id.dart';

class RotaryDialController extends StatefulWidget {
  final ServoId servoId;
  final double size;

  const RotaryDialController({
    super.key,
    required this.servoId,
    this.size = 92,
  });

  @override
  State<RotaryDialController> createState() => _RotaryDialControllerState();
}

class _RotaryDialControllerState extends State<RotaryDialController> {
  double? _lastTouchAngle;
  double _accumulatedAngle = 90.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final state = context.read<RobotController>().getServo(widget.servoId);
        setState(() {
          _accumulatedAngle = state.commandedAngle.toDouble();
        });
      }
    });
  }

  void _onPanStart(DragStartDetails details, Offset center) {
    final dx = details.localPosition.dx - center.dx;
    final dy = details.localPosition.dy - center.dy;
    _lastTouchAngle = math.atan2(dy, dx);
    final state = context.read<RobotController>().getServo(widget.servoId);
    _accumulatedAngle = state.commandedAngle.toDouble();
  }

  void _onPanUpdate(DragUpdateDetails details, Offset center) {
    if (_lastTouchAngle == null) return;

    final controller = context.read<RobotController>();
    final state = controller.getServo(widget.servoId);
    if (!state.isEnabled || controller.isStopped) return;

    final dx = details.localPosition.dx - center.dx;
    final dy = details.localPosition.dy - center.dy;
    final currentTouchAngle = math.atan2(dy, dx);

    double delta = currentTouchAngle - _lastTouchAngle!;
    // Normalize angular wrap-around (-pi to +pi)
    if (delta > math.pi) {
      delta -= 2 * math.pi;
    } else if (delta < -math.pi) {
      delta += 2 * math.pi;
    }

    _lastTouchAngle = currentTouchAngle;

    // Convert radian delta to degrees (sensitivity factor 1.0)
    final degDelta = delta * (180.0 / math.pi);
    _accumulatedAngle += degDelta;
    final clamped = _accumulatedAngle.clamp(
      state.minAngle.toDouble(),
      state.maxAngle.toDouble(),
    );
    _accumulatedAngle = clamped;

    controller.setServoAngle(widget.servoId, clamped.round());
  }

  void _onPanEnd(DragEndDetails details) {
    _lastTouchAngle = null;
  }

  void _onPanCancel() {
    _lastTouchAngle = null;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RobotController>();
    final state = controller.getServo(widget.servoId);
    final isEnabled = state.isEnabled;
    final isStopped = controller.isStopped;

    final center = Offset(widget.size / 2, widget.size / 2);

    return Container(
      width: widget.size + 16,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled
              ? AppTheme.primaryCyan.withValues(alpha: 0.3)
              : AppTheme.border,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          const SizedBox(height: 2),
          Text(
            widget.servoId.jointName,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMain,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // 360° Circular Dial
          GestureDetector(
            onPanStart: isEnabled && !isStopped
                ? (d) => _onPanStart(d, center)
                : null,
            onPanUpdate: isEnabled && !isStopped
                ? (d) => _onPanUpdate(d, center)
                : null,
            onPanEnd: _onPanEnd,
            onPanCancel: _onPanCancel,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _RotaryDialPainter(
                      angleDegrees: state.commandedAngle.toDouble(),
                      minAngle: state.minAngle.toDouble(),
                      maxAngle: state.maxAngle.toDouble(),
                      isEnabled: isEnabled,
                    ),
                  ),
                  // Center Degree Readout
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${state.commandedAngle}°',
                        style: AppTheme.tabularNumbers.copyWith(
                          fontSize: 18,
                          color: isEnabled
                              ? AppTheme.primaryCyan
                              : AppTheme.textDim,
                        ),
                      ),
                      Text(
                        isEnabled ? 'ROTARY 360°' : 'DISABLED',
                        style: const TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDim,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  if (!isEnabled)
                    Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.4),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: AppTheme.textDim,
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RotaryDialPainter extends CustomPainter {
  final double angleDegrees;
  final double minAngle;
  final double maxAngle;
  final bool isEnabled;

  _RotaryDialPainter({
    required this.angleDegrees,
    required this.minAngle,
    required this.maxAngle,
    required this.isEnabled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 8;

    // Track Background Circle
    final bgPaint = Paint()
      ..color = AppTheme.background
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    final trackBorderPaint = Paint()
      ..color = AppTheme.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, trackBorderPaint);

    // 360° Tick Marks
    final tickPaint = Paint()
      ..color = AppTheme.border.withValues(alpha: 0.7)
      ..strokeWidth = 1.0;
    final majorTickPaint = Paint()
      ..color = isEnabled
          ? AppTheme.primaryCyan.withValues(alpha: 0.5)
          : AppTheme.textDim.withValues(alpha: 0.3)
      ..strokeWidth = 1.5;

    for (int deg = 0; deg < 360; deg += 15) {
      final isMajor = deg % 45 == 0;
      final rad = deg * (math.pi / 180.0);
      final tickLength = isMajor ? 6.0 : 3.0;

      final startOffset = Offset(
        center.dx + (radius - tickLength) * math.cos(rad),
        center.dy + (radius - tickLength) * math.sin(rad),
      );
      final endOffset = Offset(
        center.dx + radius * math.cos(rad),
        center.dy + radius * math.sin(rad),
      );

      canvas.drawLine(startOffset, endOffset, isMajor ? majorTickPaint : tickPaint);
    }

    // Active Arc representing current 0° to 180° servo position
    // We map 0°..180° to a 240° arc starting from bottom-left (150° in standard radians)
    const double arcStartRad = 150.0 * (math.pi / 180.0);
    const double arcTotalSweepRad = 240.0 * (math.pi / 180.0);

    final normalizedFraction =
        ((angleDegrees - minAngle) / ((maxAngle - minAngle) > 0 ? (maxAngle - minAngle) : 1))
            .clamp(0.0, 1.0);
    final currentSweepRad = arcTotalSweepRad * normalizedFraction;

    // Inactive Arc Rail
    final railPaint = Paint()
      ..color = AppTheme.border.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      arcStartRad,
      arcTotalSweepRad,
      false,
      railPaint,
    );

    // Glowing Active Arc
    if (isEnabled) {
      final glowPaint = Paint()
        ..color = AppTheme.primaryCyan.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9.0
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 10),
        arcStartRad,
        currentSweepRad,
        false,
        glowPaint,
      );

      final activeArcPaint = Paint()
        ..color = AppTheme.primaryCyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 10),
        arcStartRad,
        currentSweepRad,
        false,
        activeArcPaint,
      );
    }

    // Handle Knob on Perimeter
    final handleAngleRad = arcStartRad + currentSweepRad;
    final handleCenter = Offset(
      center.dx + (radius - 10) * math.cos(handleAngleRad),
      center.dy + (radius - 10) * math.sin(handleAngleRad),
    );

    final handlePaint = Paint()
      ..color = isEnabled ? AppTheme.electricBlue : AppTheme.border
      ..style = PaintingStyle.fill;
    canvas.drawCircle(handleCenter, 6.0, handlePaint);

    final handleBorderPaint = Paint()
      ..color = isEnabled ? Colors.white : AppTheme.textDim
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(handleCenter, 6.0, handleBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _RotaryDialPainter oldDelegate) {
    return oldDelegate.angleDegrees != angleDegrees ||
        oldDelegate.isEnabled != isEnabled ||
        oldDelegate.minAngle != minAngle ||
        oldDelegate.maxAngle != maxAngle;
  }
}
