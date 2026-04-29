import 'dart:convert';
import '../services/api_client.dart';

class LoginApi {
  static final ApiClient _apiClient = ApiClient();

  static Future<Map<String, dynamic>> sendOtp({
    required String mobile,
    required String type,
    required String deviceId,
    required String lat,
    required String lng,
    required String appSignature,
    String? cid,
  }) async {
    final Map<String, dynamic> body = {
      "type": type,
      "lt": lat,
      "ln": lng,
      "device_id": deviceId,
      "mobile": mobile,
      "app_signature": appSignature,
    };

    if (cid != null) body["cid"] = cid;

    final response = await _apiClient.post(body);
    return jsonDecode(response.body);
  }

  /// VERIFY OTP
  static Future<Map<String, dynamic>> verifyOtp({
    required String mobile,
    required String otp,
    required String cid,
    required String type,
    required String deviceId,
    required String lat,
    required String lng,
    required String appSignature,
  }) async {
    final response = await _apiClient.post({
        "type": type, // 2001
        "cid": cid,
        "lt": lat,
        "ln": lng,
        "device_id": deviceId,
        "mobile": mobile,
        "otp": otp,
        "app_signature": appSignature,
    });

    return jsonDecode(response.body);
  }

  /// LOGIN WITH USERNAME/PASSWORD (TYPE 2087)
  static Future<Map<String, dynamic>> loginWithPassword({
    required String username,
    required String password,
    required String deviceId,
    required String lat,
    required String lng,
  }) async {
    final response = await _apiClient.post({
      "type": "2087",
      "username": username,
      "password": password,
      "device_id": deviceId,
      "lt": lat,
      "ln": lng,
    });

    return jsonDecode(response.body);
  }
}
