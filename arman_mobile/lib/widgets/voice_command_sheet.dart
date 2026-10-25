import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../controllers/robot_controller.dart';
import '../models/voice_command_result.dart';
import '../services/arman_api_service.dart';
import '../services/voice_command_parser.dart';

class VoiceCommandSheet extends StatefulWidget {
  const VoiceCommandSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VoiceCommandSheet(),
    );
  }

  @override
  State<VoiceCommandSheet> createState() => _VoiceCommandSheetState();
}

class _VoiceCommandSheetState extends State<VoiceCommandSheet> {
  final TextEditingController _textController = TextEditingController();
  VoiceCommandResult? _parsedResult;
  bool _isProcessingBackend = false;
  bool _useBackendParsing = false;

  final List<String> _quickChips = const [
    'Move servo A to 45 degrees',
    'Servo A 90',
    'Set A to 180',
    'Open gripper',
    'Close gripper',
    'Home all',
    'Emergency stop',
  ];

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _textController.text;
    if (text.trim().isEmpty) {
      setState(() {
        _parsedResult = null;
      });
      return;
    }

    if (!_useBackendParsing) {
      final result = VoiceCommandParser.parse(text);
      setState(() {
        _parsedResult = result;
      });
    }
  }

  Future<void> _processViaBackend(String text) async {
    final controller = context.read<RobotController>();
    setState(() {
      _isProcessingBackend = true;
    });

    try {
      final apiService = ArmanApiService();
      final remoteResult = await apiService.sendVoiceCommand(
        serverUrl: controller.settings.serverUrl,
        transcript: text,
        executeImmediately: false,
      );

      if (mounted) {
        setState(() {
          _parsedResult = remoteResult ?? VoiceCommandParser.parse(text);
          _isProcessingBackend = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _parsedResult = VoiceCommandParser.parse(text);
          _isProcessingBackend = false;
        });
      }
    }
  }

  void _executeCommand() {
    if (_parsedResult == null) return;
    final controller = context.read<RobotController>();
    controller.executeVoiceCommand(_parsedResult!);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: bottomInset + 20,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppTheme.border, width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic, color: AppTheme.primaryCyan, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice Intent Bridge',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                      ),
                    ),
                    Text(
                      'Speak or simulate robotic arm voice phrases',
                      style: TextStyle(fontSize: 11, color: AppTheme.textDim),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textDim),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Backend vs Local Parser Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Parser Engine',
                style: TextStyle(fontSize: 12, color: AppTheme.textDim),
              ),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Local Dart', style: TextStyle(fontSize: 11)),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Spring Boot', style: TextStyle(fontSize: 11)),
                  ),
                ],
                selected: {_useBackendParsing},
                onSelectionChanged: (set) {
                  setState(() {
                    _useBackendParsing = set.first;
                    if (_textController.text.trim().isNotEmpty) {
                      if (_useBackendParsing) {
                        _processViaBackend(_textController.text);
                      } else {
                        _parsedResult = VoiceCommandParser.parse(_textController.text);
                      }
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Transcript Input
          TextField(
            controller: _textController,
            autofocus: false,
            style: const TextStyle(color: AppTheme.textMain),
            decoration: InputDecoration(
              hintText: 'e.g. "Move servo A to 45 degrees"',
              hintStyle: const TextStyle(color: AppTheme.textDim),
              filled: true,
              fillColor: AppTheme.background,
              prefixIcon: const Icon(Icons.record_voice_over, color: AppTheme.primaryCyan),
              suffixIcon: _textController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppTheme.textDim),
                      onPressed: () => _textController.clear(),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryCyan),
              ),
            ),
            onSubmitted: (val) {
              if (_useBackendParsing) {
                _processViaBackend(val);
              }
            },
          ),
          const SizedBox(height: 12),

          // Simulation Chips
          const Text(
            'QUICK SIMULATION PHRASES',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDim,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _quickChips.map((phrase) {
              return ActionChip(
                backgroundColor: AppTheme.background,
                side: const BorderSide(color: AppTheme.border),
                label: Text(
                  phrase,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMain),
                ),
                onPressed: () {
                  _textController.text = phrase;
                  if (_useBackendParsing) {
                    _processViaBackend(phrase);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Preview Card
          if (_isProcessingBackend)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: AppTheme.primaryCyan),
              ),
            )
          else if (_parsedResult != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _parsedResult!.intent == 'UNKNOWN'
                      ? AppTheme.statusRed
                      : AppTheme.statusGreen,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _parsedResult!.intent == 'UNKNOWN'
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        size: 16,
                        color: _parsedResult!.intent == 'UNKNOWN'
                            ? AppTheme.statusRed
                            : AppTheme.statusGreen,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'INTENT: ${_parsedResult!.intent}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _parsedResult!.intent == 'UNKNOWN'
                              ? AppTheme.statusRed
                              : AppTheme.statusGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _parsedResult!.message,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMain),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Execute Button
          ElevatedButton.icon(
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('EXECUTE VOICE INTENT'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: (_parsedResult != null && _parsedResult!.intent != 'UNKNOWN')
                  ? AppTheme.electricBlue
                  : AppTheme.border,
            ),
            onPressed: (_parsedResult != null && _parsedResult!.intent != 'UNKNOWN')
                ? _executeCommand
                : null,
          ),
        ],
      ),
    );
  }
}
