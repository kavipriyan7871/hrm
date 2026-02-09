import 'dart:io';
import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionResult {
  final bool isValid;
  final String? error;
  final Face? face;

  FaceDetectionResult({required this.isValid, this.error, this.face});
}

class FaceDetectorService {
  late final FaceDetector _faceDetector;

  FaceDetectorService() {
    final options = FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
    );
    _faceDetector = FaceDetector(options: options);
  }

  Future<FaceDetectionResult> detectFace(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        return FaceDetectionResult(isValid: false, error: "No face detected.");
      }

      if (faces.length > 1) {
        return FaceDetectionResult(
          isValid: false,
          error:
              "Multiple faces detected. Please ensure only one person is in the frame.",
        );
      }

      final face = faces.first;

      // Ensure the face is looking forward (Euler Y and Z angles should be close to 0)
      // Standard allowance is usually around 15-20 degrees
      if (face.headEulerAngleY! > 20 || face.headEulerAngleY! < -20) {
        return FaceDetectionResult(
          isValid: false,
          error: "Please look straight at the camera.",
        );
      }

      if (face.headEulerAngleZ! > 15 || face.headEulerAngleZ! < -15) {
        return FaceDetectionResult(
          isValid: false,
          error: "Please keep your head straight.",
        );
      }

      return FaceDetectionResult(isValid: true, face: face);
    } catch (e) {
      return FaceDetectionResult(isValid: false, error: "Analysis failed: $e");
    }
  }

  /// Generates a simple geometric profile of the face based on landmark distances.
  /// This is a heuristic for "identification same" without a TFLite recognition model.
  List<double> getFaceProfile(Face face) {
    final leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
    final rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;
    final noseBase = face.landmarks[FaceLandmarkType.noseBase]?.position;
    final mouthBottom = face.landmarks[FaceLandmarkType.bottomMouth]?.position;

    if (leftEye == null ||
        rightEye == null ||
        noseBase == null ||
        mouthBottom == null) {
      return [];
    }

    // Distances
    double eyeDist = _distance(leftEye, rightEye);
    double noseToLeftEye = _distance(noseBase, leftEye);
    double noseToRightEye = _distance(noseBase, rightEye);
    double noseToMouth = _distance(noseBase, mouthBottom);

    // Ratios (Scale independent)
    return [
      noseToLeftEye / eyeDist,
      noseToRightEye / eyeDist,
      noseToMouth / eyeDist,
    ];
  }

  bool isSamePersona(
    List<double> p1,
    List<double> p2, {
    double threshold = 0.15,
  }) {
    if (p1.length != p2.length || p1.isEmpty) return false;

    double diff = 0;
    for (int i = 0; i < p1.length; i++) {
      diff += (p1[i] - p2[i]).abs();
    }

    // Average difference
    return (diff / p1.length) < threshold;
  }

  double _distance(Point<int> p1, Point<int> p2) {
    return (p1.x - p2.x).abs().toDouble() + (p1.y - p2.y).abs().toDouble();
    // Simplified Manhattan or Euclidean could work, using Euclidean for better precision
    // return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2));
  }

  // Note: Point<int> is from math, let's use the actual types from mlkit or dart:math
  // In ML Kit position is Point<int>

  void dispose() {
    _faceDetector.close();
  }
}
