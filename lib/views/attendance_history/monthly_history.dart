import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:intl/intl.dart';

class AttendanceMonthlyHistory extends StatefulWidget {
  const AttendanceMonthlyHistory({super.key});

  @override
  State<AttendanceMonthlyHistory> createState() =>
      _AttendanceMonthlyHistoryState();
}

class _AttendanceMonthlyHistoryState extends State<AttendanceMonthlyHistory> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  bool isLoading = false;
  Map<String, dynamic>? stats;
  List<dynamic> attendanceList = [];

  // API Params
  String cid = "21472147";
  int uid = 0;
  String? deviceId;

  final List<String> months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      cid = prefs.getString('cid') ?? "21472147";
      uid = prefs.getInt('uid') ?? 0;
    });
    await _getDeviceId();
    _fetchMonthlyData();
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

  Future<void> _fetchMonthlyData() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
      attendanceList = [];
      stats = null;
    });

    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
        );
      } catch (e) {
        debugPrint("Location error: $e");
      }

      final body = {
        "type": "2064",
        "cid": cid,
        "uid": uid.toString(),
        "device_id": deviceId ?? "unknown",
        "lt": position?.latitude.toString() ?? "0.0",
        "ln": position?.longitude.toString() ?? "0.0",
        "month": selectedMonth.toString(),
        "year": selectedYear.toString(),
      };

      debugPrint("Monthly Request: $body");

      final response = await http.post(
        Uri.parse("https://erpsmart.in/total/api/m_api/"),
        body: body,
      );

      debugPrint("Monthly Response: ${response.body}");

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
      debugPrint("Error fetching monthly data: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _nextMonth() {
    // Check if next month is in the future
    DateTime now = DateTime.now();
    DateTime nextMonthDate;

    if (selectedMonth == 12) {
      nextMonthDate = DateTime(selectedYear + 1, 1);
    } else {
      nextMonthDate = DateTime(selectedYear, selectedMonth + 1);
    }

    if (nextMonthDate.isAfter(DateTime(now.year, now.month))) {
      // Don't navigate to future month
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot navigate to future months")),
      );
      return;
    }

    setState(() {
      if (selectedMonth == 12) {
        selectedMonth = 1;
        selectedYear++;
      } else {
        selectedMonth++;
      }
    });
    _fetchMonthlyData();
  }

  void _previousMonth() {
    setState(() {
      if (selectedMonth == 1) {
        selectedMonth = 12;
        selectedYear--;
      } else {
        selectedMonth--;
      }
    });
    _fetchMonthlyData();
  }

  void _showYearPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ListView.builder(
          itemCount: 20,
          itemBuilder: (context, index) {
            final year = DateTime.now().year - 10 + index;
            return ListTile(
              title: Text(year.toString()),
              onTap: () {
                setState(() => selectedYear = year);
                Navigator.pop(context);
                _fetchMonthlyData();
              },
            );
          },
        );
      },
    );
  }

  void _showMonthPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Select Month",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Divider(),
            Flexible(
              child: ListView.builder(
                itemCount: months.length,
                itemBuilder: (context, index) {
                  final isSelected = selectedMonth == index + 1;
                  return ListTile(
                    title: Text(
                      months[index],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? const Color(0xff26A69A)
                            : Colors.black,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xff26A69A),
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        selectedMonth = index + 1;
                      });
                      Navigator.pop(context);
                      _fetchMonthlyData();
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xffEFEFEF)),
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
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    // Calculate progress percentage
    double progress = 0.0;
    int daysPresent = 0;
    int totalWorkingDays = 0;

    // Calculate locally based on attendanceList and date logic
    // Days present: count from list
    daysPresent = attendanceList.where((record) {
      String status = record["status"]?.toString().toLowerCase() ?? "";
      return status.contains("present") || status.contains("check out");
    }).length;

    // 2. Calculate Total Working Days (Denominator)
    DateTime now = DateTime.now();
    int daysInMonth = DateUtils.getDaysInMonth(selectedYear, selectedMonth);

    if (selectedYear == now.year && selectedMonth == now.month) {
      // Current month: up to today
      totalWorkingDays = now.day;
    } else {
      // Past month: full month
      totalWorkingDays = daysInMonth;
    }

    if (totalWorkingDays > 0) {
      progress = (daysPresent / totalWorkingDays).clamp(0.0, 1.0);
    }

    return Scaffold(
      backgroundColor: const Color(0xffF5F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xff00A79D),
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
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _tabButton(
                            title: "Weekly",
                            isActive: false,
                            onTap: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _tabButton(
                            title: "Monthly",
                            isActive: true,
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: h * 0.02),

                  /// MONTH SELECTOR
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: w * 0.04,
                      vertical: 14,
                    ),
                    decoration: cardDecoration(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.calendar_month, size: 18),
                        const SizedBox(width: 6),
                        _calendarHeader(),
                      ],
                    ),
                  ),

                  SizedBox(height: h * 0.02),

                  /// STATS ROW
                  Row(
                    children: [
                      Expanded(
                        child: _statsBox(
                          "Total Hours",
                          stats != null && stats!["total_hours_worked"] != null
                              ? "${stats!["total_hours_worked"]}h"
                              : "0h",
                        ),
                      ),
                      SizedBox(width: w * 0.03),
                      Expanded(
                        child: _statsBox(
                          "Over Time",
                          stats?["overtime"]?.toString() ?? "0h",
                          valueColor: Colors.red,
                        ),
                      ),
                      SizedBox(width: w * 0.03),
                      Expanded(
                        child: _statsBox(
                          "Days Present",
                          // Using calculated daysPresent
                          daysPresent.toString(),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: h * 0.02),

                  /// PROGRESS
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
                          backgroundColor: Colors.grey.shade300,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 6),
                        const SizedBox(height: 6),
                        Text(
                          "$daysPresent of $totalWorkingDays work days completed",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: h * 0.02),

                  Container(
                    decoration: cardDecoration(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Calendar View",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _weekDaysRow(),
                        const SizedBox(height: 10),
                        _calendarGrid(),
                        const SizedBox(height: 16),
                        const Divider(),
                        _calendarLegend(),
                      ],
                    ),
                  ),

                  SizedBox(height: h * 0.02),

                  /// WEEKLY BREAKDOWN TITLE
                  const Text(
                    "Weekly Breakdown",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),

                  SizedBox(height: h * 0.015),

                  ..._buildWeeklyBreakdown(),
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
        // TODO: Share logic
      } else if (value == 'refresh') {
        _fetchMonthlyData();
      }
    });
  }

  /// TAB BUTTON
  Widget _tabButton({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xff26A69A) : Colors.grey[300],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// STATS BOX
  Widget _statsBox(
    String title,
    String value, {
    Color valueColor = Colors.black,
  }) {
    return Container(
      decoration: cardDecoration(),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _calendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: _previousMonth,
        ),
        const SizedBox(width: 12),
        _dropdownBox(months[selectedMonth - 1], () => _showMonthPicker()),
        const SizedBox(width: 8),

        /// YEAR DROPDOWN
        _dropdownBox(selectedYear.toString(), () => _showYearPicker()),
        const SizedBox(width: 12),

        /// NEXT MONTH
        IconButton(
          icon: const Icon(Icons.chevron_right),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: _nextMonth,
        ),
      ],
    );
  }

  Widget _dropdownBox(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _weekDaysRow() {
    const days = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days
          .map(
            (d) => SizedBox(
              width: 32,
              child: Text(
                d,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _calendarGrid() {
    // Generate days for the selected month
    final daysInMonth = DateUtils.getDaysInMonth(selectedYear, selectedMonth);
    final firstDay = DateTime(selectedYear, selectedMonth, 1);
    final firstWeekday = firstDay.weekday % 7;

    final List<String?> days = [];
    for (int i = 0; i < firstWeekday; i++) {
      days.add(null);
    }
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(i.toString());
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final dayStr = days[index];
        if (dayStr == null) return const SizedBox.shrink();

        // Check status for this day
        // Assuming date format in API is YYYY-MM-DD
        String dateKey =
            "$selectedYear-${selectedMonth.toString().padLeft(2, '0')}-${dayStr.padLeft(2, '0')}";

        bool isPresent = false;
        // bool isAbsent = false;

        // Find if any record exists for this date
        // API returns "date": "2026-02-10" or similar
        // Note: data list contains presence data
        final record = attendanceList.firstWhere(
          (element) => element["date"] == dateKey,
          orElse: () => null,
        );

        Color? statusColor;
        bool isFuture = false;

        DateTime currentDayDate = DateTime(
          selectedYear,
          selectedMonth,
          int.tryParse(dayStr) ?? 1,
        );
        if (currentDayDate.isAfter(DateTime.now())) {
          isFuture = true;
        }

        if (!isFuture && record != null) {
          // If record exists, assume present or check status
          statusColor = const Color(0xffD9F3EF); // Light Greenish
          isPresent = true;
        }

        return GestureDetector(
          onTap: () {
            if (!isFuture) {
              // Handle date selection if needed, e.g., show details
              debugPrint("Selected date: $dayStr");
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Cannot select future dates")),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                dayStr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isFuture
                      ? Colors.grey.shade300
                      : (isPresent ? Colors.black : Colors.black),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _calendarLegend() {
    return Row(
      children: [
        _legendItem(const Color(0xffD9F3EF), "Present"),
        const SizedBox(width: 20),
        _legendItem(Colors.red.shade100, "Absent"),
        const SizedBox(width: 20),
        _legendItem(Colors.orange.shade100, "Holiday"),
      ],
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  List<Widget> _buildWeeklyBreakdown() {
    if (attendanceList.isEmpty && !isLoading) {
      return [const Center(child: Text("No records found"))];
    }

    List<Widget> weekWidgets = [];
    int daysInMonth = DateUtils.getDaysInMonth(selectedYear, selectedMonth);
    int currentDay = 1;
    int weekNumber = 1;

    // Determine the offset for the first week based on month starting weekday
    // We want aligned full weeks or partial first week.
    // Let's iterate until month end.

    while (currentDay <= daysInMonth) {
      DateTime weekStart = DateTime(selectedYear, selectedMonth, currentDay);
      // Calculate remaining days in the week (assuming Sunday start like grid)
      // weekStart.weekday: Mon=1..Sun=7.
      // If our grid is Su Mo Tu...
      // Days from current weekday to next Saturday (which corresponds to index 6 in 0-6).
      // If Mon(1), we have Mon,Tue,Wed,Thu,Fri,Sat -> 6 days incl today.
      // If Sun(7), we have Sun...Sat -> 7 days.

      // Calculate weekEnd date
      // add daysLeftInWeek: if we are at Mon, add 6 days -> next Sunday? No.
      // If Mon(1), +6 days = Sun(7). But grid ends at Sat?
      // Grid: Su Mo Tu We Th Fr Sa
      // Check _weekDaysRow: Su Mo Tu We Th Fr Sa.
      // So Valid Week is Sun -> Sat.

      // If currentDay is NOT Sunday, it's a partial week from [currentDay -> next Sat].
      // If Mon(1), next Sat(6).
      // Diff: 6 - 1 = 5 days to add.
      // currentDay + 5.

      int offsetToSat = (weekStart.weekday == 7) ? 6 : (6 - weekStart.weekday);
      // Example Sun(7): offset 6. Sun+6 -> Sat. Correct.
      // Example Mon(1): offset 5. Mon+5 -> Sat. Correct.
      // Example Sat(6): offset 0. Sat+0 -> Sat. Correct.

      DateTime weekEnd = weekStart.add(Duration(days: offsetToSat));
      if (weekEnd.month != selectedMonth) {
        weekEnd = DateTime(selectedYear, selectedMonth, daysInMonth);
      }

      String range =
          "${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d').format(weekEnd)}";

      // Stats
      double totalHours = 0;
      int daysPresent = 0;
      int daysChecked = 0; // Number of days in this week range

      // Loop through range
      DateTime loopDate = weekStart;
      while (!loopDate.isAfter(weekEnd)) {
        daysChecked++;
        String dateKey = DateFormat('yyyy-MM-dd').format(loopDate);
        var record = attendanceList.firstWhere(
          (e) => e["date"] == dateKey,
          orElse: () => null,
        );
        if (record != null) {
          totalHours +=
              (double.tryParse(record["duration_decimal"]?.toString() ?? "0") ??
              0.0);
          String status = record["status"]?.toString().toLowerCase() ?? "";
          if (status.contains("present") || status.contains("check out")) {
            daysPresent++;
          }
        }
        loopDate = loopDate.add(const Duration(days: 1));
      }

      int h = totalHours.floor();
      int m = ((totalHours - h) * 60).round();
      bool isCompleted = weekEnd.isBefore(DateTime.now());

      weekWidgets.add(
        _weekCard(
          "Week $weekNumber",
          range,
          "${h}h ${m}m",
          "$daysPresent/$daysChecked",
          isCompleted: isCompleted,
        ),
      );

      currentDay = weekEnd.day + 1;
      weekNumber++;
    }

    return weekWidgets;
  }

  Widget _weekCard(
    String week,
    String range,
    String hours,
    String present, {
    bool isCompleted = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffEFEFEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 110,
            decoration: const BoxDecoration(
              color: Color(0xff26A69A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            week,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            range,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xffD9F3EF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Completed",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff26A69A),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Total Hours",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hours,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Day Present",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  present,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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
