import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';

class PermissionApi {
  static final ApiClient _apiClient = ApiClient();

  static Future<String?> getEmployeeId([SharedPreferences? prefs]) async {
    final effectivePrefs = prefs ?? await SharedPreferences.getInstance();
    // Prioritize uid, then fallbacks
    String? id = effectivePrefs.getString('uid');
    if (id == null || id.isEmpty) {
      id = effectivePrefs.getString('login_cus_id');
    }
    if (id == null || id.isEmpty) {
      id = effectivePrefs.get('uid')?.toString();
    }
    return id;
  }

  static Future<Map<String, dynamic>> submitPermission({
    required String date,
    required String fromTime,
    String? toTime,
    required String reason,
    required String deviceId,
    required String lt,
    required String ln,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? empId = await getEmployeeId(prefs);

    final Map<String, dynamic> body = {
      "type": "2065",
      "uid": empId ?? "",
      "id": empId ?? "",
      "permission_date": date,
      "from_time": fromTime,
      "end_time": toTime ?? "",
      "reason": reason,
      "token": prefs.getString('token') ?? "",
      "device_id": deviceId, 
      "lt": lt,
      "ln": ln,
    };

    try {
      final response = await _apiClient.post(body);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"error": true, "error_msg": "Server error: ${response.statusCode}"};
      }
    } catch (e) {
      return {"error": true, "error_msg": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getPermissionTypes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? empId = await getEmployeeId(prefs);

    final Map<String, dynamic> body = {
      "type": "2066",
      "uid": empId ?? "",
      "id": empId ?? "",
      "token": prefs.getString('token') ?? "",
    };

    try {
      final response = await _apiClient.post(body);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"error": true, "error_msg": "Server error: ${response.statusCode}"};
      }
    } catch (e) {
      return {"error": true, "error_msg": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getPermissionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? empId = await getEmployeeId(prefs);

    final Map<String, dynamic> body = {
      "type": "2078",
      "uid": empId ?? "",
      "id": empId ?? "",
      "token": prefs.getString('token') ?? "",
    };

    try {
      final response = await _apiClient.post(body);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"error": true, "error_msg": "Server error: ${response.statusCode}"};
      }
    } catch (e) {
      debugPrint("PERMISSION HISTORY ERROR: $e");
      return {"error": true, "error_msg": e.toString()};
    }
  }
}
