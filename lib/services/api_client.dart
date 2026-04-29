import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  final http.Client _client = http.Client();

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal();

  static const String baseUrl = "https://erpsmart.in/total/api/m_api/";

  Future<http.Response> post(Map<String, dynamic> body) async {
    Map<String, String> finalBody = {};
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Inject global params if not explicitly provided in body
      finalBody = Map<String, String>.from(
        body.map((key, value) => MapEntry(key, value.toString()))
      );

      final String? token = prefs.getString('token');
      final String? cid = prefs.getString('cid') ?? prefs.getString('cid_str');

      if (!finalBody.containsKey('cid') && cid != null) {
        finalBody['cid'] = cid;
      }
      
      if (!finalBody.containsKey('lt')) {
        finalBody['lt'] = prefs.getString('lt') ?? prefs.getDouble('lat')?.toString() ?? prefs.getString('latitude') ?? "";
      }
      if (!finalBody.containsKey('ln')) {
        finalBody['ln'] = prefs.getString('ln') ?? prefs.getDouble('lng')?.toString() ?? prefs.getString('longitude') ?? "";
      }
      if (!finalBody.containsKey('device_id')) {
        finalBody['device_id'] = prefs.getString('device_id') ?? "123456";
      }

      final response = await _client.post(
        Uri.parse(baseUrl),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          if (token != null) 'token': token,
          if (token != null) 'Token': token,
          if (token != null) 'auth-token': token,
          if (token != null) 'Authorization-Plain': token, // Extra fallback
        },
        body: finalBody,
      ).timeout(const Duration(seconds: 30));

      debugPrint("API REQUEST [${finalBody['type']}] => $finalBody");
      debugPrint("API RESPONSE [${finalBody['type']}] => ${response.body}");

      // TOKEN ROTATION: Auto-save new token if returned by server
      try {
        final data = json.decode(response.body);
        final String? newToken = data["token"]?.toString();
        if (newToken != null && newToken.isNotEmpty) {
          await prefs.setString("token", newToken);
          debugPrint("TOKEN ROTATION => New token saved");
        }
      } catch (_) {}

      return response;
    } catch (e) {
      debugPrint("API POST ERROR => $finalBody");
      debugPrint("DETAILED ERROR => $e");
      rethrow;
    }
  }

  Future<http.Response> postJson(Map<String, dynamic> body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> finalBody = Map<String, dynamic>.from(body);
      final String? token = prefs.getString('token');
      final String? cid = prefs.getString('cid') ?? prefs.getString('cid_str');

      if (!finalBody.containsKey('cid') && cid != null) finalBody['cid'] = cid;
      if (!finalBody.containsKey('lt')) finalBody['lt'] = prefs.getDouble('lat') ?? 0.0;
      if (!finalBody.containsKey('ln')) finalBody['ln'] = prefs.getDouble('lng') ?? 0.0;
      if (!finalBody.containsKey('device_id')) finalBody['device_id'] = prefs.getString('device_id') ?? "Unknown";

      debugPrint("API REQUEST JSON => $finalBody");
      final response = await _client.post(
        Uri.parse(baseUrl),
        headers: {
          "Content-Type": "application/json",
          if (token != null) 'Authorization': 'Bearer $token',
          if (token != null) 'token': token,
          if (token != null) 'Token': token,
          if (token != null) 'auth-token': token,
        },
        body: jsonEncode(finalBody),
      ).timeout(const Duration(seconds: 30));

      // TOKEN ROTATION
      try {
        final data = json.decode(response.body);
        final String? newToken = data["token"]?.toString();
        if (newToken != null && newToken.isNotEmpty) {
          await prefs.setString("token", newToken);
        }
      } catch (_) {}

      return response;
    } catch (e) {
      debugPrint("API POST JSON ERROR => $e");
      rethrow;
    }
  }

  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      final String? cid = prefs.getString('cid') ?? prefs.getString('cid_str');

      if (request is http.MultipartRequest && cid != null) {
        if (!request.fields.containsKey('cid')) request.fields['cid'] = cid;
      }

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
        request.headers['token'] = token;
        request.headers['Token'] = token;
        request.headers['auth-token'] = token;
        request.headers['Authorization-Plain'] = token;
      }

      debugPrint("API SEND HEADERS => ${request.headers}");
      final streamedResponse = await _client.send(request).timeout(const Duration(seconds: 60));
      
      return streamedResponse;
    } catch (e) {
      debugPrint("API SEND ERROR => $e");
      rethrow;
    }
  }

  // Closes the client when the application is finished.
  void dispose() {
    _client.close();
  }
}
