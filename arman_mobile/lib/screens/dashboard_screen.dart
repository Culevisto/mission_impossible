import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../controllers/robot_controller.dart';
import '../models/servo_id.dart';
import '../widgets/connection_banner.dart';
import '../widgets/global_presets_bar.dart';
import '../widgets/gripper_control_card.dart';
import '../widgets/servo_control_card.dart';
import '../widgets/stop_commands_bar.dart';
import '../widgets/voice_command_sheet.dart';
import 'landscape_controller_screen.dart';
import 'settings_screen.dart';
import 'vision_camera_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RobotController>();
    final isVoiceEnabled = controller.settings.isVoiceControlEnabled;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.electricBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryCyan, width: 1.5),
              ),
              child: const Icon(
                Icons.precision_manufacturing_rounded,
                size: 20,
                color: AppTheme.primaryCyan,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ARMAN',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  '7-AXIS ROBOTIC CONTROLLER',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryCyan,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (isVoiceEnabled)
            IconButton(
              icon: const Icon(Icons.mic_rounded, color: AppTheme.primaryCyan),
              tooltip: 'Voice Commands',
              onPressed: () => VoiceCommandSheet.show(context),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.textMain),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Top Connection Banner
          const ConnectionBanner(),
          const SizedBox(height: 16),

          // Primary Navigation Action Cards (2 Large Hero Cards)
          _buildHeroNavigationCard(
            context: context,
            title: 'CONTROLLER MODE',
            subtitle: '7-Axis Landscape Cockpit • Rotary, Linear & Claw Hold Controls',
            icon: Icons.gamepad_rounded,
            accentColor: AppTheme.primaryCyan,
            badgeText: 'RECOMMENDED',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LandscapeControllerScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildHeroNavigationCard(
            context: context,
            title: 'VISION / CAMERA',
            subtitle: 'Full-Screen Live Phone Camera Feed',
            icon: Icons.videocam_rounded,
            accentColor: AppTheme.electricBlue,
            badgeText: 'LIVE HUD',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VisionCameraScreen()),
              );
            },
          ),
          const SizedBox(height: 20),

          // Quick Global Positioning Presets
          const GlobalPresetsBar(),
          const SizedBox(height: 16),

          // Claw / Gripper Quick Action Panel (Servo G)
          const GripperControlCard(),
          const SizedBox(height: 16),

          // Individual Actuator Fine-Tuning Cards (Servos A through G)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, size: 16, color: AppTheme.primaryCyan),
                SizedBox(width: 8),
                Text(
                  'INDIVIDUAL JOINT ACTUATORS (A–G)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDim,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          ...ServoId.values.map((id) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: ServoControlCard(servoId: id),
              )),
          const SizedBox(height: 8),

          // Telemetry and Diagnostics Log Card
          _buildTelemetryLogCard(controller),
          const SizedBox(height: 16),

          // Prominent Red Stop Commands Bar
          const StopCommandsBar(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeroNavigationCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accentColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                accentColor.withValues(alpha: 0.12),
                AppTheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accentColor, width: 1.5),
                ),
                child: Icon(icon, color: accentColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            color: AppTheme.textMain,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textDim,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: accentColor, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryLogCard(RobotController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.terminal_rounded, size: 16, color: AppTheme.primaryCyan),
                const SizedBox(width: 8),
                const Text(
                  'TELEMETRY & COMMAND LOGS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppTheme.textMain,
                  ),
                ),
                const Spacer(),
                Text(
                  '${controller.logs.length} entries',
                  style: const TextStyle(fontSize: 10, color: AppTheme.textDim),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 110,
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: controller.logs.isEmpty
                  ? const Center(
                      child: Text(
                        'Awaiting robot commands...',
                        style: TextStyle(fontSize: 11, color: AppTheme.textDim),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: controller.logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            controller.logs[index],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              color: AppTheme.primaryCyan,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
