import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:intl/intl.dart';

import 'monthly_history.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  int selectedTab = 0;
  bool isLoading = false;
  Map<String, dynamic>? stats;
  List<dynamic> attendanceList = [];

  // Current Week Logic
  DateTime now = DateTime.now();
  late DateTime startOfWeek;
  late DateTime endOfWeek;

  // API Params
  String cid = "21472147";
  int uid = 0;
  String? deviceId;
  String userName = "User";
  bool isCheckedIn = false;
  bool breakSwitch = false;

  // Mimic attendance.dart methods if needed or simplified

  @override
  void initState() {
    super.initState();
    // Calculate start of week (Monday)
    // DateTime.weekday: Mon=1 ... Sun=7
    startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    endOfWeek = startOfWeek.add(const Duration(days: 6));

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      cid = prefs.getString('cid') ?? "21472147";
      uid = prefs.getInt('uid') ?? 0;
      userName = prefs.getString('name') ?? "User";
      isCheckedIn = prefs.getBool('isCheckedIn') ?? false;
    });
    await _getDeviceId();
    _fetchWeeklyData();
  }

  Future<void> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor;
      }
    } catch (e) {
      deviceId = "unknown";
    }
  }

  Future<void> _fetchWeeklyData() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
        );
      } catch (e) {
        debugPrint("Location error: $e");
      }

      // We fetch data for the current month/year to get the records
      // API seemed to use month/year or just return list.
      // We will try sending month/year covering the week.
      // If week crosses months, might need two calls or API handles date range?
      // Assuming API handles "month" param.

      final body = {
        "type": "2064",
        "cid": cid,
        "uid": uid.toString(),
        "device_id": deviceId ?? "unknown",
        "lt": position?.latitude.toString() ?? "0.0",
        "ln": position?.longitude.toString() ?? "0.0",
        "month": startOfWeek.month.toString(),
        "year": startOfWeek.year.toString(),
        // Potentially add "from_date": startOfWeek... if API supports
      };

      debugPrint("Weekly Request: $body");

      final response = await http.post(
        Uri.parse("https://erpsmart.in/total/api/m_api/"),
        body: body,
      );

      final data = jsonDecode(response.body);
      if (data["error"] == false || data["error"] == "false") {
        setState(() {
          if (data["statistics"] != null) {
            stats = Map<String, dynamic>.from(data["statistics"]);
          }
          if (data["data"] != null) {
            attendanceList = List<dynamic>.from(data["data"]);
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching weekly data: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xffEFEFEF), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final teal = const Color(0xff00A79D);

    String dateRange =
        "${DateFormat('MMM d').format(startOfWeek)} – ${DateFormat('MMM d, y').format(endOfWeek)}";

    // Calculate Weekly Progress locally based on attendanceList
    // Get records within this week range
    int daysPresent = 0;
    int daysPassedInWeek = 0;

    // Days present
    daysPresent = attendanceList.where((record) {
      String dateStr = record["date"] ?? "";
      if (dateStr.isEmpty) return false;
      DateTime? rd = DateTime.tryParse(dateStr);
      if (rd == null) return false;
      // Check range
      if (rd.isBefore(startOfWeek) ||
          rd.isAfter(endOfWeek.add(const Duration(days: 1))))
        return false;

      String status = record["status"]?.toString().toLowerCase() ?? "";
      return status.contains("present") || status.contains("check out");
    }).length;

    // Days passed in week (denominator)
    // If current week: up to today (or end of week if past)
    // StartOfWeek is usually Monday.
    DateTime now = DateTime.now();
    if (now.isAfter(endOfWeek)) {
      daysPassedInWeek = 6; // Full week (assuming 6 days work week)
    } else if (now.isBefore(startOfWeek)) {
      daysPassedInWeek = 0; // Future
    } else {
      // Inside current week
      // difference in days + 1
      daysPassedInWeek = now.difference(startOfWeek).inDays + 1;
      if (daysPassedInWeek > 6) daysPassedInWeek = 6;
    }

    double progress = 0.0;
    if (daysPassedInWeek > 0) {
      progress = (daysPresent / daysPassedInWeek).clamp(0.0, 1.0);
    }

    return Scaffold(
      backgroundColor: const Color(0xffF5F7F8),
      appBar: AppBar(
        backgroundColor: teal,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          "Attendance History",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTapDown: (TapDownDetails details) {
                _showPopupMenu(context, details.globalPosition);
              },
              child: const Icon(Icons.more_vert, color: Colors.white),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(w * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: tabButton("Weekly", 0)),
                        const SizedBox(width: 8),
                        Expanded(child: tabButton("Monthly", 1)),
                      ],
                    ),
                  ),

                  SizedBox(height: h * 0.02),

                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: w * 0.04,
                      vertical: 14,
                    ),
                    decoration: cardDecoration(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_left),
                          onPressed: () {
                            setState(() {
                              startOfWeek = startOfWeek.subtract(
                                const Duration(days: 7),
                              );
                              endOfWeek = endOfWeek.subtract(
                                const Duration(days: 7),
                              );
                            });
                            _fetchWeeklyData();
                          },
                        ),
                        Text(
                          dateRange,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_right),
                          onPressed: () {
                            DateTime nextWeekStart = startOfWeek.add(
                              const Duration(days: 7),
                            );
                            if (nextWeekStart.isAfter(DateTime.now())) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Cannot navigate to future weeks",
                                  ),
                                ),
                              );
                              return;
                            }

                            setState(() {
                              startOfWeek = startOfWeek.add(
                                const Duration(days: 7),
                              );
                              endOfWeek = endOfWeek.add(
                                const Duration(days: 7),
                              );
                            });
                            _fetchWeeklyData();
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: h * 0.02),

                  /// STATS
                  Row(
                    children: [
                      Expanded(
                        child: statsBox(
                          "Total Hours",
                          stats != null && stats!["total_hours_worked"] != null
                              ? "${stats!["total_hours_worked"]}h"
                              : "0h",
                          valueColor: Colors.black,
                        ),
                      ),
                      SizedBox(width: w * 0.03),
                      Expanded(
                        child: statsBox(
                          "Overtime",
                          stats != null && stats!["overtime"] != null
                              ? stats!["overtime"].toString()
                              : "0h 00m",
                          valueColor: Colors.red,
                        ),
                      ),
                    ],
                  ),

                  // Logic moved up
                  Container(
                    decoration: cardDecoration(),
                    padding: EdgeInsets.all(w * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Attendance Progress",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
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
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          color: Colors.blue,
                          backgroundColor: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "$daysPresent of $daysPassedInWeek work days completed",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (now.isAfter(startOfWeek) &&
                                now.isBefore(
                                  endOfWeek.add(const Duration(days: 1)),
                                ) &&
                                daysPassedInWeek > 0)
                              Text(
                                "(Current Week)",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: h * 0.02),

                  /// DAY CARDS - Dynamic List
                  if (attendanceList.isEmpty)
                    const Center(child: Text("No records for this week"))
                  else
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: attendanceList.length,
                      itemBuilder: (context, index) {
                        final record = attendanceList[index];
                        final dateStr = record["date"] ?? "";

                        // Filter records for this week locally just in case
                        DateTime? recordDate;
                        try {
                          if (dateStr.isNotEmpty)
                            recordDate = DateTime.parse(dateStr);
                        } catch (e) {}

                        if (recordDate != null) {
                          // Check range
                          if (recordDate.isBefore(startOfWeek) ||
                              recordDate.isAfter(
                                endOfWeek.add(const Duration(days: 1)),
                              )) {
                            return const SizedBox.shrink(); // Skip
                          }
                        }

                        return attendanceCard(
                          day: recordDate != null
                              ? DateFormat('E').format(recordDate)
                              : "",
                          date: recordDate != null
                              ? DateFormat('d').format(recordDate)
                              : "",
                          status: record["status"] ?? "Present",
                          statusColor:
                              (record["status"] ?? "")
                                  .toString()
                                  .toLowerCase()
                                  .contains("absent")
                              ? Colors.red
                              : Colors.green,
                          leftColor:
                              (record["status"] ?? "")
                                  .toString()
                                  .toLowerCase()
                                  .contains("absent")
                              ? Colors.red
                              : Colors.green,
                          checkIn: record["in_time"],
                          checkOut: record["out_time"],
                          breakTime:
                              "0h 00m", // Assuming break info not in list or adjust
                          total: "${record["overall_hours"] ?? 0}h",
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  void _showPopupMenu(BuildContext context, Offset position) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: const [
              Icon(Icons.share, color: Color(0xff00A79D)),
              SizedBox(width: 12),
              Text(
                "Share",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'refresh',
          child: Row(
            children: const [
              Icon(Icons.refresh, color: Color(0xff00A79D)),
              SizedBox(width: 12),
              Text(
                "Refresh",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'share') {
      } else if (value == 'refresh') {
        _fetchWeeklyData();
      }
    });
  }

  /// TAB BUTTON
  Widget tabButton(String text, int index) {
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AttendanceMonthlyHistory()),
          );
        } else {
          setState(() => selectedTab = 0);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selectedTab == index
              ? const Color(0xff26A69A)
              : Colors.grey[300],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selectedTab == index ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// STATS BOX
  Widget statsBox(
    String title,
    String value, {
    Color valueColor = Colors.black,
  }) {
    return Container(
      decoration: cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget attendanceCard({
    required String day,
    required String date,
    required String status,
    required Color statusColor,
    required Color leftColor,
    String? checkIn,
    String? checkOut,
    String? breakTime,
    String? overtime,
    required String total,
  }) {
    final bool isSmaller = status == "Absent" || status == "Holiday";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: cardDecoration(),
      child: Row(
        children: [
          Container(
            width: isSmaller ? 5 : 6,
            height: isSmaller ? 95 : 120,
            decoration: BoxDecoration(
              color: leftColor,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(isSmaller ? 10 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "$day\n$date",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(color: statusColor, fontSize: 12),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "Total\n$total",
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  if (checkIn != null && checkIn.isNotEmpty) ...[
                    const SizedBox(height: 10),

                    const Divider(
                      thickness: 1,
                      height: 1,
                      color: Color(0xffE0E0E0),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        info("Check In", checkIn),
                        if (checkOut != null && checkOut.isNotEmpty)
                          info("Check Out", checkOut),
                        // info("Break", breakTime!), // Hiding breakTime if not available
                      ],
                    ),
                  ],

                  if (overtime != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        "⏱ Overtime: $overtime",
                        style: const TextStyle(
                          color: Colors.deepOrange,
                          fontSize: 12,
                        ),
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

  Widget info(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
