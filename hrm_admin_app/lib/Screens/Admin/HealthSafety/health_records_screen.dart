import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class HealthRecordsScreen extends StatelessWidget {
  const HealthRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> healthData = [
      {
        "name": "Kavi Priyan",
        "id": "EMP001",
        "bloodGroup": "O+",
        "allergies": "None",
        "lastCheckup": "15 Mar 2024",
        "status": "Healthy",
        "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Kavi",
      },
      {
        "name": "Arun Kumar",
        "id": "EMP002",
        "bloodGroup": "B+",
        "allergies": "Dust",
        "lastCheckup": "10 Jan 2024",
        "status": "Healthy",
        "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Arun",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          "Employee Health Records",
          style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: healthData.length,
        itemBuilder: (context, index) => _healthCard(healthData[index]),
      ),
    );
  }

  Widget _healthCard(Map<String, dynamic> data) {
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6.r)),
                child: Text(data['status'], style: GoogleFonts.poppins(fontSize: 10.sp, fontWeight: FontWeight.bold, color: Colors.green)),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoTile("Blood Group", data['bloodGroup']),
              _infoTile("Allergies", data['allergies']),
              _infoTile("Last Checkup", data['lastCheckup']),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: Icon(Icons.history, size: 16.sp),
                label: Text("Medical History", style: GoogleFonts.poppins(fontSize: 11.sp, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(foregroundColor: Colors.teal),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey)),
        Text(value, style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
