import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; 
import 'marketing_checkout.dart';
import '../../models/marketing_api.dart';

class MarketingScreen extends StatefulWidget {
  const MarketingScreen({super.key});

  @override
  State<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends State<MarketingScreen> {
  bool isCheckedIn = false;
  bool isCheckedOut = false;
  String checkInTime = "00.00.00";
  String checkOutTime = "00.00.00";
  bool isLoading = false;
  List<dynamic> historyRecords = [];

  String? employeeName;
  String? employeeCode;
  String? profilePhoto;
  String? deviceId;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String lastDate = prefs.getString('marketing_last_action_date_local') ?? "";

    if (lastDate != today && lastDate.isNotEmpty) {
      await prefs.remove('is_marketing_checked_in_local');
      await prefs.remove('marketing_check_in_time_local');
      await prefs.remove('has_done_marketing_today');
      await prefs.remove('is_marketing_checked_out_local');
      await prefs.remove('marketing_check_out_time_local');
      await prefs.remove('current_marketing_id');
    }

    setState(() {
      isCheckedIn = prefs.getBool('is_marketing_checked_in_local') ?? false;
      checkInTime = prefs.getString('marketing_check_in_time_local') ?? "00.00.00";
      isCheckedOut = prefs.getBool('is_marketing_checked_out_local') ?? false;
      checkOutTime = prefs.getString('marketing_check_out_time_local') ?? "00.00.00";
      employeeName = prefs.getString('name');
      employeeCode = prefs.getString('employee_code');
      profilePhoto = prefs.getString('profile_photo');
    });
    _getDeviceId();
    _fetchServerStatus();
  }

  Future<void> _fetchServerStatus() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final String cid = prefs.getString('cid') ?? "";
      final String uid = prefs.getString('uid') ?? prefs.getString('login_cus_id') ?? "";
      final String token = prefs.getString('token') ?? "";
      final String lat = prefs.getDouble('lat')?.toString() ?? "0.0";
      final String lng = prefs.getDouble('lng')?.toString() ?? "0.0";
      final String dId = deviceId ?? prefs.getString('device_id') ?? "";

      final response = await http.post(
        Uri.parse("https://erpsmart.in/total/api/m_api/"),
        body: {
          "type": "2062",
          "cid": cid,
          "uid": uid,
          "device_id": dId,
          "lt": lat,
          "ln": lng,
          if (token.isNotEmpty) "token": token,
        },
      );

