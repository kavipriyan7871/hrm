import 'dart:convert';
import '../services/api_client.dart';

class SignupApi {
  static final ApiClient _apiClient = ApiClient();

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
    final response = await _apiClient.postJson({
        "name": name,
        "mobile": mobile,
        "w_number": whatsapp,
        "email": email,
        "cid": cid,
        "type": type,
        "device_id": deviceId,
        "ln": lng,
        "lt": lat,
    });

    return jsonDecode(response.body);
  }
}
