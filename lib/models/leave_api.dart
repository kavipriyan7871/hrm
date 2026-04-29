import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';

class LeaveService {
  static final ApiClient _apiClient = ApiClient();

  /// ===============================
  /// GET EMPLOYEE TABLE ID
  /// ===============================
  static Future<String?> getEmployeeTableId([SharedPreferences? prefs]) async {
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

  /// ===============================
  /// GET LEAVE SUMMARY (Type: 2051)
  /// ===============================
  static Future<Map<String, dynamic>> getLeaveSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final empId = await getEmployeeTableId(prefs);
    
    final body = {
      "type": "2051",
      "uid": empId ?? "",
      "id": empId ?? "",
      "token": prefs.getString('token') ?? "",
      "cid": (prefs.get('cid') ?? prefs.get('cid_str') ?? "").toString(),
      "device_id": prefs.getString('device_id') ?? "",
      "lt": (prefs.getDouble('lat') ?? 0.0).toString(),
      "ln": (prefs.getDouble('lng') ?? 0.0).toString(),
    };
    
    final res = await _apiClient.post(body);
    return jsonDecode(res.body);
  }

  /// ===============================
  /// GET LEAVE HISTORY (Type: 2052)
  /// ===============================
  static Future<Map<String, dynamic>> getLeaveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final empId = await getEmployeeTableId();
    
    final body = {
      "type": "2052",
      "uid": empId ?? "",
      "id": empId ?? "",
      "token": prefs.getString('token') ?? "",
      "cid": (prefs.get('cid') ?? prefs.get('cid_str') ?? "").toString(),
      "device_id": prefs.getString('device_id') ?? "",
      "lt": (prefs.getDouble('lat') ?? 0.0).toString(),
      "ln": (prefs.getDouble('lng') ?? 0.0).toString(),
    };
    
    final res = await _apiClient.post(body);
    return jsonDecode(res.body);
  }

  /// ===============================
  /// GET LEAVE DURATIONS (Type: 2083)
  /// ===============================
  static Future<List<String>> getLeaveDurations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final body = {
        "type": "2083",
        "cid": (prefs.get('cid') ?? prefs.get('cid_str') ?? "").toString(),
        "device_id": prefs.getString('device_id') ?? "",
        "lt": (prefs.getDouble('lat') ?? 0.0).toString(),
        "ln": (prefs.getDouble('lng') ?? 0.0).toString(),
        "form": "sm_main_form_16313",
        "select": "dur",
      };

      final res = await _apiClient.post(body);
      final data = jsonDecode(res.body);

      if (data["error"].toString() == "false") {
        var rawData = data["data"];
        if (rawData is List) {
          return rawData.map((e) => e["dur"].toString()).toList();
        }
      }
    } catch (e) {
      debugPrint("API Error in getLeaveDurations: $e");
    }
    return ["Full Day", "Half Day(First Half)", "Half Day(Second Half)"]; // Fallback
  }

  /// ===============================
  /// GET LEAVE TYPES (Type: 2044)
  /// ===============================
  static Future<List<Map<String, dynamic>>> getLeaveTypes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final empId = await getEmployeeTableId(prefs);
      
      final body = {
        "type": "2044",
        "uid": empId ?? "",
        "id": empId ?? "",
        "token": prefs.getString('token') ?? "",
        "cid": (prefs.get('cid') ?? prefs.get('cid_str') ?? "").toString(),
        "device_id": prefs.getString('device_id') ?? "",
        "lt": (prefs.getDouble('lat') ?? 0.0).toString(),
        "ln": (prefs.getDouble('lng') ?? 0.0).toString(),
        "select": "*",
      };

      final res = await _apiClient.post(body);
      final data = jsonDecode(res.body);

      if (data["error"].toString() == "false" || data["error"] == false) {
        var rawData = data["data"];
        List? rawList;
        
        if (rawData is List) {
          rawList = rawData;
        } else if (rawData is Map) {
          rawList = rawData["leave_types"] ?? rawData["data"] ?? rawData["list"] ?? rawData["types"];
        }
        
        rawList ??= data["leave_types"] ?? data["data"] ?? data["list"] ?? data["types"];

        if (rawList is List && rawList.isNotEmpty) {
          return rawList.map((e) {
            if (e is Map) {
              return {
                "id": e["id"]?.toString() ?? e["leave_id"]?.toString() ?? "",
                "name": (e["leave_type_name"] ?? e["leave_type"] ?? e["name"] ?? "").toString(),
                "max_month": e["max_leave_per_month"]?.toString() ?? e["max_month"]?.toString() ?? "0",
                "max_year": e["max_days_per_year"]?.toString() ?? e["max_year"]?.toString() ?? "0",
              };
            }
            return {"name": e.toString(), "max_month": "0", "max_year": "0"};
          }).where((e) => e["name"].toString().isNotEmpty).map((e) => e as Map<String, dynamic>).toList();
        }
      }
    } catch (e) {
      debugPrint("API Error in getLeaveTypes: $e");
    }
    
    // Fallback if API fails (common leave types)
    return [
      {"id": "1", "name": "Casual Leave", "max_month": "1", "max_year": "12"},
      {"id": "2", "name": "Sick Leave", "max_month": "1", "max_year": "12"},
      {"id": "3", "name": "Earned Leave", "max_month": "1", "max_year": "15"},
    ];
  }

  /// ===============================
  /// APPLY LEAVE (Type: 2043)
  /// ===============================
  static Future<Map<String, dynamic>> applyLeave({
    required String leaveType,
    required String fromDate,
    required String toDate,
    required String reason,
    required String leaveDur,
  }) async {
    final empId = await getEmployeeTableId();

    if (empId == null || empId.isEmpty) {
      return {
        "error": true,
        "error_msg": "Employee not found. Please re-login.",
      };
    }

    final prefs = await SharedPreferences.getInstance();
    final res = await _apiClient.post({
        "type": "2043",
        "uid": empId,
        "id": empId,
        "token": prefs.getString('token') ?? "",
        "leave_type": leaveType,
        "leave_start_date": fromDate,
        "leave_end_date": toDate,
        "reason": reason,
        "leave_dur": leaveDur,
        "cid": prefs.getString('cid') ?? prefs.getString('cid_str') ?? "",
        "device_id": prefs.getString('device_id') ?? "",
        "lt": (prefs.getDouble('lat') ?? 0.0).toString(),
        "ln": (prefs.getDouble('lng') ?? 0.0).toString(),
    });

    return jsonDecode(res.body);
  }
}
