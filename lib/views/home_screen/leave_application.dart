import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';

import '../../models/leave_api.dart';
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

  List<Map<String, dynamic>> leaveTypes = [];
  Map<String, dynamic>? selectedLeaveTypeObj;
  String? leaveDuration;
  List<String> durations = [];
  bool isLoading = false;
  bool isTypesLoading = false;
  bool _isPickingImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadEmployeeId();
    _fetchLeaveTypes();
    _fetchDurations();
  }

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  /// 🔥 STANDARDIZED UID LOADING
  Future<void> _loadEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    employeeTableId =
        prefs.getString('uid') ??
        prefs.getString('login_cus_id') ??
        prefs.get('uid')?.toString() ??
        "";

    debugPrint("LEAVE SCREEN STANDARDIZED UID => $employeeTableId");
    _employeeCompleter.complete();
  }

  Future<void> _fetchLeaveTypes() async {
    setState(() => isTypesLoading = true);
    try {
      // 1. Fetch official types (2044)
      final types = await LeaveService.getLeaveTypes();
      
      // Update UI immediately with types so dropdown is not empty
      if (mounted) {
        setState(() {
          leaveTypes = types.map((t) => {
            ...t,
            "taken_month": 0.0,
            "taken_year": 0.0,
            "is_exhausted": false,
          }).toList();
          isTypesLoading = false; 
        });
        
        if (types.isEmpty) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("No leave types found from server."))
           );
        }
      }

      // 2. Fetch history (2052) to calculate current month/year usage in background
      final historyRes = await LeaveService.getLeaveHistory();
      List<dynamic> historyList = [];
      
      if (historyRes['leave_applications'] != null && historyRes['leave_applications'] is List) {
        historyList = historyRes['leave_applications'];
      } else if (historyRes['data'] != null && historyRes['data'] is List) {
        historyList = historyRes['data'];
      }

      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;

      if (!mounted) return;

      setState(() {
        leaveTypes = leaveTypes.map((t) {
          String typeName = t['name']?.toString().toLowerCase().trim() ?? "";
          String typeId = t['id']?.toString() ?? "";
          
          var matches = historyList.where((h) {
            String hType = h['leave_type']?.toString().toLowerCase().trim() ?? "";
            String hTypeId = h['leave_type_id']?.toString() ?? "";
            bool idMatch = (typeId.isNotEmpty && (hTypeId == typeId || hType == typeId));
            bool nameMatch = hType.contains(typeName) || typeName.contains(hType);
            return idMatch || nameMatch;
          }).where((h) {
            final s = h['status']?.toString().toLowerCase() ?? "";
            return s == "approved" || s == "pending" || s == "" || s == "1";
          });

          double takenYear = 0;
          double takenMonth = 0;

          for (var item in matches) {
            try {
              String dateStr = item['leave_start_date'] ?? item['applied_date'] ?? "";
              if (dateStr.isNotEmpty) {
                DateTime? d;
                try { d = DateTime.parse(dateStr); } catch (_) {
                  if (dateStr.contains('-')) {
                    var parts = dateStr.split('-');
                    if (parts[0].length == 4) d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
                    else d = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
                  } else if (dateStr.contains('/')) {
                     var parts = dateStr.split('/');
                     if (parts[0].length == 4) d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
                     else d = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
                  }
                }
                if (d != null && d.year == currentYear) {
                  double days = double.tryParse(item['total_days']?.toString() ?? item['leave_taken']?.toString() ?? "1") ?? 1.0;
                  takenYear += days;
                  if (d.month == currentMonth) takenMonth += days;
                }
              }
            } catch (_) {}
          }

          int maxMonth = int.tryParse(t['max_month']?.toString() ?? "0") ?? 0;
          int maxYear = int.tryParse(t['max_year']?.toString() ?? "0") ?? 0;
          bool monthExhausted = (maxMonth > 0 && takenMonth >= maxMonth);
          bool yearExhausted = (maxYear > 0 && takenYear >= maxYear);

          return {
            ...t,
            "taken_month": takenMonth,
            "taken_year": takenYear,
            "max_month": maxMonth,
            "max_year": maxYear,
            "is_exhausted": monthExhausted || yearExhausted,
            "exhausted_reason": monthExhausted ? "Monthly limit reached" : "Yearly limit reached",
          };
        }).toList();
        isTypesLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching leave types & history: $e");
      if (mounted) setState(() => isTypesLoading = false);
    }
  }

  Future<void> _fetchDurations() async {
    final list = await LeaveService.getLeaveDurations();
    if (mounted) {
      setState(() {
        durations = list;
        if (durations.isNotEmpty) leaveDuration = durations.first;
      });
    }
  }

  Future<void> _pickAttachment(ImageSource source) async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: const Color(0xff26A69A),
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
            IOSUiSettings(
              title: 'Crop Image',
            ),
          ],
        );

        if (croppedFile != null && mounted) {
          setState(() {
            attachment = File(croppedFile.path);
          });
        }
      }
    } catch (e) {
      debugPrint("Error picking/cropping image: $e");
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Choose Attachment Method",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _optionItem(Icons.camera_alt_rounded, "Camera", () {
                  Navigator.pop(context);
                  _pickAttachment(ImageSource.camera);
                }),
                _optionItem(Icons.photo_library_rounded, "Gallery", () {
                  Navigator.pop(context);
                  _pickAttachment(ImageSource.gallery);
                }),
                _optionItem(Icons.attach_file_rounded, "File", () async {
                  Navigator.pop(context);
                  final result = await FilePicker.platform.pickFiles();
                  if (result != null && mounted) {
                    setState(() {
                      attachment = File(result.files.single.path!);
                    });
                  }
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionItem(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xff26A69A).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xff26A69A), size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.poppins(fontSize: 12)),
      ],
    );
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
      final res = await LeaveService.applyLeave(
        leaveType: leaveType!,
        fromDate: DateFormat('yyyy-MM-dd').format(fromDate!),
        toDate: DateFormat('yyyy-MM-dd').format(toDate!),
        reason: reason!,
        leaveDur: leaveDuration ?? "Full Day",
      );

      if (!mounted) return;

      if (res["error"] == false || res["error"] == 'false') {
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
          if (durations.isNotEmpty) leaveDuration = durations.first;
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res["error_msg"] ?? 'Failed to apply leave'),
            backgroundColor: Colors.red,
          ),
        );
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

  String _formatDate(DateTime d) => DateFormat('dd-MM-yyyy').format(d);

  // Helper to format numbers cleanly (1 instead of 1.0)
  String fmt(dynamic n) {
    if (n == null) return "0";
    double? val = double.tryParse(n.toString());
    if (val == null) return n.toString();
    if (val == val.toInt().toDouble()) return val.toInt().toString();
    return val.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Leave Type'),
          DropdownButtonFormField<String>(
            value: selectedLeaveTypeObj?['id'],
            hint: Text(
              isTypesLoading ? 'Loading Types...' : 'Select Leave Type',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
            decoration: _inputDecoration(),
            items: leaveTypes.map((e) {
              bool isExhausted = e['is_exhausted'] == true;
              return DropdownMenuItem<String>(
                value: e['id'],
                enabled: !isExhausted,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isExhausted ? Colors.grey.shade400 : Colors.black,
                        fontWeight: isExhausted ? FontWeight.normal : FontWeight.w600,
                      ),
                    ),
                    Text(
                      "Taken: ${fmt(e['taken_month'])}/${e['max_month']} Month, ${fmt(e['taken_year'])}/${e['max_year']} Year",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: isExhausted ? Colors.red.withOpacity(0.5) : Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            selectedItemBuilder: (BuildContext context) {
              return leaveTypes.map<Widget>((e) {
                return Text(
                  e['name'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList();
            },
            onChanged: isTypesLoading
                ? null
                : (v) {
                    setState(() {
                      selectedLeaveTypeObj = leaveTypes.firstWhere((e) => e['id'] == v);
                      leaveType = selectedLeaveTypeObj?['name'];
                    });
                  },
            validator: (v) => v == null ? 'Required' : null,
          ),

          const SizedBox(height: 16),
          _label('Leave Duration'),
          DropdownButtonFormField<String>(
            value: leaveDuration,
            hint: Text(
              'Select Duration',
              style: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
            ),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
            decoration: _inputDecoration(),
            items: durations.map((e) {
              return DropdownMenuItem<String>(
                value: e,
                child: Text(
                  e,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w500),
                ),
              );
            }).toList(),
            onChanged: (v) => setState(() => leaveDuration = v),
            validator: (v) => v == null ? 'Required' : null,
          ),

          if (selectedLeaveTypeObj != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (selectedLeaveTypeObj!['is_exhausted'] == true) 
                    ? Colors.red.shade50 
                    : const Color(0xff26A69A).withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (selectedLeaveTypeObj!['is_exhausted'] == true) 
                      ? Colors.red.shade200 
                      : const Color(0xff26A69A).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: (selectedLeaveTypeObj!['is_exhausted'] == true) ? Colors.red : const Color(0xff26A69A),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${selectedLeaveTypeObj!['name']} Balance Details",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: (selectedLeaveTypeObj!['is_exhausted'] == true) ? Colors.red : const Color(0xff26A69A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "This Month: ${fmt(selectedLeaveTypeObj!['taken_month'])} / ${selectedLeaveTypeObj!['max_month']} Taken",
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.black87),
                        ),
                        Text(
                          "This Year: ${fmt(selectedLeaveTypeObj!['taken_year'])} / ${selectedLeaveTypeObj!['max_year']} Taken",
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.black87),
                        ),
                        if (selectedLeaveTypeObj!['is_exhausted'] == true)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "⚠️ ${selectedLeaveTypeObj!['exhausted_reason']}",
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
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
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: (isFrom
                  ? fromDate
                  : (toDate ?? (fromDate ?? now))) ??
              now,
          firstDate: now, // restrict to future and present
          lastDate: now.add(const Duration(days: 365)),
        );
        if (!mounted) return;
        if (picked != null) {
          setState(() {
            if (isFrom) {
              fromDate = picked;
              _fromDateController.text = _formatDate(picked);
              // reset toDate if it's before new fromDate
              if (toDate != null && toDate!.isBefore(fromDate!)) {
                toDate = null;
                _toDateController.clear();
              }
            } else {
              if (fromDate != null && picked.isBefore(fromDate!)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('To Date cannot be before From Date')),
                );
                return;
              }
              toDate = picked;
              _toDateController.text = _formatDate(picked);
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
    return Column(
      children: [
        if (attachment != null)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: _isImage(attachment!.path)
                        ? Image.file(attachment!, fit: BoxFit.cover)
                        : Container(
                            color: const Color(0xff26A69A).withOpacity(0.1),
                            child: const Icon(
                              Icons.description_rounded,
                              color: Color(0xff26A69A),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attachment!.path.split('/').last,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "${(attachment!.lengthSync() / 1024).toStringAsFixed(1)} KB",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => attachment = null),
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                ),
              ],
            ),
          )
        else
          GestureDetector(
            onTap: _showAttachmentOptions,
            child: DottedBorder(
              color: const Color(0xff534F8C),
              strokeWidth: 1,
              dashPattern: const [6, 4],
              borderType: BorderType.RRect,
              radius: const Radius.circular(12),
              child: Container(
                width: double.infinity,
                height: 100,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo_outlined, size: 32, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      "Add Attachment",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  bool _isImage(String path) {
    final mime = path.toLowerCase();
    return mime.endsWith('.jpg') ||
        mime.endsWith('.jpeg') ||
        mime.endsWith('.png') ||
        mime.endsWith('.gif') ||
        mime.endsWith('.webp');
  }
}
