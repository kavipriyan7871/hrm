import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginApi {
  static const String baseUrl = "https://erpsmart.in/total/api/m_api/";

  /// SEND OTP
  static Future<Map<String, dynamic>> sendOtp({
    required String mobile,
    required String cid,
    required String type,
    required String deviceId,
    required String lat,
    required String lng,
    required String appSignature,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      body: {
        "type": type,
        "cid": cid,
        "lt": lat,
        "ln": lng,
        "device_id": deviceId,
        "mobile": mobile,
        "app_signature": appSignature,
      },
    );

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
    final response = await http.post(
      Uri.parse(baseUrl),
      body: {
        "type": type, // 2001
        "cid": cid,
        "lt": lat,
        "ln": lng,
        "device_id": deviceId,
        "mobile": mobile,
        "otp": otp,
        "app_signature": appSignature,
      },
    );

    return jsonDecode(response.body);
  }
}
