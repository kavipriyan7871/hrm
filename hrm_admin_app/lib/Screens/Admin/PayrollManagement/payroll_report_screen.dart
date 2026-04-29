import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class PayrollReportScreen extends StatefulWidget {
  const PayrollReportScreen({super.key});

  @override
  State<PayrollReportScreen> createState() => _PayrollReportScreenState();
}

class _PayrollReportScreenState extends State<PayrollReportScreen> {
  final List<Map<String, dynamic>> _payrollReports = [
    {
      "month": "April 2024",
      "totalEmployees": 150,
      "totalSalary": "₹45,20,500",
      "totalAdvance": "₹1,20,000",
      "totalDeduction": "₹4,50,000",
      "status": "In-Progress",
      "color": Colors.blue,
    },
    {
      "month": "March 2024",
      "totalEmployees": 145,
      "totalSalary": "₹42,80,000",
      "totalAdvance": "₹95,000",
      "totalDeduction": "₹4,20,000",
      "status": "Closed",
      "color": Colors.green,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          "Monthly Payroll Report",
          style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _payrollReports.length,
        itemBuilder: (context, index) => _reportCard(_payrollReports[index]),
      ),
    );
  }

  Widget _reportCard(Map<String, dynamic> data) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data['month'], style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.indigo)),
              _statusBadge(data['status'], data['color'] as Color),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              _summaryItem("Employees", "${data['totalEmployees']}"),
              _divider(),
              _summaryItem("Total Payout", data['totalSalary']),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              _summaryItem("Total Advance", data['totalAdvance']),
              _divider(),
              _summaryItem("Total Deduction", data['totalDeduction'], color: Colors.red),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: Icon(Icons.analytics_outlined, size: 16.sp),
                label: Text("Deep Analysis", style: GoogleFonts.poppins(fontSize: 11.sp, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(foregroundColor: Colors.teal),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.grey)),
          Text(value, style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.bold, color: color ?? Colors.black87)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 25.h, color: Colors.grey.shade200, margin: EdgeInsets.symmetric(horizontal: 16.w));
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6.r)),
      child: Text(status, style: GoogleFonts.poppins(fontSize: 10.sp, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
