import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main_root.dart';
import 'package:hrm/views/security/app_lock_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _saveLocation();
      await _navigateNext();
    });
  }

  /// CHECK LOGIN & NAVIGATE
  Future<void> _navigateNext() async {
    final prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    // Load Security Settings
    bool bioEnabled = prefs.getBool('auth_biometric_enabled') ?? false;
    bool appFaceEnabled = prefs.getBool('auth_app_face_enabled') ?? false;
    bool pinEnabled = prefs.getBool('auth_pin_enabled') ?? false;
    String? savedPin = prefs.getString('auth_pin_code');

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (isLoggedIn) {
      // Check if security is enabled
      if (bioEnabled ||
          appFaceEnabled ||
          (pinEnabled && savedPin != null && savedPin.isNotEmpty)) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AppLockScreen(
              isBiometricEnabled: bioEnabled,
              isAppFaceEnabled: appFaceEnabled,
              isPinEnabled: pinEnabled,
              savedPin: savedPin,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainRoot()),
        );
      }
    } else {
      // ✅ No local login anymore. Always go to MainRoot as the host app handles auth.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainRoot()),
      );
    }
  }

  /// SAVE LATITUDE & LONGITUDE
  Future<void> _saveLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('lat', position.latitude);
      await prefs.setDouble('lng', position.longitude);
    } catch (e) {
      debugPrint("Location error in splash: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', width: 180.w),
            SizedBox(height: 24.h),
            Text(
              "HRM",
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF26A69A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
