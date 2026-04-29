import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminExpenseReportScreen extends StatefulWidget {
  const AdminExpenseReportScreen({super.key});

  @override
  State<AdminExpenseReportScreen> createState() => _AdminExpenseReportScreenState();
}

class _AdminExpenseReportScreenState extends State<AdminExpenseReportScreen> {
  final List<Map<String, dynamic>> _approvedExpenses = [
    {
      "name": "Kavi Priyan",
      "id": "EMP001",
      "type": "Client Travel",
      "amount": "₹1,250",
      "date": "04 Apr 2024",
      "status": "Finalized",
      "approver": "Admin (Suresh)",
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Kavi",
    },
    {
      "name": "Arun Kumar",
      "id": "EMP002",
      "type": "Office Supplies",
      "amount": "₹450",
      "date": "03 Apr 2024",
      "status": "Disbursed",
      "approver": "HR (Priya)",
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Arun",
    },
    {
       "name": "Santhosh Mani",
       "id": "EMP003",
       "type": "Food & Meal",
       "amount": "₹820",
       "date": "02 Apr 2024",
       "status": "Approved",
       "approver": "MD (Ramesh)",
       "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Santhosh",
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          "Approved Expenses",
          style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildTotalSummary(),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: _approvedExpenses.length,
              itemBuilder: (context, index) => _expenseReportCard(_approvedExpenses[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSummary() {
    return Container(
      padding: EdgeInsets.all(20.w),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _sumItem("Approved This Month", "₹24,500", Colors.teal),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          _sumItem("Total Disbursed", "₹18,200", Colors.blue),
        ],
      ),
    );
  }

  Widget _sumItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.grey)),
        Text(value, style: GoogleFonts.poppins(fontSize: 20.sp, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _expenseReportCard(Map<String, dynamic> data) {
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
                    Text("${data['id']} | ${data['type']}", style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.grey)),
                  ],
                ),
              ),
              Text(data['amount'], style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.indigo)),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Approved By", style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey)),
                  Text(data['approver'], style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Approval Date", style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey)),
                  Text(data['date'], style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6.r)),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 12.sp, color: Colors.green),
                    SizedBox(width: 4.w),
                    Text(data['status'], style: GoogleFonts.poppins(fontSize: 10.sp, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
