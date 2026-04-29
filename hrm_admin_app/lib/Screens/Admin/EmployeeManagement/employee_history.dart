import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class EmployeeHistoryScreen extends StatefulWidget {
  const EmployeeHistoryScreen({super.key});

  @override
  State<EmployeeHistoryScreen> createState() => _EmployeeHistoryScreenState();
}

class _EmployeeHistoryScreenState extends State<EmployeeHistoryScreen> {
  final List<Map<String, dynamic>> _employeeHistory = [
    {
      "name": "Kavi Priyan",
      "id": "EMP001",
      "event": "Promotion",
      "date": "10 Jan 2024",
      "oldValue": "Junior Developer",
      "newValue": "Senior Developer",
      "color": Colors.green,
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Kavi",
    },
    {
      "name": "Arun Kumar",
      "id": "EMP002",
      "event": "Transfer",
      "date": "15 Feb 2024",
      "oldValue": "Chennai H.O",
      "newValue": "Bangalore Branch",
      "color": Colors.blue,
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Arun",
    },
    {
       "name": "Santhosh Mani",
       "id": "EMP003",
       "event": "Dept. Change",
       "date": "05 Mar 2024",
       "oldValue": "Marketing",
       "newValue": "Creative",
       "color": Colors.orange,
       "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Santhosh",
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          "Employee Career History",
          style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _employeeHistory.length,
        itemBuilder: (context, index) => _buildHistoryCard(_employeeHistory[index]),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> history) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
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
              CircleAvatar(radius: 20.r, backgroundImage: NetworkImage(history['photo'])),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(history['name'], style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                    Text(history['id'], style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: (history['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  history['event'],
                  style: GoogleFonts.poppins(fontSize: 10.sp, fontWeight: FontWeight.bold, color: history['color'] as Color),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Previous", style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey)),
                    Text(history['oldValue'], style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
                  ],
                ),
              ),
              Icon(Icons.arrow_right_alt, color: Colors.grey.shade400),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("Current", style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey)),
                    Text(history['newValue'], style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.indigo)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.calendar_today, size: 12.sp, color: Colors.grey),
              SizedBox(width: 4.w),
              Text(history['date'], style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
