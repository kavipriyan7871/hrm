import 'dart:io';
import 'dart:async';
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

class CheckOutVerificationScreen extends StatefulWidget {
  const CheckOutVerificationScreen({super.key});

  @override
  State<CheckOutVerificationScreen> createState() =>
      _CheckOutVerificationScreenState();
}

class _CheckOutVerificationScreenState
    extends State<CheckOutVerificationScreen> {
  final TextEditingController outTimeController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  Timer? _timer;

  String selectedMode = 'Mode of work';
  bool isLoading = false;
  int? uid;
  String? cid;
  String? deviceId;
  Position? currentPosition;

  File? _image;
  final ImagePicker _picker = ImagePicker();
  final FaceDetectorService _faceDetectorService = FaceDetectorService();

  @override
  void initState() {
    super.initState();
    _loadUid();
    _getDeviceId();
    _fetchLocationAndTime();
  }

  @override
  void dispose() {
    _timer?.cancel();
    outTimeController.dispose();
    locationController.dispose();
    _faceDetectorService.dispose();
    super.dispose();
  }

  void _updateTime() {
    if (mounted) {
      final now = DateTime.now();
      setState(() {
        outTimeController.text = DateFormat('hh:mm:ss a').format(now);
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
    // 1. Set Current Time and Start Timer
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
        desiredAccuracy: LocationAccuracy.high,
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
        if (address.endsWith(','))
          address = address.substring(0, address.length - 1).trim();

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
      cid = prefs.getString('cid') ?? "21472147";
    });
    debugPrint("LOADED UID: $uid, CID: $cid");
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
          'Check out Verification',
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
                'Check out Verification',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              /// Out Time
              _label('Out Time'),
              _textField(
                controller: outTimeController,
                hint: 'Current Time',
                readOnly: true,
                prefixIcon: Icons.access_time_outlined,
              ),
              const SizedBox(height: 14),

              /// Location
              _label('Location'),
              _textField(
                controller: locationController,
                hint: '',
                prefixIcon: Icons.my_location,
              ),
              const SizedBox(height: 14),

              /// Work Mode
              _label('Work Mode'),
              _dropdownField(),
              const SizedBox(height: 18),

              /// Selfie
              _selfieCard(size),
              SizedBox(height: size.height * 0.1),

              /// Submit Button
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

  /// ---------- UI Helpers ----------

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

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
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF2AA89A)),
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
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF26A69A)),
        style: const TextStyle(fontSize: 14, color: Colors.black),
        items: const [
          DropdownMenuItem(value: 'Mode of work', child: Text('Mode of work')),
          DropdownMenuItem(value: 'Office', child: Text('Office')),
          DropdownMenuItem(
            value: 'Work From Home',
            child: Text('Work From Home'),
          ),
        ],
        onChanged: (value) {
          setState(() {
            selectedMode = value!;
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selfie Verification',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Center(
            child: DottedBorder(
              color: Colors.grey.shade400,
              strokeWidth: 1.5,
              dashPattern: const [6, 4],
              borderType: BorderType.RRect,
              radius: const Radius.circular(8),
              child: Container(
                height: size.height * 0.18,
                width: 300,
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _image!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.camera_alt_outlined,
                          size: 34,
                          color: Color(0xFF2AA89A),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: SizedBox(
              height: 38,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2AA89A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: _takeSelfie,
                icon: const Icon(Icons.camera_alt, size: 16),
                label: Text(
                  _image == null ? 'Take Selfie' : 'Retake Selfie',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ---------- Actions ----------

  Future<void> _takeSelfie() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 50,
    );

    if (photo != null) {
      final String extension = photo.path.split('.').last.toLowerCase();
      if (extension == 'jpeg' || extension == 'jpg' || extension == 'png') {
        // Start Analysis
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

          // Verify Identification matches Check-in
          final prefs = await SharedPreferences.getInstance();
          final String? savedProfileStr = prefs.getString(
            'checkin_face_profile',
          );
          if (savedProfileStr != null) {
            final List<double> currentProfile = _faceDetectorService
                .getFaceProfile(result.face!);
            final List<dynamic> savedProfileRaw = jsonDecode(savedProfileStr);
            final List<double> savedProfile = savedProfileRaw
                .map((e) => (e as num).toDouble())
                .toList();

            final bool isMatch = _faceDetectorService.isSamePersona(
              currentProfile,
              savedProfile,
            );

            if (!isMatch) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Face identification failed: This does not match the check-in person.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }
          }

          setState(() {
            _image = imageFile;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Full single face identified successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          debugPrint("CHECK-OUT FACE DETECTION ERROR => $e");
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

  void _submit() async {
    String? errorMsg;
    if (uid == null) {
      errorMsg = 'User ID not found. Please log in again.';
    } else if (outTimeController.text.isEmpty) {
      errorMsg = 'Please select Out Time';
    } else if (locationController.text.isEmpty ||
        locationController.text == "Fetching location...") {
      errorMsg = 'Please wait for location to be fetched';
    } else if (selectedMode == 'Mode of work') {
      errorMsg = 'Please select Work Mode';
    } else if (_image == null) {
      errorMsg = 'Please take a selfie for verification';
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

      request.fields.addAll({
        "type": "2047",
        "cid": cid ?? "21472147",
        "uid": uid.toString(),
        "out_time": outTimeController.text,
        "loc": locationController.text,
        "wrk_mde": selectedMode,
        "device_id": deviceId ?? "unknown",
        "lt": currentPosition?.latitude.toString() ?? "0.0",
        "ln": currentPosition?.longitude.toString() ?? "0.0",
      });

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

      debugPrint("CHECK-OUT RESPONSE => ${response.body}");

      final bool isSuccess =
          responseData["error"] == false ||
          responseData["error"] == "false" ||
          responseData["message"].toString().toLowerCase().contains(
            "success",
          ) ||
          responseData["message"].toString().toLowerCase().contains(
            "successfully",
          );

      if (isSuccess) {
        // Clear check-in status
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isCheckedIn', false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                responseData["message"] ?? 'Checked out successfully',
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
              content: Text(responseData["message"] ?? 'Check-out failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("CHECK-OUT ERROR => $e");
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
}
