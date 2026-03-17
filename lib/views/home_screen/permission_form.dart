import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'leave_management.dart';

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

  // Controllers for displaying text in read-only fields
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _fromTimeController = TextEditingController();
  final TextEditingController _toTimeController = TextEditingController();

  String? employeeName;
  String? employeeId;
  String? uid;
  bool isLoading = false;

  String? selectedPermissionCode;
  DateTime? selectedDate;
  TimeOfDay? fromTime;
  TimeOfDay? toTime;
  String? reason;

  List<dynamic> permissionTypesData = [];

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
    setState(() {
      employeeName = prefs.getString('name');
      uid = prefs.getInt('uid')?.toString();
      employeeId = uid;
    });
    _fetchPermissionTypes();
  }

  Future<void> _fetchPermissionTypes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final response = await http.post(
        Uri.parse("https://erpsmart.in/total/api/m_api/"),
        body: {
          "type": "2066",
          "cid": prefs.getString('cid') ?? "",
          "device_id": prefs.getString('device_id') ?? "123456",
          "lt": "145",
          "ln": "145",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['error'] == false) {
          setState(() {
            permissionTypesData = data['data']['permission_types'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching permission types: $e");
    }
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

    try {
      final prefs = await SharedPreferences.getInstance();
      final String uidParam =
          prefs.getInt('uid')?.toString() ?? "10"; // Default or fallback
      final String cid = prefs.getString('cid') ?? "";

      // 1. Get Device ID
      String deviceId = "unknown";
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? "unknown";
      }

      // 2. Get Location (Lat/Lng only, No Address/Loc as per new request)
      String lat = "0.0";
      String lng = "0.0";

      try {
        Position? pos = await _determinePosition();
        if (pos != null) {
          lat = pos.latitude.toString();
          lng = pos.longitude.toString();
        }
      } catch (e) {
        debugPrint("Location error: $e");
      }

      // 3. API Call
      final url = Uri.parse("https://erpsmart.in/total/api/m_api/");

      // Format Time to HH:mm (24h)
      String fromTimeStr =
          "${fromTime!.hour.toString().padLeft(2, '0')}:${fromTime!.minute.toString().padLeft(2, '0')}";
      String toTimeStr =
          "${toTime!.hour.toString().padLeft(2, '0')}:${toTime!.minute.toString().padLeft(2, '0')}";

      final body = {
        "type": "2067",
        "cid": cid,
        "uid": uidParam,
        "permission_type": selectedPermissionCode ?? "",
        "app_date":
            "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}",
        "start_time": fromTimeStr,
        "end_time": toTimeStr,
        "reason": reason ?? "",
        "device_id": deviceId,
        "lt": lat,
        "ln": lng,
        "token": "", // From user example
      };

      debugPrint("Permission API Request Body: $body");

      final response = await http.post(url, body: body);

      debugPrint("Permission API Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Check "error": false
        if (data['error'] == false) {
          String msg =
              data['error_msg'] ?? "Permission request submitted successfully";
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: Colors.green),
            );

            // Redirect to Leave Management Screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LeaveManagementScreen(),
              ),
            );
          }
        } else {
          throw Exception(
            data['error_msg'] ?? data['message'] ?? "Submission Failed",
          );
        }
      } else {
        throw Exception("Server Error: ${response.statusCode}");
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

  Future<Position?> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null;
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
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request Permission',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xff1A237E),
            ),
          ),
          const SizedBox(height: 20),

          // Permission Type
          _sectionTitle('Permission type'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedPermissionCode,
            decoration: _inputDecoration('Select Permission Type'),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
            items: permissionTypesData.map((type) {
              return DropdownMenuItem(
                value: type['code'].toString(),
                child: Text(
                  type['permission_type_name'].toString(),
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (val) => setState(() => selectedPermissionCode = val),
            validator: (val) => val == null ? 'Required' : null,
          ),

          const SizedBox(height: 16),

          // Date
          _sectionTitle('Date'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _dateController,
            readOnly: true,
            enabled: false, // Fully disable manual editing
            onTap:
                null, // Disable date picker popup as per request "date edit panna mutiyadhu"
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

          // Time Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('From Time'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _fromTimeController,
                      readOnly: true,
                      onTap: () => _selectTime(context, true),
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: _inputDecoration('', icon: Icons.access_time),
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
                    _sectionTitle('To Time'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _toTimeController,
                      readOnly: true,
                      onTap: () => _selectTime(context, false),
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: _inputDecoration('', icon: Icons.access_time),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Reason
          _sectionTitle('Reason'),
          const SizedBox(height: 8),
          TextFormField(
            maxLines:
                4, // Changed to 1 line to match LeaveForm or kept 3? Keep 3 but styled
            decoration: _inputDecoration('Enter Reason For Permission'),
            style: GoogleFonts.poppins(fontSize: 14),
            onChanged: (val) => reason = val,
            validator: (val) => val!.isEmpty ? 'Required' : null,
          ),

          const SizedBox(height: 60),

          // Submit Button
          Center(
            child: SizedBox(
              width: 325,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : _applyPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff26A69A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
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
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintText: hint,
      prefixIcon: icon != null
          ? Icon(icon, color: const Color(0xff534F8C), size: 20)
          : null,
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xff534F8C)),
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
}
