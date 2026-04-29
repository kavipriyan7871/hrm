import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Utils/shared_prefs_util.dart';

class LoginResponse {
  final bool error;
  final String errorMsg;
  final String? otp;
  final String? cusId;
  final dynamic cid;
  final String? compName;
  final String? name;
  final String? token;
  final String? mobile;

  LoginResponse({
    required this.error,
    required this.errorMsg,
    this.otp,
    this.cusId,
    this.cid,
    this.compName,
    this.name,
    this.token,
    this.mobile,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      error: json['error'] ?? false,
      errorMsg: json['error_msg'] ?? (json['message'] ?? ""),
      otp: json['otp']?.toString(),
      cusId: json['cus_id']?.toString(),
      cid: json['cid'],
      compName: json['comp_name'],
      name: json['name'],
      token: json['token'],
      mobile: json['mobile']?.toString(),
    );
  }

  @override
  String toString() {
    return 'LoginResponse(error: $error, msg: $errorMsg, cusId: $cusId, token: $token)';
  }
}

class LoginApi {
  static const String _baseUrl = "https://erpsmart.in/total/api/m_api/";

  // SMS Login API (type 2088)
  static Future<LoginResponse> sendSmsOtp({
    required String mobile,
    required String deviceId,
    required String lat,
    required String lng,
  }) async {
    try {
      final String cid = await SharedPrefsUtil.getCid();

      final Map<String, String> body = {
        'type': '2088',
        'cid': cid,
        'lt': lat,
        'ln': lng,
        'device_id': deviceId,
        'mobile': mobile,
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        body: body,
      );

      print("SMS Login Response: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(response.body);
        return LoginResponse.fromJson(decodedData);
      } else {
        return LoginResponse(
          error: true,
          errorMsg: "Server error: ${response.statusCode}",
        );
      }
    } catch (e) {
      print("SMS Login API Error: $e");
      return LoginResponse(
        error: true,
        errorMsg: "Failed to send OTP: $e",
      );
    }
  }

  // OTP Verification API (type 2089)
  static Future<LoginResponse> verifySmsOtp({
    required String mobile,
    required String otp,
    required String token,
    required String deviceId,
    required String lat,
    required String lng,
  }) async {
    try {
      final String cid = await SharedPrefsUtil.getCid();

      final Map<String, String> body = {
        'type': '2089',
        'cid': cid,
        'lt': lat,
        'ln': lng,
        'device_id': deviceId,
        'mobile': mobile,
        'otp': otp,
        'token': token,
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        body: body,
      );

      print("OTP Verification Response: ${response.body}");

      if (response.statusCode == 200) {
        print("OTP VERIFY RAW DATA => ${response.body}");
        final Map<String, dynamic> decodedData = jsonDecode(response.body);
        print("OTP VERIFY DECODED MAP => $decodedData");
        
        final apiResponse = LoginResponse.fromJson(decodedData);
        print("Parsed response: $apiResponse");
        
        return apiResponse;
      } else {
        return LoginResponse(
          error: true,
          errorMsg: "Server error: ${response.statusCode}",
        );
      }
    } catch (e) {
      print("OTP Verification API Error: $e");
      return LoginResponse(
        error: true,
        errorMsg: "Failed to verify OTP: $e",
      );
    }
  }
}
