import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../controllers/robot_controller.dart';
import '../services/phone_camera_service.dart';

class VisionCameraScreen extends StatefulWidget {
  const VisionCameraScreen({super.key});

  @override
  State<VisionCameraScreen> createState() => _VisionCameraScreenState();
}

class _VisionCameraScreenState extends State<VisionCameraScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cameraService = context.read<PhoneCameraService>();
      if (!cameraService.isInitialized && !cameraService.isInitializing) {
        cameraService.initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cameraService = context.watch<PhoneCameraService>();
    final robotController = context.watch<RobotController>();
    final isConnected = robotController.health.isSerialConnected;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            const Icon(Icons.videocam_rounded, color: AppTheme.primaryCyan, size: 20),
            const SizedBox(width: 8),
            const Text(
              'LIVE PHONE VISION',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isConnected
                    ? AppTheme.statusGreen.withValues(alpha: 0.2)
                    : AppTheme.statusAmber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(
                  color: isConnected ? AppTheme.statusGreen : AppTheme.statusAmber,
                  width: 1,
                ),
              ),
              child: Text(
                isConnected ? 'SERIAL ONLINE' : 'STANDBY',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isConnected ? AppTheme.statusGreen : AppTheme.statusAmber,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (cameraService.hasMultipleCameras)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios_rounded, color: AppTheme.primaryCyan),
              tooltip: 'Flip Camera (Front/Back)',
              onPressed: () => cameraService.switchCamera(),
            ),
        ],
      ),
      body: SafeArea(
        child: _buildCameraBody(cameraService),
      ),
    );
  }

  Widget _buildCameraBody(PhoneCameraService cameraService) {
    if (cameraService.isInitialized && cameraService.controller != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: cameraService.controller!.value.aspectRatio,
          child: CameraPreview(cameraService.controller!),
        ),
      );
    }

    if (cameraService.isInitializing) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryCyan),
            SizedBox(height: 16),
            Text(
              'Initializing camera sensor...',
              style: TextStyle(color: AppTheme.textDim, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Fallback UI when camera is denied or hardware unavailable
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_rounded, size: 48, color: AppTheme.statusAmber),
            const SizedBox(height: 16),
            const Text(
              'Camera Stream Unavailable',
              style: TextStyle(
                color: AppTheme.textMain,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cameraService.errorMessage ??
                  'Unable to access physical camera sensor on this platform.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textDim, fontSize: 12),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry Camera'),
              onPressed: () => cameraService.retry(),
            ),
          ],
        ),
      ),
    );
  }
}
