import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class PhoneCameraService extends ChangeNotifier {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isInitializing = false;
  bool _isInitialized = false;
  String? _errorMessage;

  CameraController? get controller => _controller;
  bool get isInitialized =>
      _isInitialized && _controller != null && _controller!.value.isInitialized;
  bool get isInitializing => _isInitializing;
  bool get hasMultipleCameras => _cameras.length > 1;
  String? get errorMessage => _errorMessage;
  List<CameraDescription> get availableCameraList => List.unmodifiable(_cameras);

  CameraLensDirection? get currentLensDirection {
    if (_cameras.isNotEmpty && _selectedCameraIndex < _cameras.length) {
      return _cameras[_selectedCameraIndex].lensDirection;
    }
    return null;
  }

  /// Initializes the device camera. If [preloadedCameras] is provided, uses them (handy for unit tests).
  Future<void> initialize({List<CameraDescription>? preloadedCameras}) async {
    if (_isInitializing) return;

    _isInitializing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (preloadedCameras != null) {
        _cameras = preloadedCameras;
      } else {
        _cameras = await availableCameras();
      }

      if (_cameras.isEmpty) {
        _isInitialized = false;
        _isInitializing = false;
        _errorMessage = 'No camera sensor hardware detected on this device.';
        notifyListeners();
        return;
      }

      // Default to the first back camera if available, otherwise first camera
      int defaultIndex = 0;
      for (int i = 0; i < _cameras.length; i++) {
        if (_cameras[i].lensDirection == CameraLensDirection.back) {
          defaultIndex = i;
          break;
        }
      }
      _selectedCameraIndex = defaultIndex;

      await _initControllerForIndex(_selectedCameraIndex);
    } catch (e) {
      _isInitialized = false;
      _errorMessage = 'Failed to initialize phone camera: $e';
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> _initControllerForIndex(int index) async {
    final oldController = _controller;
    if (oldController != null) {
      _controller = null;
      await oldController.dispose();
    }

    if (index >= _cameras.length) return;

    final cameraDescription = _cameras[index];
    final newController = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _controller = newController;
    await newController.initialize();
    _isInitialized = newController.value.isInitialized;
    _errorMessage = null;
  }

  /// Flips between back and front camera
  Future<void> switchCamera() async {
    if (_cameras.length < 2 || _isInitializing) return;

    _isInitializing = true;
    notifyListeners();

    try {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
      await _initControllerForIndex(_selectedCameraIndex);
    } catch (e) {
      _errorMessage = 'Error switching camera: $e';
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Retries initialization (e.g. after permissions granted)
  Future<void> retry() async {
    await initialize();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}
