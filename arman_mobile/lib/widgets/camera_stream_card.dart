import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_theme.dart';

class CameraStreamCard extends StatefulWidget {
  final String streamUrl;

  const CameraStreamCard({
    super.key,
    required this.streamUrl,
  });

  @override
  State<CameraStreamCard> createState() => _CameraStreamCardState();
}

class _CameraStreamCardState extends State<CameraStreamCard> {
  Uint8List? _currentFrame;
  bool _isLoading = false;
  String? _errorMessage;
  http.Client? _httpClient;
  StreamSubscription<List<int>>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.streamUrl.trim().isNotEmpty) {
      _startStream(widget.streamUrl.trim());
    }
  }

  @override
  void didUpdateWidget(covariant CameraStreamCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamUrl.trim() != widget.streamUrl.trim()) {
      _stopStream();
      if (widget.streamUrl.trim().isNotEmpty) {
        _startStream(widget.streamUrl.trim());
      }
    }
  }

  @override
  void dispose() {
    _stopStream();
    super.dispose();
  }

  void _stopStream() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _httpClient?.close();
    _httpClient = null;
  }

  Future<void> _startStream(String urlStr) async {
    _stopStream();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentFrame = null;
    });

    try {
      var uriString = urlStr;
      if (!uriString.startsWith('http://') && !uriString.startsWith('https://')) {
        uriString = 'http://$uriString';
      }
      final uri = Uri.parse(uriString);

      _httpClient = http.Client();
      final request = http.Request('GET', uri);
      final response = await _httpClient!.send(request);

      if (response.statusCode != 200) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Stream returned HTTP ${response.statusCode}';
          });
        }
        return;
      }

      final buffer = BytesBuilder(copy: false);

      _streamSubscription = response.stream.listen(
        (chunk) {
          buffer.add(chunk);
          final bytes = buffer.toBytes();

          // Search for JPEG Start (0xFF, 0xD8) and End (0xFF, 0xD9)
          int startIndex = -1;
          for (int i = 0; i < bytes.length - 1; i++) {
            if (bytes[i] == 0xFF && bytes[i + 1] == 0xD8) {
              startIndex = i;
              break;
            }
          }

          if (startIndex != -1) {
            int endIndex = -1;
            for (int i = startIndex + 2; i < bytes.length - 1; i++) {
              if (bytes[i] == 0xFF && bytes[i + 1] == 0xD9) {
                endIndex = i + 2;
                break;
              }
            }

            if (endIndex != -1) {
              final frameBytes = Uint8List.fromList(bytes.sublist(startIndex, endIndex));
              buffer.clear();
              if (endIndex < bytes.length) {
                buffer.add(bytes.sublist(endIndex));
              }

              if (mounted) {
                setState(() {
                  _currentFrame = frameBytes;
                  _isLoading = false;
                  _errorMessage = null;
                });
              }
            }
          }

          // Guard against runaway buffer if no markers found
          if (buffer.length > 5 * 1024 * 1024) {
            buffer.clear();
          }
        },
        onError: (err) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Stream disconnected: $err';
            });
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _isLoading = false;
              if (_currentFrame == null) {
                _errorMessage = 'Stream ended by host';
              }
            });
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Connection error: $e';
        });
      }
    }
  }

  void _openFullscreen(BuildContext context) {
    if (_currentFrame == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: const Text('Live Camera Stream'),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.memory(
                _currentFrame!,
                gaplessPlayback: true,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl = widget.streamUrl.trim().isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.videocam_rounded, size: 18, color: AppTheme.primaryCyan),
                const SizedBox(width: 8),
                const Text(
                  'VISION FEED (MJPEG)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppTheme.textMain,
                  ),
                ),
                const Spacer(),
                if (hasUrl)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18, color: AppTheme.textDim),
                    tooltip: 'Restart Stream',
                    onPressed: () => _startStream(widget.streamUrl.trim()),
                  ),
                if (_currentFrame != null)
                  IconButton(
                    icon: const Icon(Icons.fullscreen, size: 20, color: AppTheme.primaryCyan),
                    tooltip: 'Fullscreen View',
                    onPressed: () => _openFullscreen(context),
                  ),
              ],
            ),
          ),
          const Divider(),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: _buildStreamContent(hasUrl),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamContent(bool hasUrl) {
    if (!hasUrl) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_off_outlined, size: 40, color: AppTheme.textDim),
              SizedBox(height: 8),
              Text(
                'Camera Stream Unconfigured',
                style: TextStyle(color: AppTheme.textMain, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                'Set your phone MJPEG stream URL in Settings\n(e.g., http://192.168.1.50:8080/video)',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textDim, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading && _currentFrame == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryCyan),
            SizedBox(height: 12),
            Text('Connecting to MJPEG stream...', style: TextStyle(color: AppTheme.textDim, fontSize: 12)),
          ],
        ),
      );
    }

    if (_errorMessage != null && _currentFrame == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 36, color: AppTheme.statusRed),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textDim, fontSize: 12),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry Connection', style: TextStyle(fontSize: 12)),
                onPressed: () => _startStream(widget.streamUrl.trim()),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentFrame != null) {
      return Image.memory(
        _currentFrame!,
        gaplessPlayback: true,
        fit: BoxFit.contain,
      );
    }

    return const SizedBox();
  }
}
