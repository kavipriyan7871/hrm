import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MarketingTimelineScreen extends StatelessWidget {
  const MarketingTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
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
            // Summary Card
            Container(
              margin: EdgeInsets.all(16.w),
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1D264F),
                borderRadius: BorderRadius.circular(16.r),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryItem(
                        "Day Duration",
                        "8 hr 05 m",
                        Icons.access_time,
                      ),
                      _buildSummaryItem(
                        "Client Visit",
                        "10 Visit",
                        Icons.location_on_outlined,
                      ),
                      _buildSummaryItem(
                        "Travel KM",
                        "30 KM",
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
              padding: EdgeInsets.all(20.w),
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
                    icon: Icons.access_time_filled,
                    titleColor: const Color(0xFF5F5AFE),
                    isFirst: true,
                  ),
                  _buildTimelineItem(
                    title: "Client Visit - Hari",
                    time: "12:00 PM",
                    icon: Icons.access_time_filled,
                    titleColor: const Color(0xFF26A69A),
                    statusLabel: "Check Out - 1 Hr",
                    statusColor: const Color(0xFFFFF59D),
                  ),
                  _buildTimelineItem(
                    title: "Client Visit - Hari",
                    time: "11:00 AM",
                    icon: Icons.access_time_filled,
                    titleColor: const Color(0xFF26A69A),
                    statusLabel: "Check in",
                    statusColor: const Color(0xFF99F5A4),
                  ),
                  _buildTimelineItem(
                    title: "Client Visit - Akhil",
                    time: "10:00 AM",
                    icon: Icons.access_time_filled,
                    titleColor: Colors.black87,
                    statusLabel: "Check Out - 1 Hr",
                    statusColor: const Color(0xFFFFF59D),
                  ),
                  _buildTimelineItem(
                    title: "Client Visit - Akhil",
                    time: "09:00 AM",
                    icon: Icons.access_time_filled,
                    titleColor: const Color(0xFF26A69A),
                    statusLabel: "Check in",
                    statusColor: const Color(0xFF99F5A4),
                  ),
                  _buildTimelineItem(
                    title: "Attendance Check in",
                    time: "2025-12-05 08:45 AM",
                    icon: Icons.access_time_filled,
                    titleColor: const Color(0xFF5F5AFE),
                    isLast: true,
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
      width: 100.w,
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14.sp, color: const Color(0xFF1D264F)),
              SizedBox(width: 4.w),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 8.sp,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 10.sp,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String time,
    required IconData icon,
    required Color titleColor,
    String? statusLabel,
    Color? statusColor,
    bool isFirst = false,
    bool isLast = false,
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
                    color: const Color(0xFF26A69A).withOpacity(0.5),
                  ),
                ),
            ],
          ),
          SizedBox(width: 12.w),
          // Content Column
          Expanded(
            child: Container(
              padding: EdgeInsets.only(bottom: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                          ),
                        ),
                      ),
                      if (statusLabel != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            statusLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    time,
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
