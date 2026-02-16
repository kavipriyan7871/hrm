import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'marketing_checkout.dart'; // Restore this import
import '../../models/marketing_api.dart';
import '../../models/employee_api.dart';
import '../../services/user_data_manager.dart';

class MarketingScreen extends StatefulWidget {
  const MarketingScreen({super.key});

  @override
  State<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends State<MarketingScreen> {
  bool isCheckedIn = false;
  bool isLoading = false;
  String checkInTime = "00.00.00";
  String checkOutTime = "00.00.00";
  List<Map<String, dynamic>> history = [];
  String? employeeTableId;
  bool _isEmpLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCheckInState(); // Load cached data first for instant display
    _loadEmployeeDetails(); // This will trigger API fetch for fresh data
  }

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
      // Even if stored, try to refresh history
      _fetchHistoryFromApi();
      return;
    }

    // If not found, fetch from API
    // Robust UID retrieval
    var uidRaw = prefs.get('uid');
    String loginUid = "0";
    if (uidRaw != null) {
      loginUid = uidRaw.toString();
    }

    // Trust loginUid as employeeTableId if valid
    if (loginUid != "0") {
      setState(() {
        employeeTableId = loginUid;
      });
      // Don't return, allow fetching details to confirm, but trigger history fetch NOW
      _fetchHistoryFromApi();
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

        // If ID wasn't set before (loginUid was 0), update it now
        if (employeeTableId == null || employeeTableId == "0") {
          String? apiId = (data["uid"] ?? data["id"])?.toString();
          if (apiId != null) {
            setState(() => employeeTableId = apiId);
            _fetchHistoryFromApi();
          }
        }

        debugPrint("Employee Details Fetched for $loginUid");
      }
    } catch (e) {
      debugPrint("Employee fetch error => $e");
    } finally {
      if (mounted) setState(() => _isEmpLoading = false);
    }
  }

  Future<void> _fetchHistoryFromApi() async {
    debugPrint("🌐 Fetching fresh marketing history from API/Database...");

    // Get saved location or use defaults
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('lat')?.toString() ?? "145";
    final lng = prefs.getDouble('lng')?.toString() ?? "145";
    final deviceId = "12345"; // As per user request

    if (employeeTableId == null || employeeTableId == "0") {
      debugPrint(
        "⚠️ Employee ID not set ($employeeTableId), skipping history fetch",
      );
      // Try to load again if missed
      if (mounted && (employeeTableId == null)) {
        _loadEmployeeDetails();
      }
      return;
    }

    debugPrint(
      "🔍 API Request Params: UID=$employeeTableId, Lat=$lat, Lng=$lng, Device=$deviceId",
    );

    try {
      final res = await MarketingApi.fetchHistory(
        uid: employeeTableId!,
        cid: "21472147",
        lat: lat,
        lng: lng,
        deviceId: deviceId,
        type: "2062",
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
                  "company": e["company"],
                  "remarks": e["remarks"] ?? "No Remarks",
                  "date": e["date"] ?? "",
                  "time": e["time"],
                  "status": e["status"],
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
            setState(() => isLoading = false);
          }
          return;
        }
      }

      // 1. Call API
      final response = await MarketingApi.checkIn(
        uid: employeeTableId!, // Use employeeTableId

        cid: "21472147",
        deviceId: "123456",
        lat: lat,
        lng: lng,
        type: "2054",
      );

      print("CheckIn API Response: $response");

      // 2. Handle Response
      if (response['error'] == false) {
        String time = "00.00.00";
        if (response['data'] != null &&
            response['data']['check_in_time'] != null) {
          time = response['data']['check_in_time'];
        } else if (response['live_date'] != null) {
          time = response['live_date'].toString().split(' ').last;
        } else {
          time = TimeOfDay.now().format(context);
        }

        // 3. Save State
        await prefs.setBool('is_marketing_checked_in', true);
        await prefs.setString('marketing_check_in_time', time);

        // 4. Update UI
        setState(() {
          isCheckedIn = true;
          checkInTime = time;
          checkOutTime = "00.00.00";

          // Add to history
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
          String time = TimeOfDay.now().format(
            context,
          ); // Fallback or parse from msg
          await prefs.setBool('is_marketing_checked_in', true);
          await prefs.setString('marketing_check_in_time', time);

          setState(() {
            isCheckedIn = true;
            checkInTime = time;
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
                      title: "Check In",
                      time: isCheckedIn ? checkInTime : "00.00.00",
                      isCheckIn: true,
                      bgColor: isCheckedIn
                          ? const Color(0xFF66BE2F)
                          : const Color(0xFFDBDBDB),
                      textColor: isCheckedIn
                          ? Colors.white
                          : const Color(0xff1B2C61),
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

                setState(() {
                  isCheckedIn = false;
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
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withOpacity(0.4)),
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
