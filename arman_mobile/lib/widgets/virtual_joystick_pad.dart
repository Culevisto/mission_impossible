import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../controllers/robot_controller.dart';
import '../models/servo_id.dart';

class VirtualJoystickPad extends StatelessWidget {
  const VirtualJoystickPad({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.gamepad_rounded, size: 18, color: AppTheme.primaryCyan),
                SizedBox(width: 8),
                Text(
                  'DUAL VELOCITY JOYSTICKS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppTheme.textMain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 500;
                if (isWide) {
                  return const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: SingleJoystickWidget(
                          title: 'JOYSTICK 1 (BASE / SHOULDER)',
                          horizontalServo: ServoId.A,
                          verticalServo: ServoId.B,
                          horizontalLabel: 'A: Base (D8)',
                          verticalLabel: 'B: Shoulder (D9)',
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: SingleJoystickWidget(
                          title: 'JOYSTICK 2 (ELBOW / WRIST)',
                          horizontalServo: ServoId.C,
                          verticalServo: ServoId.D,
                          horizontalLabel: 'C: Elbow (D10)',
                          verticalLabel: 'D: Wrist (D11)',
                        ),
                      ),
                    ],
                  );
                } else {
                  return const Column(
                    children: [
                      SingleJoystickWidget(
                        title: 'JOYSTICK 1 (BASE / SHOULDER)',
                        horizontalServo: ServoId.A,
                        verticalServo: ServoId.B,
                        horizontalLabel: 'A: Base (D8)',
                        verticalLabel: 'B: Shoulder (D9)',
                      ),
                      SizedBox(height: 16),
                      SingleJoystickWidget(
                        title: 'JOYSTICK 2 (ELBOW / WRIST)',
                        horizontalServo: ServoId.C,
                        verticalServo: ServoId.D,
                        horizontalLabel: 'C: Elbow (D10)',
                        verticalLabel: 'D: Wrist (D11)',
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SingleJoystickWidget extends StatefulWidget {
  final String title;
  final ServoId horizontalServo;
  final ServoId verticalServo;
  final String horizontalLabel;
  final String verticalLabel;

  const SingleJoystickWidget({
    super.key,
    required this.title,
    required this.horizontalServo,
    required this.verticalServo,
    required this.horizontalLabel,
    required this.verticalLabel,
  });

  @override
  State<SingleJoystickWidget> createState() => _SingleJoystickWidgetState();
}

class _SingleJoystickWidgetState extends State<SingleJoystickWidget> {
  static const double _padRadius = 70.0;
  static const double _knobRadius = 24.0;

  Offset _knobOffset = Offset.zero;
  Timer? _integrationTimer;

  void _onPanStart(DragStartDetails details, BoxConstraints constraints) {
    _updateOffset(details.localPosition);
    _startIntegration();
  }

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    _updateOffset(details.localPosition);
  }

  void _onPanEnd(DragEndDetails details) {
    _stopIntegration();
    setState(() {
      _knobOffset = Offset.zero;
    });
  }

  void _onPanCancel() {
    _stopIntegration();
    setState(() {
      _knobOffset = Offset.zero;
    });
  }

  void _updateOffset(Offset localPosition) {
    const center = Offset(_padRadius, _padRadius);
    final delta = localPosition - center;
    final distance = delta.distance;

    Offset clampedOffset;
    if (distance <= _padRadius) {
      clampedOffset = delta;
    } else {
      clampedOffset = Offset.fromDirection(delta.direction, _padRadius);
    }

    setState(() {
      _knobOffset = clampedOffset;
    });
  }

  void _startIntegration() {
    _integrationTimer?.cancel();
    // 50ms = 20 Hz integration loop
    _integrationTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      final controller = context.read<RobotController>();

      final nx = _knobOffset.dx / _padRadius;
      final ny = -_knobOffset.dy / _padRadius; // Upward is positive velocity

      // Apply horizontal axis
      controller.applyJoystickVelocity(widget.horizontalServo, nx, 0.05);

      // Apply vertical axis
      controller.applyJoystickVelocity(widget.verticalServo, ny, 0.05);
    });
  }

  void _stopIntegration() {
    _integrationTimer?.cancel();
    _integrationTimer = null;
  }

  @override
  void dispose() {
    _stopIntegration();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RobotController>();
    final hState = controller.getServo(widget.horizontalServo);
    final vState = controller.getServo(widget.verticalServo);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDim,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: _padRadius * 2,
              height: _padRadius * 2,
              child: GestureDetector(
                onPanStart: (d) => _onPanStart(d, const BoxConstraints()),
                onPanUpdate: (d) => _onPanUpdate(d, const BoxConstraints()),
                onPanEnd: _onPanEnd,
                onPanCancel: _onPanCancel,
                child: CustomPaint(
                  size: const Size(_padRadius * 2, _padRadius * 2),
                  painter: _JoystickPainter(
                    knobOffset: _knobOffset,
                    padRadius: _padRadius,
                    knobRadius: _knobRadius,
                    horizontalActive: hState.isEnabled,
                    verticalActive: vState.isEnabled,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAxisBadge(
                label: widget.horizontalLabel,
                isEnabled: hState.isEnabled,
                angle: hState.commandedAngle,
              ),
              _buildAxisBadge(
                label: widget.verticalLabel,
                isEnabled: vState.isEnabled,
                angle: vState.commandedAngle,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAxisBadge({
    required String label,
    required bool isEnabled,
    required int angle,
  }) {
    final color = isEnabled ? AppTheme.primaryCyan : AppTheme.textDim.withValues(alpha: 0.4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isEnabled ? AppTheme.statusGreen : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: color),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isEnabled ? AppTheme.textMain : AppTheme.textDim.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          isEnabled ? '$angle°' : 'LOCKED (DISABLED)',
          style: TextStyle(
            fontSize: 10,
            fontFeatures: const [FontFeature.tabularFigures()],
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
            color: isEnabled ? AppTheme.primaryCyan : AppTheme.textDim.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}

class _JoystickPainter extends CustomPainter {
  final Offset knobOffset;
  final double padRadius;
  final double knobRadius;
  final bool horizontalActive;
  final bool verticalActive;

  _JoystickPainter({
    required this.knobOffset,
    required this.padRadius,
    required this.knobRadius,
    required this.horizontalActive,
    required this.verticalActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(padRadius, padRadius);

    // Outer boundary circle
    final padPaint = Paint()
      ..color = AppTheme.surface
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, padRadius, padPaint);

    final borderPaint = Paint()
      ..color = AppTheme.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, padRadius, borderPaint);

    // Crosshairs
    final crosshairPaint = Paint()
      ..color = AppTheme.border.withValues(alpha: 0.6)
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(center.dx - padRadius + 8, center.dy),
      Offset(center.dx + padRadius - 8, center.dy),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - padRadius + 8),
      Offset(center.dx, center.dy + padRadius - 8),
      crosshairPaint,
    );

    // Deadzone guide circle (15%)
    final deadzonePaint = Paint()
      ..color = AppTheme.border.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, padRadius * 0.15, deadzonePaint);

    // Center knob position
    final knobCenter = center + knobOffset;

    // Line from center to knob
    if (knobOffset != Offset.zero) {
      final linePaint = Paint()
        ..color = AppTheme.primaryCyan.withValues(alpha: 0.4)
        ..strokeWidth = 2.0;
      canvas.drawLine(center, knobCenter, linePaint);
    }

    // Knob body
    final anyActive = horizontalActive || verticalActive;
    final knobPaint = Paint()
      ..color = anyActive ? AppTheme.electricBlue : AppTheme.border
      ..style = PaintingStyle.fill;
    canvas.drawCircle(knobCenter, knobRadius, knobPaint);

    final knobBorderPaint = Paint()
      ..color = anyActive ? AppTheme.primaryCyan : AppTheme.textDim
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(knobCenter, knobRadius, knobBorderPaint);

    // Inner knob dot
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(knobCenter, 4.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _JoystickPainter oldDelegate) {
    return oldDelegate.knobOffset != knobOffset ||
        oldDelegate.horizontalActive != horizontalActive ||
        oldDelegate.verticalActive != verticalActive;
  }
}
