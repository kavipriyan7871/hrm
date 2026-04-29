import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';

import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../models/marketing_api.dart';
import '../../models/employee_api.dart'; // Import EmployeeApi
import 'package:device_info_plus/device_info_plus.dart';

class CheckoutScreen extends StatefulWidget {
  final String? checkinId;
  const CheckoutScreen({super.key, this.checkinId});

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
  String? employeeTableId;
  String? employeeCode;
  String? employeeName;
  String? employeeProfilePhoto;
  String? deviceId; // Standardized device ID
  Position? currentPos; // For lat/lng

  @override
  void initState() {
    super.initState();
    _getDeviceId();
    _fetchLocation();
    _loadEmployeeDetails(); // Fetch employee details on init
    final now = DateTime.now();
    _dateController.text =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
  }

  Future<void> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor;
      }
      if (deviceId != null) {
        await prefs.setString('device_id', deviceId!);
      }
    } catch (e) {
      deviceId = prefs.getString('device_id') ?? "Unknown";
    }
  }

  Future<void> _loadEmployeeDetails() async {
    final prefs = await SharedPreferences.getInstance();

    // Use login_cus_id for consistent authentication (from login cus_id: 44)
    final String sessionUid = prefs.getString('login_cus_id') ?? 
                             prefs.getString('uid') ?? 
                             prefs.getString('employee_table_id') ??
                             "54";
                             
    setState(() {
      employeeTableId = sessionUid;
    });

    String currentCid = prefs.getString('cid') ?? '';
    String currentDeviceId = prefs.getString('device_id') ?? '';

    try {
      final res = await EmployeeApi.getEmployeeDetails(
        uid: sessionUid,
        cid: currentCid,
        deviceId: currentDeviceId,
        lat: prefs.getDouble('lat')?.toString() ?? "0.0",
        lng: prefs.getDouble('lng')?.toString() ?? "0.0",
      );

      if (res["error"] == false) {
        final data = res["data"] ?? res;
        setState(() {
          employeeName = data["name"]?.toString();
          employeeCode = data["employee_code"]?.toString();
          employeeProfilePhoto = data["photo"]?.toString() ?? data["profile_image"]?.toString();
        });
        debugPrint("Checkout Screen => Profile info updated for session UID: $sessionUid");
      }
    } catch (e) {
      debugPrint("Employee fetch error => $e");
    } finally {
      if (mounted) setState(() {});
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
      currentPos = position;
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = [
          place.name,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country
        ].where((e) => e != null && e.isNotEmpty).join(", ");

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
    final ImagePicker picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1024,
                    maxHeight: 1024,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    _cropImage(image.path);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1024,
                    maxHeight: 1024,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    _cropImage(image.path);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cropImage(String path) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Attachment',
          toolbarColor: const Color(0xFF26A69A),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop Attachment',
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() => _attachments = File(croppedFile.path));
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
      
      // Standardized parameter resolution
      final String lat = currentPos?.latitude.toString() ?? prefs.getString('lt') ?? prefs.getString('latitude') ?? "145";
      final String lng = currentPos?.longitude.toString() ?? prefs.getString('ln') ?? prefs.getString('longitude') ?? "145";
      final String cid = prefs.getString('cid') ?? prefs.getString('cid_str') ?? "21472147";
      final String dId = prefs.getString('device_id') ?? "123456";
      final String token = prefs.getString('token') ?? "";

      // Standardized UID resolution - Prioritize login_cus_id (44)
      final String employeeId =
          prefs.getString('uid') ??
          prefs.getString('login_cus_id') ??
          prefs.getString('employee_table_id') ??
          "54";

      if (employeeId == "0" || employeeId.isEmpty) {
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

      // Convert Date format dd/mm/yyyy -> yyyy-mm-dd
      final dateParts = _dateController.text.split('/');
      final formattedDate =
          "${dateParts[2]}-${dateParts[1].padLeft(2, '0')}-${dateParts[0].padLeft(2, '0')}";

      final purposeId = _purposeMap[_selectedPurpose] ?? "4";

      if (token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Session expired. Please re-login.")),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final data = await MarketingApi.checkOut(
        uid: employeeId,
        cid: cid,
        deviceId: dId,
        lat: lat,
        lng: lng,
        type: '2053',
        clientName: _clientNameController.text,
        date: formattedDate,
        remarks: _remarksController.text,
        purposeOfVisitId: purposeId,
        location: _locationController.text,
        checkinId: widget.checkinId,
        token: token,
        attachment: _attachments,
      );

      debugPrint("Checkout Response JSON: $data");

      if (data['error'] == false) {
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
              data['error_msg']?.toString() ??
              data['message']?.toString() ??
              "Submission failed (Unknown Error)";

          // Check if error is specifically about missing check-in
          if (errorMsg.toLowerCase().contains("no open check-in") ||
              errorMsg.toLowerCase().contains("check-in first")) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
            );
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      debugPrint("Checkout Error: $e");
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
                          ? Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _attachments!,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => _attachments = null);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
            color: const Color(0xFF1B2C61), // Navy blue from image
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF1B2C61).withValues(alpha: 0.5),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1B2C61)),
              hint: Text(
                hint,
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade500,
                  fontSize: isTablet ? 14 : 13,
                ),
              ),
              items: items
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        e,
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 14 : 13,
                          color: const Color(0xFF1B2C61),
                        ),
                      ),
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
