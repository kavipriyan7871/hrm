import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class JobApplicationsScreen extends StatefulWidget {
  const JobApplicationsScreen({super.key});

  @override
  State<JobApplicationsScreen> createState() => _JobApplicationsScreenState();
}

class _JobApplicationsScreenState extends State<JobApplicationsScreen> {
  final List<Map<String, dynamic>> applications = [
    {
      "name": "Kavi Priyan",
      "position": "Senior Flutter Developer",
      "experience": "4.5 Years",
      "appliedDate": "04-04-2026",
      "status": "Shortlisted",
      "image": "assets/profile.png",
    },
    {
      "name": "Arun Kumar",
      "position": "UI/UX Designer",
      "experience": "2 Years",
      "appliedDate": "03-04-2026",
      "status": "Pending",
      "image": "assets/profile.png",
    },
    {
      "name": "Santhosh Mani",
      "position": "Marketing Manager",
      "experience": "6 Years",
      "appliedDate": "02-04-2026",
      "status": "Rejected",
      "image": "assets/profile.png",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Job Applications",
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTabHeader(),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: applications.length,
                itemBuilder: (context, index) {
                  return _buildApplicationCard(applications[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabItem("All (12)", true),
          _buildTabItem("Pending (05)", false),
          _buildTabItem("Selected (03)", false),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, bool isSelected) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF26A69A).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13.sp,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? const Color(0xFF26A69A) : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> candidate) {
    Color statusColor = Colors.orange;
    if (candidate['status'] == 'Shortlisted') statusColor = Colors.green;
    if (candidate['status'] == 'Rejected') statusColor = Colors.red;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8.r,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25.r,
                backgroundColor: Colors.grey.shade100,
                backgroundImage: const AssetImage("assets/profile.png"),
              ),
              SizedBox(width: 15.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      candidate['position'],
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: const Color(0xFF26A69A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  candidate['status'],
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCandidateMeta(Icons.history, candidate['experience']),
              _buildCandidateMeta(Icons.calendar_today_outlined, candidate['appliedDate']),
              const Spacer(),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF26A69A),
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
                child: Text(
                  "Review CV",
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateMeta(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(right: 12.w),
      child: Row(
        children: [
          Icon(icon, size: 14.w, color: Colors.grey),
          SizedBox(width: 4.w),
          Text(
            text,
            style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
