import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  bool _isLoading = false;
  Map<String, dynamic> _summary = {
    "total": 0,
    "completed": 0,
    "partial": 0,
    "pending": 0,
  };

  Map<String, dynamic> _monthlySummary = {
    "total": 0,
    "completed": 0,
    "partial": 0,
    "pending": 0,
  };

  DateTime _selectedDate = DateTime.now();
  String _filterType = "Day"; // "Day", "Month", "Year"
  String _employeeName = "";
  String _employeeCode = "";
  String _rawResponse = ""; // For debugging as per user request

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchMonthlyData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    String fromDate;
    String toDate;

    if (_filterType == "Day") {
      fromDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      toDate = fromDate;
    } else if (_filterType == "Month") {
      fromDate = DateFormat('yyyy-MM-01').format(_selectedDate);
      toDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime(_selectedDate.year, _selectedDate.month + 1, 0));
    } else {
      fromDate = DateFormat('yyyy-01-01').format(_selectedDate);
      toDate = DateFormat('yyyy-12-31').format(_selectedDate);
    }

    final data = await _fetchPerformanceData(fromDate, toDate);
    if (mounted && data != null && data['error'] == false) {
      setState(() {
        _summary = data['summary'] ?? _summary;
        _employeeName = data['employee_name'] ?? "";
        _employeeCode = data['employee_code'] ?? "";
        _rawResponse = jsonEncode(
          data['summary'],
        ); // Store simplified summary response
        _isLoading = false;
      });
    } else {
      setState(() {
        _rawResponse = data != null ? data['error_msg'] : "Error fetching data";
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMonthlyData() async {
    String fromDate = DateFormat('yyyy-MM-01').format(_selectedDate);
    String toDate = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(_selectedDate.year, _selectedDate.month + 1, 0));

    final data = await _fetchPerformanceData(fromDate, toDate);
    if (mounted && data != null && data['error'] == false) {
      setState(() {
        _monthlySummary = data['summary'] ?? _monthlySummary;
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchPerformanceData(
    String fromDate,
    String toDate,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cid = prefs.getString('cid') ?? "";
      final String uid = prefs.getString('server_uid') ??
                         prefs.getString('login_cus_id') ?? 
                         prefs.getString('employee_table_id') ?? 
                         prefs.getInt('uid')?.toString() ?? "";
      final String deviceId = prefs.getString('device_id') ?? "";
      final String lat = prefs.getDouble('lat')?.toString() ?? "";
      final String lng = prefs.getDouble('lng')?.toString() ?? "";
      final String? token = prefs.getString('token');

      final body = {
        "type": "2075",
        "cid": cid,
        "uid": uid,
        "device_id": deviceId,
        "lt": lat,
        "ln": lng,
        "token": token ?? "",
        "from_date": fromDate,
        "to_date": toDate,
      };

      final response = await http.post(
        Uri.parse("https://erpsmart.in/total/api/m_api/"),
        body: body,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        debugPrint("API Response: ${response.body}"); // Show in logs
        return decoded;
      }
    } catch (e) {
      debugPrint("API Error: $e");
    }
    return null;
  }

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (_employeeName.isNotEmpty)
              Text(
                '$_employeeName ($_employeeCode)',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () async {
                final date = await showDialog<DateTime>(
                  context: context,
                  builder: (context) =>
                      _CalendarDialog(initialDate: _selectedDate),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                  _fetchData();
                  _fetchMonthlyData();
                }
              },
              child: const Icon(Icons.calendar_month, color: Colors.white),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF26A69A)),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await _fetchData();
                await _fetchMonthlyData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildFilterSection(),
                    if (_rawResponse.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          "Response: $_rawResponse",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    _buildSummaryCard(context, cardPadding),
                    const SizedBox(height: 16),
                    _buildTaskCompletionCard(context, cardPadding),
                    const SizedBox(height: 16),
                    _buildStatisticsCard(cardPadding),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFilterSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ["Day", "Month", "Year"].map((type) {
        bool isSelected = _filterType == type;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Text(
              type,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 12,
              ),
            ),
            selected: isSelected,
            selectedColor: const Color(0xFF26A69A),
            backgroundColor: Colors.grey.shade100,
            onSelected: (val) {
              if (val) {
                setState(() => _filterType = type);
                _fetchData();
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCard(BuildContext context, double padding) {
    int total = _monthlySummary["total"] ?? 0;
    int completed = _monthlySummary["completed"] ?? 0;
    double percentage = total == 0 ? 0.0 : completed / total;
    String monthName = DateFormat('MMMM').format(_selectedDate);

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            'Per Month Target- $monthName',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1B2C61),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              return _buildCustomProgressBar(
                progress: percentage,
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
              Icon(
                percentage >= 0.8
                    ? Icons.thumb_up_alt_outlined
                    : (percentage >= 0.5
                          ? Icons.sentiment_satisfied
                          : Icons.sentiment_dissatisfied),
                color: const Color(0xFF34C759),
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                percentage >= 0.8
                    ? 'Excellent'
                    : (percentage >= 0.5 ? 'Good' : 'Needs Improvement'),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF34C759),
                ),
              ),
              const Spacer(),
              Text(
                '${(percentage * 100).toStringAsFixed(0)}% Completed',
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
    int total = _summary["total"] ?? 0;
    int completed = _summary["completed"] ?? 0;
    double percentage = total == 0 ? 0.0 : completed / total;
    String dateStr = DateFormat('d/MM/yyyy').format(_selectedDate);
    String label = _filterType == "Day"
        ? "Per Day Task-$dateStr"
        : (_filterType == "Month"
              ? "Monthly Task-${DateFormat('MMMM yyyy').format(_selectedDate)}"
              : "Yearly Task-${_selectedDate.year}");

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1B2C61),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              return _buildCustomProgressBar(
                progress: percentage,
                color: const Color(0xFFFF9500),
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
                '${(percentage * 100).toStringAsFixed(0)}% Progress',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFFF9500),
                ),
              ),
              Text(
                'Pending : ${((1 - percentage) * 100).toStringAsFixed(0)}%',
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
                '$completed/$total',
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
    int completed = _summary["completed"] ?? 0;
    int pending = _summary["pending"] ?? 0;
    int partial = _summary["partial"] ?? 0;
    int total = _summary["total"] ?? 0;
    double rate = total == 0 ? 0.0 : (completed / total) * 100;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
          _buildStatRow('Completed', '$completed'),
          const SizedBox(height: 12),
          _buildStatRow('Partial', '$partial'),
          const SizedBox(height: 12),
          _buildStatRow('Pending', '$pending'),
          const SizedBox(height: 12),
          _buildStatRow('Completed Rate', '${rate.toStringAsFixed(0)}%'),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 12),
          _buildStatRow('Total Task', '$total'),
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
            width: width * progress,
            decoration: BoxDecoration(
              color: isGradient ? null : color,
              gradient: gradient,
              borderRadius: BorderRadius.circular(barHeight / 2),
            ),
          ),
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
                    color: Colors.black.withValues(alpha: 0.1),
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
  final DateTime initialDate;
  const _CalendarDialog({required this.initialDate});

  @override
  State<_CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<_CalendarDialog> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      1,
    );
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
        1,
      );
    });
  }

  int _daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int _firstDayOffset(DateTime date) {
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
          color: const Color(0xFFF3F3FB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 50,
              child: Stack(
                children: [
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
                  Positioned(
                    top: -12,
                    left: 40,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F3FB),
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
                        color: Color(0xFFF3F3FB),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _previousMonth,
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Color(0xFF3E3E3E),
                        ),
                      ),
                      Text(
                        "${_monthName(_displayedMonth.month)} ${_displayedMonth.year}",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3E3E3E),
                        ),
                      ),
                      IconButton(
                        onPressed: _nextMonth,
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF3E3E3E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD3405B),
                      borderRadius: BorderRadius.circular(20),
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
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD7D7EB).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }
        final int day = index - firstDayOffset + 1;
        final bool isSelected = day == _displayedMonth.day;
        return GestureDetector(
          onTap: () => Navigator.pop(
            context,
            DateTime(_displayedMonth.year, _displayedMonth.month, day),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFD3405B)
                  : const Color(0xFFD7D7EB),
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
          ),
        );
      },
    );
  }
}
