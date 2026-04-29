import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Utils/shared_prefs_util.dart';

class EmployeeDetailResponse {
  final bool error;
  final String message;
  final int count;
  final List<EmployeeData> data;

  EmployeeDetailResponse({
    required this.error,
    required this.message,
    required this.count,
    required this.data,
  });

  factory EmployeeDetailResponse.fromJson(Map<String, dynamic> json) {
    return EmployeeDetailResponse(
      error: json['error'] ?? false,
      message: json['message'] ?? "",
      count: json['count'] ?? 0,
      data: (json['data'] as List?)
              ?.map((e) => EmployeeData.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class EmployeeData {
  final int id;
  final dynamic aid;
  final int uid;
  final dynamic bid;
  final int cid;
  final dynamic did;
  final String employeeCode;
  final String name;
  final String dob;
  final String gender;
  final String maritalStatus;
  final String bloodGroup;
  final String contactNumber;
  final String companyNumber;
  final String alternateContactNumber;
  final String emailId;
  final dynamic address;
  final String communicationAddress;
  final String department;
  final dynamic jobTitle;
  final String reportingManager;
  final String employeeType;
  final String dateOfJoining;
  final String experience;
  final String qualification;
  final String skills;
  final String workLocation;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String panNumber;
  final String aadhaarNumber;
  final String emergencyContactName;
  final String emergencyContactNumber;
  final dynamic profilePhoto;
  final dynamic documents;
  final dynamic remarks;
  final String createdDate;
  final String updatedDate;
  final String shift;
  final String age;
  final String institutionName;
  final String specification;
  final String passedOut;
  final String employeeStatus;
  final String salary;
  final String primaryAddress;
  final dynamic profileDoc;
  final dynamic currentAddress;
  final String officialMailId;
  final dynamic del;
  final dynamic isD;
  final dynamic act;
  final String dtime;

  EmployeeData({
    required this.id,
    this.aid,
    required this.uid,
    this.bid,
    required this.cid,
    this.did,
    required this.employeeCode,
    required this.name,
    required this.dob,
    required this.gender,
    required this.maritalStatus,
    required this.bloodGroup,
    required this.contactNumber,
    required this.companyNumber,
    required this.alternateContactNumber,
    required this.emailId,
    this.address,
    required this.communicationAddress,
    required this.department,
    this.jobTitle,
    required this.reportingManager,
    required this.employeeType,
    required this.dateOfJoining,
    required this.experience,
    required this.qualification,
    required this.skills,
    required this.workLocation,
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    required this.panNumber,
    required this.aadhaarNumber,
    required this.emergencyContactName,
    required this.emergencyContactNumber,
    this.profilePhoto,
    this.documents,
    this.remarks,
    required this.createdDate,
    required this.updatedDate,
    required this.shift,
    required this.age,
    required this.institutionName,
    required this.specification,
    required this.passedOut,
    required this.employeeStatus,
    required this.salary,
    required this.primaryAddress,
    this.profileDoc,
    this.currentAddress,
    required this.officialMailId,
    this.del,
    this.isD,
    this.act,
    required this.dtime,
  });

  factory EmployeeData.fromJson(Map<String, dynamic> json) {
    return EmployeeData(
      id: json['id'] ?? 0,
      aid: json['aid'],
      uid: json['uid'] ?? 0,
      bid: json['bid'],
      cid: json['cid'] ?? 0,
      did: json['did'],
      employeeCode: json['employee_code'] ?? "",
      name: json['name'] ?? "",
      dob: json['dob'] ?? "",
      gender: json['gender'] ?? "",
      maritalStatus: json['marital_status'] ?? "",
      bloodGroup: json['blood_group'] ?? "",
      contactNumber: json['contact_number'] ?? "",
      companyNumber: json['company_number'] ?? "",
      alternateContactNumber: json['alternate_contact_number'] ?? "",
      emailId: json['email_id'] ?? "",
      address: json['address'],
      communicationAddress: json['communication_address'] ?? "",
      department: json['department'] ?? "",
      jobTitle: json['job_title'],
      reportingManager: json['reporting_manager'] ?? "",
      employeeType: json['employee_type'] ?? "",
      dateOfJoining: json['date_of_joining'] ?? "",
      experience: json['experience'] ?? "",
      qualification: json['qualification'] ?? "",
      skills: json['skills'] ?? "",
      workLocation: json['work_location'] ?? "",
      bankName: json['bank_name'] ?? "",
      accountNumber: json['account_number'] ?? "",
      ifscCode: json['ifsc_code'] ?? "",
      panNumber: json['pan_number'] ?? "",
      aadhaarNumber: json['aadhaar_number'] ?? "",
      emergencyContactName: json['emergency_contact_name'] ?? "",
      emergencyContactNumber: json['emergency_contact_number'] ?? "",
      profilePhoto: json['profile_photo'],
      documents: json['documents'],
      remarks: json['remarks'],
      createdDate: json['created_date'] ?? "",
      updatedDate: json['updated_date'] ?? "",
      shift: json['shift'] ?? "",
      age: json['age'] ?? "",
      institutionName: json['institution_name'] ?? "",
      specification: json['specification'] ?? "",
      passedOut: json['passed_out'] ?? "",
      employeeStatus: json['employee_status'] ?? "",
      salary: json['salary'] ?? "",
      primaryAddress: json['primary_address'] ?? "",
      profileDoc: json['profile_doc'],
      currentAddress: json['current_address'],
      officialMailId: json['official_mail_id'] ?? "",
      del: json['del'],
      isD: json['is_d'],
      act: json['act'],
      dtime: json['dtime'] ?? "",
    );
  }
}

class EmployeeApi {
  static const String _baseUrl = "https://erpsmart.in/total/api/m_api/";

  static Future<EmployeeDetailResponse> fetchEmployeeDetails({
    String? employeeName,
    String? uid,
    String? cid,
  }) async {
    try {
      final String finalCid = cid ?? await SharedPrefsUtil.getCid();
      final String deviceId = await SharedPrefsUtil.getDeviceId();
      final String lt = await SharedPrefsUtil.getLat();
      final String ln = await SharedPrefsUtil.getLng();

      final Map<String, String> body = {
        'type': '2083',
        'cid': finalCid,
        'lt': lt,
        'ln': ln,
        'device_id': deviceId,
        'form': 'sm_main_form_15521',
        'select': '*',
      };

      if (uid != null && uid.isNotEmpty) {
        body['where'] = "uid=$uid";
      } else if (employeeName != null && employeeName.isNotEmpty) {
        body['where'] = "e_name=$employeeName";
      }

      print("Employee Details Request body: $body");

      final response = await http.post(
        Uri.parse(_baseUrl),
        body: body,
      );

      print("Employee Details response Status Code: ${response.statusCode}");
      print("Employee Details response body: ${response.body}");

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        return EmployeeDetailResponse.fromJson(decodedData);
      } else {
        throw Exception("Failed to load employee details: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching employee details: $e");
      throw Exception("Error fetching employee details: $e");
    }
  }

  static Future<ResignationResponse> fetchResignationProcess() async {
    try {
      final String cid = await SharedPrefsUtil.getCid();
      final String deviceId = await SharedPrefsUtil.getDeviceId();
      final String lt = await SharedPrefsUtil.getLat();
      final String ln = await SharedPrefsUtil.getLng();

      final Map<String, String> body = {
        'type': '2083',
        'cid': cid,
        'lt': lt,
        'ln': ln,
        'device_id': deviceId,
        'form': 'sm_main_form_15621',
        'select': '*',
      };

      print("Resignation Process Request body: $body");

      final response = await http.post(
        Uri.parse(_baseUrl),
        body: body,
      );

      print("Resignation Process response Status Code: ${response.statusCode}");
      print("Resignation Process response body: ${response.body}");

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        return ResignationResponse.fromJson(decodedData);
      } else {
        throw Exception("Failed to load resignation process: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching resignation process: $e");
      throw Exception("Error fetching resignation process: $e");
    }
  }
}

class ResignationResponse {
  final bool error;
  final String message;
  final int count;
  final List<ResignationData> data;

  ResignationResponse({
    required this.error,
    required this.message,
    required this.count,
    required this.data,
  });

  factory ResignationResponse.fromJson(Map<String, dynamic> json) {
    return ResignationResponse(
      error: json['error'] ?? false,
      message: json['message'] ?? "",
      count: json['count'] ?? 0,
      data: (json['data'] as List?)
              ?.map((e) => ResignationData.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ResignationData {
  final int id;
  final dynamic aid;
  final int uid;
  final dynamic bid;
  final int cid;
  final dynamic did;
  final String employeeName;
  final dynamic employeeId;
  final String department;
  final dynamic jobTitle;
  final String lastWrkDate;
  final String exitReason;
  final String exitInterviewStatus;
  final String handoverStatus;
  final String agreement;
  final String finalSettlementAmt;
  final String exitApproval;
  final String remark;
  final dynamic designation;
  final dynamic del;
  final dynamic isD;
  final dynamic act;
  final String dtime;

  ResignationData({
    required this.id,
    this.aid,
    required this.uid,
    this.bid,
    required this.cid,
    this.did,
    required this.employeeName,
    this.employeeId,
    required this.department,
    this.jobTitle,
    required this.lastWrkDate,
    required this.exitReason,
    required this.exitInterviewStatus,
    required this.handoverStatus,
    required this.agreement,
    required this.finalSettlementAmt,
    required this.exitApproval,
    required this.remark,
    this.designation,
    this.del,
    this.isD,
    this.act,
    required this.dtime,
  });

  factory ResignationData.fromJson(Map<String, dynamic> json) {
    return ResignationData(
      id: json['id'] ?? 0,
      aid: json['aid'],
      uid: json['uid'] ?? 0,
      bid: json['bid'],
      cid: json['cid'] ?? 0,
      did: json['did'],
      employeeName: json['employee_name'] ?? "",
      employeeId: json['employee_id'],
      department: json['department'] ?? "",
      jobTitle: json['job_title'],
      lastWrkDate: json['last_wrk_date'] ?? "",
      exitReason: json['exit_reason'] ?? "",
      exitInterviewStatus: json['exit_interview_status'] ?? "",
      handoverStatus: json['handover_status'] ?? "",
      agreement: json['agreement'] ?? "",
      finalSettlementAmt: json['final_settlement_amt'] ?? "",
      exitApproval: json['exit_approval'] ?? "",
      remark: json['remark'] ?? "",
      designation: json['designation'],
      del: json['del'],
      isD: json['is_d'],
      act: json['act'],
      dtime: json['dtime'] ?? "",
    );
  }
}
