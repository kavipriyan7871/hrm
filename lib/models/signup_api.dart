import 'dart:convert';
import 'package:http/http.dart' as http;

class SignupApi {
  static const String baseUrl =
      "https://erpsmart.in/total/api/m_api/";

  static Future<Map<String, dynamic>> signup({
    required String name,
    required String mobile,
    required String whatsapp,
    required String email,
    required String cid,
    required String type,
    required String deviceId,
    required String lat,
    required String lng,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "name": name,
        "mobile": mobile,
        "w_number": whatsapp,
        "email": email,
        "cid": cid,
        "type": type,
        "device_id": deviceId,
        "ln": lng,
        "lt": lat,
      }),
    );

    return jsonDecode(response.body);
  }
}
