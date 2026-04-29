import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'marketing_checkout.dart';
import '../../models/marketing_api.dart';
import '../../models/employee_api.dart';
import '../../services/user_data_manager.dart';
import 'package:http/http.dart' as http;
import '../../services/api_client.dart';
import 'dart:convert';

class MarketingCheckInScreen extends StatefulWidget {
  final Map<String, dynamic>? task;
  const MarketingCheckInScreen({super.key, this.task});

  @override
  State<MarketingCheckInScreen> createState() => _MarketingCheckInScreenState();
}

class _MarketingCheckInScreenState extends State<MarketingCheckInScreen> {
  bool isCheckedIn = false;
  bool isLoading = false;
  String checkInTime = "00.00.00";
  String checkOutTime = "00.00.00";
  String activeDuration = "00:00:00";
  String currentLocation = "Fetching location...";
  Position? currentPosition;
  Timer? _timer;
  List<Map<String, dynamic>> history = [];
  String? employeeTableId;
  DateTime? _checkInFullDateTime;

  @override
  void initState() {
    super.initState();
    _loadCheckInState();
    _loadEmployeeDetails();
    _startLiveUpdates();
    _fetchServerSync(); // ✅ Sync with server on entry
  }

  /// ✅ Synchronize status with server (Postman sync)
  Future<void> _fetchServerSync() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final String cid = prefs.getString('cid') ?? prefs.getString('cid_str') ?? "21472147";
      final String uid = prefs.getString('login_cus_id') ?? prefs.getString('uid') ?? "54";
      final String dId = prefs.getString('device_id') ?? "123456";
      final String lat = prefs.getString('lt') ?? prefs.getString('latitude') ?? "145";
      final String lng = prefs.getString('ln') ?? prefs.getString('longitude') ?? "145";
      final String token = prefs.getString('token') ?? "";

      final response = await ApiClient().post({
        "type": "2062", 
        "cid": cid,
        "uid": uid,
        "cus_id": uid,
        "id": uid,
        "device_id": dId,
        "lt": lat,
        "ln": lng,
        "token": token,
      });

      final data = jsonDecode(response.body);
      if (data["error"] == false) {
        final List<dynamic> records = data["data"] ?? [];
        final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

        final openCheckin = records.firstWhere(
          (e) => e["date"] == today && e["status"]?.toString().toLowerCase() == "open",
          orElse: () => null,
        );

        if (mounted) {
          final mappedRecords = records.map((e) {
            String status = e["status"]?.toString().toLowerCase() == "open"
                ? "In Progress"
                : "Completed";
            String inT = e["check_in_time"] ?? "--:--";
            String outT = e["check_out_time"] ?? "--:--";

            return {
              "company": (e["client_name"] == null || e["client_name"].toString().isEmpty) 
                  ? "Marketing Visit" 
                  : e["client_name"],
              "remarks": e["remarks"] ?? e["purpose_of_visit"] ?? "No Remarks",
              "date": e["date"] ?? "",
              "time": status == "In Progress" ? inT : "$inT – $outT",
              "status": status,
              "statusColor":
                  status == "Completed" ? Colors.green : Colors.orange,
            };
          }).toList();

          if (openCheckin != null) {
            String time = openCheckin["check_in_time"] ?? "00.00.00";
            if (time.contains(" ")) time = time.split(" ").last;

            await prefs.setBool('is_marketing_checked_in', true);
            await prefs.setString('marketing_check_in_time', time);

            setState(() {
              isCheckedIn = true;
              checkInTime = time;
              history = List<Map<String, dynamic>>.from(mappedRecords);
            });
          } else {
            setState(() {
              history = List<Map<String, dynamic>>.from(mappedRecords);
            });
            if (isCheckedIn) {
              await prefs.setBool('is_marketing_checked_in', false);
              setState(() => isCheckedIn = false);
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error syncing marketing status: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startLiveUpdates() {
    _fetchLocationAndTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isCheckedIn) {
        if (timer.tick % 10 == 0) _fetchLocationAndTime();
      } else {
        _updateActiveDuration();
      }
    });
  }

  void _updateActiveDuration() {
    if (_checkInFullDateTime == null) return;
    
    final now = DateTime.now();
    final difference = now.difference(_checkInFullDateTime!);
    
    if (difference.isNegative) return;

    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(difference.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(difference.inSeconds.remainder(60));
    
    if (mounted) {
      setState(() {
        activeDuration = "${twoDigits(difference.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
      });
    }
  }

  Future<void> _fetchLocationAndTime() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted)
          setState(() => currentLocation = "Location services disabled");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => currentLocation = "Permission denied");
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      currentPosition = position;

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

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
        String address = addressParts.where((s) => s.isNotEmpty).join(", ");
        if (mounted) {
          setState(() {
            currentLocation = address.isEmpty ? "Location found" : address;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => currentLocation = "Error getting location");
    }
  }

