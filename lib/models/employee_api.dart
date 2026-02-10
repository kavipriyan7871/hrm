import 'dart:convert';
import 'package:http/http.dart' as http;

class EmployeeApi {
  static const String baseUrl = "https://erpsmart.in/total/api/m_api/";

  static Future<Map<String, dynamic>> getEmployeeDetails({
    required String uid,
    required String cid,
    required String deviceId,
    required String lat,
    required String lng,
  }) async {
    try {
      final body = {
        "type": "2048",
        "cid": cid,
        "id": uid,
        "device_id": deviceId,
        "lt": lat,
        "ln": lng,
      };

      print("Employee Details Request Body: $body");

      final response = await http.post(Uri.parse(baseUrl), body: body);

      print("Employee Details Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "error": true,
          "error_msg": "Server returned status code ${response.statusCode}",
        };
      }
    } catch (e) {
      print("Employee Details API Error: $e");
      return {"error": true, "error_msg": e.toString()};
    }
  }
}