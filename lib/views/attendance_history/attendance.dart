import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'weekly_history.dart';
import 'check_in.dart';
import 'check_out.dart';
import '../main_root.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  AttendanceScreenState createState() => AttendanceScreenState();
}

class AttendanceScreenState extends State<AttendanceScreen> {
  bool breakSwitch = false;
  int bottomNavIndex = 1;
  int selectedTab = 1; // Default to Monthly as per typical dashboard usage here
  bool isCheckedIn = false;
  Timer? breakTimer;
  Duration breakDuration = Duration.zero;
  bool isLoading = false;
  int uid = 4; // User ID
  String userName = "User";
  String breakPurpose = "Tea"; // Default/Sample purpose
  final TextEditingController purposeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUid();
  }

  Future<void> _loadUid() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      uid = prefs.getInt('uid') ?? 4;
      isCheckedIn = prefs.getBool('isCheckedIn') ?? false;
      userName = prefs.getString('name') ?? "User";
    });
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

    // API REMOVED: Simulation success
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      breakSwitch = true;
      isLoading = false;
    });
    startBreakTimer();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Break started successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Handle Break Out API Call
  Future<void> handleBreakOut() async {
    setState(() {
      isLoading = true;
    });

    // API REMOVED: Simulation success
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      breakSwitch = false;
      isLoading = false;
      breakPurpose = "Tea"; // Reset for next time
    });
    stopBreakTimer();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Break ended successfully'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
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
          const Icon(Icons.trending_up_outlined, size: 22, color: Colors.black),
        ],
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
          Row(
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
              const Text(
                "Today Work Progress Report",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
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
            Row(
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
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
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
                if (!isCheckedIn) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please check-in first to start/end break'),
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
            Row(
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
                Text(
                  isLoading
                      ? "Processing..."
                      : breakSwitch
                      ? "Break Out (${formatDuration(breakDuration)})"
                      : "Break In (${formatDuration(breakDuration)})",
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            if (!isLoading)
              Switch(
                value: breakSwitch,
                activeColor: const Color(0xffD9D9D9),
                activeTrackColor: const Color(0xff1B2C61),
                inactiveThumbColor: const Color(0xffD9D9D9),
                inactiveTrackColor: Colors.grey.shade500,
                onChanged: (value) async {
                  if (!isCheckedIn) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please check-in first to start/end break',
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
                    "38h 30m",
                    valueColor: Colors.black,
                  ),
                ),
                SizedBox(width: w * 0.03),
                Expanded(
                  child: statsBox("Overtime", "2h 15m", valueColor: Colors.red),
                ),
              ],
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: monthlyStatBox("Day Worked", "22")),
                    SizedBox(width: w * 0.03),
                    Expanded(
                      child: monthlyStatBox(
                        "Leave Taken",
                        "2",
                        highlight: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: h * 0.02),
                Row(
                  children: [
                    Expanded(child: monthlyStatBox("LOP", "2")),
                    SizedBox(width: w * 0.03),
                    Expanded(
                      child: monthlyStatBox(
                        "Overtime",
                        "2h 15m",
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
            children: const [
              Text(
                "Attendance Progress",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Text(
                "4/6 days",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: h * 0.01),
          Image.asset(
            "assets/attendance_progress.png",
            width: double.infinity,
            fit: BoxFit.contain,
          ),
          SizedBox(height: h * 0.01),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "This week",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "80%",
                style: TextStyle(
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