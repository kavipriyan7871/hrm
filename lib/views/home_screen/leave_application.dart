import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dotted_border/dotted_border.dart';

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
          if (selectedTab == 0) const LeaveForm() else PermissionForm(),
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
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();

  List<String> leaveTypes = [];
  bool isLoading = false;

  static const String baseUrl = "https://erpsmart.in/total/api/m_api/";

  @override
  void initState() {
    super.initState();
    _loadEmployeeId();
    _fetchLeaveTypes();
  }

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
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

    if (!mounted) return;

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

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles();
    if (!mounted) return;
    if (result != null) {
      setState(() {
        attachment = File(result.files.single.path!);
      });
    }
  }

  Future<void> _applyLeave() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    if (fromDate == null || toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select From Date and To Date')),
      );
      return;
    }

    if (leaveType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Leave Type')),
      );
      return;
    }

    // Check if reason is actually saved/updated
    if (reason == null || reason!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a reason')));
      return;
    }

    setState(() => isLoading = true);

    try {
      if (employeeTableId == null) {
        // Try fetch again or fail
        final prefs = await SharedPreferences.getInstance();
        if (!mounted) return;
        employeeTableId = prefs.getString("employee_table_id");
        if (employeeTableId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employee ID not found. Relogin.')),
          );
          setState(() => isLoading = false);
          return;
        }
      }

      var request = http.MultipartRequest("POST", Uri.parse(baseUrl));
      request.fields['type'] = '2043';
      request.fields['cid'] = '21472147';
      request.fields['uid'] = employeeTableId!;
      request.fields['leave_type'] = leaveType!;
      request.fields['leave_start_date'] = _formatDate(fromDate!);
      request.fields['leave_end_date'] = _formatDate(toDate!);
      request.fields['reason'] = reason!;
      request.fields['device_id'] = '123456';
      request.fields['lt'] = "143.23"; // Dummy coords if not available
      request.fields['ln'] = "123.12";

      if (attachment != null) {
        request.files.add(
          await http.MultipartFile.fromPath('attachment', attachment!.path),
        );
      }

      var streamedResponse = await request.send();
      if (!mounted) return;
      var response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);

      if (data["error"] == false || data["error"] == 'false') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Success: Leave Applied Successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Clear Form
          _formKey.currentState!.reset();
          _fromDateController.clear();
          _toDateController.clear();
          setState(() {
            leaveType = null;
            fromDate = null;
            toDate = null;
            reason = null;
            attachment = null;
          });

          // Navigate to Leave Management Screen
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LeaveManagementScreen(),
                ),
              );
            }
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data["error_msg"] ?? 'Failed to apply leave'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _formatDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Leave Type'),
          DropdownButtonFormField<String>(
            value: leaveType,
            hint: Text(
              'Select Leave Type',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
            decoration: _inputDecoration(),
            items: leaveTypes
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, style: GoogleFonts.poppins(fontSize: 14)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => leaveType = v),
            validator: (v) => v == null ? 'Required' : null,
          ),

          const SizedBox(height: 16),
          _label('From Date'),
          _buildDatePicker(true),

          const SizedBox(height: 16),
          _label('To date'),
          _buildDatePicker(false),

          const SizedBox(height: 16),
          _label('Reason'),
          TextFormField(
            maxLines: 4,
            validator: (v) => v!.isEmpty ? 'Required' : null,
            onChanged: (v) => reason = v,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: _inputDecoration().copyWith(hintText: 'Reason'),
          ),

          const SizedBox(height: 16),
          _label('Attachments'),
          _buildAttachmentBox(),

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading ? null : _applyLeave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff26A69A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Submit',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDatePicker(bool isFrom) {
    return TextFormField(
      controller: isFrom ? _fromDateController : _toDateController,
      readOnly: true,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (!mounted) return;
        if (picked != null) {
          setState(() {
            final formatted = "${picked.day}-${picked.month}-${picked.year}";
            if (isFrom) {
              fromDate = picked;
              _fromDateController.text = formatted;
            } else {
              toDate = picked;
              _toDateController.text = formatted;
            }
          });
        }
      },
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: _inputDecoration().copyWith(
        hintText: 'Select Date',
        prefixIcon: const Icon(
          Icons.calendar_today_outlined,
          color: Color(0xff534f8c), // Indigo color for icon
          size: 20,
        ),
      ),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xff534F8C),
        ), // Dark Blue/Purple Border
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xff534F8C)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xff26A69A), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Widget _buildAttachmentBox() {
    return GestureDetector(
      onTap: _pickAttachment,
      child: DottedBorder(
        color: const Color(0xff534F8C), // Matches border color
        strokeWidth: 1,
        dashPattern: const [6, 4],
        borderType: BorderType.RRect,
        radius: const Radius.circular(12),
        child: Container(
          width: double.infinity,
          height: 140,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (attachment != null)
                Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      attachment!.path.split('/').last,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    const Icon(Icons.add, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      "Add Attachments",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
