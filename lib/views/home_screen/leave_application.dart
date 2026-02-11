import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

import 'leave_management.dart';
import 'permission_form.dart';

class LeaveApplication extends StatelessWidget {
  const LeaveApplication({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xff26A69A),
          foregroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LeaveManagementScreen(),
                ),
                (route) => false,
              );
            },
          ),
          title: Text(
            'Apply Leave / Permission',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        body: const LeaveFormScreen(),
      ),
    );
  }
}

class LeaveFormScreen extends StatefulWidget {
  const LeaveFormScreen({super.key});

  @override
  State<LeaveFormScreen> createState() => _LeaveFormScreenState();
}

class _LeaveFormScreenState extends State<LeaveFormScreen> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          /// TABS
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: selectedTab == 0
                            ? const Color(0xff26A69A)
                            : const Color(0xffC9C9C9),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Text(
                        "Leave Form",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color:
                              selectedTab == 0 ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: selectedTab == 1
                            ? const Color(0xff26A69A)
                            : const Color(0xffC9C9C9),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Text(
                        "Permission Form",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color:
                              selectedTab == 1 ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          if (selectedTab == 0) const LeaveForm() else const PermissionForm(),
        ],
      ),
    );
  }
}

class LeaveForm extends StatefulWidget {
  const LeaveForm({super.key});

  @override
  State<LeaveForm> createState() => _LeaveFormState();
}

class _LeaveFormState extends State<LeaveForm> {
  final _formKey = GlobalKey<FormState>();

  String? employeeTableId;
  final Completer<void> _employeeCompleter = Completer<void>();

  String? leaveType;
  DateTime? fromDate;
  DateTime? toDate;
  String? reason;
  File? attachment;

  List<String> leaveTypes = [];
  bool isLoading = false;

  static const String baseUrl = "https://erpsmart.in/total/api/m_api/";

  @override
  void initState() {
    super.initState();
    _loadEmployeeId();
    _fetchLeaveTypes();
  }

  /// 🔥 ONLY READ STORED EMPLOYEE ID
  Future<void> _loadEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    employeeTableId = prefs.getString("employee_table_id");

    // DEBUG (optional – can remove later)
    debugPrint("LEAVE SCREEN EMP ID => $employeeTableId");

    _employeeCompleter.complete();
  }

  Future<void> _fetchLeaveTypes() async {
    final res = await http.post(
      Uri.parse(baseUrl),
      body: {
        "type": "2044",
        "cid": "21472147",
        "device_id": "123456",
        "lt": "123",
        "ln": "123",
      },
    );

    final data = jsonDecode(res.body);
    if (data["error"] == false) {
      setState(() {
        leaveTypes = List<String>.from(
          data["data"]["leave_types"]
              .map((e) => e["leave_type_name"].toString()),
        );
      });
    }
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        attachment = File(result.files.single.path!);
      });
    }
  }

  Future<void> _applyLeave() async {
    if (!_formKey.currentState!.validate() ||
        fromDate == null ||
        toDate == null) {
      _snack("Fill all fields", false);
      return;
    }

    await _employeeCompleter.future;

    if (employeeTableId == null || employeeTableId!.isEmpty) {
      _snack("Employee not found. Please login again.", false);
      return;
    }

    final request =
        http.MultipartRequest("POST", Uri.parse(baseUrl));

    request.fields.addAll({
      "type": "2043",
      "uid": employeeTableId!, // ✅ CORRECT ID
      "leave_type": leaveType!,
      "leave_start_date": _formatDate(fromDate!),
      "leave_end_date": _formatDate(toDate!),
      "reason": reason!,
      "cid": "21472147",
      "device_id": "123456",
      "lt": "145",
      "ln": "145",
    });

    if (attachment != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          "attachment",
          attachment!.path,
        ),
      );
    }

    final response = await request.send();
    final resBody = await response.stream.bytesToString();
    final data = jsonDecode(resBody);

    if (data["error"] == false) {
      _snack("Leave applied successfully", true);
      _formKey.currentState!.reset();
      setState(() {
        fromDate = null;
        toDate = null;
        leaveType = null;
        reason = null;
        attachment = null;
      });
    } else {
      _snack(data["error_msg"] ?? "Failed", false);
    }
  }

  String _formatDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  void _snack(String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Leave Type'),
          DropdownButtonFormField<String>(
            value: leaveType,
            items: leaveTypes
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => leaveType = v),
            validator: (v) => v == null ? 'Required' : null,
          ),
          _datePicker('From Date', fromDate, true),
          _datePicker('To Date', toDate, false),
          _reasonBox(),
          _attachmentBox(),
          const SizedBox(height: 80),
          Center(
            child: SizedBox(
              width: 325,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : _applyLeave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff26A69A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Submit',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(
          t,
          style:
              GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      );

  Widget _datePicker(String label, DateTime? date, bool isFrom) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(label),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) {
              setState(() {
                isFrom ? fromDate = picked : toDate = picked;
              });
            }
          },
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              date == null
                  ? 'Select Date'
                  : '${date.day}/${date.month}/${date.year}',
            ),
          ),
        ),
      ],
    );
  }

  Widget _reasonBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Reason'),
        TextFormField(
          maxLines: 3,
          validator: (v) => v!.isEmpty ? 'Required' : null,
          onChanged: (v) => reason = v,
          decoration: const InputDecoration(hintText: 'Reason'),
        ),
      ],
    );
  }

  Widget _attachmentBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title("Attachments"),
        InkWell(
          onTap: _pickAttachment,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, size: 40, color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  attachment == null
                      ? "Add Attachments"
                      : attachment!.path.split('/').last,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
