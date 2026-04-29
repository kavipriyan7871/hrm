import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

/// Data model for break entries used in reports
class BreakEntry {
  final String purpose;
  final DateTime breakInTime;
  final DateTime? breakOutTime;
  final Duration duration;

  BreakEntry({
    required this.purpose,
    required this.breakInTime,
    this.breakOutTime,
    required this.duration,
  });
}

/// A mixin or helper class could work, but for a clean "separate file" request in Flutter, 
/// we provide the core functional logic that can be imported or used as a reference.
class BreakService {
  static const String baseUrl = "https://erpsmart.in/total/api/m_api/";

  /// Handle Break In API call (Type 2055)
  static Future<Map<String, dynamic>> startBreak({
    required String cid,
    required String uid,
    required String deviceId,
    required Position position,
    required String purpose,
    String? token,
  }) async {
    final body = {
      "type": "2055",
      "cid": cid,
      "uid": uid,
      "id": uid,
      "device_id": deviceId,
      "lt": position.latitude.toString(),
      "ln": position.longitude.toString(),
      "reason": purpose,
      if (token != null && token.isNotEmpty) "token": token,
    };

    final response = await http.post(Uri.parse(baseUrl), body: body);
    return jsonDecode(response.body);
  }

  /// Handle Break Out API call (Type 2056)
  static Future<Map<String, dynamic>> endBreak({
    required String cid,
    required String uid,
    required String deviceId,
    required Position position,
    String? token,
  }) async {
    final body = {
      "type": "2056",
      "cid": cid,
      "uid": uid,
      "id": uid,
      "device_id": deviceId,
      "lt": position.latitude.toString(),
      "ln": position.longitude.toString(),
      if (token != null && token.isNotEmpty) "token": token,
    };

    final response = await http.post(Uri.parse(baseUrl), body: body);
    return jsonDecode(response.body);
  }

  /// Fetch Break History (Type 2079)
  static Future<Map<String, dynamic>> fetchHistory({
    required String cid,
    required String uid,
    required String deviceId,
    double lat = 0.0,
    double lng = 0.0,
    String? token,
  }) async {
    final body = {
      "type": "2079",
      "cid": cid,
      "uid": uid,
      "id": uid,
      "device_id": deviceId,
      "lt": lat.toString(),
      "ln": lng.toString(),
      if (token != null && token.isNotEmpty) "token": token,
    };

    final response = await http.post(Uri.parse(baseUrl), body: body);
    return jsonDecode(response.body);
  }

  /// Format duration for UI (MM:SS)
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  /// Format duration for Report (XH XM)
  static String formatDurationHoursMinutes(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours == 0) return "${minutes}m";
    return "${hours}h ${minutes}m";
  }
}
