import 'dart:convert';
import 'package:http/http.dart' as http;

class LeaveApi {
  static const String baseUrl = "https://erpsmart.in/total/api/m_api/";

  /// GET LEAVE TYPES
  static Future<Map<String, dynamic>> getLeaveTypes({
    required String cid,
    required String deviceId,
    required String lat,
    required String lng,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      body: {
        "type": "2044",
        "cid": cid,
        "device_id": deviceId,
        "ln": lng,
        "lt": lat,
      },
    );

    return jsonDecode(response.body);
  }

  /// APPLY LEAVE
  static Future<Map<String, dynamic>> applyLeave({
    required String uid, // employee_table_id
    required String leaveType,
    required String fromDate,
    required String toDate,
    required String reason,
    required String cid,
    required String deviceId,
    required String lat,
    required String lng,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      body: {
        "type": "2043",
        "uid": uid,
        "leave_type": leaveType,
        "leave_start_date": fromDate,
        "leave_end_date": toDate,
        "reason": reason,
        "cid": cid,
        "device_id": deviceId,
        "ln": lng,
        "lt": lat,
      },
    );

    return jsonDecode(response.body);
  }
}
