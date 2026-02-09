import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'monthly_history.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  int selectedTab = 0;

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
      body: SingleChildScrollView(
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
              padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: 14),
              decoration: cardDecoration(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Icon(Icons.arrow_left),
                  Text(
                    "Jan 13 – Jan 19, 2026",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Icon(Icons.arrow_right),
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
                    "38h 30m",
                    valueColor: Colors.black,
                  ),
                ),
                SizedBox(width: w * 0.03),
                Expanded(
                  child: statsBox("Overtime", "2h 15m", valueColor: Colors.red),
                ),
              ],
            ),

            SizedBox(height: h * 0.02),

            Container(
              decoration: cardDecoration(),
              padding: EdgeInsets.all(w * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "Attendance Progress",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "4/6 days",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: 0.8,
                    minHeight: 8,
                    color: Colors.blue,
                    backgroundColor: Colors.grey.shade300,
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "This week",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "80%",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: h * 0.02),

            /// DAY CARDS
            attendanceCard(
              day: "Mon",
              date: "13",
              status: "Present",
              statusColor: Colors.green,
              leftColor: Colors.green,
              checkIn: "09:00 AM",
              checkOut: "06:00 PM",
              breakTime: "1h 00m",
              total: "8h 00m",
            ),

            attendanceCard(
              day: "Tue",
              date: "14",
              status: "Present",
              statusColor: Colors.green,
              leftColor: Colors.green,
              checkIn: "09:00 AM",
              checkOut: "06:00 PM",
              breakTime: "1h 00m",
              overtime: "2h 30m",
              total: "8h 00m",
            ),

            attendanceCard(
              day: "Wed",
              date: "15",
              status: "Absent",
              statusColor: Colors.red,
              leftColor: Colors.red,
              total: "8h 00m",
            ),

            attendanceCard(
              day: "Thu",
              date: "16",
              status: "Half day",
              statusColor: Colors.orange,
              leftColor: Colors.orange,
              checkIn: "01:00 PM",
              checkOut: "06:00 PM",
              breakTime: "1h 00m",
              total: "4h 00m",
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
      } else if (value == 'refresh') {}
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
                  if (checkIn != null) ...[
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
                        info("Check Out", checkOut!),
                        info("Break", breakTime!),
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
