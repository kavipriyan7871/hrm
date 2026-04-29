import 'dart:convert';
import '../services/api_client.dart';

class ReportApi {
  static final ApiClient _apiClient = ApiClient();

  static Future<Map<String, dynamic>> fetchReport({
    required String cid,
    required String uid,
    required String deviceId,
    required String lat,
    required String lng,
    required String reportType, // e.g., 'attendance'
    required String month, // e.g., '2026-02'
    String? date, // e.g., '2026-04-16'
    String type = "2070",
  }) async {
    try {
      final response = await _apiClient.post({
          'cid': cid,
          'uid': uid,
          'id': uid, // Mirror for backward compatibility
          'device_id': deviceId,
          'lt': lat,
          'ln': lng,
          'type': type,
          'report_type': reportType,
          'month': month,
          if (date != null) 'date': date,
      });

      if (response.statusCode == 200) {
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
