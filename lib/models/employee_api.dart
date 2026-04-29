import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';

class EmployeeApi {
  static final ApiClient _apiClient = ApiClient();

  static Future<Map<String, dynamic>> getEmployeeDetails({
    required String uid,
    required String cid,
    required String deviceId,
    required String lat,
    required String lng,
    String? token,
  }) async {
    try {
      final body = {
        "type": "2048",
        "cid": cid,
        "uid": uid,
        "id": uid,
        "cus_id": uid,
        "device_id": deviceId,
        "lt": lat,
        "ln": lng,
        if (token != null && token.isNotEmpty) "token": token,
      };

      debugPrint("Employee Details API Request (2048) => $body");
      final response = await _apiClient.post(body);
      debugPrint("Employee Details API Response (2048) => ${response.body}");
      final data = jsonDecode(response.body);

      // ✅ TOKEN ROTATION
      final newToken = data["token"]?.toString();
      if (newToken != null && newToken.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", newToken);
      }

      if (response.statusCode == 200 && data["error"] == false) {
        final profileData = data["data"] ?? {};
        final prefs = await SharedPreferences.getInstance();
        final String resolvedUid = uid ??
            prefs.getString('uid') ??
            prefs.getString('login_cus_id') ??
            prefs.getString('employee_table_id') ??
            "";

        // Map exactly to the provided response structure
        await prefs.setString('name', profileData["name"]?.toString() ?? "");
        await prefs.setString('employee_code', profileData["employee_code"]?.toString() ?? "");
        await prefs.setString('dept', profileData["department_name"]?.toString() ?? profileData["department"]?.toString() ?? "");
        await prefs.setString('doj', profileData["date_of_joining"]?.toString() ?? "");
        await prefs.setString('dob', profileData["dob"]?.toString() ?? "");
        await prefs.setString('gender', profileData["gender"]?.toString() ?? "");
        await prefs.setString('blood_group', profileData["blood_group"]?.toString() ?? "");
        await prefs.setString('mobile', profileData["contact_number"]?.toString() ?? "");
        await prefs.setString('profile_photo', profileData["profile_photo"]?.toString() ?? "");
        await prefs.setString('address', profileData["current_address"]?.toString() ?? profileData["address"]?.toString() ?? "");
        await prefs.setString('institution_name', profileData["institution_name"]?.toString() ?? "");
        await prefs.setString('qualification', profileData["qualification"]?.toString() ?? "");
        await prefs.setString('specification', profileData["specification"]?.toString() ?? "");
        await prefs.setString('passed_out', profileData["passed_out"]?.toString() ?? "");
        await prefs.setString('emergency_name', profileData["emergency_contact_name"]?.toString() ?? "");
        await prefs.setString('emergency_number', profileData["emergency_contact_number"]?.toString() ?? "");
        
        // Internal IDs (for reference only, NOT for API calls)
        await prefs.setString('db_id_reference', profileData["id"]?.toString() ?? "");
        await prefs.setString('db_uid_reference', profileData["uid"]?.toString() ?? "");

        return data;
      } else {
        return data;
      }
    } catch (e) {
      debugPrint("Employee Details API Error: $e");
      return {"error": true, "error_msg": e.toString()};
    }
  }
}
