import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AdvanceSalaryScreen extends StatefulWidget {
  const AdvanceSalaryScreen({super.key});

  @override
  State<AdvanceSalaryScreen> createState() => _AdvanceSalaryScreenState();
}

class _AdvanceSalaryScreenState extends State<AdvanceSalaryScreen> {
  final List<Map<String, dynamic>> _salaryAdvances = [
    {
      "name": "Kavi Priyan",
      "id": "EMP001",
      "amount": "₹5,000",
      "reason": "Personal Emergency",
      "status": "Pending",
      "date": "04 Apr 2024",
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Kavi",
    },
    {
      "name": "Arun Kumar",
      "id": "EMP002",
      "amount": "₹3,000",
      "reason": "Family Function",
      "status": "Approved",
      "date": "02 Apr 2024",
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Arun",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          "Advance Salary Requests",
          style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _salaryAdvances.length,
        itemBuilder: (context, index) => _advanceRequestCard(_salaryAdvances[index]),
      ),
    );
  }

  Widget _advanceRequestCard(Map<String, dynamic> data) {
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
               _statusBadge(data['status']),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoTile("Request Amount", data['amount'], valueColor: Colors.deepPurple),
              _infoTile("Reason", data['reason']),
              _infoTile("Date", data['date']),
            ],
          ),
          if (isPending)
            Padding(
              padding: EdgeInsets.only(top: 16.h),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                      ),
                      child: Text("Reject", style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600)),
                    )
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                         setState(() => data['status'] = 'Approved');
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Advance Salary Approved")));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF26A69A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                      ),
                      child: Text("Approve", style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600)),
                    )
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey)),
        Text(value, style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.bold, color: valueColor ?? Colors.black87)),
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color color = status == 'Approved' ? Colors.green : Colors.orange;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6.r)),
      child: Text(status, style: GoogleFonts.poppins(fontSize: 10.sp, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
