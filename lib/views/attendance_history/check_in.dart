import 'dart:io';
import 'dart:async'; // Added
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import '../../services/face_detector_service.dart';
import '../../models/attendance_api.dart';

class CheckInVerificationScreen extends StatefulWidget {
  const CheckInVerificationScreen({super.key});

  @override
  State<CheckInVerificationScreen> createState() =>
      _CheckInVerificationScreenState();
}

class _CheckInVerificationScreenState extends State<CheckInVerificationScreen> {
  final TextEditingController inTimeController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  Timer? _timer;

  String? selectedMode; // Changed to nullable and null by default
  bool isLoading = false;
  int? uid;
  String? cid;
  String? deviceId;
  Position? currentPosition;

  File? _image;
  final ImagePicker _picker = ImagePicker();
  final FaceDetectorService _faceDetectorService = FaceDetectorService();

  String? selectedVehicleMode;
  File? _vehicleImage;

  List<dynamic> workTypes = [];
  List<dynamic> transportTypes = [];
  bool isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUid();
    _getDeviceId();
    _fetchLocationAndTime();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    final prefs = await SharedPreferences.getInstance();
    final dId = prefs.getString('device_id') ?? "123456";
    final lat = prefs.getDouble('lat')?.toString() ?? "0.0";
    final lng = prefs.getDouble('lng')?.toString() ?? "0.0";
    final companyId = prefs.getString('cid') ?? "21472147";

