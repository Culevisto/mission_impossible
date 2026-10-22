import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:arman_mobile/app.dart';
import 'package:arman_mobile/controllers/robot_controller.dart';
import 'package:arman_mobile/models/app_settings_model.dart';
import 'package:arman_mobile/models/servo_id.dart';
import 'package:arman_mobile/screens/landscape_controller_screen.dart';
import 'package:arman_mobile/screens/vision_camera_screen.dart';
import 'package:arman_mobile/services/arman_api_service.dart';
import 'package:arman_mobile/services/phone_camera_service.dart';
import 'package:arman_mobile/services/settings_storage_service.dart';
import 'package:arman_mobile/services/voice_command_parser.dart';
import 'package:arman_mobile/widgets/cockpit/rotary_dial_controller.dart';
import 'package:arman_mobile/widgets/cockpit/vertical_axis_controller.dart';

class MockHttpClient extends http.BaseClient {
  final List<http.Request> recordedRequests = [];
  int simulatedStatusCode = 200;
  bool simulatedSerialDispatched = true;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request is http.Request) {
      recordedRequests.add(request);
    }

    final body = jsonEncode({
      'status': simulatedStatusCode == 200 ? 'success' : 'error',
      'message': 'Simulated response',
      'servo': 'A',
      'angle': 90,
      'serial_dispatched': simulatedSerialDispatched,
      'serialDispatched': simulatedSerialDispatched,
    });

    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      simulatedStatusCode,
      headers: {'content-type': 'application/json'},
    );
  }
}

class FakeSettingsStorage extends SettingsStorageService {
  AppSettingsModel storedSettings = const AppSettingsModel();

  @override
  Future<AppSettingsModel> loadSettings() async => storedSettings;

  @override
  Future<void> saveSettings(AppSettingsModel settings) async {
    storedSettings = settings;
  }
}

