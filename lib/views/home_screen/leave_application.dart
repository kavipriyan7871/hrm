import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/leave_api.dart';
import '../../models/employee_api.dart';
import 'leave_management.dart';
import 'permission_form.dart';

// Helper extension for 12-hour time format
extension TimeOfDayExtension on TimeOfDay {
  String format12Hour() {
    final hour = hourOfPeriod == 0 ? 12 : hourOfPeriod;
    final minute = this.minute.toString().padLeft(2, '0');
    final period = this.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

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

          /// Tabs (UNCHANGED)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
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
                          color: selectedTab == 0
                              ? Colors.white
                              : Colors.grey.shade700,
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

  String? employeeName;
  String? employeeTableId;

  // 🔥 FIX: wait controller
  final Completer<void> _employeeLoadCompleter = Completer<void>();

  String? leaveType;
  DateTime? fromDate;
  DateTime? toDate;
  String? reason;

  List<String> leaveTypes = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEmployeeDetails();
    _fetchLeaveTypes();
  }

  /// FETCH EMPLOYEE DETAILS (FIXED – UI UNCHANGED)
  Future<void> _loadEmployeeDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final loginUid = (prefs.getInt('uid') ?? 0).toString();

    try {
      final res = await EmployeeApi.getEmployeeDetails(
        uid: loginUid,
        cid: "21472147",
        deviceId: "123456",
        lat: prefs.getDouble('lat')?.toString() ?? "123",
        lng: prefs.getDouble('lng')?.toString() ?? "123",
      );

      if (res["error"] == false && res["data"] != null) {
        employeeName = res["data"]["name"]?.toString();
        employeeTableId = res["data"]["id"]?.toString();

        await prefs.setString('employee_table_id', employeeTableId!);
      }
    } catch (e) {
      debugPrint("Employee fetch error => $e");
    } finally {
      if (!_employeeLoadCompleter.isCompleted) {
        _employeeLoadCompleter.complete(); // 🔥 KEY FIX
      }
    }
  }

  /// FETCH LEAVE TYPES (UNCHANGED)
  Future<void> _fetchLeaveTypes() async {
    try {
      final res = await LeaveApi.getLeaveTypes(
        cid: "21472147",
        deviceId: "123456",
        lat: "123",
        lng: "123",
      );

      if (res["error"] == false &&
          res["data"] != null &&
          res["data"]["leave_types"] != null) {
        final List list = res["data"]["leave_types"];
        setState(() {
          leaveTypes = list
              .map((e) => e["leave_type_name"].toString())
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Leave type error => $e");
    }
  }

  /// APPLY LEAVE (FIXED – WAITS FOR EMPLOYEE)
  Future<void> _applyLeave() async {
    debugPrint("===== SUBMIT CLICKED =====");

    if (!_formKey.currentState!.validate() ||
        fromDate == null ||
        toDate == null) {
      _snack("Please fill all fields", false);
      return;
    }

    if (employeeTableId == null) {
      debugPrint("WAITING FOR EMPLOYEE DETAILS...");
      await _employeeLoadCompleter.future;
    }

    debugPrint("EMPLOYEE TABLE ID AFTER WAIT => $employeeTableId");

    if (employeeTableId == null || employeeTableId!.isEmpty) {
      _snack("Employee details not available. Please re-login.", false);
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await LeaveApi.applyLeave(
        uid: employeeTableId!,
        leaveType: leaveType!,
        fromDate:
            "${fromDate!.year}-${fromDate!.month.toString().padLeft(2, '0')}-${fromDate!.day.toString().padLeft(2, '0')}",
        toDate:
            "${toDate!.year}-${toDate!.month.toString().padLeft(2, '0')}-${toDate!.day.toString().padLeft(2, '0')}",
        reason: reason!,
        cid: "21472147",
        deviceId: "123456",
        lat: "145",
        lng: "145",
      );

      debugPrint("APPLY LEAVE API RESPONSE => $res");

      if (res["error"] == false) {
        _snack(res["error_msg"] ?? "Leave applied successfully", true);
        _formKey.currentState!.reset();
        setState(() {
          fromDate = null;
          toDate = null;
          leaveType = null;
          reason = null;
        });
      } else {
        _snack(res["error_msg"] ?? "Failed to apply leave", false);
      }
    } catch (e) {
      debugPrint("Apply leave error => $e");
      _snack("Server error", false);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _snack(String msg, bool success) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  /// ================= UI BELOW – 100% SAME =================

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
                if (isFrom) {
                  fromDate = picked;
                } else {
                  toDate = picked;
                }
              });
            }
          },
          child: Container(
            height: 56,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
