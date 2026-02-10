import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

          /// TABS (UNCHANGED)
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
                          color: selectedTab == 0 ? Colors.white : Colors.black,
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
                          color: selectedTab == 1 ? Colors.white : Colors.black,
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

  List<String> leaveTypes = [];
  bool isLoading = false;

  static const String baseUrl = "https://erpsmart.in/total/api/m_api/";

  @override
  void initState() {
    super.initState();
    _loadEmployeeId();
    _fetchLeaveTypes();
  }

  /// ================= EMPLOYEE ID =================
  Future<void> _loadEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();

    final stored = prefs.getString("employee_table_id");
    if (stored != null && stored.isNotEmpty) {
      employeeTableId = stored;
      _employeeCompleter.complete();
      return;
    }

    final uid = prefs.getInt("uid")?.toString();
    if (uid == null) {
      _employeeCompleter.complete();
      return;
    }

    try {
      final res = await http.post(
        Uri.parse(baseUrl),
        body: {
          "type": "2048",
          "cid": "21472147",
          "uid": uid,
          "device_id": "123456",
          "lt": "123",
          "ln": "123",
        },
      );

      final data = jsonDecode(res.body);

      if (data["error"] == false) {
        final empId = data["data"]?["id"]?.toString();
        if (empId != null && empId.isNotEmpty) {
          employeeTableId = empId;
          await prefs.setString("employee_table_id", empId);
        }
      }
    } catch (_) {}
    _employeeCompleter.complete();
  }

  /// ================= LEAVE TYPES =================
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
          data["data"]["leave_types"].map(
            (e) => e["leave_type_name"].toString(),
          ),
        );
      });
    }
  }

  /// ================= APPLY LEAVE =================
  Future<void> _applyLeave() async {
    if (!_formKey.currentState!.validate() ||
        fromDate == null ||
        toDate == null) {
      _snack("Fill all fields", false);
      return;
    }

    await _employeeCompleter.future;

    if (employeeTableId == null) {
      _snack("Employee not found. Re-login", false);
      return;
    }

    setState(() => isLoading = true);

    final res = await http.post(
      Uri.parse(baseUrl),
      body: {
        "type": "2043",
        "uid": employeeTableId!,
        "leave_type": leaveType!,
        "leave_start_date":
            "${fromDate!.year}-${fromDate!.month.toString().padLeft(2, '0')}-${fromDate!.day.toString().padLeft(2, '0')}",
        "leave_end_date":
            "${toDate!.year}-${toDate!.month.toString().padLeft(2, '0')}-${toDate!.day.toString().padLeft(2, '0')}",
        "reason": reason!,
        "cid": "21472147",
        "device_id": "123456",
        "lt": "123",
        "ln": "123",
      },
    );

    final data = jsonDecode(res.body);

    if (data["error"] == false) {
      _snack("Leave applied successfully", true);
      _formKey.currentState!.reset();
      setState(() {
        fromDate = null;
        toDate = null;
        leaveType = null;
        reason = null;
      });
    } else {
      _snack(data["error_msg"] ?? "Failed", false);
    }

    setState(() => isLoading = false);
  }

  void _snack(String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  /// ================= UI (UNCHANGED) =================
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
      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
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
}
