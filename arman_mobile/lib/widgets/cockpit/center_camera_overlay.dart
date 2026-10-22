import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../screens/vision_camera_screen.dart';
import '../../services/phone_camera_service.dart';

/// Embedded tactical center camera monitor for the robotics landscape cockpit.
/// Matches the central "CAMERA" screen from the hardware controller schematic.
class CenterCameraOverlay extends StatelessWidget {
  final VoidCallback? onClose;
  final double? width;
  final double? height;

  const CenterCameraOverlay({
    super.key,
    this.onClose,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final cameraService = context.watch<PhoneCameraService>();

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryCyan,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: AppTheme.primaryCyan.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Camera Preview or Safe Fallback
          if (cameraService.isInitialized && cameraService.controller != null)
            CameraPreview(cameraService.controller!)
          else if (cameraService.isInitializing)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.primaryCyan,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'INITIALIZING CAMERA...',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryCyan,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.videocam_rounded,
                      color: AppTheme.primaryCyan,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'CAMERA VIEWPORT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMain,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cameraService.errorMessage ?? 'Tap to initialize live phone feed',
                      style: const TextStyle(
                        fontSize: 8,
                        color: AppTheme.textDim,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => cameraService.retry(),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.primaryCyan, width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh_rounded, size: 12, color: AppTheme.primaryCyan),
                            SizedBox(width: 4),
                            Text(
                              'CONNECT CAMERA',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryCyan,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 2. High-Tech Corner Viewfinder Reticles
          CustomPaint(
            painter: _ViewfinderOverlayPainter(),
          ),

          // 3. Top HUD Status Strip
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: cameraService.isInitialized
                          ? AppTheme.statusGreen
                          : AppTheme.statusAmber,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (cameraService.isInitialized
                                  ? AppTheme.statusGreen
                                  : AppTheme.statusAmber)
                              .withValues(alpha: 0.8),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'CAMERA FEED',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),

                  // Switch Front/Back Lens
                  if (cameraService.hasMultipleCameras)
                    InkWell(
                      onTap: () => cameraService.switchCamera(),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.all(3.0),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.flip_camera_ios_rounded,
                          size: 13,
                          color: AppTheme.primaryCyan,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),

                  // Expand Fullscreen
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const VisionCameraScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.all(3.0),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.fullscreen_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  if (onClose != null) ...[
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: onClose,
                      child: Container(
                        padding: const EdgeInsets.all(3.0),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewfinderOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryCyan.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const cornerLength = 12.0;

    // Top-Left
    canvas.drawLine(const Offset(6, 6), const Offset(6 + cornerLength, 6), paint);
    canvas.drawLine(const Offset(6, 6), const Offset(6, 6 + cornerLength), paint);

    // Top-Right
    canvas.drawLine(Offset(size.width - 6, 6), Offset(size.width - 6 - cornerLength, 6), paint);
    canvas.drawLine(Offset(size.width - 6, 6), Offset(size.width - 6, 6 + cornerLength), paint);

    // Bottom-Left
    canvas.drawLine(Offset(6, size.height - 6), Offset(6 + cornerLength, size.height - 6), paint);
    canvas.drawLine(Offset(6, size.height - 6), Offset(6, size.height - 6 - cornerLength), paint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width - 6, size.height - 6), Offset(size.width - 6 - cornerLength, size.height - 6), paint);
    canvas.drawLine(Offset(size.width - 6, size.height - 6), Offset(size.width - 6, size.height - 6 - cornerLength), paint);

    // Center Crosshair
    final center = Offset(size.width / 2, size.height / 2);
    final reticlePaint = Paint()
      ..color = AppTheme.primaryCyan.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(center.dx - 8, center.dy), Offset(center.dx + 8, center.dy), reticlePaint);
    canvas.drawLine(Offset(center.dx, center.dy - 8), Offset(center.dx, center.dy + 8), reticlePaint);
    canvas.drawCircle(center, 4, Paint()..color = AppTheme.primaryCyan.withValues(alpha: 0.25)..style = PaintingStyle.stroke..strokeWidth = 1.0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
