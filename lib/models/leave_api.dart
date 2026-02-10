import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LeaveService {
  static const String baseUrl =
      "https://erpsmart.in/total/api/m_api/";

  /// ===============================
  /// FETCH EMPLOYEE TABLE ID
  /// ===============================
  static Future<String?> getEmployeeTableId() async {
    final prefs = await SharedPreferences.getInstance();

    // already stored
    final storedId = prefs.getString("employee_table_id");
    if (storedId != null && storedId.isNotEmpty) {
      return storedId;
    }

    final uid = prefs.getInt("uid")?.toString();
    if (uid == null) return null;

    final res = await http.post(
      Uri.parse(baseUrl),
      body: {
        "type": "2048",
        "cid": "21472147",
        "uid": uid,
        "device_id": "123456",
        "lt": "123",
        "ln": "123",
      },
    );

    final data = jsonDecode(res.body);

    if (data["error"] == false) {
      final empId = data["data"]?["id"]?.toString();

      if (empId != null && empId.isNotEmpty) {
        await prefs.setString("employee_table_id", empId);
        return empId;
      }
    }
    return null;
  }

  /// ===============================
  /// GET LEAVE TYPES
  /// ===============================
  static Future<List<String>> getLeaveTypes() async {
    final res = await http.post(
      Uri.parse(baseUrl),
      body: {
        "type": "2044",
        "cid": "21472147",
        "device_id": "123456",
        "lt": "123",
        "ln": "123",
      },
    );

    final data = jsonDecode(res.body);

    if (data["error"] == false) {
      return List<String>.from(
        data["data"]["leave_types"]
            .map((e) => e["leave_type_name"].toString()),
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

    if (empId == null) {
      return {
        "error": true,
        "error_msg": "Employee not found. Please re-login."
      };
    }

    final res = await http.post(
      Uri.parse(baseUrl),
      body: {
        "type": "2043",
        "uid": empId, // ✅ CORRECT ID
        "leave_type": leaveType,
        "leave_start_date": fromDate,
        "leave_end_date": toDate,
        "reason": reason,
        "cid": "21472147",
        "device_id": "123456",
        "lt": "123",
        "ln": "123",
      },
    );

    return jsonDecode(res.body);
  }
}
