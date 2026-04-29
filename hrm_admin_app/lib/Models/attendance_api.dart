import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Utils/shared_prefs_util.dart';

class AttendanceResponse {
  final bool error;
  final String message;
  final int count;
  final List<AttendanceData> data;

  AttendanceResponse({
    required this.error,
    required this.message,
    required this.count,
    required this.data,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawData = json['data'] ?? [];
    final List<AttendanceData> parsedData = rawData.map((e) => AttendanceData.fromJson(e)).where((item) {
      // Filter out deleted records
      final String delFlag = item.del?.toString() ?? "";
      final String isDFlag = item.isD?.toString() ?? "";
      return delFlag != "1" && isDFlag != "1";
    }).toList();

    // Sort by ID descending (Newest first)
    parsedData.sort((a, b) => b.id.compareTo(a.id));

    return AttendanceResponse(
      error: json['error'] ?? false,
      message: json['message'] ?? "",
      count: parsedData.length,
      data: parsedData,
    );
  }
}

class AttendanceData {
  final int id;
  final int uid;
  final int cid;
  final String? inTime;
  final String? outTime;
  final String? employeeName;
  final String? employeeCode;
  final String? loc;
  final String? screenshot; // photo field in API
  final String? selfie;
  final String? status;
  final String? date;
  final String? workMode;
  final String? transportId;
  final String? approvalStatus;
  final String? approvedBy;
  final String? totalHours;
  final String? remarks;
  final String? clientName;
  final dynamic del;
  final dynamic isD;

  // Static caches to share names/codes between records
  static final Map<int, String> _nameCache = {};
  static final Map<int, String> _codeCache = {};

  AttendanceData({
    required this.id,
    required this.uid,
    required this.cid,
    this.inTime,
    this.outTime,
    this.employeeName,
    this.employeeCode,
    this.loc,
    this.screenshot,
    this.selfie,
    this.status,
    this.date,
    this.workMode,
    this.transportId,
    this.approvalStatus,
    this.approvedBy,
    this.totalHours,
    this.remarks,
    this.clientName,
    this.del,
    this.isD,
  });

  factory AttendanceData.fromJson(Map<String, dynamic> json) {
    final int uid = json['uid'] ?? 0;

    String? name = json['employee_name'] ?? json['e_name'] ?? json['name'] ?? json['emp_name'];
    if (name != null && name.isNotEmpty && name.toLowerCase() != "unknown") {
      _nameCache[uid] = name;
    } else {
      name = _nameCache[uid];
    }

    String? code = json['employee_code'] ?? json['e_code'] ?? json['emp_code'] ?? json['staff_code'];
    if (code != null && code.isNotEmpty) {
      _codeCache[uid] = code;
    } else {
      code = _codeCache[uid];
    }

    return AttendanceData(
      id: json['id'] ?? 0,
      uid: uid,
      cid: json['cid'] ?? 0,
      inTime: json['in_time'] ?? json['check_in_time'] ?? json['break_in'],
      outTime: json['out_time'] ?? json['check_out_time'] ?? json['break_out'],
      employeeName: name,
      employeeCode: code,
      loc: json['loc'] ?? json['location'] ?? json['check_in_location'],
      screenshot: json['photo'],
      selfie: json['selfie'],
      status: json['status'],
      date: json['date'],
      workMode: json['wrk_mde'],
      transportId: json['transport_id'],
      approvalStatus: json['attendance_status'] ?? json['approval_status'],
      approvedBy: json['approved_by'],
      totalHours: json['total_hours'],
      remarks: json['remarks'] ?? json['reason'],
      clientName: json['client_name'] ?? json['cus_name'],
      del: json['del'],
      isD: json['is_d'],
    );
  }
}

class AttendanceApi {
  static const String _baseUrl = "https://erpsmart.in/total/api/m_api/";

  static Future<AttendanceResponse> fetchMobileAttendance() async {
    try {
      final params = await SharedPrefsUtil.getCommonParams();
      final Map<String, String> body = {
        'type': '2083',
        'cid': params['cid']!,
        'uid': params['uid']!,
        'id': params['uid']!,
        'cus_id': params['uid']!,
        'lt': params['lt']!,
        'ln': params['ln']!,
        'token': params['token']!,
        'device_id': params['device_id']!,
        'form': 'sm_main_form_15930',
        'select': '*',
      };

      final response = await http.post(Uri.parse(_baseUrl), body: body);
      if (response.statusCode == 200) {
        return AttendanceResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception("Failed to load attendance: ${response.statusCode}");
    } catch (e) {
      throw Exception("Error fetching attendance: $e");
    }
  }

  static Future<AttendanceResponse> fetchInOfficeAttendance() async {
    try {
      final params = await SharedPrefsUtil.getCommonParams();
      final Map<String, String> body = {
        'type': '2083',
        'cid': params['cid']!,
        'lt': params['lt']!,
        'ln': params['ln']!,
        'token': params['token']!,
        'device_id': params['device_id']!,
        'form': 'sm_main_form_15931',
        'select': '*',
      };

      final response = await http.post(Uri.parse(_baseUrl), body: body);
      if (response.statusCode == 200) {
        return AttendanceResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception("Failed to load in-office attendance: ${response.statusCode}");
    } catch (e) {
      throw Exception("Error fetching in-office attendance: $e");
    }
  }

  static Future<AttendanceResponse> fetchBreakAttendance() async {
    try {
      final params = await SharedPrefsUtil.getCommonParams();
      final Map<String, String> body = {
        'type': '2083',
        'cid': params['cid']!,
        'lt': params['lt']!,
        'ln': params['ln']!,
        'token': params['token']!,
        'device_id': params['device_id']!,
        'form': 'sm_main_form_15932',
        'select': '*',
      };

      final response = await http.post(Uri.parse(_baseUrl), body: body);
      if (response.statusCode == 200) {
        return AttendanceResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception("Failed to load break attendance: ${response.statusCode}");
    } catch (e) {
      throw Exception("Error fetching break attendance: $e");
    }
  }

  static Future<AttendanceResponse> fetchMarketingAttendance() async {
    try {
      final params = await SharedPrefsUtil.getCommonParams();
      final Map<String, String> body = {
        'type': '2083',
        'cid': params['cid']!,
        'lt': params['lt']!,
        'ln': params['ln']!,
        'token': params['token']!,
        'device_id': params['device_id']!,
        'form': 'sm_main_form_15971',
        'select': '*',
      };

      final response = await http.post(Uri.parse(_baseUrl), body: body);
      if (response.statusCode == 200) {
        return AttendanceResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception("Failed to load marketing attendance: ${response.statusCode}");
    } catch (e) {
      throw Exception("Error fetching marketing attendance: $e");
    }
  }
}
