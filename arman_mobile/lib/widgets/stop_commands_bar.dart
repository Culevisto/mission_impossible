import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../controllers/robot_controller.dart';

class StopCommandsBar extends StatelessWidget {
  const StopCommandsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RobotController>();
    final isStopped = controller.isStopped;

    if (isStopped) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.statusRed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.statusRed, width: 2),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppTheme.statusRed, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'SOFTWARE COMMAND STOP ACTIVE',
                    style: TextStyle(
                      color: AppTheme.statusRed,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Outgoing app commands are halted. Does not cut 5V hardware power to servos.',
              style: TextStyle(
                color: AppTheme.textMain,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow_rounded, size: 24),
                label: const Text(
                  'RESUME CONTROL',
                  style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.statusGreen,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => controller.resumeControl(),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.front_hand_rounded, size: 24),
        label: const Text(
          'STOP COMMANDS',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.statusRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: AppTheme.statusRed.withValues(alpha: 0.5),
        ),
        onPressed: () => controller.stopAllCommands(),
      ),
    );
  }
}
