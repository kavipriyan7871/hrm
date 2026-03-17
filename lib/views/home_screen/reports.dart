import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrm/models/report_api.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String? selectedReportType;
  String? selectedMonth;
  int selectedYear = DateTime.now().year;
  bool isLoading = false;
  Map<String, double> chartValues = {
    "Present": 0,
    "Absent": 0,
    "On Duty": 0,
    "Permission": 0,
    "Leave": 0,
    "LOP": 0,
  };

  int daysWorked = 0;
  int leaveTaken = 0;
  int onDutyCount = 0; // Added missing variable
  int permissionCount = 0; // Added missing variable
  String totalOTHours = "00";
  int lopCountInt = 0;
  String performanceRating = "Average";
  String performanceRemarks = "";
  List<dynamic> leaveHistory = []; // Added for detailed leave report

  final List<String> monthNames = const [
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
    'December',
  ];

  @override
  void initState() {
    super.initState();
    selectedReportType = 'Attendance'; // Default to Attendance
    // Set current month as default if not set
    final now = DateTime.now();
    selectedMonth = monthNames[now.month - 1];
    selectedYear = now.year;

    // delaying fetch slightly to ensure build is ready or just call it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchReport();
    });
  }

  Future<void> _fetchReport() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final cid = prefs.getString('cid') ?? "";
      final uid = (prefs.getInt('uid') ?? prefs.getString('uid') ?? "0")
          .toString();
      final deviceId = prefs.getString('device_id') ?? "";
      final lat = (prefs.getDouble('lat') ?? 0.0).toString();
      final lng = (prefs.getDouble('lng') ?? 0.0).toString();

      // Format month to YYYY-MM
      int monthIndex = monthNames.indexOf(selectedMonth!) + 1;
      String monthStr =
          "$selectedYear-${monthIndex.toString().padLeft(2, '0')}";

      final data = await ReportApi.fetchReport(
        cid: cid,
        uid: uid,
        deviceId: deviceId,
        lat: lat,
        lng: lng,
        reportType: (selectedReportType ?? 'Attendance').toLowerCase(),
        month: monthStr,
      );

      if (data['error'] == false) {
        _processReportData(data);
      } else {
        // Handle API error
        debugPrint("API Error: ${data['message']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Failed to fetch report")),
        );
      }
    } catch (e) {
      debugPrint("Exception fetching report: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _processReportData(Map<String, dynamic> data) {
    if (data['data'] == null) return;

    final mainData = data['data'];

    // Process Summary for cards
    if (mainData['summary'] != null) {
      final summary = mainData['summary'];
      daysWorked = int.tryParse(summary['days_worked']?.toString() ?? '0') ?? 0;
      leaveTaken = int.tryParse(summary['leave_taken']?.toString() ?? '0') ?? 0;
      onDutyCount = int.tryParse(summary['on_duty']?.toString() ?? '0') ?? 0;
      permissionCount =
          int.tryParse(summary['permission']?.toString() ?? '0') ?? 0;
    }

    // Process Chart Data
    if (mainData['chart'] != null) {
      final chart = mainData['chart'];
      presentCount = double.tryParse(chart['present']?.toString() ?? '0') ?? 0;
      absentCount = double.tryParse(chart['absent']?.toString() ?? '0') ?? 0;
      odCount = double.tryParse(chart['on_duty']?.toString() ?? '0') ?? 0;
      permCount = double.tryParse(chart['permission']?.toString() ?? '0') ?? 0;
      leaveCount = double.tryParse(chart['leave']?.toString() ?? '0') ?? 0;
      lopCount = double.tryParse(chart['lop']?.toString() ?? '0') ?? 0;

      chartValues = {
        "Present": daysWorked.toDouble() > 0
            ? daysWorked.toDouble()
            : presentCount,
        "Absent": absentCount,
        "On Duty": odCount,
        "Permission": permCount,
        "Leave": leaveTaken.toDouble(),
        "LOP": lopCount,
      };

      // Update summary fields from chart data if needed for display
      lopCountInt = lopCount.toInt();
      // Total OT Hours - using a placeholder or derivation if not in API
      totalOTHours = odCount.toInt().toString().padLeft(2, '0');
    }

    // Performance info
    if (mainData['performance'] != null) {
      performanceRating = mainData['performance']['rating'] ?? "Average";
      performanceRemarks = mainData['performance']['remarks'] ?? "";
    }

    // ✅ Process List Data (daily_records or details)
    final List<dynamic> records =
        mainData['daily_records'] ?? mainData['details'] ?? [];

    if (selectedReportType == 'Leave') {
      // Filter for approved leaves only
      leaveHistory = records.where((item) {
        final statusRaw = (item['status'] ?? "").toString().toLowerCase();
        final onLeave =
            item['on_leave'] == true ||
            item['on_leave']?.toString().toLowerCase() == 'true' ||
            statusRaw == "leave" ||
            statusRaw.contains("leave");

        bool isApproved =
            statusRaw == "1" ||
            statusRaw == "accept" ||
            statusRaw.contains("approv");

        // Return true only if it's a leave day AND it's approved
        return onLeave && isApproved;
      }).toList();

      // Recalculate accurately to exclude pending leaves from UI count
      num totalApprovedDays = 0;
      for (var leave in leaveHistory) {
        // Use no_of_days if present, otherwise each record is 1 day
        totalApprovedDays +=
            num.tryParse(leave['no_of_days']?.toString() ?? "1") ?? 1;
      }
      leaveTaken = totalApprovedDays.toInt();
      chartValues["Leave"] = leaveTaken.toDouble();
    } else {
      // For Attendance, we can store all records
      leaveHistory = records;
    }

    setState(() {});
  }

  double presentCount = 0,
      absentCount = 0,
      odCount = 0,
      permCount = 0,
      leaveCount = 0,
      lopCount = 0;

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
      _fetchReport();
    }
  }

  void _onReportTypeChanged(String? val) {
    setState(() {
      selectedReportType = val;
    });
    _fetchReport();
  }

  Future<void> _exportToPDF() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "HRM Attendance Report",
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  "Month: $selectedMonth $selectedYear",
                  style: pw.TextStyle(fontSize: 18),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  "Summary:",
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Bullet(text: "Days Worked: $daysWorked"),
                pw.Bullet(text: "Leave Taken: $leaveTaken"),
                pw.Bullet(text: "On Duty: $onDutyCount"),
                pw.Bullet(text: "Permission: $permissionCount"),
                pw.SizedBox(height: 20),
                pw.Text(
                  "Attendance Breakdown:",
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Bullet(text: "Present: ${chartValues['Present']?.toInt()}"),
                pw.Bullet(text: "Absent: ${chartValues['Absent']?.toInt()}"),
                pw.Bullet(text: "On Duty: ${chartValues['On Duty']?.toInt()}"),
                pw.Bullet(
                  text: "Permission: ${chartValues['Permission']?.toInt()}",
                ),
                pw.Bullet(text: "Leave: ${chartValues['Leave']?.toInt()}"),
                pw.Bullet(text: "LOP: ${chartValues['LOP']?.toInt()}"),
                pw.SizedBox(height: 20),
                pw.Text(
                  "Performance:",
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text("Rating: $performanceRating"),
                pw.Text("Remarks: $performanceRemarks"),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      debugPrint("Error exporting PDF: $e");
    }
  }

  Future<void> _shareReport() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "HRM Attendance Report",
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  "Month: $selectedMonth $selectedYear",
                  style: pw.TextStyle(fontSize: 18),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  "Summary:",
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Bullet(text: "Days Worked: $daysWorked"),
                pw.Bullet(text: "Leave Taken: $leaveTaken"),
                pw.Bullet(text: "On Duty: $onDutyCount"),
                pw.Bullet(text: "Permission: $permissionCount"),
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  context: context,
                  data: <List<String>>[
                    <String>['Status', 'Count'],
                    <String>['Present', '${chartValues['Present']?.toInt()}'],
                    <String>['Absent', '${chartValues['Absent']?.toInt()}'],
                    <String>['On Duty', '${chartValues['On Duty']?.toInt()}'],
                    <String>[
                      'Permission',
                      '${chartValues['Permission']?.toInt()}',
                    ],
                    <String>['Leave', '${chartValues['Leave']?.toInt()}'],
                    <String>['LOP', '${chartValues['LOP']?.toInt()}'],
                  ],
                ),
              ],
            );
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File(
        "${output.path}/attendance_report_$selectedMonth$selectedYear.pdf",
      );
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Check out my $selectedMonth $selectedYear Attendance Report');
    } catch (e) {
      debugPrint("Error sharing report: $e");
    }
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
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500),
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
                      color: Colors.grey.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedReportType,
                        hint: Text(
                          "Attendance",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down),
                        decoration: const InputDecoration.collapsed(
                          hintText: '',
                        ),
                        items: ['Attendance', 'Leave', 'Payroll']
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _onReportTypeChanged,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
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
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Center(
                      child: SizedBox(
                        width: 140,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  _fetchReport();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF1A237E,
                            ), // Dark Blue
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "Search",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                "$selectedMonth Month Attendance Details",
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
                  _buildStatCard(
                    daysWorked.toString().padLeft(2, '0'),
                    'Day Worked',
                    [const Color(0xFFE8EAF6), const Color(0xFFC5CAE9)],
                  ),
                  _buildStatCard(
                    leaveTaken.toString().padLeft(2, '0'),
                    'Leave Taken',
                    [const Color(0xFFE0F7FA), const Color(0xFFB2EBF2)],
                  ),
                  _buildStatCard(totalOTHours, 'Total OT Hours', [
                    const Color(0xFFF3E5F5),
                    const Color(0xFFE1BEE7),
                  ]),
                  _buildStatCard(
                    lopCountInt.toString().padLeft(2, '0'),
                    'LOP',
                    [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // PIE CHART
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  // border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ---- PIE CHART (left side) ----
                        SizedBox(
                          width: 170,
                          height: 200,
                          child: PieChart(
                            dataMap: chartValues,
                            animationDuration: const Duration(
                              milliseconds: 1000,
                            ),
                            chartRadius: 165,
                            chartType: ChartType.disc,
                            colorList: const [
                              Color(0xFF2E7D32), // Present - Green
                              Color(0xFFD32F2F), // Absent - Red
                              Color(0xFF1A237E), // On Duty - Navy Blue
                              Color(0xFF6D4C41), // Permission - Brown
                            ],
                            legendOptions: const LegendOptions(
                              showLegends: false,
                            ),
                            chartValuesOptions: ChartValuesOptions(
                              showChartValues: true,
                              showChartValuesInPercentage: false,
                              showChartValuesOutside: false,
                              decimalPlaces: 0,
                              chartValueBackgroundColor: Colors.transparent,
                              chartValueStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // ---- LABELS on right side (like image) ----
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildOutsideLegend(
                                "Present-${(daysWorked > 0 ? daysWorked : presentCount.toInt())}",
                                const Color(0xFF2E7D32),
                              ),
                              const SizedBox(height: 10),
                              _buildOutsideLegend(
                                "Absent-${absentCount.toInt()}",
                                const Color(0xFFD32F2F),
                              ),
                              const SizedBox(height: 10),
                              _buildOutsideLegend(
                                "On Duty-${odCount.toInt()}",
                                const Color(0xFF1A237E),
                              ),
                              const SizedBox(height: 10),
                              _buildOutsideLegend(
                                "Permission-${permCount.toInt()}",
                                const Color(0xFF6D4C41),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCEDC8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.star_outline,
                      size: 24,
                      color: Color(0xFF33691E),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        performanceRemarks.isEmpty
                            ? "Great attendance record this month! Keep up the good work."
                            : performanceRemarks,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF33691E),
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
                      onPressed: _exportToPDF,
                      icon: const Icon(Icons.picture_as_pdf, size: 20),
                      label: Text(
                        'Export PDF',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF26A69A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _shareReport,
                      icon: const Icon(
                        Icons.share_outlined,
                        size: 20,
                        color: Color(0xFF1A237E),
                      ),
                      label: Text(
                        'Share',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF1A237E),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF1A237E),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ✅ Detailed History (Attendance or Leave)
              if (leaveHistory.isNotEmpty) ...[
                Text(
                  selectedReportType == 'Leave'
                      ? "Leave History (Approved Only)"
                      : "Daily Attendance Records",
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: leaveHistory.length,
                  itemBuilder: (context, index) {
                    final item = leaveHistory[index];

                    if (selectedReportType == 'Leave') {
                      String dateRange =
                          "${item["leave_start_date"] ?? item["date"] ?? ""} - ${item["leave_end_date"] ?? ""}";
                      String type = item["leave_type"] ?? "Leave";
                      String days = "${item["no_of_days"] ?? "1"} Days";

                      return _buildHistoryItem(
                        icon: Icons.event_available,
                        title: type,
                        subtitle: dateRange,
                        trailing: days,
                        color: const Color(0xFF26A69A),
                      );
                    } else {
                      // Attendance Item
                      String date =
                          "${item["date"] ?? ""} (${item["day"] ?? ""})";
                      String time =
                          "In: ${item["check_in_time"] ?? "--"} | Out: ${item["check_out_time"] ?? "--"}";
                      String status =
                          item["status"]?.toString().toUpperCase() ?? "N/A";

                      return _buildHistoryItem(
                        icon: Icons.access_time,
                        title: date,
                        subtitle: time,
                        trailing: status,
                        color: const Color(0xFF1A237E),
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String trailing,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            trailing,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A237E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutsideLegend(String label, Color color) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: color,
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
          ),
        ],
      ),
    );
  }
}

class MonthPickerDialog extends StatefulWidget {
  final String? initialMonth;
  final int initialYear;
  const MonthPickerDialog({
    super.key,
    this.initialMonth,
    required this.initialYear,
  });

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
    'December',
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
                                ? Color(0xff26A69A)
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
                              Navigator.of(context).pop(
                                _MonthSelection(
                                  monthName: pickedMonth!,
                                  year: displayedYear,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
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
