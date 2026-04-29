import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AttendanceTimelineScreen extends StatelessWidget {
  const AttendanceTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Today Work Progress Report",
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Summary Card (Green)
            Container(
              margin: EdgeInsets.all(16.w),
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: const Color(0xFF006D21), // Forest Green
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tuesday 3 March",
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "Today's Work Progress",
                    style: GoogleFonts.poppins(
                      fontSize: 18.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      _buildSummaryItem(
                        "Day Duration",
                        "8 hr 05 m",
                        Icons.access_time,
                      ),
                      SizedBox(width: 12.w),
                      _buildSummaryItem(
                        "Client Visit",
                        "10 Visit",
                        Icons.location_on_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Timeline Card
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildTimelineItem(
                    title: "Office Check out",
                    time: "2025-12-05 18:00 PM",
                    icon: Icons.add,
                    isFirst: true,
                    titleColor: const Color(0xFF5C5CFF),
                  ),
                  _buildTimelineItem(
                    title: "Poster designs",
                    time: "14:30 PM - 18:00 PM",
                    description: "Directory Poster Design",
                    icon: Icons.access_time_filled,
                    titleColor: Colors.black87,
                  ),
                  _buildTimelineItem(
                    title: "HRM APP",
                    time: "10:30 AM - 13:00",
                    description: "HRM App Marketing Module\nUI Design",
                    icon: Icons.access_time_filled,
                    titleColor: Colors.black87,
                  ),
                  _buildTimelineItem(
                    title: "Daily Day Poster",
                    time: "09:00 AM - 10:00AM",
                    description: "March 3 Special Day Poster",
                    icon: Icons.access_time_filled,
                    titleColor: const Color(0xFF26A69A),
                  ),
                  _buildTimelineItem(
                    title: "Office Checkin",
                    time: "2025-12-05 08:45 AM",
                    icon: Icons.access_time_filled,
                    isLast: true,
                    titleColor: const Color(0xFF5C5CFF),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Container(
      width: 110.w,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.sp, color: const Color(0xFF1D264F)),
              SizedBox(width: 4.w),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 8.sp,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Padding(
            padding: EdgeInsets.only(left: 20.w),
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 11.sp,
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String time,
    String? description,
    required IconData icon,
    bool isFirst = false,
    bool isLast = false,
    required Color titleColor,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Column
          Column(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFF26A69A),
                    width: 2.w,
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 18.sp,
                    color: const Color(0xFF26A69A),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5.w,
                    color: const Color(0xFF26A69A).withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
          SizedBox(width: 16.w),
          // Content Column
          Expanded(
            child: Container(
              padding: EdgeInsets.only(bottom: 24.h, top: 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    time,
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: Colors.black.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (description != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        color: Colors.black87,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
