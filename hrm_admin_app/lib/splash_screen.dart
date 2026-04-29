import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'Screens/Admin/admin_dashboard.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onBackToHrm;
  const SplashScreen({super.key, this.onBackToHrm});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _navigateNext();
    });
  }

  /// CHECK LOGIN & NAVIGATE
  Future<void> _navigateNext() async {
    final prefs = await SharedPreferences.getInstance();

    // Fetch and store dynamic data (device_id, lt, ln)
    await _fetchAndStoreDeviceData(prefs);

    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AdminDashboard(onBackToHrm: widget.onBackToHrm)),
      );
    } else {
      // ✅ No local login anymore. Always go to AdminDashboard as host handles auth.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AdminDashboard(onBackToHrm: widget.onBackToHrm)),
      );
    }
  }

  Future<void> _fetchAndStoreDeviceData(SharedPreferences prefs) async {
    // 1. Fetch Device ID
    String deviceId = "Unknown";
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? "Unknown";
      }
      await prefs.setString("device_id", deviceId);
      print("Splash: Stored device_id: $deviceId");
    } catch (e) {
      print("Splash Error getting device info: $e");
    }

    // 2. Fetch Location (LT/LN)
    String lt = "0.0";
    String ln = "0.0";
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low);
        lt = position.latitude.toString();
        ln = position.longitude.toString();
      }
      await prefs.setString("lt", lt);
      await prefs.setString("ln", ln);
      print("Splash: Stored location: $lt, $ln");
    } catch (e) {
      print("Splash Error getting location: $e");
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
              "HRM ADMIN",
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
