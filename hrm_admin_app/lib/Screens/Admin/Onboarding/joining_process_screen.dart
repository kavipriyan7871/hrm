import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class JoiningProcessScreen extends StatefulWidget {
  const JoiningProcessScreen({super.key});

  @override
  State<JoiningProcessScreen> createState() => _JoiningProcessScreenState();
}

class _JoiningProcessScreenState extends State<JoiningProcessScreen> {
  final List<Map<String, dynamic>> _newJoiners = [
    {
      "name": "Kavi Priyan",
      "joiningDate": "05 Apr 2024",
      "email": true,
      "seat": false,
      "idCard": false,
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Kavi",
    },
    {
      "name": "Santhosh Mani",
      "joiningDate": "10 Apr 2024",
      "email": false,
      "seat": false,
      "idCard": false,
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Santhosh",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          "Joining Process & Setup",
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _newJoiners.length,
        itemBuilder: (context, index) => _joinerCard(_newJoiners[index]),
      ),
    );
  }

  Widget _joinerCard(Map<String, dynamic> joiner) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundImage: NetworkImage(joiner['photo']),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      joiner['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Joining: ${joiner['joiningDate']}",
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _setupItem(
            "Company Email Setup",
            joiner['email'],
            Icons.email_outlined,
          ),
          _setupItem(
            "Workspace / Seat Allocation",
            joiner['seat'],
            Icons.chair_alt_outlined,
          ),
          _setupItem(
            "Physical ID Card Issued",
            joiner['idCard'],
            Icons.badge_outlined,
          ),
          SizedBox(height: 12.h),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.check_circle_outline, color: Colors.teal),
            label: Text(
              "Complete Onboarding",
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.teal,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFE0F2F1),
              minimumSize: Size(double.infinity, 40.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _setupItem(String label, bool status, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: Colors.blueGrey),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: Colors.black87,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: status,
              onChanged: (v) {},
              activeColor: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }
}
