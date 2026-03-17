import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_fonts/google_fonts.dart';

class LiveFaceScannerView extends StatefulWidget {
  final Function(Face face, InputImage inputImage) onFaceDetected;
  final String title;
  final String description;

  const LiveFaceScannerView({
    super.key,
    required this.onFaceDetected,
    this.title = "Face Scanner",
    this.description = "Align your face within the frame",
  });

  @override
  State<LiveFaceScannerView> createState() => _LiveFaceScannerViewState();
}

class _LiveFaceScannerViewState extends State<LiveFaceScannerView>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  bool _isBusy = false;
  bool _canProcess = true;
  late AnimationController _scannerController;
  late Animation<double> _scannerAnimation;
  int _cameraIndex = -1;
  CameraDescription? _camera;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableLandmarks: true, // Required for profile generation
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scannerAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _scannerController, curve: Curves.easeInOut),
    );

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No cameras found")));
        Navigator.pop(context);
      }
      return;
    }
    _cameraIndex = cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );
    if (_cameraIndex == -1) _cameraIndex = 0;
    _camera = cameras[_cameraIndex];

    _controller = CameraController(
      _camera!,
      ResolutionPreset.high, // Higher resolution for better accuracy
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _controller?.initialize();
    if (!mounted) return;

    _controller?.startImageStream(_processCameraImage);
    setState(() {});
  }

  void _processCameraImage(CameraImage image) async {
    if (_isBusy || !_canProcess) return;
    _isBusy = true;

    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) {
      _isBusy = false;
      return;
    }

    try {
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty && mounted) {
        // Prevent multiple simultaneous detections
        _canProcess = false;

        // Give it a small delay so the user sees the "Scanning" state
        // and has time to align properly before the result is returned.
        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          widget.onFaceDetected(faces.first, inputImage);
        }
      }
    } catch (e) {
      debugPrint("Face detection error: $e");
      _canProcess = true; // Allow retry on error
    } finally {
      _isBusy = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null || _camera == null) return null;

    final sensorOrientation = _camera!.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationValue = sensorOrientation;
      if (_camera!.lensDirection == CameraLensDirection.front) {
        rotationValue = (sensorOrientation + 0) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationValue);
    }

    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    if (image.planes.isEmpty) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format:
            format ??
            (Platform.isAndroid
                ? InputImageFormat.nv21
                : InputImageFormat.bgra8888),
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _canProcess = false;
    _controller?.dispose();
    _faceDetector.close();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          Center(
            child: AspectRatio(
              aspectRatio: 1 / _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),

          // Dark Overlay with Hole
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.7),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: 320, // Increased size
                    height: 320, // Increased size
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(160),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scanner Line
          Center(
            child: AnimatedBuilder(
              animation: _scannerAnimation,
              builder: (context, child) {
                return Container(
                  width: 320, // Increased size
                  height: 320, // Increased size
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: EdgeInsets.only(top: 320 * _scannerAnimation.value),
                    width: 290, // Increased width
                    height: 3, // Slightly thicker line
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff26A69A).withValues(alpha: 0.6),
                          blurRadius: 12,
                          spreadRadius: 3,
                        ),
                      ],
                      gradient: const LinearGradient(
                        colors: [
                          Colors.transparent,
                          Color(0xff26A69A),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // UI Elements
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.title,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.description,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xff26A69A),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "SCANNING...",
                            style: GoogleFonts.poppins(
                              color: const Color(0xff26A69A),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
