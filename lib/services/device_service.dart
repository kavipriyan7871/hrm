import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:sms_autofill/sms_autofill.dart';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Initializes device info and location and stores them in SharedPreferences.
  /// Call this at app startup or before login.
  static Future<void> initDeviceInfo() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Get Device ID
    String deviceId = "unknown_device";
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        deviceId = androidInfo.id; // Unique ID for Android
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? "unknown_ios";
      }
    } catch (e) {
      debugPrint("Error getting device ID: $e");
    }
    await prefs.setString('device_id', deviceId);

    // 2. Get App Signature (for SMS autofill)
    try {
      if (Platform.isAndroid) {
        String signature = await SmsAutoFill().getAppSignature;
        await prefs.setString('app_signature', signature);
        debugPrint("APP SIGNATURE: $signature");
      }
    } catch (e) {
      debugPrint("Error getting app signature: $e");
    }

    // 3. Get Location
    try {
      Position? position = await _getCurrentLocation();
      if (position != null) {
        await prefs.setDouble('lat', position.latitude);
        await prefs.setDouble('lng', position.longitude);
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  /// Helper to get current device ID from SharedPreferences
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('device_id') ?? ""; // Default if not found
  }

  /// Helper to get stored location
  static Future<Map<String, String>> getLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'lat': prefs.getDouble('lat')?.toString() ?? "0.0",
      'ln': prefs.getDouble('lng')?.toString() ?? "0.0",
    };
  }

  static Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}
