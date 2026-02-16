import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TicketApi {
  static const String baseUrl = "https://erpsmart.in/total/api/m_api/";

  /// ================================
  /// GET DEPARTMENTS (type:2050)
  /// ================================
  static Future<List<Map<String, dynamic>>> fetchDepartments() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ ROBUST UID RETRIEVAL
      // Default to "8" if not found, matching the user's example
      String uid = "8";
      try {
        if (prefs.containsKey("uid")) {
          final val = prefs.get("uid");
          if (val != null) uid = val.toString();
        } else if (prefs.containsKey("employee_table_id")) {
          uid = prefs.getString("employee_table_id") ?? "8";
        }
      } catch (e) {
        debugPrint("UID RETRIEVAL ERROR => $e");
      }

      final body = {
        "type": "2050",
        "cid": prefs.getString("cid") ?? "21472147",
        "uid": uid,
        "device_id": "123456",
        "lt": (prefs.getDouble('lat') ?? 145).toString(),
        "ln": (prefs.getDouble('lng') ?? 145).toString(),
      };

      debugPrint("DEPT API BODY => $body");

      final response = await http.post(Uri.parse(baseUrl), body: body);

      debugPrint("DEPT API RESPONSE => ${response.body}");

      final data = json.decode(response.body);

      // Check for error false or specific structure
      if (data["error"] == false &&
          data["data"] != null &&
          data["data"]["departments"] != null) {
        return List<Map<String, dynamic>>.from(data["data"]["departments"]);
      } else if (data["departments"] != null) {
        // Fallback if structure is slightly different
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

      // ✅ ROBUST UID RETRIEVAL - PREFER stored UID, fallback to 12
      String uid = "12";
      try {
        if (prefs.containsKey("uid")) {
          final val = prefs.get("uid");
          if (val != null) uid = val.toString();
        } else if (prefs.containsKey("employee_table_id")) {
          uid = prefs.getString("employee_table_id") ?? "12";
        }
      } catch (e) {
        debugPrint("UID RETRIEVAL ERROR => $e");
      }

      final body = {
        "type": "2058",
        "cid": prefs.getString("cid") ?? "21472147",
        "device_id": "123456",
        "uid": uid,
        "lt": "3232", // Explicitly requested by user: 3232
        "ln": "332", // Explicitly requested by user: 332
      };

      debugPrint("VIEW TICKETS BODY => $body");

      final response = await http.post(Uri.parse(baseUrl), body: body);

      debugPrint("VIEW TICKETS RESPONSE => ${response.body}");

      final data = json.decode(response.body);

      // ✅ ROBUST PARSING
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
      debugPrint("VIEW TICKETS ERROR => $e");
      return [];
    }
  }

  /// ================================
  /// RAISE TICKET (type:2048)
  /// LOGGED-IN EMPLOYEE ONLY
  /// ================================
  static Future<Map<String, dynamic>> raiseTicket({
    required String subject,
    required String department,
    required String description,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ ROBUST UID RETRIEVAL
      // Default to "8" if not found
      String uid = "8";
      try {
        if (prefs.containsKey("uid")) {
          final val = prefs.get("uid");
          if (val != null) uid = val.toString();
        } else if (prefs.containsKey("employee_table_id")) {
          uid = prefs.getString("employee_table_id") ?? "8";
        }
      } catch (e) {
        debugPrint("UID RETRIEVAL ERROR => $e");
      }

      final String cid = prefs.getString("cid") ?? "21472147";

      final body = {
        "type": "2049",
        "subject": subject,
        "department": department,
        "description": description,
        "cid": cid,
        "device_id": "123456",
        "ln": (prefs.getDouble('lng') ?? 145).toString(),
        "lt": (prefs.getDouble('lat') ?? 145).toString(),
        "uid": uid,
      };

      debugPrint("RAISE TICKET BODY => $body");

      final response = await http.post(Uri.parse(baseUrl), body: body);

      debugPrint("RAISE TICKET RESPONSE => ${response.body}");

      final data = json.decode(response.body);

      return {
        "success": data["error"] == false,
        "message": data["message"] ?? data["error_msg"] ?? "Success",
        "data": data,
      };
    } catch (e) {
      debugPrint("RAISE TICKET ERROR => $e");
      return {"success": false, "message": "Something went wrong"};
    }
  }
}
