import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:hrm/views/widgets/profile_card.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../models/employee_api.dart'; // Import EmployeeApi

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  String? _selectedPurpose;
  File? _attachments;
  bool _isLoading = false;

  bool _isLocationLoading = false;
  String? employeeTableId; // To store the correct employee ID
  String? employeeCode;
  String? employeeName;
  String? employeeProfilePhoto;
  bool _isEmpLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _loadEmployeeDetails(); // Fetch employee details on init
    final now = DateTime.now();
    _dateController.text =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
  }

  // Fetch Employee Details similar to Leave Application
  Future<void> _loadEmployeeDetails() async {
    setState(() => _isEmpLoading = true);
    final prefs = await SharedPreferences.getInstance();

    // First try to get from prefs if already saved
    String? storedId = prefs.getString('employee_table_id');
    if (storedId != null && storedId.isNotEmpty) {
      setState(() {
        employeeTableId = storedId;
        _isEmpLoading = false;
      });
      return;
    }

    // If not found, fetch from API
    final loginUid = (prefs.getInt('uid') ?? 0).toString();

    // If we have a loginUid, trust it as the employee_table_id immediately
    if (loginUid != "0") {
      await prefs.setString('employee_table_id', loginUid);
      setState(() {
        employeeTableId = loginUid;
        _isEmpLoading = false;
      });
      // Continue to fetch details to update name/photo etc, but don't overwrite ID
    }

    try {
      final res = await EmployeeApi.getEmployeeDetails(
        uid: loginUid,
        cid: "21472147",
        deviceId: "123456",
        lat: prefs.getDouble('lat')?.toString() ?? "123",
        lng: prefs.getDouble('lng')?.toString() ?? "123",
      );

      if (res["error"] == false) {
        // Handle flat structure or nested "data"
        final data = res["data"] ?? res;

        // Only update auxiliary details
        setState(() {
          employeeName = data["name"]?.toString();
          employeeCode = data["employee_code"]?.toString();
          employeeProfilePhoto =
              data["photo"]?.toString() ?? data["profile_image"]?.toString();
        });

        if (employeeName != null) await prefs.setString('name', employeeName!);
        if (employeeCode != null)
          await prefs.setString('employee_code', employeeCode!);
        if (employeeProfilePhoto != null)
          await prefs.setString('profile_photo', employeeProfilePhoto!);
      }
    } catch (e) {
      debugPrint("Employee fetch error => $e");
    } finally {
      if (mounted) setState(() => _isEmpLoading = false);
    }
  }

  Future<void> _fetchLocation() async {
    setState(() => _isLocationLoading = true);
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint(
          'Location permissions are permanently denied, we cannot request permissions.',
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address =
            "${place.locality}, ${place.administrativeArea}, ${place.country}";
        // Or more detailed: ${place.street}, ${place.subLocality},
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          address = "${place.subLocality}, $address";
        }

        setState(() {
          _locationController.text = address;
        });
      }
    } catch (e) {
      debugPrint("Error fetching location: $e");
    } finally {
      if (mounted) setState(() => _isLocationLoading = false);
    }
  }

  final Map<String, String> _purposeMap = {
    'New Lead': '1',
    'Close': '2',
    'New Business Pitch': '3',
    'Meeting': '4',
  };

  Future<void> _pickAttachment() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _attachments = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_dateController.text.isEmpty ||
        _clientNameController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _selectedPurpose == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('lat')?.toString() ?? "145";
      final lng = prefs.getDouble('lng')?.toString() ?? "145";

      // Ensure we have the employee ID
      if (employeeTableId == null) {
        await _loadEmployeeDetails();
        if (employeeTableId == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Could not retrieve Employee details. Please try again.",
                ),
              ),
            );
            setState(() => _isLoading = false);
          }
          return;
        }
      }

      // Convert Date format dd/mm/yyyy -> yyyy-mm-dd
      final dateParts = _dateController.text.split('/');
      final formattedDate =
          "${dateParts[2]}-${dateParts[1].padLeft(2, '0')}-${dateParts[0].padLeft(2, '0')}";

      final purposeId = _purposeMap[_selectedPurpose] ?? "4";

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("https://erpsmart.in/total/api/m_api/"),
      );

      // Use a timestamp if date is not selected, though validation prevents that.
      // But ensure format is strictly YYYY-MM-DD
      String dateToSend = formattedDate;
      if (formattedDate.isEmpty) {
        dateToSend = DateTime.now().toString().split(' ')[0];
      }

      request.fields.addAll({
        'cid': '21472147',
        'device_id': '123456',
        'uid': employeeTableId!, // Use employeeTableId here
        'ln': lng,
        'lt': lat,
        'type': '2053',
        'client_name': _clientNameController.text,
        'date': dateToSend,
        'remarks': _remarksController.text,
        'purpose_of_visit_id': purposeId,
        'location': _locationController.text,
      });

      if (_attachments != null) {
        request.files.add(
          await http.MultipartFile.fromPath('attachments', _attachments!.path),
        );
      }

      print("Checkout Request Fields: ${request.fields}");
      if (_attachments != null) print("Attachment: ${_attachments!.path}");

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("Checkout Response: ${response.body}");

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['error'] == false) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Checkout submitted successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          String errorMsg =
              data['error_msg'] ??
              data['message'] ??
              "Submission failed (Unknown Error)";

          // Check if error is specifically about missing check-in
          if (errorMsg.toLowerCase().contains("no open check-in") ||
              errorMsg.toLowerCase().contains("check-in first")) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(
                  "Check-In Issue",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                content: Text(
                  "The system cannot find your open check-in. This might be because your employee ID was updated. \n\nPlease check in again.",
                  style: GoogleFonts.poppins(),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context, "RESET"); // Return RESET to parent
                    },
                    child: Text(
                      "OK",
                      style: GoogleFonts.poppins(
                        color: const Color(0xff26A69A),
                      ),
                    ),
                  ),
                ],
              ),
            );
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      print("Checkout Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width > 600;
    final horizontalPadding = isTablet ? 24.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Marketing",
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 22 : 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            if (employeeName != null && employeeCode != null)
              ProfileInfoCard(
                name: employeeName!,
                employeeId: employeeCode!,
                designation:
                    "", // Designation not in API response shown in logs
                profileImagePath: employeeProfilePhoto ?? "assets/profile.png",
              ),

            SizedBox(height: isTablet ? 30 : 20),
            _buildLabeledField(
              context: context,
              label: "Date",
              hint: "Date",
              controller: _dateController,
              isTablet: isTablet,
              prefixIcon: Icons.calendar_today_outlined,
              isDateField: false,
              readOnly: true,
            ),

            SizedBox(height: isTablet ? 20 : 16),

            _buildLabeledField(
              context: context,
              label: "Client Name",
              hint: "Client Name",
              controller: _clientNameController,
              isTablet: isTablet,
              prefixIcon: Icons.person_outline,
            ),

            SizedBox(height: isTablet ? 20 : 16),

            _buildLabeledField(
              context: context,
              label: "Location",
              hint: _isLocationLoading ? "Fetching location..." : "Location",
              controller: _locationController,
              isTablet: isTablet,
              prefixIcon: Icons.my_location,
              suffixFunctions: IconButton(
                icon: _isLocationLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, color: Color(0xFF26A69A)),
                onPressed: _fetchLocation,
              ),
            ),

            SizedBox(height: isTablet ? 20 : 16),

            _buildDropdownField(
              context: context,
              label: "Purpose Of Visit",
              hint: "Select Purpose of Visit",
              value: _selectedPurpose,
              isTablet: isTablet,
              items: const [
                'New Lead',
                'Close',
                'New Business Pitch',
                'Meeting',
              ],
              onChanged: (value) {
                setState(() => _selectedPurpose = value);
              },
            ),

            SizedBox(height: isTablet ? 20 : 16),

            _buildLabeledField(
              context: context,
              label: "Remarks",
              hint: "Remarks",
              controller: _remarksController,
              isTablet: isTablet,
              maxLines: 4,
            ),

            SizedBox(height: isTablet ? 20 : 16),

            Text(
              "Attachments",
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            Column(
              children: [
                GestureDetector(
                  onTap: _pickAttachment,
                  child: DottedBorder(
                    color: Colors.grey.shade400,
                    strokeWidth: 1.5,
                    dashPattern: const [6, 4],
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(8),
                    child: Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _attachments != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _attachments!,
                                fit: BoxFit.fill,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  size: 40,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Tap to Add Attachment",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: isTablet ? 40 : 30),

            SizedBox(
              width: 350,
              height: 55,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF26A69A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  elevation: 3,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Submit",
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabeledField({
    required BuildContext context,
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool isTablet,
    IconData? prefixIcon,
    bool isDateField = false,
    bool readOnly = false,
    int maxLines = 1,
    Widget? suffixFunctions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          readOnly: isDateField || readOnly,
          onTap: isDateField ? () => _selectDate(context) : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey.shade500,
              fontSize: isTablet ? 14 : 13,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: const Color(0xFF26A69A),
                    size: isTablet ? 22 : 20,
                  )
                : null,
            suffixIcon: suffixFunctions,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isTablet ? 16 : 14,
            ),
          ),
          style: GoogleFonts.poppins(fontSize: isTablet ? 14 : 13),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required BuildContext context,
    required String label,
    required String hint,
    required String? value,
    required bool isTablet,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(
                hint,
                style: GoogleFonts.poppins(color: Colors.grey.shade500),
              ),
              items: items
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e, style: GoogleFonts.poppins()),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF26A69A)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _clientNameController.dispose();
    _locationController.dispose();
    _remarksController.dispose();
    super.dispose();
  }
}
