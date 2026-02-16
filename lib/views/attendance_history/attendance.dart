import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../models/employee_api.dart';
import 'weekly_history.dart';
import 'check_in.dart';
import 'check_out.dart';
import '../main_root.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  AttendanceScreenState createState() => AttendanceScreenState();
}

// Data model for break entries
class BreakEntry {
  final String purpose;
  final DateTime breakInTime;
  final DateTime? breakOutTime;
  final Duration duration;

  BreakEntry({
    required this.purpose,
    required this.breakInTime,
    this.breakOutTime,
    required this.duration,
  });
}

class AttendanceScreenState extends State<AttendanceScreen> {
  bool breakSwitch = false;
  int bottomNavIndex = 1;
  int selectedTab = 1; // Default to Monthly as per typical dashboard usage here
  bool isCheckedIn = false;
  Timer? breakTimer;
  Duration breakDuration = Duration.zero;
  Duration totalBreakDuration = Duration.zero;
  bool isLoading = false;
  int uid = 4; // User ID
  String? serverUidString; // To store the original value from server
  String userName = "User";
  String breakPurpose = "Tea"; // Default/Sample purpose
  final TextEditingController purposeController = TextEditingController();
  List<BreakEntry> breakHistory = [];
  DateTime? currentBreakInTime;

  // API Integration fields
  String cid = "21472147"; // Company ID
  String? employeeCode;
  String? employeeName;
  String? deviceId;
  Position? currentPosition;
  int? currentBreakId; // Store break_id from API response