class FakeCameraService extends PhoneCameraService {
  @override
  Future<void> initialize({List<dynamic>? preloadedCameras}) async {
    // Safe no-op in headless test environment
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHttpClient mockClient;
  late ArmanApiService apiService;
  late FakeSettingsStorage fakeStorage;
  late RobotController controller;
  late FakeCameraService fakeCameraService;

  setUp(() {
    mockClient = MockHttpClient();
    apiService = ArmanApiService(client: mockClient);
    fakeStorage = FakeSettingsStorage();
    controller = RobotController(
      apiService: apiService,
      storageService: fakeStorage,
    );
    fakeCameraService = FakeCameraService();
  });

  group('ARMAN 7-Axis RobotController Core Logic & Safety Tests', () {
    test('All 7 servos (A–G) exist and are enabled by default for immediate access', () {
      expect(ServoId.values.length, equals(7));
      expect(ServoId.values, equals([
        ServoId.A,
        ServoId.B,
        ServoId.C,
        ServoId.D,
        ServoId.E,
        ServoId.F,
        ServoId.G,
      ]));

      // All 7 servos are accessible and enabled by default
      for (final id in ServoId.values) {
        expect(controller.getServo(id).isEnabled, isTrue);
      }
    });

    test('Servo min and max angle clamping across 7 joints', () async {
      final customSettings = const AppSettingsModel().copyWith(
        minAngles: {ServoId.A: 20, ServoId.G: 15},
        maxAngles: {ServoId.A: 160, ServoId.G: 165},
      );
      await controller.updateSettings(customSettings);

      // Below min
      controller.setServoAngle(ServoId.A, 10);
      expect(controller.getServo(ServoId.A).commandedAngle, equals(20));

      // Above max
      controller.setServoAngle(ServoId.A, 175);
      expect(controller.getServo(ServoId.A).commandedAngle, equals(160));

      // Within bounds
      controller.setServoAngle(ServoId.A, 90);
      expect(controller.getServo(ServoId.A).commandedAngle, equals(90));
    });

    test('Disabled servo protection blocks movement when disabled in settings', () async {
      // Explicitly disable Servo B in settings
      final disabledSettings = controller.settings.copyWith(
        enabledServos: {
          ...controller.settings.enabledServos,
          ServoId.B: false,
        },
      );
      await controller.updateSettings(disabledSettings);

      expect(controller.getServo(ServoId.B).isEnabled, isFalse);
      final initialAngle = controller.getServo(ServoId.B).commandedAngle;
      controller.setServoAngle(ServoId.B, 120);
      expect(controller.getServo(ServoId.B).commandedAngle, equals(initialAngle));

      // Re-enable Servo B and F in settings
      final updatedSettings = controller.settings.copyWith(
        enabledServos: {
          ...controller.settings.enabledServos,
          ServoId.B: true,
          ServoId.F: true,
        },
      );
      await controller.updateSettings(updatedSettings);

      expect(controller.getServo(ServoId.B).isEnabled, isTrue);
      controller.setServoAngle(ServoId.B, 120);
      expect(controller.getServo(ServoId.B).commandedAngle, equals(120));

      expect(controller.getServo(ServoId.F).isEnabled, isTrue);
      controller.setServoAngle(ServoId.F, 75);
      expect(controller.getServo(ServoId.F).commandedAngle, equals(75));
    });

    test('Vertical axis and joystick deadzone filtering with velocity integration', () async {
      final settings = const AppSettingsModel().copyWith(
        joystickDeadzone: 0.15,
        joystickMaxSpeedDegPerSec: 60.0,
      );
      await controller.updateSettings(settings);

      final startAngle = controller.getServo(ServoId.A).commandedAngle;

      // Deflection of 0.10 is inside deadzone (0.15) -> 0 velocity
      controller.applyJoystickVelocity(ServoId.A, 0.10, 0.05);
      expect(controller.getServo(ServoId.A).commandedAngle, equals(startAngle));

      // Full deflection 1.0 for 0.5s -> delta = 1.0 * 60 * 0.5 = +30 degrees
      controller.applyJoystickVelocity(ServoId.A, 1.0, 0.5);
      expect(controller.getServo(ServoId.A).commandedAngle, equals(startAngle + 30));
    });

    test('JSON request formatting and single-flight HTTP dispatch', () async {
      mockClient.simulatedStatusCode = 200;
      mockClient.simulatedSerialDispatched = true;

      controller.setServoAngle(ServoId.A, 90);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(mockClient.recordedRequests.isNotEmpty, isTrue);
      final req = mockClient.recordedRequests.last;
      expect(req.url.path, endsWith('/control'));

      final jsonBody = jsonDecode(req.body) as Map<String, dynamic>;
      expect(jsonBody['servo'], equals('A'));
      expect(jsonBody['angle'], equals(90));
    });

    test('Honest confirmation: serial_dispatched confirmation tracking', () async {
      // Scenario 1: HTTP 200 with serial_dispatched = true
      mockClient.simulatedStatusCode = 200;
      mockClient.simulatedSerialDispatched = true;

      controller.setServoAngle(ServoId.A, 45);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      var stateA = controller.getServo(ServoId.A);
      expect(stateA.lastSerialConfirmedAngle, equals(45));
      expect(stateA.isDispatchedConfirmed, isTrue);

      // Scenario 2: HTTP 503 (Serial port disconnected)
      mockClient.simulatedStatusCode = 503;
      mockClient.simulatedSerialDispatched = false;

      controller.setServoAngle(ServoId.A, 135);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      stateA = controller.getServo(ServoId.A);
      expect(stateA.commandedAngle, equals(135));
      expect(stateA.isDispatchedConfirmed, isFalse);
    });

    test('Stop button immediately halts outgoing commands', () {
      controller.stopAllCommands();
      expect(controller.isStopped, isTrue);

      final prevAngle = controller.getServo(ServoId.A).commandedAngle;
      controller.setServoAngle(ServoId.A, prevAngle + 10);
      expect(controller.getServo(ServoId.A).commandedAngle, equals(prevAngle));

      controller.resumeControl();
      expect(controller.isStopped, isFalse);
      controller.setServoAngle(ServoId.A, prevAngle + 10);
      expect(controller.getServo(ServoId.A).commandedAngle, equals(prevAngle + 10));
    });

    test('Voice command parsing and robotic execution for 7 joints and Claw G', () {
      // 1. Move Servo A
      final moveResA = VoiceCommandParser.parse('Move servo A to 45 degrees');
      expect(moveResA.intent, equals('MOVE_SERVO'));
      expect(moveResA.servoId, equals(ServoId.A));
      expect(moveResA.targetAngle, equals(45));

      controller.executeVoiceCommand(moveResA);
      expect(controller.getServo(ServoId.A).commandedAngle, equals(45));

      // 2. Move Servo F (Wrist Tilt)
      final moveResF = VoiceCommandParser.parse('Set servo F to 60');
      expect(moveResF.intent, equals('MOVE_SERVO'));
      expect(moveResF.servoId, equals(ServoId.F));
      expect(moveResF.targetAngle, equals(60));

      // 3. Open Claw -> maps to Servo G
      final openRes = VoiceCommandParser.parse('Open claw');
      expect(openRes.intent, equals('OPEN_GRIPPER'));
      expect(openRes.servoId, equals(ServoId.G));
      expect(openRes.targetAngle, equals(30));

      // 4. Close Claw -> maps to Servo G
      final closeRes = VoiceCommandParser.parse('Close gripper');
      expect(closeRes.intent, equals('CLOSE_GRIPPER'));
      expect(closeRes.servoId, equals(ServoId.G));
      expect(closeRes.targetAngle, equals(150));

      // 5. Emergency Stop
      final stopRes = VoiceCommandParser.parse('Emergency stop');
      expect(stopRes.intent, equals('STOP'));
      controller.executeVoiceCommand(stopRes);
      expect(controller.isStopped, isTrue);
    });

    test('Claw progress fraction calculation for Release and Capture', () {
      const openAngle = 30;
      const closeAngle = 150;
      const totalSpan = closeAngle - openAngle; // 120

      // When claw is at 30° (fully open)
      int currentAngle = 30;
      double captureFraction = ((currentAngle - openAngle) / totalSpan).clamp(0.0, 1.0);
      double releaseFraction = (1.0 - captureFraction).clamp(0.0, 1.0);
      expect(captureFraction, equals(0.0));
      expect(releaseFraction, equals(1.0));

      // When claw is at 90° (midway)
      currentAngle = 90;
      captureFraction = ((currentAngle - openAngle) / totalSpan).clamp(0.0, 1.0);
      releaseFraction = (1.0 - captureFraction).clamp(0.0, 1.0);
      expect(captureFraction, closeTo(0.5, 0.01));
      expect(releaseFraction, closeTo(0.5, 0.01));

      // When claw is at 150° (fully closed)
      currentAngle = 150;
      captureFraction = ((currentAngle - openAngle) / totalSpan).clamp(0.0, 1.0);
      releaseFraction = (1.0 - captureFraction).clamp(0.0, 1.0);
      expect(captureFraction, equals(1.0));
      expect(releaseFraction, equals(0.0));
    });
  });

  group('Navigation & Cockpit UI Widget Tests', () {
    testWidgets('Dashboard renders and navigates to Landscape Cockpit Screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ArmanApp(
          controller: controller,
          cameraService: fakeCameraService,
        ),
      );
      await tester.pumpAndSettle();

      // Verify Hero Navigation Cards on Dashboard
      expect(find.text('CONTROLLER MODE'), findsOneWidget);
      expect(find.text('VISION / CAMERA'), findsOneWidget);

      // Tap CONTROLLER MODE hero card
      await tester.tap(find.text('CONTROLLER MODE'));
      await tester.pumpAndSettle();

      // Verify Landscape Cockpit Screen opened
      expect(find.byType(LandscapeControllerScreen), findsOneWidget);
      expect(find.text('ARMAN COCKPIT'), findsOneWidget);

      // Verify Rotary Dial Controllers (Servo A and Servo E)
      expect(find.byType(RotaryDialController), findsNWidgets(2));

      // Verify Vertical Axis Controllers (Servos B, C, D, F)
      expect(find.byType(VerticalAxisController), findsNWidgets(4));

      // Return to Dashboard
      await tester.tap(find.text('DASHBOARD'));
      await tester.pumpAndSettle();
      expect(find.byType(LandscapeControllerScreen), findsNothing);
    });

    testWidgets('Dashboard navigates to Vision / Camera Screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ArmanApp(
          controller: controller,
          cameraService: fakeCameraService,
        ),
      );
      await tester.pumpAndSettle();

      // Tap VISION / CAMERA hero card
      await tester.tap(find.text('VISION / CAMERA'));
      await tester.pumpAndSettle();

      // Verify Vision Camera Screen opened
      expect(find.byType(VisionCameraScreen), findsOneWidget);
      expect(find.text('LIVE PHONE VISION'), findsOneWidget);
    });
  });
}
