import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../controllers/robot_controller.dart';
import '../models/servo_id.dart';

class GripperControlCard extends StatelessWidget {
  const GripperControlCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RobotController>();
    final gripperState = controller.getServo(ServoId.G);
    final isEnabled = gripperState.isEnabled;
    final isStopped = controller.isStopped;
    final openAngle = controller.settings.gripperOpenAngle;
    final closeAngle = controller.settings.gripperCloseAngle;

    final isCurrentlyOpen = gripperState.commandedAngle <= (openAngle + 10);
    final isCurrentlyClosed = gripperState.commandedAngle >= (closeAngle - 10);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.back_hand_rounded, size: 18, color: AppTheme.primaryCyan),
                const SizedBox(width: 8),
                const Text(
                  'CLAW / GRIPPER (SERVO G • PIN D7)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppTheme.textMain,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? AppTheme.statusGreen.withValues(alpha: 0.15)
                        : AppTheme.textDim.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(
                      color: isEnabled ? AppTheme.statusGreen : AppTheme.textDim,
                    ),
                  ),
                  child: Text(
                    isEnabled ? 'ENABLED' : 'DISABLED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isEnabled ? AppTheme.statusGreen : AppTheme.textDim,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppTheme.statusAmber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Calibration Notice: Verify mechanical claw linkages before enabling Servo G to avoid stalling SG90 motor gears against end-stops.',
                      style: TextStyle(fontSize: 11, color: AppTheme.textDim),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.lock_open_rounded, size: 18),
                    label: Text('OPEN ($openAngle°)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentlyOpen
                          ? AppTheme.primaryCyan
                          : AppTheme.surface,
                      foregroundColor: isCurrentlyOpen ? Colors.black : Colors.white,
                      side: const BorderSide(color: AppTheme.primaryCyan),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: (!isEnabled || isStopped)
                        ? null
                        : () => controller.openGripper(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.lock_rounded, size: 18),
                    label: Text('CLOSE ($closeAngle°)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentlyClosed
                          ? AppTheme.electricBlue
                          : AppTheme.surface,
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppTheme.electricBlue),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: (!isEnabled || isStopped)
                        ? null
                        : () => controller.closeGripper(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