  Map<String, dynamic>? attendanceHistory;
  bool isHistoryLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUid();
    _loadEmployeeData();
    _getDeviceId().then((_) {
      _fetchAttendanceSummary();
    });
  }

  Future<void> _loadUid() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      uid = prefs.getInt('uid') ?? 4;
      cid = prefs.getString('cid') ?? "21472147";
      serverUidString = prefs.getString('server_uid');
      isCheckedIn = prefs.getBool('isCheckedIn') ?? false;
      userName = prefs.getString('name') ?? "User";
      employeeName = prefs.getString('name');
      employeeCode = prefs.getString('employee_code');
    });
    debugPrint(
      "LOADED INITIAL STATE: isCheckedIn=$isCheckedIn, uid=$uid, cid=$cid",
    );
  }

  Future<void> _loadEmployeeData() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Get identifiers from SharedPreferences
    final storedUid = prefs.getInt('uid') ?? 0;
    final storedCid = prefs.getString('cid') ?? "21472147";
    final storedCode = prefs.getString('employee_code');
    final storedName = prefs.getString('name');

    setState(() {
      uid = storedUid;
      cid = storedCid;
      employeeCode = storedCode;
      employeeName = storedName ?? userName;
    });

    debugPrint(
      "Initial Load: uid=$uid, cid=$cid, code=$employeeCode, name=$employeeName",
    );

    // 2. Fetch full details from server to sync state
    try {
      final res = await EmployeeApi.getEmployeeDetails(
        uid: uid.toString(),
        cid: cid,
        deviceId: deviceId ?? "123456",
        lat: prefs.getDouble('lat')?.toString() ?? "123",
        lng: prefs.getDouble('lng')?.toString() ?? "123",
      );

      if (res["error"] == false) {
        debugPrint("FULL SYNC RESPONSE: ${jsonEncode(res)}");
        final data = res["data"] ?? res;

        // Multi-Identifier Discovery
        String? foundId = data["id"]?.toString(); // Numeric DB ID
        String? foundUid = data["uid"]?.toString(); // Potential String UID/Code

        final String? serverCid =
            data["cid"]?.toString() ?? data["cus_id"]?.toString();
        final String? serverName = data["name"]?.toString();

        debugPrint(
          "IDENTIFIED => Record ID: $foundId, Server UID: $foundUid, CID: $serverCid",
        );

        setState(() {
          if (foundId != null && foundId != "null" && foundId.isNotEmpty) {
            uid = int.tryParse(foundId) ?? uid;
          }
          if (foundUid != null && foundUid != "null") {
            serverUidString = foundUid;
          }
          if (serverCid != null &&
              serverCid != "null" &&
              serverCid.isNotEmpty) {
            cid = serverCid;
          }
          if (serverName != null) {
            employeeName = serverName;
            userName = serverName;
          }
          if (data["employee_code"] != null)
            employeeCode = data["employee_code"].toString();
        });

        // Persist synced identifiers
        await prefs.setInt('uid', uid);
        await prefs.setString('cid', cid);
        if (serverUidString != null)
          await prefs.setString('server_uid', serverUidString!);
        if (foundId != null)
          await prefs.setString('employee_table_id', foundId);
        if (employeeName != null) await prefs.setString('name', employeeName!);
        if (employeeCode != null)
          await prefs.setString('employee_code', employeeCode!);
      } else {
        debugPrint("DETAILS SYNC FAILED => ${res["error_msg"]}");
      }
    } catch (e) {
      debugPrint("Error in _loadEmployeeData sync: $e");
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
      debugPrint("Device ID: $deviceId");
    } catch (e) {
      debugPrint("Error getting device ID: $e");
      deviceId = "unknown";
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission permanently denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      debugPrint("Location Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error getting location'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _fetchAttendanceSummary() async {
    setState(() {
      isHistoryLoading = true;
    });

    try {
      // Get location for API call
      final currentPos =
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).onError((error, stackTrace) {
            debugPrint("Location error in fetch summary: $error");
            return Position(
              longitude: 0,
              latitude: 0,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
              altitudeAccuracy: 0,
              headingAccuracy: 0,
            );
          });

      // Use user provided params or dynamic
      // User requested: "type:2064, cid:21472147, uid:8, device_id:12345, lt:145, ln:145"
      // We will use dynamic values but stick to the provided example parameters logic if needed
      final body = {
        "type": "2064",
        "cid": cid, // Dynamic or default "21472147"
        "uid": uid.toString(), // Dynamic or default "8"
        "device_id": deviceId ?? "123456",
        "lt": currentPos.latitude.toString(),
        "ln": currentPos.longitude.toString(),
      };

      debugPrint("ATTENDANCE SUMMARY REQUEST => $body");

      final response = await http.post(
        Uri.parse("https://erpsmart.in/total/api/m_api/"),
        body: body,
      );

      debugPrint("ATTENDANCE SUMMARY RESPONSE => ${response.body}");
      final data = jsonDecode(response.body);

      if (data["error"] == false || data["error"] == "false") {
        if (mounted) {
          setState(() {
            if (data["statistics"] != null) {
              attendanceHistory = Map<String, dynamic>.from(data["statistics"]);
            } else {
              attendanceHistory = {};
            }
          });
        }
      } else {
        debugPrint(
          "Error fetching history: ${data["error_msg"] ?? data["message"]}",
        );
      }
    } catch (e) {
      debugPrint("Error in _fetchAttendanceSummary: $e");
    } finally {
      if (mounted) {
        setState(() {
          isHistoryLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    breakTimer?.cancel();
    purposeController.dispose();
    super.dispose();
  }

  /// Handle Break In API Call
  Future<void> handleBreakIn() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get current location
      currentPosition = await _getCurrentLocation();
      if (currentPosition == null) {
        setState(() => isLoading = false);
        return;
      }

      // Make API call using identified parameters from login/sync flow
      final body = {
        "type": "2055",
        "cid": cid,
        "uid": serverUidString ?? uid.toString(),
        "device_id": deviceId ?? "123456",
        "lt": currentPosition!.latitude.toString(),
        "ln": currentPosition!.longitude.toString(),
        "reason": breakPurpose,
      };

      debugPrint("BREAK IN POST REQUEST => $body");

      final response = await http.post(
        Uri.parse("https://erpsmart.in/total/api/m_api/"),
        body: body,
      );

      debugPrint("BREAK IN RAW RESPONSE => ${response.body}");
      final responseData = jsonDecode(response.body);

      if (responseData["error"] == false || responseData["error"] == "false") {
        debugPrint("BREAK IN SUCCESS! Data: ${responseData["data"]}");
      } else {
        debugPrint("BREAK IN FAILED! Message: ${responseData["error_msg"]}");
      }
      final bool isSuccess =
          responseData["error"] == false || responseData["error"] == "false";

      if (isSuccess && responseData["data"] != null) {
        final data = responseData["data"];

        // Note: Break API uses 'employee_name' as per user info
        if (data["employee_name"] != null) {
          employeeName = data["employee_name"].toString();
        }
        if (data["employee_code"] != null) {
          employeeCode = data["employee_code"].toString();
        }

        currentBreakId =
            int.tryParse((data["break_id"] ?? "").toString()) ?? currentBreakId;

        setState(() {
          breakSwitch = true;
          isLoading = false;
          currentBreakInTime = DateTime.now();
          breakDuration = Duration.zero;
        });
        startBreakTimer();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                responseData["error_msg"] ?? 'Break started successfully',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                responseData["error_msg"] ?? 'Failed to start break',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("BREAK IN ERROR => $e");
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle Break Out API Call
  Future<void> handleBreakOut() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get current location
      currentPosition = await _getCurrentLocation();
      if (currentPosition == null) {
        setState(() => isLoading = false);
        return;
      }

      // Make API call using identified parameters from login/sync flow
      final body = {
        "type": "2056",
        "cid": cid,
        "uid": serverUidString ?? uid.toString(),
        "device_id": deviceId ?? "123456",
        "lt": currentPosition!.latitude.toString(),
        "ln": currentPosition!.longitude.toString(),
      };

      debugPrint("BREAK OUT POST REQUEST => $body");

      final response = await http.post(
        Uri.parse("https://erpsmart.in/total/api/m_api/"),
        body: body,
      );

      debugPrint("BREAK OUT RESPONSE => ${response.body}");
      final responseData = jsonDecode(response.body);
      final bool isSuccess =
          responseData["error"] == false || responseData["error"] == "false";

      if (isSuccess && responseData["data"] != null) {
        final data = responseData["data"];

        // Update employee name if provided (Break Out also uses employee_name)
        if (data["employee_name"] != null) {
          employeeName = data["employee_name"].toString();
        }
        if (data["employee_code"] != null) {
          employeeCode = data["employee_code"].toString();
        }

        // Parse break times from API response
        DateTime? breakInTime = currentBreakInTime;
        DateTime? breakOutTime = DateTime.now();
        Duration duration = breakDuration;

        // Try to parse duration from API response if available
        if (data["total_break_duration"] != null) {
          try {
            final durationStr = data["total_break_duration"] as String;
            final parts = durationStr.split(':');
            if (parts.length >= 2) {
              final hours = int.tryParse(parts[0]) ?? 0;
              final minutes = int.tryParse(parts[1]) ?? 0;
              duration = Duration(hours: hours, minutes: minutes);
            }
          } catch (e) {
            debugPrint("Error parsing duration: $e");
          }
        }

        // Record the break entry with API data
        if (breakInTime != null) {
          breakHistory.add(
            BreakEntry(
              purpose: breakPurpose,
              breakInTime: breakInTime,
              breakOutTime: breakOutTime,
              duration: duration,
            ),
          );
          totalBreakDuration += duration;
        }

        setState(() {
          breakSwitch = false;
          isLoading = false;
          breakPurpose = "Tea";
          currentBreakInTime = null;
          currentBreakId = null;
        });
        stopBreakTimer();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                responseData["error_msg"] ?? 'Break ended successfully',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData["error_msg"] ?? 'Failed to end break'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("BREAK OUT ERROR => $e");
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void startBreakTimer() {
    breakTimer?.cancel();
    breakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        breakDuration += const Duration(seconds: 1);
      });
    });
  }

  void stopBreakTimer() {
    breakTimer?.cancel();
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  Future<void> _showBreakPurposeDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F6F4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        "assets/cup.png",
                        width: 32,
                        height: 32,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Start Break",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Please specify the purpose of your break before starting.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                const Text(
                  "Break Purpose",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: purposeController,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF00A79D)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF00A79D),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Color(0xFF00A79D)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (purposeController.text.trim().isNotEmpty) {
                            setState(() {
                              breakPurpose = purposeController.text.trim();
                            });
                            Navigator.pop(context);
                            handleBreakIn();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please enter a purpose"),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A79D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text(
                          "Start Break",
                          style: TextStyle(color: Colors.white),
                        ),
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

  Future<void> _showBreakReportDialog() async {
    return showDialog(
      context: context,
      builder: (context) {
        final w = MediaQuery.of(context).size.width;
        final h = MediaQuery.of(context).size.height;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: h * 0.85,
              maxWidth: w * 0.95,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F6F4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.asset(
                            "assets/cup.png",
                            width: 32,
                            height: 32,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Break Report",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "View all your breaks taken today",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  // Summary Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F6F4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF00A79D).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      "assets/cup.png",
                                      width: 20,
                                      height: 20,
                                      color: const Color(0xFF00A79D),
                                    ),
                                    const SizedBox(width: 6),
                                    const Flexible(
                                      child: Text(
                                        "Total Breaks",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "${breakHistory.length}",
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00A79D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFF9800).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.access_time,
                                      size: 20,
                                      color: Color(0xFFFF9800),
                                    ),
                                    SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        "Total Time",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _formatDurationHoursMinutes(
                                      totalBreakDuration,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFF9800),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Break History Section
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Break History",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Break History List
                  breakHistory.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                "assets/cup.png",
                                width: 60,
                                height: 60,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "No breaks taken yet",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Your break history will appear here",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: breakHistory.length,
                          itemBuilder: (context, index) {
                            final entry = breakHistory[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE6F6F4),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Image.asset(
                                      "assets/cup.png",
                                      width: 20,
                                      height: 20,
                                      color: const Color(0xFF00A79D),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.purpose,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.login,
                                              size: 14,
                                              color: Colors.green,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatTime(entry.breakInTime),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            const Icon(
                                              Icons.logout,
                                              size: 14,
                                              color: Colors.red,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              entry.breakOutTime != null
                                                  ? _formatTime(
                                                      entry.breakOutTime!,
                                                    )
                                                  : "--:--",
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3E0),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _formatDurationHoursMinutes(
                                        entry.duration,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFFF9800),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  String _formatDurationHoursMinutes(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return "${hours}h ${minutes}m";
  }

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: const Color(0xffEFEFEF),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final Color teal = const Color(0xFF00A79D);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A79D),
        foregroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainRoot()),
              (route) => false,
            );
          },
        ),
        title: Text(
          'Attendance',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.more_vert),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.04,
            vertical: h * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // DEBUG LABEL
              timeTrackingCard(w, h),
              if (breakSwitch) ...[
                SizedBox(height: h * 0.02),
                onBreakInfoCard(w, h),
              ],
              SizedBox(height: h * 0.02),
              Center(
                child: const Text(
                  "Make sure your location and camera \npermissions are enabled",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: h * 0.02),
              greetingCard(w, h),
              SizedBox(height: h * 0.02),
              breakReportCard(w, h),
              SizedBox(height: h * 0.015),
              todayWorkProgressCard(w, h),
              SizedBox(height: h * 0.015),
              attendanceProgressCard(w, h, teal),
              SizedBox(height: h * 0.02),
            ],
          ),
        ),
      ),
    );
  }

  Widget onBreakInfoCard(double w, double h) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBE6), // Light yellow background
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9D773), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset("assets/cup.png", width: 24, height: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "On Break",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                Text(
                  "Purpose: $breakPurpose",
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const Text(
                  "Click the toggle above to end your break",
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget breakReportCard(double w, double h) {
    return GestureDetector(
      onTap: () => _showBreakReportDialog(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.04,
          vertical: h * 0.018,
        ),
        decoration: BoxDecoration(
          color: const Color(0xffF1F1F1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xffE6F6F4),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset("assets/cup.png", width: 22, height: 22),
                ),
                SizedBox(width: w * 0.03),
                const Text(
                  "Break Report",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const Icon(
              Icons.trending_up_outlined,
              size: 22,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  Widget todayWorkProgressCard(double w, double h) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.018),
      decoration: BoxDecoration(
        color: const Color(0xffF1F1F1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xffE3F2FD),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.access_time,
                    color: Color(0xff2196F3),
                    size: 26,
                  ),
                ),
                SizedBox(width: w * 0.03),
                const Flexible(
                  child: Text(
                    "Today Work Progress Report",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.trending_up_outlined,
            size: 22,
            color: Colors.black54,
          ),
        ],
      ),
    );
  }

  Widget timeTrackingCard(double w, double h) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset("assets/time.png", width: 26, height: 26),
            SizedBox(width: w * 0.02),
            const Text(
              "Time Tracking",
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
            ),
          ],
        ),
        SizedBox(height: h * 0.02),
        if (!isCheckedIn)
          checkInOutButton(
            label: "Attendance In",
            color: const Color(0xFF4CAF50),
            borderColor: const Color(0xFF4CAF50).withOpacity(0.4),
            icon: Icons.login,
            w: w,
            h: h,
            onTap: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const CheckInVerificationScreen(),
                ),
              );

              if (result == true) {
                setState(() {
                  isCheckedIn = true;
                });
              }
            },
          ),
        if (isCheckedIn)
          checkInOutButton(
            label: "Attendance out",
            color: const Color(0xFFF44336),
            borderColor: const Color(0xFFF44336),
            icon: Icons.logout,
            w: w,
            h: h,
            onTap: () async {
              if (breakSwitch) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please end your break before checking out'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const CheckOutVerificationScreen(),
                ),
              );

              if (result == true) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isCheckedIn', false);

                setState(() {
                  isCheckedIn = false;
                  if (breakSwitch) {
                    breakSwitch = false;
                    stopBreakTimer();
                  }
                });
              }
            },
          ),
        SizedBox(height: h * 0.014),
        breakButton(w, h),
      ],
    );
  }

  Widget checkInOutButton({
    required String label,
    required Color color,
    required Color borderColor,
    required IconData icon,
    required double w,
    required double h,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor, width: 1),
          ),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 24, color: color),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: color.withOpacity(0.8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xff90BD83),
            ),
          ],
        ),
      ),
    );
  }

  Widget breakButton(double w, double h) {
    return SizedBox(
      height: h * 0.058,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: isLoading
              ? Colors.grey.shade400
              : (!isCheckedIn ? Colors.grey.shade400 : const Color(0xff727272)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: isLoading
            ? null
            : () async {
                debugPrint(
                  "Break Button Pressed. Current isCheckedIn: $isCheckedIn",
                );
                debugPrint(
                  "Break Button Pressed. Current isCheckedIn: $isCheckedIn, breakSwitch: $breakSwitch",
                );
                if (!isCheckedIn) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'You must check in first before taking a break!',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (breakSwitch) {
                  await handleBreakOut();
                } else {
                  await _showBreakPurposeDialog();
                }
              },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Image.asset(
                      "assets/cup.png",
                      width: 24,
                      height: 24,
                      color: Colors.white,
                    ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      isLoading
                          ? "Processing..."
                          : breakSwitch
                          ? "Break Out (${formatDuration(breakDuration)})"
                          : "Break In (${formatDuration(breakDuration)})",
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (!isLoading)
              Switch(
                value: breakSwitch,
                activeColor: const Color(0xffD9D9D9),
                activeTrackColor: const Color(0xff1B2C61),
                inactiveThumbColor: const Color(0xffD9D9D9),
                inactiveTrackColor: Colors.grey.shade500,
                onChanged: (value) async {
                  debugPrint(
                    "Break Switch Changed: $value, isCheckedIn: $isCheckedIn",
                  );
                  debugPrint(
                    "Break Switch Changed: $value, isCheckedIn: $isCheckedIn",
                  );
                  if (!isCheckedIn) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'You must check in first before taking a break!',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  if (value) {
                    await _showBreakPurposeDialog();
                  } else {
                    await handleBreakOut();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget greetingCard(double w, double h) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffEFEFEF),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: EdgeInsets.all(w * 0.04),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: w * 0.08,
                backgroundImage: const AssetImage('assets/profile.png'),
              ),
              SizedBox(width: w * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Good Morning, $userName!",
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Ready to make today productive?",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Day Shift",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isCheckedIn ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isCheckedIn ? "Checked In" : "Not Checked In",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isCheckedIn ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: h * 0.02),
          shiftBreakInfo(w, h),
        ],
      ),
    );
  }

  Widget shiftBreakInfo(double w, double h) {
    return Container(
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Current Shift",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Day Shift",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  isCheckedIn ? "09:00 - 18:00" : "--:--",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: w * 0.10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Break Duration",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.05,
                    vertical: h * 0.01,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${formatDuration(breakDuration)} / 1 hr",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget attendanceProgressCard(double w, double h, Color teal) {
    // Calculate progress for dashboard metrics
    double progress = 0.0;
    int daysPresent = 0;
    int totalWorkingDays = 1;

    if (attendanceHistory != null && !isHistoryLoading) {
      // Use stats from API if reliable
      daysPresent =
          int.tryParse(
            attendanceHistory!["total_records"]?.toString() ?? "0",
          ) ??
          0;

      DateTime now = DateTime.now();
      totalWorkingDays = now.day; // Approximation: days passed in month

      if (totalWorkingDays == 0) totalWorkingDays = 1;
      progress = (daysPresent / totalWorkingDays).clamp(0.0, 1.0);
    }

    return Container(
      padding: EdgeInsets.all(w * 0.04),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Attendance Progress",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          SizedBox(height: h * 0.015),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey, width: 1),
            ),
            child: Row(
              children: [
                Expanded(child: tabButton("Weekly", 0)),
                const SizedBox(width: 10),
                Expanded(child: tabButton("Monthly", 1)),
              ],
            ),
          ),
          SizedBox(height: h * 0.02),
          Row(
            children: const [
              Icon(Icons.trending_up_outlined),
              SizedBox(width: 8),
              Text(
                "This Monthly Progress",
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              ),
            ],
          ),
          SizedBox(height: h * 0.02),
          if (selectedTab == 0)
            Row(
              children: [
                Expanded(
                  child: statsBox(
                    "Total Hours",
                    attendanceHistory != null &&
                            attendanceHistory!["total_hours_worked"] != null
                        ? "${attendanceHistory!["total_hours_worked"]}h"
                        : "0h",
                    valueColor: Colors.black,
                  ),
                ),
                SizedBox(width: w * 0.03),
                Expanded(
                  child: statsBox(
                    "Overtime",
                    attendanceHistory != null &&
                            attendanceHistory!["overtime"] != null
                        ? attendanceHistory!["overtime"].toString()
                        : "0h 00m",
                    valueColor: Colors.red,
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: monthlyStatBox(
                        "Day Worked",
                        attendanceHistory != null &&
                                attendanceHistory!["total_records"] != null
                            ? attendanceHistory!["total_records"].toString()
                            : "0",
                      ),
                    ),
                    SizedBox(width: w * 0.03),
                    Expanded(
                      child: monthlyStatBox(
                        "Leave Taken",
                        attendanceHistory != null &&
                                attendanceHistory!["leave_taken"] != null
                            ? attendanceHistory!["leave_taken"].toString()
                            : "0",
                        highlight: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: h * 0.02),
                Row(
                  children: [
                    Expanded(
                      child: monthlyStatBox(
                        "LOP",
                        attendanceHistory != null &&
                                attendanceHistory!["lop"] != null
                            ? attendanceHistory!["lop"].toString()
                            : "0",
                      ),
                    ),
                    SizedBox(width: w * 0.03),
                    Expanded(
                      child: monthlyStatBox(
                        "Overtime",
                        attendanceHistory != null &&
                                attendanceHistory!["monthly_overtime"] != null
                            ? attendanceHistory!["monthly_overtime"].toString()
                            : "0h 00m",
                        highlight: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          SizedBox(height: h * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Attendance Progress",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Text(
                "${(progress * 100).toStringAsFixed(0)}%",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: h * 0.01),
          // Using LinearProgressIndicator instead of Image if preferable, but user has Image asset
          // Assuming user might want accurate visual representation, let's keep image or replace?
          // The user said "oluga data show aagala" (data not showing properly).
          // Maybe they mean the TEXT? "4/6 days" and "80%" were hardcoded.
          // Let's replace the text values correctly.
          // And maybe use a real progress bar if the image is static.
          // I'll add a LinearProgressIndicator below or replace the image if permitted.
          // Given the prompt "fix pannu" (fix it), replacing static image with dynamic indicator is better.
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            color: teal,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          SizedBox(height: h * 0.01),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "This Month",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "$daysPresent/$totalWorkingDays days",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: h * 0.02),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: teal,
                padding: EdgeInsets.symmetric(vertical: h * 0.014),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AttendanceHistoryScreen(),
                  ),
                );
              },
              child: const Text(
                "Attendance History",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget monthlyStatBox(String title, String value, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffEFEFEF), width: 2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: highlight ? Colors.deepOrange : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget tabButton(String text, int index) {
    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selectedTab == index
              ? const Color(0xff26A69A)
              : const Color(0xffC9C9C9),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selectedTab == index ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget statsBox(
    String title,
    String value, {
    Color valueColor = Colors.black,
  }) {
    final bool isOvertime = title.toLowerCase().contains("overtime");
    final Color finalColor = isOvertime ? Colors.red : valueColor;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffEFEFEF), width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value.split(' ')[0],
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: finalColor,
                    ),
                  ),
                  if (value.contains(' '))
                    TextSpan(
                      text: " ${value.split(' ')[1]}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: finalColor.withOpacity(0.85),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
