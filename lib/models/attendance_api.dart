import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AttendanceApi {
  static const String baseUrl = "https://erpsmart.in/total/api/m_api/";

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

      debugPrint("Fetch Work Types Request: $body");
      final response = await http.post(Uri.parse(baseUrl), body: body);
      debugPrint("Fetch Work Types Response: ${response.body}");

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

      debugPrint("Fetch Transport Types Request: $body");
      final response = await http.post(Uri.parse(baseUrl), body: body);
      debugPrint("Fetch Transport Types Response: ${response.body}");

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
}
