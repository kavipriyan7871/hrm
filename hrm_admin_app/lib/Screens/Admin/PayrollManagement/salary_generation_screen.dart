import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class SalaryGenerationScreen extends StatefulWidget {
  const SalaryGenerationScreen({super.key});

  @override
  State<SalaryGenerationScreen> createState() => _SalaryGenerationScreenState();
}

class _SalaryGenerationScreenState extends State<SalaryGenerationScreen> {
  final List<Map<String, dynamic>> _employeePayrollData = [
    {
      "name": "Kavi Priyan",
      "id": "EMP001",
      "workingDays": 26,
      "otHours": 12,
      "basicSalary": 25000,
      "allowances": 3000,
      "deductions": 1500,
      "status": "Pending",
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Kavi",
    },
    {
      "name": "Arun Kumar",
      "id": "EMP002",
      "workingDays": 24,
      "otHours": 8,
      "basicSalary": 18000,
      "allowances": 2000,
      "deductions": 1000,
      "status": "Generated",
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Arun",
    },
    {
       "name": "Santhosh Mani",
       "id": "EMP003",
       "workingDays": 25,
       "otHours": 15,
       "basicSalary": 22000,
       "allowances": 2500,
       "deductions": 1200,
       "status": "Pending",
       "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Santhosh",
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          "Salary Generation",
          style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: _employeePayrollData.length,
              itemBuilder: (context, index) => _salaryCalcCard(_employeePayrollData[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Colors.white,
      child: Row(
        children: [
          Icon(Icons.calendar_month, color: Colors.teal, size: 20.sp),
          SizedBox(width: 12.w),
          Text(
            "April 2024",
            style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const Spacer(),
          TextButton(onPressed: () {}, child: Text("Change Month", style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.teal))),
        ],
      ),
    );
  }

  Widget _salaryCalcCard(Map<String, dynamic> data) {
    double otAmt = data['otHours'] * 150.0; // Assume 150 per OT hour
    double netSalary = data['basicSalary'] + data['allowances'] + otAmt - data['deductions'];
    bool isPending = data['status'] == 'Pending';

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
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
            children: [
              CircleAvatar(radius: 20.r, backgroundImage: NetworkImage(data['photo'])),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['name'], style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                    Text(data['id'], style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.grey)),
                  ],
                ),
              ),
              if (!isPending)
                 const Icon(Icons.check_circle, color: Colors.green)
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoTile("Working Days", "${data['workingDays']}"),
              _infoTile("OT Hours", "${data['otHours']}h"),
              _infoTile("Net Salary", "₹${netSalary.toStringAsFixed(0)}", valueColor: Colors.indigo),
            ],
          ),
          SizedBox(height: 16.h),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text("View Details", style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.teal, fontWeight: FontWeight.bold)),
              tilePadding: EdgeInsets.zero,
              children: [
                _detailRow("Basic Salary", "₹${data['basicSalary']}"),
                _detailRow("Allowances", "+ ₹${data['allowances']}"),
                _detailRow("OT Amount", "+ ₹${otAmt.toStringAsFixed(0)}"),
                _detailRow("Deductions", "- ₹${data['deductions']}", isNegative: true),
                const Divider(),
              ],
            ),
          ),
          if (isPending)
            ElevatedButton(
              onPressed: () {
                setState(() => data['status'] = 'Generated');
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Salary Generated successfully")));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF26A69A),
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 40.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                elevation: 0,
              ),
              child: Text("Generate Salary", style: GoogleFonts.poppins(fontSize: 13.sp, fontWeight: FontWeight.w600)),
            )
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey)),
        Text(value, style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.bold, color: valueColor ?? Colors.black87)),
      ],
    );
  }

  Widget _detailRow(String label, String value, {bool isNegative = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.blueGrey)),
          Text(value, style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: isNegative ? Colors.red : Colors.black87)),
        ],
      ),
    );
  }
}
