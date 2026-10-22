import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../controllers/robot_controller.dart';
import '../models/app_settings_model.dart';
import '../models/servo_id.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _serverUrlController;
  late TextEditingController _cameraUrlController;

  late Map<ServoId, bool> _enabledServos;
  late Map<ServoId, int> _minAngles;
  late Map<ServoId, int> _maxAngles;
  late double _joystickDeadzone;
  late double _joystickSpeed;
  late int _gripperOpenAngle;
  late int _gripperCloseAngle;
  late bool _voiceEnabled;

  bool _isTestingConnection = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    final settings = context.read<RobotController>().settings;
    _serverUrlController = TextEditingController(text: settings.serverUrl);
    _cameraUrlController = TextEditingController(text: settings.cameraStreamUrl);

    _enabledServos = Map.of(settings.enabledServos);
    _minAngles = Map.of(settings.minAngles);
    _maxAngles = Map.of(settings.maxAngles);
    _joystickDeadzone = settings.joystickDeadzone;
    _joystickSpeed = settings.joystickMaxSpeedDegPerSec;
    _gripperOpenAngle = settings.gripperOpenAngle;
    _gripperCloseAngle = settings.gripperCloseAngle;
    _voiceEnabled = settings.isVoiceControlEnabled;
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _cameraUrlController.dispose();
    super.dispose();
  }

  void _enableAllServosDemo() {
    setState(() {
      for (final id in ServoId.values) {
        _enabledServos[id] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All 7 Servos (A–G) enabled for Cockpit Demo Mode!'),
        backgroundColor: AppTheme.primaryCyan,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _resetToDefault() {
    setState(() {
      for (final id in ServoId.values) {
        _enabledServos[id] = id.defaultEnabled; // Only A is true
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reset to hardware default: Only Servo A enabled.'),
        backgroundColor: AppTheme.statusAmber,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _testResult = null;
    });

    final controller = context.read<RobotController>();
    await controller.checkHealth();
    final health = controller.health;

    if (mounted) {
      setState(() {
        _isTestingConnection = false;
        if (health.isOnline) {
          _testResult = health.isSerialConnected
              ? 'Connected to Spring Boot & Arduino (${health.serialPort})'
              : 'Spring Boot is Online, but Serial is Disconnected';
        } else {
          _testResult = 'Connection Failed: ${health.errorMessage}';
        }
      });
    }
  }

  Future<void> _saveSettings() async {
    final controller = context.read<RobotController>();

    final updated = AppSettingsModel(
      serverUrl: _serverUrlController.text.trim(),
      cameraStreamUrl: _cameraUrlController.text.trim(),
      enabledServos: _enabledServos,
      minAngles: _minAngles,
      maxAngles: _maxAngles,
      joystickDeadzone: _joystickDeadzone,
      joystickMaxSpeedDegPerSec: _joystickSpeed,
      gripperOpenAngle: _gripperOpenAngle,
      gripperCloseAngle: _gripperCloseAngle,
      isVoiceControlEnabled: _voiceEnabled,
    );

    await controller.updateSettings(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ARMAN settings saved successfully'),
          backgroundColor: AppTheme.statusGreen,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Robot Settings & 7-Axis Safety Limits'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.check, color: AppTheme.primaryCyan),
            label: const Text(
              'SAVE',
              style: TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.w700),
            ),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section 1: Server & Network
          _buildSectionHeader('SERVER & NETWORK CONNECTION'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _serverUrlController,
                    decoration: InputDecoration(
                      labelText: 'Spring Boot Server URL',
                      hintText: 'http://192.168.1.100:5000',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.dns_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cameraUrlController,
                    decoration: InputDecoration(
                      labelText: 'External MJPEG Stream URL (Optional)',
                      hintText: 'http://192.168.1.101:8080/video',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.videocam_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: _isTestingConnection
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.network_check_rounded, size: 18),
                          label: const Text('Test Connection'),
                          onPressed: _isTestingConnection ? null : _testConnection,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Reconnect Serial'),
                          onPressed: () {
                            context.read<RobotController>().reconnectSerial();
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_testResult != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _testResult!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _testResult!.contains('Connected to Spring Boot & Arduino')
                            ? AppTheme.statusGreen
                            : AppTheme.statusAmber,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section 2: Actuator Enables & Limits (Servos A through G)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('7-AXIS ACTUATOR ENABLES & LIMITS (A–G)'),
            ],
          ),
          // Demo Mode One-Tap Activation Bar
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryCyan.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_mode_rounded, color: AppTheme.primaryCyan, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'COCKPIT DEMO MODE',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primaryCyan),
                      ),
                      Text(
                        'Enable all 7 controllers with one tap for cockpit testing',
                        style: TextStyle(fontSize: 10, color: AppTheme.textDim),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    backgroundColor: AppTheme.primaryCyan,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _enableAllServosDemo,
                  child: const Text('ENABLE ALL 7', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                  onPressed: _resetToDefault,
                  child: const Text('RESET', style: TextStyle(fontSize: 10)),
                ),
              ],
            ),
          ),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: ServoId.values.map((id) {
                  final isEnabled = _enabledServos[id] ?? false;
                  final minA = _minAngles[id] ?? 0;
                  final maxA = _maxAngles[id] ?? 180;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isEnabled
                                    ? AppTheme.primaryCyan.withValues(alpha: 0.2)
                                    : AppTheme.border,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                id.code,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                  color: isEnabled ? AppTheme.primaryCyan : AppTheme.textDim,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${id.jointName} (${id.pinName})',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            const Spacer(),
                            Switch(
                              value: isEnabled,
                              activeThumbColor: AppTheme.primaryCyan,
                              onChanged: (val) {
                                setState(() {
                                  _enabledServos[id] = val;
                                });
                              },
                            ),
                          ],
                        ),
                        if (isEnabled) ...[
                          Row(
                            children: [
                              Text('Min: $minA°', style: const TextStyle(fontSize: 11, color: AppTheme.textDim)),
                              Expanded(
                                child: RangeSlider(
                                  values: RangeValues(minA.toDouble(), maxA.toDouble()),
                                  min: 0,
                                  max: 180,
                                  divisions: 180,
                                  labels: RangeLabels('$minA°', '$maxA°'),
                                  onChanged: (RangeValues values) {
                                    setState(() {
                                      _minAngles[id] = values.start.round();
                                      _maxAngles[id] = values.end.round();
                                    });
                                  },
                                ),
                              ),
                              Text('Max: $maxA°', style: const TextStyle(fontSize: 11, color: AppTheme.textDim)),
                            ],
                          ),
                        ],
                        const Divider(),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section 3: Virtual Joystick Kinematics
          _buildSectionHeader('VERTICAL & ROTARY CONTROLLER KINEMATICS'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Deadzone Filtering', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('${(_joystickDeadzone * 100).round()}%', style: AppTheme.tabularNumbers),
                    ],
                  ),
                  Slider(
                    value: _joystickDeadzone,
                    min: 0.05,
                    max: 0.40,
                    divisions: 35,
                    onChanged: (val) {
                      setState(() {
                        _joystickDeadzone = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Max Integration Speed (deg/sec)', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('${_joystickSpeed.round()}°/s', style: AppTheme.tabularNumbers),
                    ],
                  ),
                  Slider(
                    value: _joystickSpeed,
                    min: 15.0,
                    max: 180.0,
                    divisions: 33,
                    onChanged: (val) {
                      setState(() {
                        _joystickSpeed = val;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section 4: Claw Gripper Calibration (Servo G)
          _buildSectionHeader('CLAW ACTUATOR CALIBRATION (SERVO G)'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Open Angle (Release Target)', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('$_gripperOpenAngle°', style: AppTheme.tabularNumbers),
                    ],
                  ),
                  Slider(
                    value: _gripperOpenAngle.toDouble(),
                    min: 0,
                    max: 90,
                    divisions: 90,
                    onChanged: (val) {
                      setState(() {
                        _gripperOpenAngle = val.round();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Closed Angle (Capture Target)', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('$_gripperCloseAngle°', style: AppTheme.tabularNumbers),
                    ],
                  ),
                  Slider(
                    value: _gripperCloseAngle.toDouble(),
                    min: 90,
                    max: 180,
                    divisions: 90,
                    onChanged: (val) {
                      setState(() {
                        _gripperCloseAngle = val.round();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section 5: Voice Control
          _buildSectionHeader('VOICE INTENT SYSTEM'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.mic, color: AppTheme.primaryCyan),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Enable Voice Control Bridge', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('Shows microphone button on dashboard', style: TextStyle(fontSize: 11, color: AppTheme.textDim)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _voiceEnabled,
                    activeThumbColor: AppTheme.primaryCyan,
                    onChanged: (val) {
                      setState(() {
                        _voiceEnabled = val;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppTheme.textDim,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
