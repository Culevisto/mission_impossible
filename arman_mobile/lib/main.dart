import 'package:flutter/material.dart';
import 'app.dart';
import 'controllers/robot_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final robotController = RobotController();
  await robotController.init();

  runApp(ArmanApp(controller: robotController));
}
