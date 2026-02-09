// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import 'package:path/path.dart' as path;

// class AttendanceApi {
//   static const String baseUrl =
//       "https://erpsmart.in/total/api/m_api/";

//   static Future<Map<String, dynamic>> checkIn({
//     required String cid,
//     required String uid,
//     required String inTime,
//     required String location,
//     required String workMode,
//     required String deviceId,
//     required String lat,
//     required String lng,
//     required File selfie,
//   }) async {
//     final uri = Uri.parse(baseUrl);
//     final request = http.MultipartRequest('POST', uri);

//     /// TEXT FIELDS
//     request.fields.addAll({
//       "type": "2046",
//       "cid": cid,
//       "uid": uid,
//       "in_time": inTime,
//       "loc": location,
//       "wrk_mde": workMode,
//       "device_id": deviceId,
//       "ld": "34",
//       "lt": lat,
//       "ln": lng,
//     });

//     /// 🔥 FORCE JPEG IMAGE
//     final fileName =
//         "checkin_${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg";

//     final multipartFile = await http.MultipartFile.fromPath(
//       "selfie",
//       selfie.path,
//       filename: fileName,
//       contentType: MediaType("image", "jpeg"),
//     );

//     request.files.add(multipartFile);

//     final streamedResponse = await request.send();
//     final response =
//         await http.Response.fromStream(streamedResponse);

//     debugPrint("RAW RESPONSE => ${response.body}");

//     return jsonDecode(response.body);
//   }
// }
