import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'controllers/robot_controller.dart';
import 'screens/dashboard_screen.dart';
import 'services/phone_camera_service.dart';

class ArmanApp extends StatelessWidget {
  final RobotController controller;
  final PhoneCameraService? cameraService;

  const ArmanApp({
    super.key,
    required this.controller,
    this.cameraService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RobotController>.value(value: controller),
        ChangeNotifierProvider<PhoneCameraService>(
          create: (_) => cameraService ?? PhoneCameraService(),
        ),
      ],
      child: MaterialApp(
        title: 'ARMAN Robotics Controller',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const DashboardScreen(),
      ),
    );
  }
}
