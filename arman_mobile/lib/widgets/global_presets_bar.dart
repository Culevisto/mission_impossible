import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../controllers/robot_controller.dart';

class GlobalPresetsBar extends StatelessWidget {
  const GlobalPresetsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RobotController>();
    final isStopped = controller.isStopped;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.tune_rounded, size: 18, color: AppTheme.primaryCyan),
                SizedBox(width: 8),
                Text(
                  'GLOBAL POSITION PRESETS (ACTIVE SERVOS ONLY)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppTheme.textMain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isStopped ? null : () => controller.setAllActiveTo(0),
                    child: const Text('ALL ACTIVE → 0°'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isStopped ? null : () => controller.setAllActiveTo(90),
                    child: const Text('CENTER → 90°'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: isStopped ? null : () => controller.setAllActiveTo(180),
                    child: const Text('ALL ACTIVE → 180°'),
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
