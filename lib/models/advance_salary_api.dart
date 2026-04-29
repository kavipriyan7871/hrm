import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';

class AdvanceSalaryApi {
  static final ApiClient _apiClient = ApiClient();

  /// ===============================
  /// GET EMPLOYEE ID
  /// ===============================
  static Future<String?> getEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('uid') ?? 
           prefs.getString('login_cus_id') ?? 
           prefs.get('uid')?.toString();
  }

  /// ===============================
  /// SUBMIT ADVANCE SALARY REQUEST (Type: 2067)
  /// ===============================
  static Future<Map<String, dynamic>> submitAdvanceRequest({
    required String amount,
    required String reason,
    required String date,
    required String deviceId,
    required String lt,
    required String ln,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? empId = await getEmployeeId();

    final Map<String, dynamic> body = {
      "type": "2067",
      "uid": empId ?? "",
      "id": empId ?? "",
      "advance_amount": amount,
      "reason": reason,
      "request_date": date,
      "token": prefs.getString('token') ?? "",
      "device_id": deviceId, 
      "lt": lt,
      "ln": ln,
      "cid": (prefs.get('cid') ?? prefs.get('cid_str') ?? "").toString(),
    };

    try {
      final response = await _apiClient.post(body);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"error": true, "error_msg": "Server error: ${response.statusCode}"};
      }
    } catch (e) {
      debugPrint("ADVANCE REQUEST ERROR: $e");
      return {"error": true, "error_msg": e.toString()};
    }
  }

  /// ===============================
  /// GET ADVANCE HISTORY (Type: 2068)
  /// ===============================
  static Future<Map<String, dynamic>> getAdvanceHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? empId = await getEmployeeId();

    final Map<String, dynamic> body = {
      "type": "2068",
      "uid": empId ?? "",
      "id": empId ?? "",
      "token": prefs.getString('token') ?? "",
      "cid": (prefs.get('cid') ?? prefs.get('cid_str') ?? "").toString(),
    };

    try {
      final response = await _apiClient.post(body);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"error": true, "error_msg": "Server error: ${response.statusCode}"};
      }
    } catch (e) {
      debugPrint("ADVANCE HISTORY ERROR: $e");
      return {"error": true, "error_msg": e.toString()};
    }
  }
}