      final data = jsonDecode(response.body);
      if (data["error"] == false) {
        final List<dynamic> rawRecords = data["data"] ?? [];
        final List<dynamic> records = rawRecords.where((e) {
          final String delFlag = e["del"]?.toString() ?? "";
          final String isDFlag = e["is_d"]?.toString() ?? "";
          return delFlag != "1" && isDFlag != "1";
        }).toList();

        final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

        final Map<String, dynamic>? latestOpenCheckin = records.firstWhere(
          (e) =>
              e["date"] == today &&
              e["status"]?.toString().toLowerCase() == "open",
          orElse: () => null,
        );

        if (mounted) {
          setState(() {
            if (latestOpenCheckin != null) {
              isCheckedIn = true;
              checkInTime = latestOpenCheckin["check_in_time"] ?? "00.00.00";
              isCheckedOut = false;
            } else {
              isCheckedIn = false;
              checkInTime = "00.00.00";
            }
            historyRecords = records;
          });
          await prefs.setBool('is_marketing_checked_in_local', isCheckedIn);
          await prefs.setString('marketing_check_in_time_local', checkInTime);
        }
      }
    } catch (e) {
      debugPrint("Error fetching marketing server status: $e");
    }
  }

  Future<void> _getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor;
      }
    } catch (e) {
      deviceId = "";
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;
      return await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
    } catch (e) {
      return null;
    }
  }

  Future<void> _performCheckIn() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final Position? pos = await _getCurrentLocation();
      final String uid = prefs.getString('login_cus_id') ?? "";
      final String cid = prefs.getString('cid') ?? "";
      final String lt = pos?.latitude.toString() ?? "0.0";
      final String ln = pos?.longitude.toString() ?? "0.0";
      final String dId = deviceId ?? prefs.getString('device_id') ?? "";
      final String? token = prefs.getString('token');

      String checkInLocation = "Unknown Location";
      try {
        if (pos != null) {
          debugPrint("Fetching address for Lat: ${pos.latitude}, Lng: ${pos.longitude}");
          List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
          if (placemarks.isNotEmpty) {
            Placemark p = placemarks[0];
            List<String> addressParts = [
              if (p.name != null && p.name != p.street) p.name!,
              if (p.street != null) p.street!,
              if (p.subLocality != null) p.subLocality!,
              if (p.locality != null) p.locality!,
              if (p.administrativeArea != null) p.administrativeArea!,
              if (p.postalCode != null) p.postalCode!,
              if (p.country != null) p.country!,
            ];
            checkInLocation = addressParts.where((s) => s.isNotEmpty).join(", ");
            debugPrint("Determined Address: $checkInLocation");
          }
        } else {
          debugPrint("Current position is null, unable to geocode.");
        }
      } catch (e) {
        debugPrint("Location Geocoding Error: $e");
        checkInLocation = "Location Unavailable ($e)";
      }

      final DateTime now = DateTime.now();
      final String formattedDate = DateFormat('yyyy-MM-dd').format(now);
      final String formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

      final response = await MarketingApi.checkIn(
        uid: uid,
        cid: cid,
        deviceId: dId,
        lat: lt,
        lng: ln,
        type: "2054",
        date: formattedDate,
        checkInTime: formattedTime,
        token: token,
        checkInLocation: checkInLocation,
      );

      if (response['error'] == false) {
        await _fetchServerStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Checked in successfully!"), backgroundColor: Colors.green));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${response['error_msg'] ?? "Check-in failed"}"), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showCheckInDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Are you sure want to Check in?", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), side: const BorderSide(color: Colors.black87)),
                        child: Text("NO", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black87)),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async { Navigator.pop(context); await _performCheckIn(); },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E2F5E), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        child: Text("YES", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Text("Marketing", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('is_marketing_checked_in_local');
              await prefs.remove('marketing_check_in_time_local');
              setState(() { isCheckedIn = false; checkInTime = "00.00.00"; });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoading) const Center(child: CircularProgressIndicator()),
            if (isCheckedIn)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(color: const Color(0xFF98D1C1), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 12), Text("Check in Successfully", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500))]),
              ),
            Row(
              children: [
                Expanded(child: _buildTimeBox(isCheckedIn ? "Add New Check In" : "Check In", checkInTime, isCheckedIn: isCheckedIn, onTap: _showCheckInDialog, showAddIcon: isCheckedIn)),
                const SizedBox(width: 20),
                Expanded(child: _buildTimeBox("Check Out", checkOutTime, isCheckedIn: false, onTap: () async {
                  if (!isCheckedIn) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please Check In first"), backgroundColor: Colors.orange));
                    return;
                  }
                  String? currentVisitId;
                  final openRecord = historyRecords.firstWhere((e) => e["status"]?.toString().toLowerCase() == "open", orElse: () => null);
                  if (openRecord != null) currentVisitId = openRecord["id"]?.toString();
                  final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => CheckoutScreen(checkinId: currentVisitId)));
                  if (result == true) _fetchServerStatus();
                })),
              ],
            ),
            const SizedBox(height: 32),
            Text("History", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            if (historyRecords.isEmpty && !isCheckedIn)
              Center(child: Padding(padding: const EdgeInsets.only(top: 20), child: Text("No history found for today", style: GoogleFonts.poppins(color: Colors.grey))))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: historyRecords.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final record = historyRecords[index];
                  final String status = record["status"]?.toString().toLowerCase() ?? "open";
                  final bool isClosed = status == "closed";
                  return _buildHistoryItem(
                    company: record["client_name"] ?? "Unknown",
                    time: isClosed ? "${record["check_in_time"]} - ${record["check_out_time"]}" : "${record["check_in_time"]}",
                    status: isClosed ? "Completed" : "In Progress",
                    badgeBg: isClosed ? const Color(0xFFA8E6CF) : const Color(0xFFFFB38E),
                    onTap: isClosed ? null : () async {
                      final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => CheckoutScreen(checkinId: record["id"]?.toString())));
                      if (result == true) _fetchServerStatus();
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBox(String label, String time, {bool isCheckedIn = false, bool showAddIcon = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: isCheckedIn ? const Color(0xFF76C73F) : const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showAddIcon) const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
            Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: isCheckedIn ? Colors.white : const Color(0xFF2C3E50))),
            const SizedBox(height: 4),
            Text(time, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: isCheckedIn ? Colors.white : const Color(0xFF2C3E50))),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem({required String company, required String time, required String status, required Color badgeBg, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.person_pin_circle_outlined, color: status == "Completed" ? const Color(0xFF2ECC71) : const Color(0xFFE67E22), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(company, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(time, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                        child: Text(status, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                      if (onTap != null)
                        ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF26A69A), padding: const EdgeInsets.symmetric(horizontal: 12), minimumSize: const Size(60, 28)),
                          child: Text("Checkout", style: GoogleFonts.poppins(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
