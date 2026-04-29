import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/api_client.dart';

class AttendanceApi {
  static final ApiClient _apiClient = ApiClient();

  /// Fetch Work Types (Type 2069)
  static Future<Map<String, dynamic>> fetchWorkTypes({
    required String cid,
    required String deviceId,
    required String lat,
    required String lng,
  }) async {
    try {
      final body = {
        "type": "2069",
        "cid": cid,
        "device_id": deviceId,
        "lt": lat,
        "ln": lng,
      };

      final response = await _apiClient.post(body);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "error": true,
          "error_msg": "Server Error ${response.statusCode}",
        };
      }
    } catch (e) {
      debugPrint("Fetch Work Types Error: $e");
      return {"error": true, "error_msg": e.toString()};
    }
  }

  /// Fetch Transport Types (Type 2072)
  static Future<Map<String, dynamic>> fetchTransportTypes({
    required String cid,
    required String deviceId,
    required String lat,
    required String lng,
  }) async {
    try {
      final body = {
        "type": "2072",
        "cid": cid,
        "device_id": deviceId,
        "lt": lat,
        "ln": lng,
      };

      final response = await _apiClient.post(body);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "error": true,
          "error_msg": "Server Error ${response.statusCode}",
        };
      }
    } catch (e) {
      debugPrint("Fetch Transport Types Error: $e");
      return {"error": true, "error_msg": e.toString()};
    }
  }

  /// Attendance Check-In (Type 2046)
  static Future<Map<String, dynamic>> checkIn({
    required String cid,
    required String uid,
    required String inTime,
    required String loc,
    required String workMode,
    required String deviceId,
    required String lat,
    required String lng,
    String? transportId,
    String? token,
    File? selfie,
    File? vehiclePhoto,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("https://erpsmart.in/total/api/m_api/"),
      );

      request.fields.addAll({
        "type": "2046",
        "cid": cid,
        "uid": uid,
        "id": uid,
        "in_time": inTime,
        "loc": loc,
        "wrk_mde": workMode,
        "device_id": deviceId,
        "lt": lat,
        "ln": lng,
        if (transportId != null && transportId.isNotEmpty)
          "transport_id": transportId,
        if (token != null && token.isNotEmpty) "token": token,
      });

      if (selfie != null) {
        request.files.add(
          await http.MultipartFile.fromPath('selfie', selfie.path),
        );
      }

      if (vehiclePhoto != null) {
        request.files.add(
          await http.MultipartFile.fromPath('photo', vehiclePhoto.path),
        );
      }

      final streamedResponse = await _apiClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Check-In API Error: $e");
      return {"error": true, "error_msg": e.toString()};
    }
  }

  /// Attendance Check-Out (Type 2047)
  static Future<Map<String, dynamic>> checkOut({
    required String cid,
    required String uid,
    required String outTime,
    required String loc,
    required String workMode,
    required String deviceId,
    required String lat,
    required String lng,
    String? transportId,
    String? token,
    File? selfie,
    File? vehiclePhoto,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("https://erpsmart.in/total/api/m_api/"),
      );

      request.fields.addAll({
        "type": "2047",
        "cid": cid,
        "uid": uid,
        "id": uid,
        "out_time": outTime,
        "loc": loc,
        "wrk_mde": workMode,
        "device_id": deviceId,
        "lt": lat,
        "ln": lng,
        if (transportId != null && transportId.isNotEmpty)
          "transport_id": transportId,
        if (token != null && token.isNotEmpty) "token": token,
      });

      if (selfie != null) {
        request.files.add(
          await http.MultipartFile.fromPath('out_selfie', selfie.path),
        );
      }

      if (vehiclePhoto != null) {
        request.files.add(
          await http.MultipartFile.fromPath('out_photo', vehiclePhoto.path),
        );
      }

      final streamedResponse = await _apiClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Check-Out API Error: $e");
      return {"error": true, "error_msg": e.toString()};
    }
  }
}
