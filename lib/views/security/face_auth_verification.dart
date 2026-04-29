import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hrm/services/face_detector_service.dart';
import 'package:hrm/views/main_root.dart';
import 'package:hrm/components/live_face_scanner_view.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceAuthVerificationScreen extends StatefulWidget {
  const FaceAuthVerificationScreen({super.key});

  @override
  State<FaceAuthVerificationScreen> createState() =>
      _FaceAuthVerificationScreenState();
}

class _FaceAuthVerificationScreenState
    extends State<FaceAuthVerificationScreen> {
  final FaceDetectorService _faceDetectorService = FaceDetectorService();
  bool _isLoading = false;

  @override
  void dispose() {
    _faceDetectorService.dispose();
    super.dispose();
  }

  Future<void> _startLiveVerification() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveFaceScannerView(
          title: "Verify Face",
          description: "Hold still for verification",
          onFaceDetected: (Face face, InputImage inputImage) async {
            _onFaceDetected(face);
          },
        ),
      ),
    );
  }

  Future<void> _onFaceDetected(Face face) async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedProfileJson = prefs.getString('auth_app_face_profile');

      if (savedProfileJson == null) {
        _showError('No face profile registered. Please register first.');
        Navigator.pop(context);
        return;
      }

      final List<double> savedProfile = (jsonDecode(savedProfileJson) as List)
          .map((v) => (v as num).toDouble())
          .toList();
      final List<double> currentProfile = _faceDetectorService.getFaceProfile(
        face,
      );

      // Check if profile format is compatible (new version has 8 features)
      if (savedProfile.length != currentProfile.length) {
        _showError(
          'Face profile format updated. Please re-register your face.',
        );
        Navigator.pop(context);
        return;
      }

      final bool isMatched = _faceDetectorService.isSamePersona(
        savedProfile,
        currentProfile,
        threshold: 0.08, // Stricter threshold for higher security
      );

      if (isMatched) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification Successful!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainRoot()),
            (route) => false,
          );
        }
      } else {
        _showError('Face does not match. Try again.');
        Navigator.pop(context); // Close scanner to allow retry
      }
    } catch (e) {
      _showError('Error during verification.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff26A69A),
        elevation: 0,
        title: Text(
          "Face Authentication",
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xff26A69A).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.face_unlock_rounded,
                  size: 60,
                  color: Color(0xff26A69A),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                "Secure Face Unlock",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Use the live scanner to quickly and securely unlock your HRM portal.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _startLiveVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff26A69A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isLoading
                      ? const SizedBox.shrink()
                      : const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Colors.white,
                        ),
                  label: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Start Live Scan",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

