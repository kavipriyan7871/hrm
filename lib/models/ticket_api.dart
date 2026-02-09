import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TicketApi {
  static const String baseUrl =
      "https://erpsmart.in/total/api/m_api/";

  /// ================================
  /// GET DEPARTMENTS (type:2050)
  /// ================================
  static Future<List<Map<String, dynamic>>> fetchDepartments() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final body = {
        "type": "2050",
        "cid": prefs.getString("cid") ?? "21472147",
        "device_id": "123456",
        "lt": (prefs.getDouble('lat') ?? 145).toString(),
        "ln": (prefs.getDouble('lng') ?? 145).toString(),
      };

      debugPrint("DEPT API BODY => $body");

      final response = await http.post(
        Uri.parse(baseUrl),
        body: body,
      );

      debugPrint("DEPT API RESPONSE => ${response.body}");

      final data = json.decode(response.body);

      if (data["error"] == false &&
          data["data"] != null &&
          data["data"]["departments"] != null) {
        return List<Map<String, dynamic>>.from(
          data["data"]["departments"],
        );
      }

      return [];
    } catch (e) {
      debugPrint("DEPT API ERROR => $e");
      return [];
    }
  }

  /// ================================
  /// RAISE TICKET (type:2049)
  /// LOGGED-IN EMPLOYEE ONLY
  /// ================================
  static Future<Map<String, dynamic>> raiseTicket({
    required String subject,
    required String department,
    required String description,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ READ UID AS INT (FIX)
      final int? uidInt = prefs.getInt("uid");
      final String? uid = uidInt?.toString();

      final String cid = prefs.getString("cid") ?? "21472147";

      if (uid == null || uid.isEmpty) {
        return {
          "success": false,
          "message": "User not logged in",
        };
      }

      final body = {
        "type": "2049",
        "subject": subject,
        "department": department,
        "description": description,
        "cid": cid,
        "device_id": "123456",
        "ln": (prefs.getDouble('lng') ?? 145).toString(),
        "lt": (prefs.getDouble('lat') ?? 145).toString(),
        "id": uid, // ✅ SAFE STRING UID
      };

      debugPrint("RAISE TICKET BODY => $body");

      final response = await http.post(
        Uri.parse(baseUrl),
        body: body,
      );

      debugPrint("RAISE TICKET RESPONSE => ${response.body}");

      final data = json.decode(response.body);

      return {
        "success": data["error"] == false,
        "message": data["error_msg"],
        "data": data,
      };
    } catch (e) {
      debugPrint("RAISE TICKET ERROR => $e");
      return {
        "success": false,
        "message": "Something went wrong",
      };
    }
  }
}
