import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ReportApi {
  static const String baseUrl = "https://erpsmart.in/total/api/m_api/";

  static Future<Map<String, dynamic>> fetchReport({
    required String cid,
    required String uid,
    required String deviceId,
    required String lat,
    required String lng,
    required String reportType, // e.g., 'attendance'
    required String month, // e.g., '2026-02'
    String type = "2070",
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        body: {
          'cid': cid,
          'uid': uid,
          'device_id': deviceId,
          'lt': lat,
          'ln': lng,
          'type': type,
          'report_type': reportType,
          'month': month,
        },
      );

      if (response.statusCode == 200) {
        // Log the response to help debugging
        debugPrint("Report API Response: ${response.body}");
        return jsonDecode(response.body);
      } else {
        return {
          "error": true,
          "message": "Server error: ${response.statusCode}",
        };
      }
    } catch (e) {
      return {"error": true, "message": e.toString()};
    }
  }
}


