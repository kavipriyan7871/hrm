import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hrm/services/face_detector_service.dart';
import 'package:hrm/components/live_face_scanner_view.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class RegisterAppFaceScreen extends StatefulWidget {
  const RegisterAppFaceScreen({super.key});

  @override
  State<RegisterAppFaceScreen> createState() => _RegisterAppFaceScreenState();
}

class _RegisterAppFaceScreenState extends State<RegisterAppFaceScreen> {
  final FaceDetectorService _faceDetectorService = FaceDetectorService();
  bool _isLoading = false;

  @override
  void dispose() {
    _faceDetectorService.dispose();
    super.dispose();
  }

  Future<void> _startLiveScan() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveFaceScannerView(
          title: "Setup Face Lock",
          description: "Hold your phone steady and look at the camera",
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
      final profile = _faceDetectorService.getFaceProfile(face);
      if (profile.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_app_face_profile', jsonEncode(profile));
        await prefs.setBool('auth_app_face_enabled', true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Face registered successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Close scanner
          Navigator.pop(context, true); // Close registration screen
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not generate face profile. Try again.'),
            ),
          );
          Navigator.pop(context); // Close scanner to allow retry
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error registering face.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff26A69A),
        title: Text(
          "Set Face Lock",
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xff26A69A), width: 3),
                ),
                child: const Icon(
                  Icons.face_retouching_natural_rounded,
                  size: 80,
                  color: Color(0xff26A69A),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                "Register Your Face",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Experience a seamless face scan to secure your app identity.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _startLiveScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff26A69A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.face_unlock_outlined,
                          color: Colors.white,
                        ),
                  label: Text(
                    _isLoading ? "Processing..." : "Start Face Scan",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
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
