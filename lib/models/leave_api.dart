import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LeaveService {
  static const String baseUrl = "https://erpsmart.in/total/api/m_api/";

  /// ===============================
  /// GET EMPLOYEE TABLE ID (FIXED)
  /// ===============================
  static Future<String?> getEmployeeTableId() async {
    final prefs = await SharedPreferences.getInstance();

    // 🔥 ONLY SOURCE OF TRUTH
    final empId = prefs.getString("employee_table_id");

    if (empId != null && empId.isNotEmpty) {
      return empId;
    }

    // ❌ NO API CALL HERE
    return null;
  }

  /// ===============================
  /// GET LEAVE TYPES
  /// ===============================
  static Future<List<String>> getLeaveTypes() async {
    final prefs = await SharedPreferences.getInstance();
    final res = await http.post(
      Uri.parse(baseUrl),
      body: {
        "type": "2044",
        "cid": prefs.getString('cid') ?? "",
        "device_id": prefs.getString('device_id') ?? "",
        "lt": "123",
        "ln": "123",
      },
    );

    final data = jsonDecode(res.body);

    if (data["error"] == false) {
      return List<String>.from(
        data["data"]["leave_types"].map((e) => e["leave_type_name"].toString()),
      );
    }
    return [];
  }

  /// ===============================
  /// APPLY LEAVE
  /// ===============================
  static Future<Map<String, dynamic>> applyLeave({
    required String leaveType,
    required String fromDate,
    required String toDate,
    required String reason,
  }) async {
    final empId = await getEmployeeTableId();

    if (empId == null || empId.isEmpty) {
      return {
        "error": true,
        "error_msg": "Employee not found. Please re-login.",
      };
    }

    final prefs = await SharedPreferences.getInstance();
    final res = await http.post(
      Uri.parse(baseUrl),
      body: {
        "type": "2043",
        "uid": empId, // ✅ ALWAYS CORRECT
        "leave_type": leaveType,
        "leave_start_date": fromDate,
        "leave_end_date": toDate,
        "reason": reason,
        "cid": prefs.getString('cid') ?? "",
        "device_id": prefs.getString('device_id') ?? "",
        "lt": "123",
        "ln": "123",
      },
    );

    return jsonDecode(res.body);
  }
}
