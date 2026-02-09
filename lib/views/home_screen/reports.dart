import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/profile_card.dart';
import 'package:pie_chart/pie_chart.dart';

import 'dart:math';

const uploadedImagePath = '/mnt/data/Screenshot 2025-11-21 151109.png';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String? selectedReportType;
  String? selectedMonth;
  int selectedYear = DateTime.now().year;

  Map<String, double> chartValues = {
    "Present": 24,
    "Absent": 2,
    "On Duty": 1,
    "Permission": 1,
  };

  @override
  void initState() {
    super.initState();
    selectedReportType = null;
    selectedMonth = null;
  }

  void _updateChartForSelection() {
    final seed = (selectedReportType ?? 'Attendance') +
        '|' +
        (selectedMonth ?? 'None') +
        '|' +
        selectedYear.toString();
    final rnd = seed.codeUnits.fold<int>(0, (p, n) => p + n);

    final present = 18 + (rnd % 8);
    final absent = 1 + (rnd % 4);
    final onDuty = (rnd % 3) == 0 ? 1 : 0;
    final permission = (rnd % 5) == 0 ? 1 : 0;

    setState(() {
      chartValues = {
        "Present": present.toDouble(),
        "Absent": absent.toDouble(),
        "On Duty": onDuty.toDouble(),
        "Permission": permission.toDouble(),
      };
    });
  }

  Future<void> _showMonthPickerDialog() async {
    final result = await showDialog<_MonthSelection>(
      context: context,
      builder: (context) {
        return MonthPickerDialog(
          initialMonth: selectedMonth,
          initialYear: selectedYear,
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedMonth = result.monthName;
        selectedYear = result.year;
      });
      _updateChartForSelection();
    }
  }

  void _onReportTypeChanged(String? val) {
    setState(() {
      selectedReportType = val;
    });
    _updateChartForSelection();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Reports",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ProfileInfoCard(
              //   name: 'Harish',
              //   employeeId: '1023',
              //   designation: 'Supervisor',
              //   profileImagePath: 'assets/profile.png',
              // ),

              // const SizedBox(height: 24),
              Text(
                "Reports",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              // FILTER CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedReportType,
                        hint: Text(
                          "Attendance",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down),
                        decoration:
                        const InputDecoration.collapsed(hintText: ''),
                        items: ['Attendance', 'Leave', 'Payroll']
                            .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            value,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ))
                            .toList(),
                        onChanged: _onReportTypeChanged,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedMonth == null
                                  ? "Select Month"
                                  : "$selectedMonth, $selectedYear",
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: selectedMonth == null
                                    ? Colors.black54
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: _showMonthPickerDialog,
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.all(6.0),
                              child: Icon(Icons.calendar_month),
                            ),
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: 130,
                      height: 42,
                      child: ElevatedButton(
                        onPressed: () {
                          _updateChartForSelection();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF465583),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "Search",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                "October Month Attendance Details",
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard('24', 'Day Worked',
                      [const Color(0xFFF5F5F5), const Color(0xFFD4D6FF)]),
                  _buildStatCard('02', 'Leave Taken',
                      [const Color(0xFFF5F5F5), const Color(0xFFD4FEFF)]),
                  _buildStatCard('08', 'Total OT Hours',
                      [const Color(0xFFF5F5F5), const Color(0xFFF4D4FF)]),
                  _buildStatCard('01', 'LOP',
                      [const Color(0xFFF5F5F5), const Color(0xFFFFD4D5)]),
                ],
              ),

              const SizedBox(height: 24),

              // PIE CHART
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Attendance Report",
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 160,
                          height: 160,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(
                          dataMap: {
                          "Present": 24,
                          "Absent": 4,
                          "On Duty": 5,
                          "Permission": 4
                          },
                                animationDuration: const Duration(milliseconds: 1000),
                                chartRadius: 360,
                                chartType: ChartType.disc,
                                ringStrokeWidth: 32,

                                colorList: const [
                                  Color(0xFF2E7D32),
                                  Color(0xFFD32F2F),
                                  Color(0xFF6D4C41),
                                  Color(0xFF1565C0),
                                ],
                                legendOptions: const LegendOptions(
                                  showLegends: false,
                                ),
                                chartValuesOptions: const ChartValuesOptions(
                                  showChartValues: false,
                                  showChartValuesInPercentage: false,
                                  showChartValuesOutside: false,
                                ),
                              ),

                            ],
                          ),
                        ),

                        const SizedBox(width: 20),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLegendItem(
                                "Present",
                                chartValues['Present']?.toInt().toString() ??
                                    '0',
                                Colors.green),
                            const SizedBox(height: 12),
                            _buildLegendItem(
                                "Absent",
                                chartValues['Absent']?.toInt().toString() ??
                                    '0',
                                Colors.red),
                            const SizedBox(height: 12),
                            _buildLegendItem(
                                "On Duty",
                                chartValues['On Duty']?.toInt().toString() ??
                                    '0',
                                Colors.brown),
                            const SizedBox(height: 12),
                            _buildLegendItem(
                                "Permission",
                                chartValues['Permission']?.toInt().toString() ??
                                    '0',
                                Colors.blue),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color:  Colors.lime.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF26A69A).withOpacity(0.35),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 35,
                      height: 35,
                      child: const Icon(
                        Icons.star_border,
                        size: 25,
                        color: Color(0xFF1B5E5A),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // TEXT
                    Expanded(
                      child: Text(
                        "Great attendance record this month! Keep up the good work.",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1B5E5A),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.picture_as_pdf),
                      label: Text(
                        'Export PDF',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF26A69A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon:
                      const Icon(Icons.share, color: Color(0xFF465583)),
                      label: Text(
                        'Share',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF465583),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side:
                        const BorderSide(color: Color(0xFF465583)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  )
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, List<Color> gradient) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          "$label: $value",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        )
      ],
    );
  }
}

class MonthPickerDialog extends StatefulWidget {
  final String? initialMonth;
  final int initialYear;
  const MonthPickerDialog(
      {super.key, this.initialMonth, required this.initialYear});

  @override
  State<MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<MonthPickerDialog> {
  static const monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  late int displayedYear;
  String? pickedMonth;

  @override
  void initState() {
    super.initState();
    displayedYear = widget.initialYear;
    pickedMonth = widget.initialMonth;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 320,
        height: 360,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        displayedYear--;
                      });
                    },
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        displayedYear.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        displayedYear++;
                      });
                    },
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.1,
                  children: List.generate(12, (index) {
                    final m = monthNames[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          pickedMonth = m;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: pickedMonth == m
                              ? const Color(0xFFDCE9FF)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: pickedMonth == m
                                ?  Color(0xff26A69A)
                                : Colors.transparent,
                            width: 1.2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          m.substring(0, 3),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: pickedMonth == m
                                ? const Color(0xff26A69A)
                                : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('Cancel', style: GoogleFonts.poppins()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: pickedMonth == null
                          ? null
                          : () {
                        Navigator.of(context).pop(_MonthSelection(
                          monthName: pickedMonth!,
                          year: displayedYear,
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:  Colors.white,
                      ),
                      child: Text('Select', style: GoogleFonts.poppins()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthSelection {
  final String monthName;
  final int year;
  _MonthSelection({required this.monthName, required this.year});
}