    try {
      final workRes = await AttendanceApi.fetchWorkTypes(
        cid: companyId,
        deviceId: dId,
        lat: lat,
        lng: lng,
      );
      final transportRes = await AttendanceApi.fetchTransportTypes(
        cid: companyId,
        deviceId: dId,
        lat: lat,
        lng: lng,
      );

      if (mounted) {
        setState(() {
          if (workRes["error"] == false) {
            workTypes = workRes["data"]["work_types"] ?? [];
          }
          if (transportRes["error"] == false) {
            transportTypes = transportRes["data"]["transport_types"] ?? [];
          }
          isInitialLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching dropdown data: $e");
      if (mounted) setState(() => isInitialLoading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    inTimeController.dispose();
    locationController.dispose();
    _faceDetectorService.dispose();
    super.dispose();
  }

  void _updateTime() {
    if (mounted) {
      final now = DateTime.now();
      setState(() {
        // Updated to 24h format with seconds as per response example
        inTimeController.text = DateFormat('HH:mm:ss').format(now);
      });
    }
  }

  Future<void> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor;
    }
    setState(() {});
  }

  Future<void> _fetchLocationAndTime() async {
    // 1. Set Current Time and Start Timer for Live Update
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });

    // 2. Fetch Location
    setState(() {
      locationController.text = "Fetching location...";
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => locationController.text = "Location services disabled");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => locationController.text = "Permission denied");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(
          () => locationController.text = "Permission permanently denied",
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      currentPosition = position;

      // Reverse geocoding to get address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address =
            "${place.locality ?? ''}, ${place.subAdministrativeArea ?? ''}"
                .trim();
        if (address.startsWith(',')) address = address.substring(1).trim();
        if (address.endsWith(',')) {
          address = address.substring(0, address.length - 1).trim();
        }

        setState(() {
          locationController.text = address.isEmpty
              ? "Location found"
              : address;
        });
      } else {
        setState(() => locationController.text = "Address not found");
      }
    } catch (e) {
      debugPrint("LOCATION ERROR => $e");
      setState(() => locationController.text = "Error getting location");
    }
  }

  Future<void> _loadUid() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      uid = prefs.getInt('uid') ?? 4;
      cid = prefs.getString('cid') ?? "";
    });
    debugPrint("AUTO LOADED UID: $uid, CID: $cid");
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Check in Verification',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.06,
            vertical: size.height * 0.03,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Check in Verification',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              _label('In Time'),
              _textField(
                controller: inTimeController,
                hint: 'Current Time',
                readOnly: true,
                prefixIcon: Icons.access_time_outlined,
              ),
              const SizedBox(height: 14),

              _label('Location'),
              _textField(
                controller: locationController,
                hint: '',
                prefixIcon: Icons.my_location,
              ),
              const SizedBox(height: 14),

              _label('Work Mode'),
              _dropdownField(),
              const SizedBox(height: 18),

              if (isInitialLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                if (selectedMode?.toLowerCase() == 'marketing') ...[
                  _label('Vehicle Mode'),
                  _vehicleDropdownField(),
                  const SizedBox(height: 18),

                  if (_isVehiclePhotoRequired()) ...[
                    _label('Vehicle Photo'),
                    _vehiclePhotoCard(size),
                    const SizedBox(height: 18),
                  ],
                ],
                _selfieCard(size),
              ],
              SizedBox(height: size.height * 0.05),

              Center(
                child: SizedBox(
                  width: size.width * 0.55,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2AA89A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Submit',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    String? errorMsg;
    if (uid == null) {
      errorMsg = 'User ID not found. Please log in again.';
    } else if (inTimeController.text.isEmpty) {
      errorMsg = 'Please select In Time';
    } else if (locationController.text.isEmpty ||
        locationController.text == "Fetching location...") {
      errorMsg = 'Please wait for location to be fetched';
    } else if (selectedMode == null) {
      errorMsg = 'Please select Work Mode';
    } else if (selectedMode?.toLowerCase() == 'marketing' &&
        selectedVehicleMode == null) {
      errorMsg = 'Please select Vehicle Mode';
    } else if (selectedMode?.toLowerCase() == 'marketing' &&
        _isVehiclePhotoRequired() &&
        _vehicleImage == null) {
      errorMsg = 'Please upload vehicle photo';
    } else if (_image == null) {
      errorMsg = 'Please take a selfie for verification';
    }

    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastCheckIn = prefs.getString('last_checkin_date');

    if (lastCheckIn == today) {
      errorMsg = 'You have already checked in for today.';
    }

    if (errorMsg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("https://erpsmart.in/total/api/m_api/"),
      );

      String transportId = "";
      if (selectedVehicleMode != null) {
        final transport = transportTypes.firstWhere(
          (e) => e["name"] == selectedVehicleMode,
          orElse: () => null,
        );
        if (transport != null) {
          transportId = transport["id"].toString();
        }
      }

      request.fields.addAll({
        "type": "2046",
        "cid": cid ?? "",
        "uid": uid.toString(),
        "in_time": inTimeController.text,
        "loc": locationController.text,
        "wrk_mde": selectedMode?.toLowerCase() ?? "",
        "device_id": deviceId ?? "123456",
        "lt": currentPosition?.latitude.toString() ?? "0.0",
        "ln": currentPosition?.longitude.toString() ?? "0.0",
        "transport_id": transportId,
      });

      if (_vehicleImage != null) {
        final String vExt = _vehicleImage!.path.split('.').last.toLowerCase();
        request.files.add(
          await http.MultipartFile.fromPath(
            'photo', // Updated key to match user's example
            _vehicleImage!.path,
            contentType: MediaType('image', vExt == 'jpg' ? 'jpeg' : vExt),
          ),
        );
      }

      final String extension = _image!.path.split('.').last.toLowerCase();
      request.files.add(
        await http.MultipartFile.fromPath(
          'selfie',
          _image!.path,
          contentType: MediaType(
            'image',
            extension == 'jpg' ? 'jpeg' : extension,
          ),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(response.body);

      debugPrint("CHECK-IN RESPONSE => ${response.body}");

      final bool isSuccess =
          responseData["error"] == false ||
          responseData["error"] == "false" ||
          responseData["message"].toString().toLowerCase().contains(
            "success",
          ) ||
          responseData["message"].toString().toLowerCase().contains(
            "successfully",
          ) ||
          responseData["message"].toString().toLowerCase().contains(
            "already checked in",
          );

      if (isSuccess) {
        // Persist check-in status and save new token if provided
        final prefs = await SharedPreferences.getInstance();
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        await prefs.setBool('isCheckedIn', true);
        await prefs.setString('last_checkin_date', today);

        // Save token if it exists in the response
        final String? newToken =
            responseData["token"] ?? responseData["data"]?["token"];
        if (newToken != null && newToken.isNotEmpty) {
          await prefs.setString('token', newToken);
          debugPrint("Check-in: New Session Token Saved => $newToken");
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                responseData["message"] ?? 'Checked in successfully',
              ),
              backgroundColor: const Color(0xFF2AA89A),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData["message"] ?? 'Check-in failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("CHECK-IN ERROR => $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  bool _isVehiclePhotoRequired() {
    if (selectedVehicleMode == null) return false;
    final transport = transportTypes.firstWhere(
      (e) => e["name"] == selectedVehicleMode,
      orElse: () => null,
    );
    return transport?["photo_required"] ?? false;
  }

  Future<void> _takeSelfie() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 50,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (photo != null) {
      final String extension = photo.path.split('.').last.toLowerCase();
      if (extension == 'jpeg' || extension == 'jpg' || extension == 'png') {
        // Face detection logic
        setState(() => isLoading = true);

        try {
          final File imageFile = File(photo.path);
          final FaceDetectionResult result = await _faceDetectorService
              .detectFace(imageFile);

          if (!result.isValid) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result.error ?? 'Face detection failed.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          // Generate and Save Face Profile for Checkout Identification
          final profile = _faceDetectorService.getFaceProfile(result.face!);
          if (profile.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('checkin_face_profile', jsonEncode(profile));
          }

          setState(() {
            _image = imageFile;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Full single face recognized successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          debugPrint("FACE DETECTION ERROR => $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error analyzing face. Please try again.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => isLoading = false);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Only JPEG and PNG images are allowed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),
  );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    bool readOnly = false,
    VoidCallback? onTap,
    IconData? prefixIcon,
  }) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: const Color(0xFF26A69A), size: 20)
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF2AA89A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF2AA89A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF26A69A), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _dropdownField() {
    return SizedBox(
      height: 48,
      child: DropdownButtonFormField<String>(
        value: selectedMode,
        hint: const Text('Work Mode'),
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF26A69A)),
        style: const TextStyle(fontSize: 14, color: Colors.black),
        items: workTypes.map((type) {
          return DropdownMenuItem<String>(
            value: type["name"],
            child: Text(type["name"]),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedMode = value;
            if (selectedMode?.toLowerCase() != 'marketing') {
              selectedVehicleMode = null;
              _vehicleImage = null;
            }
          });
        },
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFD7FFFA),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF2AA89A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF2AA89A)),
          ),
        ),
      ),
    );
  }

  Widget _selfieCard(Size size) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selfie Verification',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Center(
            child: DottedBorder(
              color: Colors.grey,
              dashPattern: const [6, 4],
              borderType: BorderType.RRect,
              radius: const Radius.circular(8),
              child: SizedBox(
                height: size.height * 0.18,
                width: 300,
                child: _image != null
                    ? Image.file(_image!, fit: BoxFit.cover)
                    : const Icon(
                        Icons.camera_alt_outlined,
                        size: 34,
                        color: Color(0xFF2AA89A),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: ElevatedButton.icon(
              onPressed: _takeSelfie,
              icon: const Icon(Icons.camera_alt, size: 16),
              label: Text(_image == null ? 'Take Selfie' : 'Retake Selfie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2AA89A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vehicleDropdownField() {
    return SizedBox(
      height: 48,
      child: DropdownButtonFormField<String>(
        value: selectedVehicleMode,
        hint: const Text('Vehicle Mode'),
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF26A69A)),
        style: const TextStyle(fontSize: 14, color: Colors.black),
        items: transportTypes.map((type) {
          return DropdownMenuItem<String>(
            value: type["name"],
            child: Text(type["name"]),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedVehicleMode = value;
            _vehicleImage = null; // Reset image if mode changes
          });
        },
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF2AA89A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF2AA89A)),
          ),
        ),
      ),
    );
  }

  Widget _vehiclePhotoCard(Size size) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload $selectedVehicleMode Photo',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Center(
            child: DottedBorder(
              color: Colors.grey,
              dashPattern: const [6, 4],
              borderType: BorderType.RRect,
              radius: const Radius.circular(8),
              child: SizedBox(
                height: size.height * 0.18,
                width: 300,
                child: _vehicleImage != null
                    ? Image.file(_vehicleImage!, fit: BoxFit.cover)
                    : const Icon(
                        Icons.image_outlined,
                        size: 34,
                        color: Color(0xFF2AA89A),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: ElevatedButton.icon(
              onPressed: _takeVehiclePhoto,
              icon: const Icon(Icons.camera_alt, size: 16),
              label: Text(
                _vehicleImage == null ? 'Take Only Photo' : 'Retake Photo',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2AA89A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _takeVehiclePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (photo != null) {
      setState(() {
        _vehicleImage = File(photo.path);
      });
    }
  }
}
