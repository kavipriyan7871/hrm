import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrm/views/home/settings.dart';
import 'package:hrm/views/home_screen/employee_detail.dart';
import 'package:hrm/views/home_screen/performance.dart';
import 'package:hrm/views/home_screen/reports.dart';

import 'leave_management.dart';
import 'marketing_checkin.dart';
import 'notification.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String userName = "User";

  @override
  void initState() {
    super.initState();
    _loadEmployeeName();
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
            Text(
              "Your Task",
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.w700,
              ),
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
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF1B2C61),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "92%",
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Image.asset(
            "assets/progress_bar.png",
            width: double.infinity,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 12),
          Text(
            "Allmost all assigned tasks completed on time",
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
          Image.asset(
            "assets/progress_bar.png",
            width: double.infinity,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 12),
          Text(
            "90% Completed",
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
        children: [
          Row(
            children: [
              Image.asset("assets/casual_leave.png", height: 60, width: 60),
              const SizedBox(width: 12),
              Text(
                "Casual Leave:\nTaken: 0 Day\nBalance: 12 Days",
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Image.asset("assets/casual_leave.png", height: 60, width: 60),
              const SizedBox(width: 12),
              Text(
                "Medical Leave:\nTaken: 0 Day\nBalance: 12 Days",
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}