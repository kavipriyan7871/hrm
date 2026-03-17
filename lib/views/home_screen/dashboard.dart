import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrm/views/home/settings.dart';
import 'package:hrm/views/home_screen/employee_detail.dart';
import 'package:hrm/views/home_screen/performance.dart';
import 'package:hrm/views/home_screen/reports.dart';

import 'leave_management.dart';
import 'marketing_screen.dart';
import 'marketing_checkin.dart';
import 'tasks_list.dart';
import 'notification.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../chat/chat.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String userName = "User";
  double _monthlyRate = 0; // Completion rate for the current month

  // State for Assigned Tasks

  @override
  void initState() {
    super.initState();
    _loadEmployeeName();
    _fetchLeaveSummary();
    _fetchMonthlyPerformance();
  }

  // Helper structure to hold leave balance data
  List<Map<String, dynamic>> leaveBalanceData = [
    {"type": "Casual", "taken": 0, "total": 12, "balance": "12/12"},
    {"type": "Sick", "taken": 0, "total": 12, "balance": "12/12"},
    {"type": "Earned", "taken": 0, "total": 12, "balance": "12/12"},
    {"type": "Unpaid", "taken": 0, "total": null, "balance": "0/-"},
  ];

  Future<void> _fetchLeaveSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getInt('uid') ?? 1;
      final lat = prefs.getDouble('lat')?.toString() ?? "145";
      final lng = prefs.getDouble('lng')?.toString() ?? "145";

      final response = await http.post(
        Uri.parse("https://erpsmart.in/total/api/m_api/"),
        body: {
          "cid": prefs.getString('cid') ?? "",
          "device_id": prefs.getString('device_id') ?? "",
          "lt": lat,
          "ln": lng,
          "type": "2051",
          "uid": uid.toString(),
          "id": uid.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['error'] == false) {
          List<dynamic> apiList = [];
          if (data['leave_summary'] != null && data['leave_summary'] is List) {
            apiList = data['leave_summary'];
          } else if (data['data'] != null && data['data'] is List) {
            apiList = data['data'];
          }

          if (mounted) {
            setState(() {
              for (var staticItem in leaveBalanceData) {
                String staticType = staticItem['type'].toString().toLowerCase();
                var apiItem = apiList.firstWhere((api) {
                  String apiType =
                      (api['leave_type_name'] ??
                              api['leave_type'] ??
                              api['type'] ??
                              "")
                          .toString()
                          .toLowerCase();
                  if (staticType == "earned") {
                    return apiType.contains("privilege") ||
                        apiType.contains("earned");
                  }
                  if (staticType == "casual") return apiType.contains("casual");
                  if (staticType == "sick") {
                    return apiType.contains("medical") ||
                        apiType.contains("sick");
                  }
                  return apiType.contains(staticType);
                }, orElse: () => null);

                if (apiItem != null) {
                  int taken =
                      int.tryParse(
                        apiItem['leaves_taken_this_year']?.toString() ??
                            apiItem['leave_taken']?.toString() ??
                            "0",
                      ) ??
                      0;
                  int total =
                      int.tryParse(
                        apiItem['max_days_per_year']?.toString() ??
                            apiItem['total_allowed']?.toString() ??
                            "12",
                      ) ??
                      12;
                  staticItem['total'] = total;
                  staticItem['taken'] =
                      taken; // Temporary update, will be refined by history
                  staticItem['balance'] = "${total - taken}/$total";
                }
              }
            });
          }
        }
      }
      // Fetch history for accurate 'taken' count
      await _fetchLeaveHistory();
    } catch (e) {
      debugPrint("Error fetching leave summary: $e");
    }
  }

  Future<void> _fetchLeaveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getInt('uid') ?? 1;
      final empCode = prefs.getString('employee_code') ?? "";
      final lat = prefs.getDouble('lat')?.toString() ?? "145";
      final lng = prefs.getDouble('lng')?.toString() ?? "145";

      final response = await http.post(
        Uri.parse("https://erpsmart.in/total/api/m_api/"),
        body: {
          "cid": prefs.getString('cid') ?? "",
          "device_id": prefs.getString('device_id') ?? "",
          "lt": lat,
          "ln": lng,
          "type": "2052",
          "uid": uid.toString(),
          "id": uid.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> fetchedList = [];

        if (data is List) {
          fetchedList = data;
        } else if (data['leave_applications'] != null &&
            data['leave_applications'] is List) {
          fetchedList = data['leave_applications'];
        } else if (data['data'] != null && data['data'] is List) {
          fetchedList = data['data'];
        }

        if (empCode.isNotEmpty) {
          fetchedList = fetchedList
              .where(
                (item) => (item['employee_uid']?.toString() ?? "") == empCode,
              )
              .toList();
        }

        // Calculate Taken from History
        if (mounted) {
          setState(() {
            // Reset taken
            for (var b in leaveBalanceData) {
              b['taken'] = 0;
            }

            for (var h in fetchedList) {
              String status = (h['status'] ?? "0").toString().toLowerCase();
              // ✅ Only count APPROVED leaves in taken count
              bool isApproved =
                  status == "1" ||
                  status.contains("approv") ||
                  status.contains("accept");
              if (!isApproved) continue;

              // Check if it's unpaid/LOP
              String leaveTypeLower = (h['leave_type'] ?? h['reason'] ?? "")
                  .toString()
                  .toLowerCase();
              bool isLop =
                  leaveTypeLower.contains("unpaid") ||
                  leaveTypeLower.contains("lop") ||
                  leaveTypeLower.contains("loss of pay") ||
                  leaveTypeLower.contains("without pay");
              if (isLop) {
                num lopDays = 0;
                if (h['no_of_days'] != null) {
                  lopDays = num.tryParse(h['no_of_days'].toString()) ?? 0;
                } else if (h['total_days'] != null) {
                  lopDays = num.tryParse(h['total_days'].toString()) ?? 0;
                } else if (h['days'] != null) {
                  lopDays = num.tryParse(h['days'].toString()) ?? 0;
                } else {
                  lopDays = 1;
                }
                var unpaidItem = leaveBalanceData.firstWhere(
                  (b) => b['type'] == 'Unpaid',
                  orElse: () => <String, dynamic>{},
                );
                if (unpaidItem.isNotEmpty) {
                  unpaidItem['taken'] = (unpaidItem['taken'] as num) + lopDays;
                }
                continue;
              }

              num days = 0;
              if (h['no_of_days'] != null) {
                days = num.tryParse(h['no_of_days'].toString()) ?? 0;
              } else if (h['total_days'] != null) {
                days = num.tryParse(h['total_days'].toString()) ?? 0;
              } else if (h['days'] != null) {
                days = num.tryParse(h['days'].toString()) ?? 0;
              } else {
                days = 1;
              }

              String type = (h['leave_type'] ?? h['reason'] ?? "")
                  .toString()
                  .toLowerCase();

              for (var b in leaveBalanceData) {
                String bType = b['type'].toString().toLowerCase();
                bool match = false;
                if (bType == "earned") {
                  match = type.contains("privilege") || type.contains("earned");
                } else if (bType == "casual") {
                  match = type.contains("casual");
                } else if (bType == "sick") {
                  match = type.contains("medical") || type.contains("sick");
                } else {
                  match = type.contains(bType);
                }

                if (match) {
                  b['taken'] = (b['taken'] as num) + days;
                  break;
                }
              }
            }

            // Update Balance Strings
            for (var b in leaveBalanceData) {
              num total = b['total'] ?? 12;
              num taken = b['taken'];
              b['balance'] = "${total - taken}/$total";
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching leave history: $e");
    }
  }

  Future<void> _fetchMonthlyPerformance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cid = prefs.getString('cid') ?? "";
      final String uid = (prefs.getInt('uid') ?? 0).toString();
      final String deviceId = prefs.getString('device_id') ?? "";
      final String lat = prefs.getDouble('lat')?.toString() ?? "145";
      final String lng = prefs.getDouble('lng')?.toString() ?? "145";
      final String? token = prefs.getString('token');

      DateTime now = DateTime.now();
      String fromDate = DateFormat('yyyy-MM-01').format(now);
      String toDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime(now.year, now.month + 1, 0));

      final response = await http.post(
        Uri.parse("https://erpsmart.in/total/api/m_api/"),
        body: {
          "type": "2075",
          "cid": cid,
          "uid": uid,
          "device_id": deviceId,
          "lt": lat,
          "ln": lng,
          "token": token ?? "",
          "from_date": fromDate,
          "to_date": toDate,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['error'] == false && data['summary'] != null) {
          int total = data['summary']['total'] ?? 0;
          int completed = data['summary']['completed'] ?? 0;
          setState(() {
            _monthlyRate = total == 0 ? 0 : (completed / total) * 100;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching monthly performance: $e");
    }
  }

  Future<void> _loadEmployeeName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('name') ?? "User";
    });
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;

    bool isTablet = w >= 600 && w < 1024;
    bool isDesktop = w >= 1024;

    double padding = w * 0.04;
    double boxRadius = w * 0.03;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        elevation: 0,
        title: Text(
          "Welcome $userName",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: isTablet
                ? 26
                : isDesktop
                ? 28
                : 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, size: w * 0.07, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsScreen()),
              );
            },
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatProjectsScreen(),
                ),
              );
            },
            icon: Image.asset(
              "assets/icons/announcement.png",
              color: Colors.white,
              width: isTablet ? 30 : 25,
              height: isTablet ? 30 : 25,
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationApp()),
              );
            },
            icon: Icon(
              Icons.notifications_none,
              color: Colors.white,
              size: isTablet ? 30 : 26,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your HR Management Hub",
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 22 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: h * 0.02),

            LayoutBuilder(
              builder: (context, constraints) {
                double boxWidth = (constraints.maxWidth - 12) / 2;

                return Column(
                  children: [
                    Row(
                      children: [
                        menuBox(
                          context,
                          boxWidth,
                          "Employee",
                          "assets/businessman.png",
                          const LinearGradient(
                            colors: [Colors.white, Color(0xFFFAFFB8)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        const SizedBox(width: 12),
                        menuBox(
                          context,
                          boxWidth,
                          "Leave",
                          "assets/leave.png",
                          const LinearGradient(
                            colors: [Colors.white, Color(0xFFA3DCFF)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: h * 0.02),

                    Row(
                      children: [
                        menuBox(
                          context,
                          boxWidth,
                          "Marketing",
                          "assets/marketing.png",
                          const LinearGradient(
                            colors: [
                              Colors.white,
                              Color.fromRGBO(255, 202, 141, 0.75),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        const SizedBox(width: 12),
                        menuBox(
                          context,
                          boxWidth,
                          "Performance",
                          "assets/performance.png",
                          const LinearGradient(
                            colors: [
                              Colors.white,
                              Color.fromRGBO(255, 152, 154, 0.53),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: h * 0.02),

                    menuBox(
                      context,
                      constraints.maxWidth,
                      "Reports",
                      "assets/reports.png",
                      const LinearGradient(
                        colors: [Colors.white, Color(0xFFAEFFE3)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      isFullWidth: true,
                    ),
                  ],
                );
              },
            ),

            SizedBox(height: h * 0.02),

            Container(
              padding: EdgeInsets.all(w * 0.03),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2C61),
                borderRadius: BorderRadius.circular(boxRadius),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.campaign,
                    color: Colors.white,
                    size: isTablet ? 36 : 30,
                  ),
                  SizedBox(width: w * 0.03),
                  Expanded(
                    child: Text(
                      "Company Announcement\nNew HR policy updates available.",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: isTablet ? 18 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1B2C61),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {},
                    child: Text(
                      "View",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isTablet ? 16 : 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: h * 0.02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Your Task",
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TasksListScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.arrow_circle_right_outlined,
                    color: Color(0xFF26A69A),
                    size: 28,
                  ),
                ),
              ],
            ),
            SizedBox(height: h * 0.01),
            taskCard(),

            SizedBox(height: h * 0.02),
            Text(
              "Your Target",
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: h * 0.01),
            targetBox(),

            SizedBox(height: h * 0.02),
            Container(
              padding: EdgeInsets.all(w * 0.04),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFF24D7B3)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(boxRadius),
                boxShadow: const [
                  BoxShadow(
                    offset: Offset(0, 10),
                    blurRadius: 5,
                    color: Colors.black12,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Image.asset(
                    "assets/frame.png",
                    height: isTablet ? 90 : 70,
                    width: isTablet ? 50 : 35,
                  ),
                  SizedBox(width: w * 0.04),
                  Expanded(
                    child: Text(
                      "Almost there! Push through the last 25% and claim your success!!",
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 18 : 14,
                        color: const Color(0xff1B2C61),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: h * 0.02),
            Text(
              "Leave Reports",
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: h * 0.01),
            leaveReport(),
            SizedBox(height: h * 0.03),
          ],
        ),
      ),
    );
  }

  Widget menuBox(
    BuildContext context,
    double width,
    String title,
    String asset,
    Gradient gradient, {
    bool isFullWidth = false,
  }) {
    double w = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () {
        if (title == "Employee") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EmployeeDetailsScreen(),
            ),
          );
        } else if (title == "Marketing") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MarketingScreen()),
          );
        } else if (title == "Performance") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PerformanceScreen()),
          );
        } else if (title == "Reports") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ReportsScreen()),
          );
        } else if (title == "Leave") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LeaveManagementScreen()),
          );
        }
      },
      child: Container(
        width: width,
        padding: EdgeInsets.all(isFullWidth ? w * 0.06 : w * 0.03),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(w * 0.03),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: isFullWidth
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(asset, height: w * 0.15),
                  SizedBox(width: w * 0.04),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: w * 0.06,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Image.asset(asset, height: w * 0.12),
                  SizedBox(height: w * 0.02),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: w * 0.035,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget taskCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 10),
            blurRadius: 6,
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Task Completion Rate",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              // const Icon(
              //   Icons.arrow_forward_ios,
              //   size: 16,
              //   color: Color(0xFF1B2C61),
              // ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "${_monthlyRate.toStringAsFixed(0)}%",
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              return _buildDashboardProgressBar(
                progress: _monthlyRate / 100,
                color: const Color(0xFF26A69A),
                width: constraints.maxWidth,
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            _monthlyRate >= 80
                ? "Excellent performance! Keep it up!"
                : (_monthlyRate >= 50
                      ? "Good progress, keep pushing!"
                      : "Tasks need more focus this month."),
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget targetBox() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 10),
            blurRadius: 10,
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset("assets/target.png", height: 25, width: 25),
              const SizedBox(width: 8),
              Text(
                "Your Target Completion",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              return _buildDashboardProgressBar(
                progress: _monthlyRate / 100,
                color: const Color(0xffEC6E2D),
                width: constraints.maxWidth,
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            "${_monthlyRate.toStringAsFixed(0)}% Completed",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xffEC6E2D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardProgressBar({
    required double progress,
    required Color color,
    required double width,
  }) {
    const double barHeight = 10;
    const double iconSize = 24;

    return SizedBox(
      height: iconSize,
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          Container(
            height: barHeight,
            width: width,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(barHeight / 2),
            ),
          ),
          Container(
            height: barHeight,
            width: width * (progress > 1 ? 1 : (progress < 0 ? 0 : progress)),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(barHeight / 2),
            ),
          ),
          Positioned(
            left:
                (width * (progress > 1 ? 1 : (progress < 0 ? 0 : progress))) -
                (iconSize / 2),
            child: Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.local_fire_department,
                  size: 14,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget leaveReport() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 10),
            blurRadius: 10,
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        children: leaveBalanceData
            .where(
              (item) =>
                  item['type'] == 'Casual' ||
                  item['type'] == 'Sick' ||
                  item['type'] == 'Unpaid',
            )
            .map((item) {
              String displayType;
              String asset = "assets/casual_leave.png";
              if (item['type'] == "Sick") {
                displayType = "Medical Leave";
              } else if (item['type'] == "Unpaid") {
                displayType = "Unpaid Leave (LOP)";
              } else {
                displayType = "${item['type']} Leave";
              }

              num taken = item['taken'] as num;
              String balanceLine;
              if (item['type'] == 'Unpaid') {
                balanceLine = "LOP Days: $taken";
              } else {
                num total = item['total'] as num? ?? 12;
                num bal = (total - taken).clamp(0, total);
                balanceLine = "Balance: $bal / $total Days";
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Row(
                  children: [
                    Image.asset(
                      asset,
                      height: 60,
                      width: 60,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.event_busy,
                        size: 48,
                        color: Color(0xFF26A69A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "$displayType:\nTaken: $taken Day\n$balanceLine",
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            })
            .toList(),
      ),
    );
  }
}
