import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../controllers/robot_controller.dart';
import '../models/servo_id.dart';
import '../services/phone_camera_service.dart';
import '../widgets/cockpit/center_camera_overlay.dart';
import '../widgets/cockpit/claw_contour_controller.dart';
import '../widgets/cockpit/rotary_dial_controller.dart';
import '../widgets/cockpit/vertical_axis_controller.dart';

/// Landscape-Locked 7-Controller Robotics Cockpit based on hardware console layout:
/// - Left Console: Dial A (Base) on top, 4 Vertical Faders (B, C, D, F) below.
/// - Center Console: Embedded live camera viewfinder with telemetry and presets.
/// - Right Console: Dial E (Wrist Rotator) on top, Claw with R (Release) & C (Capture) below.
class LandscapeControllerScreen extends StatefulWidget {
  const LandscapeControllerScreen({super.key});

  @override
  State<LandscapeControllerScreen> createState() => _LandscapeControllerScreenState();
}

class _LandscapeControllerScreenState extends State<LandscapeControllerScreen> {
  @override
  void initState() {
    super.initState();
    // Lock orientation to Landscape and enable immersive sticky mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cameraService = context.read<PhoneCameraService>();
      if (!cameraService.isInitialized && !cameraService.isInitializing) {
        cameraService.initialize();
      }
    });
  }

  @override
  void dispose() {
    // Restore normal orientation and UI mode when leaving the cockpit
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final robotController = context.watch<RobotController>();
    final health = robotController.health;
    final isStopped = robotController.isStopped;

    final activeServoCount = robotController.servoStates.values
        .where((s) => s.isEnabled)
        .length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Minimal Tactical HUD Bar
            _buildTacticalHudBar(health, isStopped, activeServoCount, robotController),

            // 2. Main Three-Quadrant Cockpit Console (Left, Center, Right)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // LEFT CONSOLE: Dial A (Base) + Faders (B, C, D, F)
                        _buildLeftConsole(),

                        const SizedBox(width: 8),

                        // CENTER CONSOLE: Embedded Live Camera Viewfinder + Telemetry
                        _buildCenterConsole(robotController),

                        const SizedBox(width: 8),

                        // RIGHT CONSOLE: Dial E (Wrist Rotator) + Claw R & C Buttons
                        _buildRightConsole(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Left Console: Dial A on top, Sliders B, C, D, F below.
  Widget _buildLeftConsole() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Top: Dial A (Base Rotator)
        RotaryDialController(
          servoId: ServoId.A,
          size: 88,
        ),
        SizedBox(height: 6),

        // Bottom: 4 Vertical Faders (B, C, D, F) side by side
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            VerticalAxisController(
              servoId: ServoId.B,
              width: 50,
              trackHeight: 88,
            ),
            SizedBox(width: 4),
            VerticalAxisController(
              servoId: ServoId.C,
              width: 50,
              trackHeight: 88,
            ),
            SizedBox(width: 4),
            VerticalAxisController(
              servoId: ServoId.D,
              width: 50,
              trackHeight: 88,
            ),
            SizedBox(width: 4),
            VerticalAxisController(
              servoId: ServoId.F,
              width: 50,
              trackHeight: 88,
            ),
          ],
        ),
      ],
    );
  }

  /// Center Console: Dedicated Live Camera Viewfinder + Tactical Telemetry Strip.
  Widget _buildCenterConsole(RobotController controller) {
    final isSerialConnected = controller.health.isSerialConnected;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Live Camera Viewfinder Monitor
        const CenterCameraOverlay(
          width: 310,
          height: 185,
        ),
        const SizedBox(height: 6),

        // Center Quick Control Bar (Presets & Status)
        Container(
          width: 310,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Hardware Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: isSerialConnected
                      ? AppTheme.statusGreen.withValues(alpha: 0.15)
                      : AppTheme.statusAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSerialConnected
                        ? AppTheme.statusGreen
                        : AppTheme.statusAmber,
                  ),
                ),
                child: Text(
                  isSerialConnected ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: isSerialConnected
                        ? AppTheme.statusGreen
                        : AppTheme.statusAmber,
                  ),
                ),
              ),

              // Center All (90°) Quick Preset
              InkWell(
                onTap: () {
                  for (final id in ServoId.values) {
                    controller.setServoAngle(id, 90);
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.primaryCyan),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.center_focus_strong_rounded,
                          size: 11, color: AppTheme.primaryCyan),
                      SizedBox(width: 3),
                      Text(
                        'HOME (90°)',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryCyan,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Emergency Stop Action
              InkWell(
                onTap: () {
                  if (controller.isStopped) {
                    controller.resumeControl();
                  } else {
                    controller.stopAllCommands();
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: controller.isStopped
                        ? AppTheme.statusGreen
                        : AppTheme.statusRed,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        controller.isStopped
                            ? Icons.play_arrow_rounded
                            : Icons.front_hand_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        controller.isStopped ? 'RESUME' : 'STOP',
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Right Console: Dial E on top, Claw R & C Buttons below.
  Widget _buildRightConsole() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Top: Dial E (Wrist Rotator)
        RotaryDialController(
          servoId: ServoId.E,
          size: 88,
        ),
        SizedBox(height: 6),

        // Bottom: Claw Controller with R and C Round Buttons
        SizedBox(
          width: 175,
          child: ClawContourController(servoId: ServoId.G),
        ),
      ],
    );
  }

  Widget _buildTacticalHudBar(
    dynamic health,
    bool isStopped,
    int activeServoCount,
    RobotController controller,
  ) {
    final isSerialConnected = health.isSerialConnected as bool? ?? false;

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Back to Portrait Dashboard Button
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_rounded, size: 13, color: AppTheme.primaryCyan),
                  SizedBox(width: 4),
                  Text(
                    'DASHBOARD',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMain,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Branding & Status Badge
          const Text(
            'ARMAN COCKPIT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              color: AppTheme.primaryCyan,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: isSerialConnected
                  ? AppTheme.statusGreen.withValues(alpha: 0.15)
                  : AppTheme.statusAmber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSerialConnected ? AppTheme.statusGreen : AppTheme.statusAmber,
              ),
            ),
            child: Text(
              isSerialConnected ? 'ONLINE' : 'OFFLINE',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: isSerialConnected ? AppTheme.statusGreen : AppTheme.statusAmber,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(
              '$activeServoCount/7 ACTIVE',
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDim,
              ),
            ),
          ),

          const Spacer(),

          // Stop / Resume Quick Indicator
          if (isStopped)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.statusRed,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'HALTED',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