  Future<void> _loadEmployeeDetails() async {
    final prefs = await SharedPreferences.getInstance();

    // ALWAYS prioritize login_cus_id (Session ID) - This is '44' from login response
    final String sessionUid = prefs.getString('uid') ?? 
                             prefs.getString('login_cus_id') ?? 
                             prefs.getString('employee_table_id') ??
                             "54";
                             
    setState(() {
      employeeTableId = sessionUid;
    });

    // We still fetch details for profile info, but we NEVER overwrite employeeTableId from the API response
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
        // Fetch history immediately after confirming ID is valid
        _fetchHistoryFromApi();
        debugPrint("Employee Details Fetched for session UID: $sessionUid");
      }
    } catch (e) {
      debugPrint("Employee fetch error => $e");
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<void> _fetchHistoryFromApi() async {
    debugPrint("🌐 Fetching fresh marketing history from API/Database...");

    // Get saved location or use defaults
    final prefs = await SharedPreferences.getInstance();
    final String lat = prefs.getDouble('lat')?.toString() ?? "";
    final String lng = prefs.getDouble('lng')?.toString() ?? "";
    final String cid = prefs.getString('cid') ?? "";
    final String deviceId = prefs.getString('device_id') ?? "";
    final String token = prefs.getString('token') ?? "";

    if (employeeTableId == null || employeeTableId == "0") {
      debugPrint(
        "⚠️ Employee ID not set ($employeeTableId), skipping history fetch",
      );
      return;
    }

    if (employeeTableId == null) {
      debugPrint("⚠️ employeeTableId is null, skipping history fetch");
      return;
    }
    try {
      final res = await MarketingApi.fetchHistory(
        uid: employeeTableId!,
        cid: cid,
        lat: lat,
        lng: lng,
        deviceId: deviceId,
        type: "2062",
        token: token,
      );

      debugPrint("📡 Marketing History API Response: $res");

      if (res["error"] == false) {
        // "data" can be null or empty list
        List<dynamic> apiData = res["data"] ?? [];
        debugPrint("📊 Data count: ${apiData.length}");

        if (apiData.isEmpty) {
          setState(() => history = []);
          debugPrint("📭 No history data in database for this user");
          return;
        }

        setState(() {
          history = apiData
              .map((e) {
                // Determine Status (from JSON: status="closed")
                String? statusApi = e["status"]?.toString().toLowerCase();
                String statusLocal = "Completed";
                Color color = const Color(0xff3CA80A);

                if (statusApi == "closed" || statusApi == "completed") {
                  statusLocal = "Completed";
                  color = const Color(0xff3CA80A);
                } else {
                  // Assume anything else might be open
                  statusLocal = "In Progress";
                  color = Colors.redAccent;
                }

                // Fields from JSON
                String clientName =
                    e["client_name"] ?? e["company"] ?? "Unknown Client";
                String remarks = e["remarks"] ?? "No Remarks";
                String date = e["date"] ?? "";
                String checkIn = e["check_in_time"] ?? "00:00:00";
                String? checkOut = e["check_out_time"]
                    ?.toString(); // Handle nullable

                // Format Time Display
                String timeDisplay = checkIn;
                if (statusLocal == "Completed" &&
                    checkOut != null &&
                    checkOut != "00:00:00") {
                  timeDisplay = "$checkIn – $checkOut";
                }

                return {
                  "company": clientName,
                  "remarks": remarks,
                  "date": date,
                  "time": timeDisplay,
                  "status": statusLocal,
                  "statusColor": color,
                };
              })
              .toList()
              .cast<Map<String, dynamic>>();

          _saveHistory(history);
        });
        debugPrint(
          "✅ Loaded ${history.length} items from database and updated cache",
        );
      } else {
        debugPrint(
          "❌ API returned error: ${res['message'] ?? res['error_msg']}",
        );
      }
    } catch (e) {
      debugPrint("❌ History Fetch Error: $e");
    }
  }

  Future<void> _loadCheckInState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isCheckedIn = prefs.getBool('is_marketing_checked_in') ?? false;
      checkInTime = prefs.getString('marketing_check_in_time') ?? "00.00.00";
      String? savedFullTime = prefs.getString('marketing_check_in_full_time');
      if (savedFullTime != null) {
        _checkInFullDateTime = DateTime.tryParse(savedFullTime);
      }
    });

    // Load user-specific history from cache
    debugPrint("📦 Loading cached marketing history...");
    final historyList = await UserDataManager.getCurrentUserList(
      'marketing_history',
    );
    if (historyList != null) {
      try {
        setState(() {
          history = historyList
              .map((e) {
                // Restore color which is not JSON serializable directly
                Color color = e['status'] == 'Completed'
                    ? const Color(0xff3CA80A)
                    : Colors.redAccent;
                return {
                  "company": e["company"] ?? "Unknown Company",
                  "remarks": e["remarks"] ?? "No Remarks",
                  "date": e["date"] ?? "",
                  "time": e["time"] ?? "00:00:00",
                  "status": e["status"] ?? "Pending",
                  "statusColor": color,
                };
              })
              .toList()
              .cast<Map<String, dynamic>>();
        });
        debugPrint("✅ Loaded ${history.length} cached history items");
      } catch (e) {
        setState(() => history = []);
        debugPrint("❌ Error loading cached history: $e");
      }
    } else {
      setState(() => history = []);
      debugPrint("📭 No cached history found");
    }
  }

  Future<void> _saveHistory(List<Map<String, dynamic>> newHistory) async {
    // Remove color objects before saving as they can't be JSON encoded
    List<Map<String, dynamic>> toSave = newHistory.map((e) {
      return {
        "company": e["company"],
        "remarks": e["remarks"],
        "date": e["date"],
        "time": e["time"],
        "status": e["status"],
        // "statusColor" will be re-assigned on load
      };
    }).toList();

    // Save to user-specific storage
    await UserDataManager.saveCurrentUserList('marketing_history', toSave);
  }

  Future<void> _performCheckIn() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String lat =
          currentPosition?.latitude.toString() ??
          prefs.getString('lt') ??
          "145";
      final String lng =
          currentPosition?.longitude.toString() ??
          prefs.getString('ln') ??
          "145";
      final String cid = prefs.getString('cid') ?? prefs.getString('cid_str') ?? "21472147";
      final String deviceId = prefs.getString('device_id') ?? "123456";
      final String token = prefs.getString('token') ?? "";
      final String currentTime = DateFormat('HH:mm:ss').format(DateTime.now());

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
            setState(() => isLoading = false);
          }
          return;
        }
      }

      final DateTime now = DateTime.now();
      final String formattedDate = DateFormat('yyyy-MM-dd').format(now);
      final String formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

      // 1. Call API
      final response = await MarketingApi.checkIn(
        uid: employeeTableId!, 
        cid: cid,
        deviceId: deviceId,
        lat: lat,
        lng: lng,
        type: "2054",
        date: formattedDate,
        checkInTime: formattedTime,
        token: token,
        checkInLocation: currentLocation,
      );

      debugPrint("CheckIn API Response: $response");

      // 2. Handle Response
      if (response['error'] == false) {
        // Save new token if returned
        if (response['token'] != null && response['token'].toString().isNotEmpty) {
          await prefs.setString('token', response['token'].toString());
        }

        String time = "00.00.00";
        final data = response['data'] ?? {};
        if (data['check_in_time'] != null) {
          // Parse "2026-04-08 13:56:04" to "13:56:04"
          String rawTime = data['check_in_time'].toString();
          if (rawTime.contains(" ")) {
            time = rawTime.split(" ").last;
          } else {
            time = rawTime;
          }
        } else if (response['live_date'] != null) {
          time = response['live_date'].toString().split(' ').last;
        } else {
          time = currentTime;
        }

        // 3. Save State
        DateTime fullDateTime = DateTime.now();
        await prefs.setBool('is_marketing_checked_in', true);
        await prefs.setBool('has_done_marketing_today', true);
        await prefs.setString('marketing_check_in_time', time);
        await prefs.setString('marketing_check_in_location', currentLocation);
        await prefs.setString('marketing_check_in_full_time', fullDateTime.toIso8601String());

        // 4. Update UI
        setState(() {
          isCheckedIn = true;
          checkInTime = time;
          _checkInFullDateTime = fullDateTime;
          checkOutTime = "00.00.00";

          // Add to history
          history = [
            {
              "company": data["employee_name"] ?? "KAVIPRIYAN",
              "remarks": "Marketing Started: ${data["employee_id"] ?? ""}",
              "date": data["date"] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
              "time": time,
              "status": "In Progress",
              "statusColor": Colors.redAccent,
            },
            ...history,
          ];

          _saveHistory(history);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green,
              content: Text("Checked In Successfully at $time"),
            ),
          );
        }
      } else {
        // Handle "Already checked in" or other errors logic
        if (response['error_msg'].toString().contains("already checked in")) {
          // If API says already checked in, sync local state
          if (!mounted) return;
          String time = TimeOfDay.now().format(
            context,
          ); // Fallback or parse from msg
          await prefs.setBool('is_marketing_checked_in', true);
          await prefs.setBool('has_done_marketing_today', true);
          await prefs.setString('marketing_check_in_time', time);
          await prefs.setString('marketing_check_in_full_time', DateTime.now().toIso8601String());

          setState(() {
            isCheckedIn = true;
            checkInTime = time;
            _checkInFullDateTime = DateTime.now();
            history = [
              {
                "company": "Smart Global Solution",
                "time": time,
                "status": "In Progress",
                "statusColor": Colors.redAccent,
              },
              ...history,
            ];

            _saveHistory(history);
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(
                response['message'] ??
                    response['error_msg'] ??
                    'Check in failed',
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("CheckIn Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showCheckInDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Are you sure want to Check in?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.black54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          "NO",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _performCheckIn();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF26A69A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: Text(
                          "YES",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width > 600;

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
      body: RefreshIndicator(
        onRefresh: _fetchHistoryFromApi,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 24 : 16),
          child: Column(
            children: [
              if (!isCheckedIn) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF26A69A).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFF26A69A),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              currentLocation,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_filled,
                            color: Color(0xFF26A69A),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat(
                              'dd MMM yyyy • hh:mm a',
                            ).format(DateTime.now()),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              if (isCheckedIn)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9AD9D0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Check in Successfully",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: isTablet ? 30 : 20),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeCard(
                      context: context,
                      title: isCheckedIn ? "Active for" : "Check In",
                      time: isCheckedIn ? activeDuration : "00.00.00",
                      isCheckIn: true,
                      bgColor: isCheckedIn
                          ? const Color(0xFF66BE2F)
                          : const Color(0xFFDBDBDB),
                      textColor: isCheckedIn
                          ? Colors.white
                          : const Color(0xff1B2C61),
                      subText: isCheckedIn ? "Started at $checkInTime" : null,
                    ),
                  ),
                  SizedBox(width: isTablet ? 20 : 12),
                  Expanded(
                    child: _buildTimeCard(
                      context: context,
                      title: "Check Out",
                      time: checkOutTime,
                      bgColor: const Color(0xffD9D9D9),
                      textColor: const Color(0xff1B2C61),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isTablet ? 30 : 20),
              _buildHistorySection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeCard({
    required BuildContext context,
    required String title,
    required String time,
    required Color bgColor,
    required Color textColor,
    bool isCheckIn = false,
    String? subText,
  }) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return GestureDetector(
      onTap: title == "Check In"
          ? (isCheckedIn
                ? null
                : _showCheckInDialog) // Disable Check In if already checked in
          : title == "Check Out"
          ? () async {
              if (!isCheckedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please Check In first to Check Out"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // 1. Navigate to Checkout Screen
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CheckoutScreen()),
              );

              // 2. If Checkout Successful or Reset Requested
              if (result == "RESET") {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('is_marketing_checked_in');
                await prefs.remove('marketing_check_in_time');
                await prefs.remove('marketing_check_in_full_time');

                setState(() {
                  isCheckedIn = false;
                  _checkInFullDateTime = null;
                  activeDuration = "00:00:00";
                  checkInTime = "00.00.00";
                  // Only clear check-in state, but KEEP history or update it as cancelled?
                  // User wanted to re-check in, so maybe we don't clear history fully,
                  // but for the "No open check-in" error, "In Progress" item is invalid.
                  history = history
                      .where((item) => item['status'] != "In Progress")
                      .toList();
                  _saveHistory(history);
                });
              } else if (result == true) {
                final prefs = await SharedPreferences.getInstance();

                // Clear Check-in State
                await prefs.remove('is_marketing_checked_in');
                await prefs.remove('marketing_check_in_time');
                await prefs.remove('marketing_check_in_full_time');

                if (!mounted || !context.mounted) return;
                String currentCheckOutTime = TimeOfDay.now().format(context);

                setState(() {
                  // Update ALL "In Progress" items to "Completed"
                  history = history.map((item) {
                    if (item['status'] == "In Progress") {
                      return {
                        "company": "Smart Global Solution",
                        "time": "${item['time']} – $currentCheckOutTime",
                        "status": "Completed",
                        "statusColor": const Color(0xff3CA80A),
                      };
                    }
                    return item;
                  }).toList();

                  // Reset UI State
                  isCheckedIn = false;
                  _checkInFullDateTime = null;
                  activeDuration = "00:00:00";
                  // checkInTime = "00.00.00"; // Optional: keep or reset
                  checkOutTime = currentCheckOutTime;

                  _saveHistory(history);
                });
              }
            }
          : null,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 10,
          vertical: isTablet ? 12 : 6,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            const BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            SizedBox(height: isTablet ? 7 : 6),
            Text(
              time,
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            if (subText != null) ...[
              const SizedBox(height: 4),
              Text(
                subText,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: textColor.withOpacity(0.8),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: isTablet ? 18 : 14),
          child: Text(
            "History",
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (history.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Center(
              child: Text(
                "No Check-in History Today",
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
              ),
            ),
          )
        else
          ...history.map(
            (item) => _historyCard(
              context,
              company: item["company"],
              remarks: item["remarks"] ?? "No Remarks",
              date: item["date"] ?? "",
              time: item["time"],
              status: item["status"],
              statusColor: item["statusColor"],
            ),
          ),
      ],
    );
  }

  String _formatTime12Hour(String time24) {
    try {
      if (time24.contains("–")) {
        // Handle range like "10:00:00 – 11:00:00"
        final parts = time24.split("–");
        final start = _formatTime12Hour(parts[0].trim());
        final end = _formatTime12Hour(parts[1].trim());
        return "$start – $end";
      }

      final parts = time24.split(':');
      if (parts.length < 2) return time24;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final period = hour >= 12 ? 'PM' : 'AM';
      var hour12 = hour % 12;
      if (hour12 == 0) hour12 = 12;

      return "$hour12:${minute.toString().padLeft(2, '0')} $period";
    } catch (e) {
      return time24;
    }
  }

  Widget _historyCard(
    BuildContext context, {
    required String company,
    required String remarks,
    required String date,
    required String time,
    required String status,
    required Color statusColor,
  }) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 18 : 14),
      margin: EdgeInsets.only(bottom: isTablet ? 18 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [
          BoxShadow(color: Colors.black12, offset: Offset(0, 3), blurRadius: 8),
        ],
      ),
      child: _buildHistoryItem(
        context: context,
        company: company,
        remarks: remarks,
        date: date,
        time: _formatTime12Hour(time),
        status: status,
        statusColor: statusColor,
      ),
    );
  }

  Widget _buildHistoryItem({
    required BuildContext context,
    required String company,
    required String remarks,
    required String date,
    required String time,
    required String status,
    required Color statusColor,
  }) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    String assetPath = status == "Completed"
        ? "assets/completed.png"
        : "assets/progress.png";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isTablet ? 24 : 20,
          height: isTablet ? 24 : 20,
          margin: EdgeInsets.only(
            top: isTablet ? 4 : 2,
            right: isTablet ? 16 : 12,
          ),
          child: Image.asset(
            assetPath,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                status == "Completed" ? Icons.check_circle : Icons.timelapse,
                color: statusColor,
              );
            },
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                company,
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Remarks
              SizedBox(height: isTablet ? 6 : 4),
              Text(
                remarks,
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 14 : 12,
                  color: Colors.black87,
                ),
              ),
              // Date
              SizedBox(height: isTablet ? 6 : 4),
              Text(
                date,
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 14 : 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              // Time
              SizedBox(height: isTablet ? 6 : 4),
              Text(
                time,
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 14 : 12,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: isTablet ? 8 : 6),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 12 : 8,
                  vertical: isTablet ? 4 : 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 12 : 10,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
