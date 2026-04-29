import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Utils/shared_prefs_util.dart';

class MarketingAttendanceResponse {
  final bool error;
  final String message;
  final int count;
  final List<MarketingAttendanceData> data;

  MarketingAttendanceResponse({
    required this.error,
    required this.message,
    required this.count,
    required this.data,
  });

  factory MarketingAttendanceResponse.fromJson(Map<String, dynamic> json) {
    return MarketingAttendanceResponse(
      error: json['error'] ?? false,
      message: json['message'] ?? "",
      count: json['count'] ?? 0,
      data: (json['data'] as List?)
              ?.map((e) => MarketingAttendanceData.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class MarketingAttendanceData {
  final int id;
  final dynamic aid;
  final int uid;
  final dynamic bid;
  final int cid;
  final dynamic did;
  final String employeeName;
  final String employeeId;
  final String date;
  final String clientName;
  final String location;
  final String purposeOfVisit;
  final String remarks;
  final String? attachments;
  final String checkInTime;
  final String checkOutTime;
  final String? checkOutLocation;
  final String? checkInLocation;
  final dynamic del;
  final dynamic isD;
  final dynamic act;
  final String dtime;

  MarketingAttendanceData({
    required this.id,
    this.aid,
    required this.uid,
    this.bid,
    required this.cid,
    this.did,
    required this.employeeName,
    required this.employeeId,
    required this.date,
    required this.clientName,
    required this.location,
    required this.purposeOfVisit,
    required this.remarks,
    this.attachments,
    required this.checkInTime,
    required this.checkOutTime,
    this.checkOutLocation,
    this.checkInLocation,
    this.del,
    this.isD,
    this.act,
    required this.dtime,
  });

  factory MarketingAttendanceData.fromJson(Map<String, dynamic> json) {
    return MarketingAttendanceData(
      id: json['id'] ?? 0,
      aid: json['aid'],
      uid: json['uid'] ?? 0,
      bid: json['bid'],
      cid: json['cid'] ?? 0,
      did: json['did'],
      employeeName: json['employee_name'] ?? "",
      employeeId: json['employee_id'] ?? "",
      date: json['date'] ?? "",
      clientName: json['client_name'] ?? "",
      location: json['location'] ?? "",
      purposeOfVisit: json['purpose_of_visit'] ?? "",
      remarks: json['remarks'] ?? "",
      attachments: json['attachments'],
      checkInTime: json['check_in_time'] ?? "",
      checkOutTime: json['check_out_time'] ?? "",
      checkOutLocation: json['check_out_location'],
      checkInLocation: json['check_in_location'],
      del: json['del'],
      isD: json['is_d'],
      act: json['act'],
      dtime: json['dtime'] ?? "",
    );
  }
}

class MarketingApi {
  static const String _baseUrl = "https://erpsmart.in/total/api/m_api/";

  static Future<MarketingAttendanceResponse> fetchMarketingAttendance() async {
    try {
      final String cid = await SharedPrefsUtil.getCid();
      final String deviceId = await SharedPrefsUtil.getDeviceId();
      final String lt = await SharedPrefsUtil.getLat();
      final String ln = await SharedPrefsUtil.getLng();

      final String uid = await SharedPrefsUtil.getUid();

      final Map<String, String> body = {
        'type': '2083',
        'cid': cid,
        'uid': uid,
        'id': uid,
        'cus_id': uid,
        'lt': lt,
        'ln': ln,
        'device_id': deviceId,
        'form': 'sm_main_form_15971',
        'select': '*',
      };

      print("Marketing Attendance Request body: $body");

      final response = await http.post(
        Uri.parse(_baseUrl),
        body: body,
      );

      print("Marketing Attendance response Status Code: ${response.statusCode}");
      print("Marketing Attendance response body: ${response.body}");

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        return MarketingAttendanceResponse.fromJson(decodedData);
      } else {
        throw Exception("Failed to load marketing attendance: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching marketing attendance: $e");
      throw Exception("Error fetching marketing attendance: $e");
    }
  }
}
