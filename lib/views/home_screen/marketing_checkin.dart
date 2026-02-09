import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'marketing_checkout.dart'; // Restore this import
import '../../models/marketing_api.dart';
import '../../models/employee_api.dart';

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
    _loadCheckInState();
    _loadEmployeeDetails();
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
      return;
    }

    // If not found, fetch from API
    final loginUid = (prefs.getInt('uid') ?? 0).toString();
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

        // Try 'id' first, then 'employee_code'
        var empId = data["id"]?.toString();
        if (empId == null || empId == "null" || empId.isEmpty) {
          empId = data["employee_code"]?.toString();
        }

        if (empId != null && empId != "null" && empId.isNotEmpty) {
          await prefs.setString('employee_table_id', empId);
          setState(() => employeeTableId = empId);
          debugPrint("Employee ID fetched: $empId");
        } else {
          debugPrint("CRITICAL: Employee ID missing in response: $res");
        }
      }
    } catch (e) {
      debugPrint("Employee fetch error => $e");
    } finally {
      if (mounted) setState(() => _isEmpLoading = false);
    }
  }

  Future<void> _loadCheckInState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isCheckedIn = prefs.getBool('is_marketing_checked_in') ?? false;
      checkInTime = prefs.getString('marketing_check_in_time') ?? "00.00.00";

      // Load History
      String? historyJson = prefs.getString('marketing_history');
      if (historyJson != null) {
        try {
          List<dynamic> loaded = jsonDecode(historyJson);
          history = loaded
              .map((e) {
                // Restore color which is not JSON serializable directly
                Color color = e['status'] == 'Completed'
                    ? const Color(0xff3CA80A)
                    : Colors.redAccent;
                return {
                  "company": e["company"],
                  "time": e["time"],
                  "status": e["status"],
                  "statusColor": color,
                };
              })
              .toList()
              .cast<Map<String, dynamic>>();
        } catch (e) {
          history = [];
        }
      } else {
        history = [];
      }
    });
  }

  Future<void> _saveHistory(List<Map<String, dynamic>> newHistory) async {
    final prefs = await SharedPreferences.getInstance();
    // Remove color objects before saving as they can't be JSON encoded
    List<Map<String, dynamic>> toSave = newHistory.map((e) {
      return {
        "company": e["company"],
        "time": e["time"],
        "status": e["status"],
        // "statusColor" will be re-assigned on load
      };
    }).toList();
    await prefs.setString('marketing_history', jsonEncode(toSave));
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
      body: SingleChildScrollView(
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
              time: item["time"],
              status: item["status"],
              statusColor: item["statusColor"],
            ),
          ),
      ],
    );
  }

  Widget _historyCard(
    BuildContext context, {
    required String company,
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
        time: time,
        status: status,
        statusColor: statusColor,
      ),
    );
  }

  Widget _buildHistoryItem({
    required BuildContext context,
    required String company,
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
