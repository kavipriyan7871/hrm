import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hrm/models/payroll_api.dart';
import '../../views/payroll/advance_salary_request.dart';
import '../main_root.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  static const Color tealColor = Color(0xFF26A69A);

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _payrollData;

  // Month and Year selection
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _fetchPayroll();
  }

  Future<void> _fetchPayroll() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ Payroll API uses login_cus_id (login user ID = 2), NOT server/employee ID
      final String uid =
          prefs.getString('login_cus_id') ??
          prefs.getString('server_uid') ??
          prefs.getString('employee_table_id') ??
          prefs.getInt('uid')?.toString() ??
          "";
      final String cid = prefs.getString('cid') ?? "";
      final String deviceId = prefs.getString('device_id') ?? "";

      debugPrint("Payroll: cid=$cid, uid=$uid");

      // Check permissions and get location
      final position = await _determinePosition();

      final month = _selectedMonth.toString().padLeft(2, '0');
      final year = _selectedYear.toString();

      final response = await PayrollRepo.getPayroll(
        cid: cid,
        uid: uid,
        month: month,
        year: year,
        deviceId: deviceId,
        lat: position?.latitude.toString() ?? "0.0",
        lng: position?.longitude.toString() ?? "0.0",
      );

      print("Payroll API Response: $response");

      if (!mounted) return;

      if (response["error"] == false) {
        setState(() {
          _payrollData = response["data"];
          _isLoading = false;
        });
      } else {
        // Instead of showing error screen, show UI with zero values
        setState(() {
          _payrollData = null; // UI handles null by showing 0
          _error = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Payroll Fetch Error: $e");
      if (mounted) {
        setState(() {
          _payrollData = null;
          _error = null;
          _isLoading = false;
        });
      }
    }
  }

  Future<Position?> _determinePosition() async {
    try {
      // ⚡ SPEED OPTIMIZATION: Payroll doesn't strictly need high-accuracy GPS
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      // Fast current position (low accuracy, very short timeout)
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(milliseconds: 500),
      );
    } catch (e) {
      print("Location Fetch Error (Handled): $e");
      return null;
    }
  }

  Future<void> _showMonthYearPicker() async {
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => _MonthYearPickerDialog(
        initialMonth: _selectedMonth,
        initialYear: _selectedYear,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedMonth = result['month']!;
        _selectedYear = result['year']!;
      });
      _fetchPayroll();
    }
  }

  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final monthName = _getMonthName(_selectedMonth);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainRoot()),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: tealColor,
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
            'Payroll',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: _showMonthYearPicker,
              tooltip: 'Select Month/Year',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchPayroll,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdvanceSalaryRequestScreen()),
            );
          },
          backgroundColor: tealColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            "Advance Request",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _fetchPayroll,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Retry"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tealColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _showMonthYearPicker,
                        icon: const Icon(Icons.calendar_month),
                        label: const Text("Change Month/Year"),
                        style: TextButton.styleFrom(foregroundColor: tealColor),
                      ),
                    ],
                  ),
                ),
              )
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: 100, // Space for bottom nav and extra breathing room
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Teal Container with 4 White Cards
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: tealColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$monthName Month Salary Details",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildWhiteInnerCard(
                                    "Monthly",
                                    "?${_payrollData?['earnings']?['basic_salary'] ?? 0}",
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildWhiteInnerCard(
                                    "Per Day",
                                    "?${_payrollData?['attendance']?['per_day_salary'] ?? 0}",
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildWhiteInnerCard(
                                    "Present",
                                    "${_payrollData?['attendance']?['no_of_present'] ?? 0} Days",
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildWhiteInnerCard(
                                    "Absence",
                                    "${_payrollData?['attendance']?['no_of_absence'] ?? 0} Days",
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Earnings
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Earnings & Allowances",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildEarningsRow(
                              "Basic Salary",
                              "? ${_payrollData?['earnings']?['basic_salary'] ?? 0}",
                            ),
                            _buildEarningsDivider(),
                            _buildEarningsRow(
                              "HRA",
                              "? ${_payrollData?['earnings']?['hra'] ?? 0}",
                            ),
                            _buildEarningsDivider(),
                            _buildEarningsRow(
                              "Conveyance",
                              "? ${_payrollData?['earnings']?['conveyance_allowance'] ?? 0}",
                            ),
                            _buildEarningsDivider(),
                            _buildEarningsRow(
                              "Medical",
                              "? ${_payrollData?['earnings']?['medical_allowance'] ?? 0}",
                            ),
                            _buildEarningsDivider(),
                            _buildEarningsRow(
                              "Special",
                              "? ${_payrollData?['earnings']?['special_allowance'] ?? 0}",
                            ),
                            _buildEarningsDivider(),
                            _buildEarningsRow(
                              "Others",
                              "? ${_payrollData?['earnings']?['other_allowances'] ?? 0}",
                            ),
                            _buildEarningsDivider(),
                            _buildEarningsRow(
                              "Incentives",
                              "? ${_payrollData?['earnings']?['incentives'] ?? 0}",
                            ),
                            const SizedBox(height: 20),
                            if (_payrollData?['earnings']?['incentive_message'] !=
                                    null &&
                                _payrollData!['earnings']['incentive_message']
                                    .toString()
                                    .isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xff34C759),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.stars,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _payrollData!['earnings']['incentive_message'],
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Breakdown Section
                      Text(
                        "Breakdown",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildBreakdownRow(
                              "Gross Salary",
                              "?${_payrollData?['net_pay']?['gross_salary'] ?? 0}",
                              isBold: true,
                              valueColor: Colors.black87,
                            ),
                            const Divider(height: 24),
                            _buildBreakdownRow(
                              "PF Deduction",
                              "?${_payrollData?['deductions']?['pf_deduction'] ?? 0}",
                              valueColor: Colors.red.shade700,
                            ),
                            _buildBreakdownRow(
                              "ESI Deduction",
                              "?${_payrollData?['deductions']?['esi_deduction'] ?? 0}",
                              valueColor: Colors.red.shade700,
                            ),
                            _buildBreakdownRow(
                              "Professional Tax",
                              "?${_payrollData?['deductions']?['professional_tax'] ?? 0}",
                              valueColor: Colors.red.shade700,
                            ),
                            _buildBreakdownRow(
                              "Loss of Pay",
                              "?${_payrollData?['deductions']?['loss_of_pay'] ?? 0}",
                              valueColor: Colors.red.shade700,
                            ),
                            _buildBreakdownRow(
                              "Advance",
                              "?${_payrollData?['deductions']?['advance'] ?? 0}",
                              valueColor: Colors.red.shade700,
                            ),
                            const Divider(height: 24),
                            _buildBreakdownRow(
                              "Total Deduction",
                              "?${_payrollData?['net_pay']?['total_deduction'] ?? 0}",
                              isBold: true,
                              valueColor: Colors.red.shade700,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _buildBreakdownRow(
                                "Net Paid Amount",
                                "?${_payrollData?['net_pay']?['net_paid'] ?? 0}",
                                isBold: true,
                                valueColor: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Action Buttons
                      Center(
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildActionButton(
                              "Download",
                              Icons.download,
                              tealColor,
                              _downloadPDF,
                            ),
                            _buildActionButton(
                              "Share",
                              Icons.share,
                              tealColor,
                              _sharePDF,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // White Cards inside Teal Container
  Widget _buildWhiteInnerCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: tealColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: tealColor,
            ),
          ),
        ],
      ),
    );
  }

  // Earnings Row
  Widget _buildEarningsRow(String title, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
          ),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsDivider() =>
      Divider(color: Colors.grey.shade300, height: 1);

  // Updated Breakdown Row with Custom Color Support
  Widget _buildBreakdownRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Generate PDF of Breakdown
  Future<File> _generatePDF() async {
    final pdf = pw.Document();
    final monthName = _getMonthName(_selectedMonth);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                color: PdfColor.fromHex('#26A69A'),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Payroll Breakdown',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      '$monthName $_selectedYear',
                      style: pw.TextStyle(fontSize: 16, color: PdfColors.white),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Breakdown Table
              pw.Text(
                'Salary Breakdown',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),

              // Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  _buildPdfRow(
                    'Basic Salary',
                    'Rs.${_payrollData?['earnings']?['basic_salary'] ?? 0}',
                  ),
                  _buildPdfRow(
                    'Incentives',
                    'Rs.${_payrollData?['earnings']?['incentives'] ?? 0}',
                  ),
                  _buildPdfRow(
                    'Gross Salary',
                    'Rs.${_payrollData?['net_pay']?['gross_salary'] ?? 0}',
                    isBold: true,
                  ),
                  _buildPdfRow(
                    'Total Deduction',
                    'Rs.${_payrollData?['net_pay']?['total_deduction'] ?? 0}',
                    isBold: true,
                  ),
                  _buildPdfRow(
                    'Net Paid',
                    'Rs.${_payrollData?['net_pay']?['net_paid'] ?? 0}',
                    isBold: true,
                    isTotal: true,
                  ),
                ],
              ),

              pw.SizedBox(height: 40),

              // Footer
              pw.Text(
                'Generated on ${DateTime.now().toString().split('.')[0]}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ],
          );
        },
      ),
    );

    // Save to temp first
    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/payroll_breakdown_${monthName}_$_selectedYear.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.TableRow _buildPdfRow(
    String label,
    String value, {
    bool isBold = false,
    bool isTotal = false,
  }) {
    return pw.TableRow(
      decoration: isTotal
          ? pw.BoxDecoration(color: PdfColor.fromHex('#E8F5E9'))
          : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(12),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(12),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  // Download PDF
  Future<void> _downloadPDF() async {
    print("Download PDF button pressed");
    try {
      final tempFile = await _generatePDF();
      print("PDF generated at: ${tempFile.path}");

      // Get persistent directory
      final appDir = await getApplicationDocumentsDirectory();
      final String persistentPath =
          '${appDir.path}/${tempFile.uri.pathSegments.last}';

      // Copy from temp to persistent
      final File persistentFile = await tempFile.copy(persistentPath);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved to: ${persistentFile.path}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () {
              // Optional: Add open file logic here if package available,
              // otherwise Share it as a way to open
              Share.shareXFiles([XFile(persistentFile.path)]);
            },
          ),
        ),
      );
    } catch (e, stack) {
      print("Error downloading PDF: $e\n$stack");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Share PDF
  Future<void> _sharePDF() async {
    print("Share PDF button pressed");
    try {
      final file = await _generatePDF();
      final monthName = _getMonthName(_selectedMonth);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Payroll Breakdown for $monthName $_selectedYear');
    } catch (e, stack) {
      print("Error sharing PDF: $e\n$stack");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Action Buttons
  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// Month/Year Picker Dialog
class _MonthYearPickerDialog extends StatefulWidget {
  final int initialMonth;
  final int initialYear;

  const _MonthYearPickerDialog({
    required this.initialMonth,
    required this.initialYear,
  });

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int _selectedMonth;
  late int _selectedYear;

  final List<String> _months = [
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
    _selectedMonth = widget.initialMonth;
    _selectedYear = widget.initialYear;
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (index) => currentYear - index);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select Month & Year",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),

            // Month Selector
            Text(
              "Month",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedMonth,
                  isExpanded: true,
                  items: List.generate(12, (index) {
                    return DropdownMenuItem(
                      value: index + 1,
                      child: Text(
                        _months[index],
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      _selectedMonth = value!;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Year Selector
            Text(
              "Year",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedYear,
                  isExpanded: true,
                  items: years.map((year) {
                    return DropdownMenuItem(
                      value: year,
                      child: Text(
                        year.toString(),
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedYear = value!;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.poppins(color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'month': _selectedMonth,
                      'year': _selectedYear,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF26A69A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Apply",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
