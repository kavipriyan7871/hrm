import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double horizontalPadding = size.width * 0.04;
    final double cardPadding = size.width * 0.05;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Performance',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => const _CalendarDialog(),
                );
              },
              child: const Icon(Icons.calendar_month, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildSummaryCard(context, cardPadding),
            const SizedBox(height: 16),
            _buildTaskCompletionCard(context, cardPadding),
            const SizedBox(height: 16),
            _buildStatisticsCard(cardPadding),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, double padding) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Summary',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1B2C61),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Per Month Target- October',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1B2C61),
            ),
          ),
          const SizedBox(height: 16),

          /// CUSTOM PROGRESS BAR (GREEN)
          LayoutBuilder(
            builder: (context, constraints) {
              return _buildCustomProgressBar(
                progress: 0.8,
                color: const Color(0xFF34C759),
                thumbColor: const Color(0xFF34C759),
                width: constraints.maxWidth,
                isGradient: false,
              );
            },
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(
                Icons.thumb_up_alt_outlined,
                color: Color(0xFF34C759),
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                'Excellent',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF34C759),
                ),
              ),
              const Spacer(),
              Text(
                '80% Completed',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF34C759),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCompletionCard(BuildContext context, double padding) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task Completion',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1B2C61),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Per Day Task-5/11/2025',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1B2C61),
            ),
          ),
          const SizedBox(height: 16),

          /// CUSTOM PROGRESS BAR (ORANGE)
          LayoutBuilder(
            builder: (context, constraints) {
              return _buildCustomProgressBar(
                progress: 0.6,
                color: const Color(0xFFFF9500), // Orange
                thumbColor: const Color(0xFFFF9500),
                width: constraints.maxWidth,
                isGradient: true,
              );
            },
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '60% Progress',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFFF9500),
                ),
              ),
              Text(
                'Pending : 40%',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Completed',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1B2C61),
                ),
              ),
              Text(
                '60/100',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1B2C61),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(double padding) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          _buildStatRow('Completed', '60'),
          const SizedBox(height: 12),
          _buildStatRow('Pending', '40'),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 12),
          _buildStatRow('Total Task', '100'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomProgressBar({
    required double progress,
    required Color color,
    required Color thumbColor,
    required double width,
    bool isGradient = false,
  }) {
    const double barHeight = 10;
    const double iconSize = 24;

    // Gradient definition for the orange bar
    final Gradient? gradient = isGradient
        ? const LinearGradient(colors: [Color(0xFFE6A266), Color(0xFFD67D3E)])
        : null;

    return SizedBox(
      height: iconSize,
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          /// Background Track
          Container(
            height: barHeight,
            width: width,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(barHeight / 2),
            ),
          ),

          /// Active Progress Track
          Container(
            height: barHeight,
            width: width * progress,
            decoration: BoxDecoration(
              color: isGradient ? null : color,
              gradient: gradient,
              borderRadius: BorderRadius.circular(barHeight / 2),
            ),
          ),

          /// Icon Handle (Thumb)
          Positioned(
            left: (width * progress) - (iconSize / 2),
            child: Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isGradient
                      ? const Color(0xFFD67D3E)
                      : const Color(0xFF66BB6A),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.local_fire_department,
                  size: 14,
                  color: isGradient
                      ? const Color(0xFFD67D3E)
                      : const Color(0xFF66BB6A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarDialog extends StatefulWidget {
  const _CalendarDialog();

  @override
  State<_CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<_CalendarDialog> {
  final DateTime _currentDate = DateTime.now();
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(_currentDate.year, _currentDate.month);
  }

  int _daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int _firstDayOffset(DateTime date) {
    // DateTime.weekday returns 1 for Mon, 7 for Sun.
    // We want 0 for Sun, 1 for Mon... 6 for Sat.
    // So if weekday is 7 (Sun), return 0.
    final weekday = DateTime(date.year, date.month, 1).weekday;
    return weekday == 7 ? 0 : weekday;
  }

  String _monthName(int month) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3FB), // Light Lavender Background
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// NOTCHED HEADER
            SizedBox(
              height: 50,
              child: Stack(
                children: [
                  // Pink Header Bar
                  Container(
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD3405B),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                  ),
                  // White Notches (Simulated by circles matching background or white if that's the cut)
                  // The screenshot shows white semi-circles.
                  Positioned(
                    top: -12,
                    left: 40,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(
                          0xFFF3F3FB,
                        ), // Matches body bg to look like a cutout
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -12,
                    right: 40,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F3FB), // Matches body bg
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                children: [
                  /// Month Title
                  Text(
                    _monthName(_displayedMonth.month), // Real-time Month
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3E3E3E),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// Weekday Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD3405B),
                      borderRadius: BorderRadius.circular(20), // Pill shape
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children:
                          ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
                              .map(
                                (d) => SizedBox(
                                  width: 35,
                                  child: Text(
                                    d,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// Calendar Grid
                  _buildCalendarGrid(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final int daysInMonth = _daysInMonth(_displayedMonth);
    final int firstDayOffset = _firstDayOffset(_displayedMonth);

    // We want to fill the grid rows.
    final int totalCells = (daysInMonth + firstDayOffset <= 35) ? 35 : 42;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        if (index < firstDayOffset || index >= firstDayOffset + daysInMonth) {
          // Placeholder/Empty slots
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD7D7EB).withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }

        final int day = index - firstDayOffset + 1;
        // Check if today
        final bool isToday =
            day == _currentDate.day &&
            _displayedMonth.month == _currentDate.month &&
            _displayedMonth.year == _currentDate.year;

        final bool isSelected = isToday;

        return Container(
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFD3405B) // Pink
                : const Color(0xFFD7D7EB), // Light Purple
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            "$day",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        );
      },
    );
  }
}
