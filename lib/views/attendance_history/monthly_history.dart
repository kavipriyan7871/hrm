import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AttendanceMonthlyHistory extends StatefulWidget {
  const AttendanceMonthlyHistory({super.key});

  @override
  State<AttendanceMonthlyHistory> createState() => _AttendanceMonthlyHistoryState();
}

class _AttendanceMonthlyHistoryState
    extends State<AttendanceMonthlyHistory> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  final List<String> months = [
    "Jan","Feb","Mar","Apr","May","Jun",
    "Jul","Aug","Sep","Oct","Nov","Dec"
  ];

  void _nextMonth() {
    setState(() {
      if (selectedMonth == 12) {
        selectedMonth = 1;
        selectedYear++;
      } else {
        selectedMonth++;
      }
    });
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

            /// Drag Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 12),

            /// Title
            const Text(
              "Select Month",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),
            const Divider(),

            /// MONTH LIST
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
                        fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
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

    return Scaffold(
      backgroundColor: const Color(0xffF5F7F8),
      appBar: AppBar(
        backgroundColor: Color(0xff00A79D),
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
          )
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
              padding:
              EdgeInsets.symmetric(horizontal: w * 0.04, vertical: 14),
              decoration: cardDecoration(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Icon(Icons.arrow_left),
                  Row(
                    children: [
                      Icon(Icons.calendar_month, size: 18),
                      SizedBox(width: 6),
                      Text(
                        "Jan 2026",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_right),
                ],
              ),
            ),

            SizedBox(height: h * 0.02),

            /// STATS ROW
            Row(
              children: [
                Expanded(child: _statsBox("Total Hours", "165h 30m")),
                SizedBox(width: w * 0.03),
                Expanded(
                    child: _statsBox("Over Time", "8h 30m",
                        valueColor: Colors.red)),
                SizedBox(width: w * 0.03),
                Expanded(child: _statsBox("Days Present", "15/20")),
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
                    children: const [
                      Text(
                        "Attendance Progress",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "75%",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: 0.75,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade300,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "15 of 20 work days completed",
                    style:
                    TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),

                  _calendarHeader(),
                  const SizedBox(height: 14),

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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,color: Colors.black),
            ),

            SizedBox(height: h * 0.015),

            _weekCard("Week 1", "Jan 1 - Jan 6", "38h 00m", "5/6"),
            _weekCard("Week 2", "Jan 8 - Jan 13", "38h 00m", "5/6"),
            _weekCard("Week 3", "Jan 14 - Jan 19", "38h 00m", "5/6"),
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
        Rect.fromPoints(
          position,
          position,
        ),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      items: [
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: const [
              Icon(Icons.share, color: Color(0xff00A79D)),
              SizedBox(width: 12),
              Text("Share",
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'refresh',
          child: Row(
            children: const [
              Icon(Icons.refresh, color: Color(0xff00A79D)),
              SizedBox(width: 12),
              Text("Refresh",
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'share') {
        // TODO: Share logic
      } else if (value == 'refresh') {
        // TODO: Refresh logic
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
  Widget _statsBox(String title, String value,
      {Color valueColor = Colors.black}) {
    return Container(
      decoration: cardDecoration(),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Text(title,
              textAlign: TextAlign.center,
              style:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: valueColor),
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
          onPressed: _previousMonth,
        ),

        const SizedBox(width: 12),

        _dropdownBox(
          months[selectedMonth - 1],
              () => _showMonthPicker(),
        ),

        const SizedBox(width: 8),

        /// YEAR DROPDOWN
        _dropdownBox(
          selectedYear.toString(),
              () => _showYearPicker(),
        ),

        const SizedBox(width: 12),

        /// NEXT MONTH
        IconButton(
          icon: const Icon(Icons.chevron_right),
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
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
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ),
      )
          .toList(),
    );
  }

  Widget _calendarGrid() {
    final days = [
      "", "", "", "", "", "",
      "1", "2", "3", "4", "5", "6",
      "7", "8", "9", "10", "11", "12", "13",
      "14", "15", "16", "17", "18", "19", "20",
      "21", "22", "23", "24", "25", "26", "27",
      "28", "29", "30", "1", "2", "3", "4",
    ];

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
        final isDisabled = index >= 34; // next month dates

        return Center(
          child: Text(
            days[index],
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDisabled ? Colors.grey.shade400 : Colors.black,
            ),
          ),
        );
      },
    );
  }

  Widget _calendarLegend() {
    return Row(
      children: [
        _legendItem(Colors.grey.shade300, "Present"),
        const SizedBox(width: 20),
        _legendItem(Colors.grey.shade300, "Absent"),
      ],
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  Widget _weekCard(
      String week,
      String range,
      String hours,
      String present,
      ) {
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
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

                  /// FOOTER STATS
                  Row(
                    children: [
                      /// TOTAL HOURS
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Total Hours",
                                  style: TextStyle(
                                      fontSize: 12,fontWeight: FontWeight.w600, color: Colors.grey),
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

                      /// DAYS PRESENT
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Day Present",
                                  style: TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w600,color: Colors.grey),
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
