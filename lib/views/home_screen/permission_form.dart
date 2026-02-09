import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String? employeeName;
  String? employeeId;
  String? uid;
  bool isLoading = false;

  String? permissionType;
  DateTime? selectedDate;
  TimeOfDay? fromTime;
  TimeOfDay? toTime;
  String? reason;

  final List<String> permissionTypes = [
    'Select Permission Type',
    'Medical Appointment',
    'Personal Work',
    'Family Emergency',
    'Official Work',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      employeeName = prefs.getString('name');
      uid = prefs.getInt('uid')?.toString();
      employeeId = uid;
    });
  }

  Future<void> _applyPermission() async {
    if (!_formKey.currentState!.validate() ||
        selectedDate == null ||
        fromTime == null ||
        toTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Permission request submitted successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      _formKey.currentState!.reset();
      setState(() {
        selectedDate = null;
        fromTime = null;
        toTime = null;
        permissionType = null;
        reason = null;
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xff26A69A)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context, bool isFrom) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xff26A69A)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromTime = picked;
        } else {
          toTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Request Permission',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xff1A237E), // Dark blue text
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Permission Type
          _sectionTitle('Permission type'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: permissionType,
            decoration: _inputDecoration('Select Permission Type'),
            icon: const Icon(Icons.arrow_drop_down),
            items: permissionTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type, style: GoogleFonts.poppins(fontSize: 14)),
              );
            }).toList(),
            onChanged: (val) => setState(() => permissionType = val),
            validator: (val) => val == null || val == 'Select Permission Type'
                ? 'Required'
                : null,
          ),

          const SizedBox(height: 20),

          // Date
          _sectionTitle('Date'),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _selectDate(context),
            child: IgnorePointer(
              child: TextFormField(
                key: ValueKey(selectedDate),
                decoration: _inputDecoration(
                  '',
                  icon: Icons.calendar_today_outlined,
                ),
                controller: TextEditingController(
                  text: selectedDate == null
                      ? ''
                      : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                ),
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Time Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('From Time'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectTime(context, true),
                      child: IgnorePointer(
                        child: TextFormField(
                          key: ValueKey(fromTime),
                          decoration: _inputDecoration(
                            '',
                            icon: Icons.access_time,
                          ),
                          controller: TextEditingController(
                            text: fromTime?.format12Hour() ?? '',
                          ),
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('To Time'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectTime(context, false),
                      child: IgnorePointer(
                        child: TextFormField(
                          key: ValueKey(toTime),
                          decoration: _inputDecoration(
                            '',
                            icon: Icons.access_time,
                          ),
                          controller: TextEditingController(
                            text: toTime?.format12Hour() ?? '',
                          ),
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Reason
          _sectionTitle('Reason'),
          const SizedBox(height: 8),
          TextFormField(
            maxLines: 3,
            decoration: _inputDecoration('Enter Reason For Permission'),
            style: GoogleFonts.poppins(fontSize: 14),
            onChanged: (val) => reason = val,
            validator: (val) => val!.isEmpty ? 'Required' : null,
          ),

          const SizedBox(height: 40),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading ? null : _applyPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff26A69A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Submit',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null
          ? Icon(icon, color: const Color(0xff1A237E), size: 20)
          : null,
      hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide
            .none, // Light grey border as per image check? No slightly grey
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xff26A69A), width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
