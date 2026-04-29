import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';

class MarketingApi {
  static final ApiClient _apiClient = ApiClient();

  // Marketing Check-In (Type: 2054)
  static Future<Map<String, dynamic>> checkIn({
    required String uid,
    required String cid,
    required String deviceId,
    required String lat,
    required String lng,
    required String type, // Default: 2054
    required String date,
    required String checkInTime,
    String? token,
    String? checkInLocation,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'cid': cid,
        'device_id': deviceId,
        'uid': uid,
        'id': uid,
        'cus_id': uid,
        'employee_id': uid,
        'lt': lat,
        'ln': lng,
        'type': type,
        'date': date,
        'check_in_time': checkInTime,
        'location': checkInLocation ?? "Unknown",
        'dtime': checkInTime,
        if (checkInLocation != null) 'check_in_location': checkInLocation,
      };

      debugPrint("Marketing Check-In Request Body: $body");

      final response = await _apiClient.post(body);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded["token"] != null &&
            decoded["token"].toString().isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("token", decoded["token"].toString());
        }
        return decoded;
      } else {
        return {
          "error": true,
          "error_msg": "Server error: ${response.statusCode}",
          "message": "Server error: ${response.statusCode}",
        };
      }
    } catch (e) {
      debugPrint("Marketing Check-In Error: $e");
      return {
        "error": true,
        "error_msg": e.toString(),
        "message": e.toString(),
      };
    }
  }

  // Marketing Check-Out (Type: 2053)
  static Future<Map<String, dynamic>> checkOut({
    required String uid,
    required String cid,
    required String deviceId,
    required String lat,
    required String lng,
    required String type, // Default: 2053
    required String clientName,
    required String date,
    required String remarks,
    required String purposeOfVisitId,
    required String location,
    String? checkinId,
    String? token,
    File? attachment,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(ApiClient.baseUrl));
      request.fields.addAll({
        'cid': cid,
        'device_id': deviceId,
        'uid': uid,
        'id': uid, 
        'cus_id': uid,
        'employee_id': uid,
        'lt': lat,
        'ln': lng,
        'type': type,
        'client_name': clientName,
        'cus_name': clientName, 
        'date': date,
        'remarks': remarks,
        'purpose_of_visit_id': purposeOfVisitId,
        'purpose_of_visit': purposeOfVisitId,
        'location': location,
        'check_out_location': location,
        if (checkinId != null) 'checkin_id': checkinId,
        if (token != null) 'token': token.trim(),
      });

      if (attachment != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'attachments',
            attachment.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final streamedResponse = await _apiClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded["token"] != null &&
            decoded["token"].toString().isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("token", decoded["token"].toString());
        }
        return decoded;
      } else {
        return {
          "error": true,
          "message": "Server error: ${response.statusCode}",
        };
      }
    } catch (e) {
      debugPrint("Marketing Check-Out Error: $e");
      return {"error": true, "message": e.toString()};
    }
  }

  // Fetch Marketing Enquiries (Type: 2076)
  static Future<Map<String, dynamic>> fetchEnquiries({
    required String uid,
    required String cid,
    required String deviceId,
    required String lat,
    required String lng,
    required String assignTo,
    String? token,
    String type = "2076",
  }) async {
    try {
      final Map<String, dynamic> body = {
        'cid': cid,
        'uid': uid,
        'id': uid,
        'cus_id': uid,
        'employee_id': uid,
        'device_id': deviceId,
        'lt': lat,
        'ln': lng,
        'assign_to': assignTo,
        'type': type,
      };

      final response = await _apiClient.post(body);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "error": true,
          "error_msg": "Server error: ${response.statusCode}",
        };
      }
    } catch (e) {
      debugPrint("Fetch Enquiries Error: $e");
      return {"error": true, "error_msg": e.toString()};
    }
  }

  // Fetch History (Type: 2062)
  static Future<Map<String, dynamic>> fetchHistory({
    required String uid,
    required String cid,
    required String deviceId,
    required String lat,
    required String lng,
    String? token,
    String type = "2062",
  }) async {
    try {
      final body = {
        'cid': cid,
        'device_id': deviceId,
        'uid': uid,
        'id': uid,
        'cus_id': uid,
        'employee_id': uid,
        'lt': lat,
        'ln': lng,
        'type': type,
      };

      final response = await _apiClient.post(body);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "error": true,
          "error_msg": "Server error: ${response.statusCode}",
        };
      }
    } catch (e) {
      debugPrint("Fetch Marketing History Error: $e");
      return {"error": true, "error_msg": e.toString()};
    }
  }
}
