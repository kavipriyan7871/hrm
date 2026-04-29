import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Utils/shared_prefs_util.dart';

class PermissionRequestResponse {
  final bool error;
  final String message;
  final int count;
  final List<PermissionRequestData> data;

  PermissionRequestResponse({
    required this.error,
    required this.message,
    required this.count,
    required this.data,
  });

  factory PermissionRequestResponse.fromJson(Map<String, dynamic> json) {
    return PermissionRequestResponse(
      error: json['error'] ?? false,
      message: json['message'] ?? "",
      count: json['count'] ?? 0,
      data: (json['data'] as List?)
              ?.map((e) => PermissionRequestData.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class PermissionRequestData {
  final int id;
  final int? uid;
  final String employeeName;
  final String? employeeCode;
  final String? permissionType;
  final String? appDate;
  final String? startTime;
  final String? endDate;
  final String? reason;
  final String? status;
  final String? appBy;
  final String? approvalDate;
  final String? balPermission;

  PermissionRequestData({
    required this.id,
    this.uid,
    required this.employeeName,
    this.employeeCode,
    this.permissionType,
    this.appDate,
    this.startTime,
    this.endDate,
    this.reason,
    this.status,
    this.appBy,
    this.approvalDate,
    this.balPermission,
  });

  factory PermissionRequestData.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    return PermissionRequestData(
      id: parseId(json['id']),
      uid: json['uid'] != null ? parseId(json['uid']) : null,
      employeeName: json['employee_name'] ?? json['e_name'] ?? "Unknown",
      employeeCode: json['employee_code'],
      permissionType: json['permission_type'],
      appDate: json['app_date'] ?? json['date'],
      startTime: json['start_time'],
      endDate: json['end_date'],
      reason: json['reason'],
      status: json['status'],
      appBy: json['app_by'],
      approvalDate: json['approval_date'],
      balPermission: json['bal_permission']?.toString(),
    );
  }
}

class PermissionApi {
  static const String _baseUrl = "https://erpsmart.in/total/api/m_api/";

  static Future<PermissionRequestResponse> fetchPermissionRequests({String? reportingManager}) async {
    try {
      final params = await SharedPrefsUtil.getCommonParams();

      final Map<String, String> body = {
        'type': '2083',
        'cid': params['cid']!,
        'lt': params['lt']!,
        'ln': params['ln']!,
        'device_id': params['device_id']!,
        'token': params['token']!,
        'form': 'sm_main_form_16143',
        'select': '*',
        if (reportingManager != null && reportingManager.isNotEmpty)
          'where': 'reporting_manager=$reportingManager',
      };

      print("Permission Request Request body: $body");

      final response = await http.post(
        Uri.parse(_baseUrl),
        body: body,
      );

      print("Permission Request response Status Code: ${response.statusCode}");
      print("Permission Request response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(response.body);
        return PermissionRequestResponse.fromJson(decodedData);
      } else {
        throw Exception("Failed to load permission requests: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching permission requests: $e");
      throw Exception("Error fetching permission requests: $e");
    }
  }

  static Future<Map<String, dynamic>> updatePermissionStatus({
    required String permissionId,
    required String status,
    String? rejectReason,
  }) async {
    try {
      final params = await SharedPrefsUtil.getCommonParams();
      final String adminUid = params['uid']!;

      final Map<String, String> body = {
        'type': '2091',
        'cid': params['cid']!,
        'lt': params['lt']!,
        'ln': params['ln']!,
        'device_id': params['device_id']!,
        'token': params['token']!,
        'form': 'sm_main_form_16143',
        'permission_id': permissionId,
        'uid': adminUid.isEmpty ? "0" : adminUid,
        'id': adminUid.isEmpty ? "0" : adminUid,
        'status': status,
        if (rejectReason != null && rejectReason.isNotEmpty) 'remarks': rejectReason,
      };

      print("--- UPDATING PERMISSION STATUS ---");
      print("URL: $_baseUrl");
      print("BODY: $body");

      final response = await http.post(
        Uri.parse(_baseUrl),
        body: body,
      );

      print("Update Permission Status Response: ${response.body}");
      return jsonDecode(response.body);
    } catch (e) {
      print("Error updating permission status: $e");
      return {"error": true, "message": e.toString()};
    }
  }
}
