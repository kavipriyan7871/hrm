import 'dart:convert';
import 'package:http/http.dart' as http;

class PayrollRepo {
  static const String baseUrl = "https://erpsmart.in/total/api/m_api/";

  static Future<Map<String, dynamic>> getPayroll({
    required String cid,
    required String uid,
    required String month,
    required String year,
    required String deviceId,
    required String lat,
    required String lng,
  }) async {
    try {
      final body = {
        "cid": cid,
        "uid": uid,
        "month": month,
        "year": year,
        "type": "2061",
        "device_id": deviceId,
        "lt": lat,
        "ln": lng,
      };

      print("Get Payroll Request Body: $body");

      final response = await http.post(Uri.parse(baseUrl), body: body);

      print("Get Payroll Response: ${response.body}");

      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          // If JSON is invalid, return the raw body as the error message
          // This allows seeing SQL errors like "Access denied" on the UI
          String rawError = response.body.trim();
          if (rawError.length > 200) {
            rawError =
                "${rawError.substring(0, 200)}..."; // Truncate if too long
          }
          return {"error": true, "error_msg": "Server Error: $rawError"};
        }
      } else {
        return {
          "error": true,
          "error_msg": "Server returned status code ${response.statusCode}",
        };
      }
    } catch (e) {
      print("Get Payroll API Error: $e");
      return {"error": true, "error_msg": e.toString()};
    }
  }
}
