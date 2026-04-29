import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/permission_api.dart';

extension TimeOfDayExtension on TimeOfDay {
  String format12Hour() {
    final hour = hourOfPeriod == 0 ? 12 : hourOfPeriod;
    final minute = this.minute.toString().padLeft(2, '0');
    final period = this.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

class PermissionForm extends StatefulWidget {
  const PermissionForm({super.key});

  @override
  State<PermissionForm> createState() => _PermissionFormState();
}

class _PermissionFormState extends State<PermissionForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _fromTimeController = TextEditingController();
  final TextEditingController _toTimeController = TextEditingController();

  String? employeeName;
  String? employeeId;
  String? uid;
  bool isLoading = false;

  DateTime? selectedDate;
  TimeOfDay? fromTime;
  TimeOfDay? toTime;
  String? reason;
  final Color themeGreen = const Color(0xff26A69A);

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _dateController.text =
        "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}";
    _fetchUserData();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _fromTimeController.dispose();
    _toTimeController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        employeeName = prefs.getString('name');
        uid = prefs.get('uid')?.toString() ?? "";
        employeeId = uid;
      });
    }
  }


  Future<void> _applyPermission() async {
    if (!_formKey.currentState!.validate() ||
        selectedDate == null ||
        fromTime == null ||
        toTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      String deviceId = prefs.getString('device_id') ?? "";
      String lat = (prefs.getDouble('lat') ?? 0.0).toString();
      String lng = (prefs.getDouble('lng') ?? 0.0).toString();

      String fromTimeStr =
          "${fromTime!.hour.toString().padLeft(2, '0')}:${fromTime!.minute.toString().padLeft(2, '0')}";
      String toTimeStr =
          "${toTime!.hour.toString().padLeft(2, '0')}:${toTime!.minute.toString().padLeft(2, '0')}";

      String dateStr =
          "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";

      final res = await PermissionApi.submitPermission(
        date: dateStr,
        fromTime: fromTimeStr,
        toTime: toTimeStr,
        reason: reason ?? "",
        deviceId: deviceId,
        lt: lat,
        ln: lng,
      );

      if (res['error'].toString() == "false") {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                res['error_msg'] ?? "Permission request submitted successfully",
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Redirect to Dashboard after 1 second delay
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.of(context).maybePop();
            }
          });
        }
      } else {
        throw Exception(res['error_msg'] ?? "Submission Failed");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _selectTime(BuildContext context, bool isFrom) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: themeGreen),
          ),
          child: child!,
        );
      },
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromTime = picked;
          _fromTimeController.text = picked.format12Hour();
        } else {
          toTime = picked;
          _toTimeController.text = picked.format12Hour();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: themeGreen,
        foregroundColor: Colors.white,
        title: Text(
          'Permission Request',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [


            _sectionTitle('Date'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _dateController,
              readOnly: true,
              enabled: false,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
              decoration: _inputDecoration(
                'Select Date',
                icon: Icons.calendar_today_outlined,
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Out Time'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _fromTimeController,
                        readOnly: true,
                        onTap: () => _selectTime(context, true),
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: _inputDecoration(
                          '',
                          icon: Icons.access_time,
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Return Time'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _toTimeController,
                        readOnly: true,
                        onTap: () => _selectTime(context, false),
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: _inputDecoration(
                          '',
                          icon: Icons.access_time,
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _sectionTitle('Reason'),
            const SizedBox(height: 8),
            TextFormField(
              maxLines: 4,
              decoration: _inputDecoration('Enter Reason For Permission'),
              style: GoogleFonts.poppins(fontSize: 14),
              onChanged: (val) => reason = val,
              validator: (val) => val!.isEmpty ? 'Required' : null,
            ),

            const SizedBox(height: 30),

            Center(
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _applyPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
                          'Submit Request',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1E293B),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintText: hint,
      prefixIcon: icon != null
          ? Icon(icon, color: themeGreen.withOpacity(0.7), size: 20)
          : null,
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: themeGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}
