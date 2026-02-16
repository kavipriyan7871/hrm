import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class MarketingApi {
  static const String baseUrl = "https://erpsmart.in/total/api/m_api/";

  // Marketing Check-In (Type: 2054)
  static Future<Map<String, dynamic>> checkIn({
    required String uid,
    required String cid,
    required String deviceId,
    required String lat,
    required String lng,
    required String type, // Default: 2054 from UI side request
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      request.fields.addAll({
        'cid': cid,
        'device_id': deviceId,
        'id': uid, // Request says 'id: 40'
        'ln': lng,
        'lt': lat,
        'type': type,
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("Marketing Check-In Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "error": true,
          "message": "Server error: ${response.statusCode}",
        };
      }
    } catch (e) {
      print("Marketing Check-In Error: $e");
      return {"error": true, "message": e.toString()};
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
    File? attachment,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      request.fields.addAll({
        'cid': cid,
        'device_id': deviceId,
        'uid': uid, // Request says 'uid: 20'
        'ln': lng,
        'lt': lat,
        'type': type,
        'client_name': clientName,
        'date': date,
        'remarks': remarks,
        'purpose_of_visit_id': purposeOfVisitId,
        'location': location,
      });

      if (attachment != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'attachments',
            attachment.path,
            contentType: MediaType('image', 'jpeg'), // Or dynamic
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("Marketing Check-Out Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "error": true,
          "error_msg": "Server error: ${response.statusCode}",
        };
      }
    } catch (e) {
      print("Marketing Check-Out Error: $e");
      return {"error": true, "error_msg": e.toString()};
    }
  }

  // Fetch Marketing History (Type: 2062)
  static Future<Map<String, dynamic>> fetchHistory({
    required String uid,
    required String cid,
    required String lat,
    required String lng,
    required String deviceId,
    String type = "2062",
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        body: {
          'cid': cid,
          'uid': uid,
          'type': type,
          'lt': lat,
          'ln': lng,
          'device_id': deviceId,
        },
      );

      print("Marketing History Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "error": true,
          "error_msg": "Server error: ${response.statusCode}",
        };
      }
    } catch (e) {
      print("Marketing History Error: $e");
      return {"error": true, "error_msg": e.toString()};
    }
  }
}
