import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';

class TicketApi {
  static final ApiClient _apiClient = ApiClient();

  /// ================================
  /// GET DEPARTMENTS (type:2050)
  /// ================================
  static Future<List<Map<String, dynamic>>> fetchDepartments() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ Standardized UID Priority: login_cus_id (Primary)
      String uid =
          prefs.getString("login_cus_id") ??
          prefs.getString("server_uid") ??
          prefs.getString("employee_table_id") ??
          prefs.getInt("uid")?.toString() ??
          "";

      final body = {
        "type": "2050",
        "cid": prefs.getString("cid") ?? "",
        "uid": uid,
        "id": uid, // Mirror for backward compatibility
        "device_id": prefs.getString('device_id') ?? "",
        "lt": (prefs.getDouble('lat') ?? 0.0).toString(),
        "ln": (prefs.getDouble('lng') ?? 0.0).toString(),
        if (prefs.getString('token') != null)
          "token": prefs.getString('token')!,
      };

      debugPrint("DEPT API BODY => $body");

      final response = await _apiClient.post(body);

      debugPrint("DEPT API RESPONSE => ${response.body}");

      final data = json.decode(response.body);

      // ✅ TOKEN ROTATION
      final newToken = data["token"]?.toString();
      if (newToken != null && newToken.isNotEmpty) {
        await prefs.setString("token", newToken);
      }

      if (data["error"] == false &&
          data["data"] != null &&
          data["data"]["departments"] != null) {
        return List<Map<String, dynamic>>.from(data["data"]["departments"]);
      } else if (data["departments"] != null) {
        return List<Map<String, dynamic>>.from(data["departments"]);
      }

      return [];
    } catch (e) {
      debugPrint("DEPT API ERROR => $e");
      return [];
    }
  }

  /// ================================
  /// VIEW TICKETS (type:2058)
  /// ================================
  static Future<List<Map<String, dynamic>>> fetchTickets() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Standardized UID Priority: login_cus_id (Primary)
      String uid =
          prefs.getString("login_cus_id") ??
          prefs.getString("server_uid") ??
          prefs.getString("employee_table_id") ??
          prefs.getInt("uid")?.toString() ??
          "";

      final body = {
        "type": "2058",
        "cid": prefs.getString("cid") ?? "",
        "device_id": prefs.getString('device_id') ?? "",
        "uid": uid,
        "id": uid, // Mirror for backward compatibility
        "lt": (prefs.getDouble('lat') ?? 0.0).toString(),
        "ln": (prefs.getDouble('lng') ?? 0.0).toString(),
        if (prefs.getString('token') != null)
          "token": prefs.getString('token')!,
      };

      final response = await _apiClient.post(body);
      final data = json.decode(response.body);

      if (data["error"] == false) {
        if (data["data"] is List) {
          return List<Map<String, dynamic>>.from(data["data"]);
        } else if (data["data"] is Map && data["data"]["tickets"] != null) {
          return List<Map<String, dynamic>>.from(data["data"]["tickets"]);
        } else if (data["tickets"] != null) {
          return List<Map<String, dynamic>>.from(data["tickets"]);
        }
      }

      return [];
    } catch (e) {
      debugPrint("TICKET FETCH ERROR => $e");
      return [];
    }
  }

  /// ================================
  /// RAISE TICKET (type:2049)
  /// ================================
  static Future<Map<String, dynamic>> raiseTicket({
    required String subject,
    required String department,
    required String description,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Standardized UID Priority: login_cus_id (Primary)
      String uid =
          prefs.getString("login_cus_id") ??
          prefs.getString("server_uid") ??
          prefs.getString("employee_table_id") ??
          prefs.getInt("uid")?.toString() ??
          "";

      final body = {
        "type": "2049",
        "cid": prefs.getString("cid") ?? "",
        "device_id": prefs.getString('device_id') ?? "",
        "uid": uid,
        "id": uid, // Mirror for backward compatibility
        "token": prefs.getString('token') ?? "",
        "department": department,
        "subject": subject,
        "description": description,
        "priority": "normal",
        "lt": (prefs.getDouble('lat') ?? 0.0).toString(),
        "ln": (prefs.getDouble('lng') ?? 0.0).toString(),
      };

      final response = await _apiClient.post(body);
      final data = json.decode(response.body);

      return {
        "success": data["error"] == false,
        "message":
            data["error_msg"] ??
            data["message"] ??
            "Ticket raised successfully",
        "ticket_id": data["ticket_id"],
        "data": data,
      };
    } catch (e) {
      debugPrint("RAISE TICKET ERROR => $e");
      return {"success": false, "message": "Something went wrong"};
    }
  }
}
