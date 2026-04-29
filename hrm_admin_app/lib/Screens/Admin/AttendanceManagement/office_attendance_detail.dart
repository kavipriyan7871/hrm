import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../Models/attendance_api.dart';

class OfficeAttendanceDetailScreen extends StatelessWidget {
  final AttendanceData record;
  const OfficeAttendanceDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Office Attendance Detail",
          style: GoogleFonts.outfit(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF26A69A),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// EMPLOYEE PROFILE SECTION
            _buildProfileSection(),
            SizedBox(height: 30.h),

            /// LOGS SECTION
            _buildSectionTitle("Daily Statistics"),
            SizedBox(height: 16.h),
            _buildStatsGrid(),
            SizedBox(height: 30.h),

            /// REMARKS SECTION
            _buildSectionTitle("Administrative Notes"),
            SizedBox(height: 16.h),
            _buildRemarksCard(),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF26A69A), Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF26A69A).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40.r,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              record.employeeName?.isNotEmpty == true ? record.employeeName![0].toUpperCase() : "?",
              style: GoogleFonts.outfit(fontSize: 32.sp, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            record.employeeName ?? "Unknown Employee",
            style: GoogleFonts.outfit(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 4.h),
          Text(
            "Employee Code: ${record.employeeCode ?? 'N/A'}",
            style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.white.withOpacity(0.8)),
          ),
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_month_rounded, color: Colors.white, size: 16.sp),
                SizedBox(width: 10.w),
                Text(
                  record.date ?? "No Date Provided",
                  style: GoogleFonts.poppins(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16.h,
      crossAxisSpacing: 16.w,
      childAspectRatio: 1.1,
      children: [
        _buildStatTile("CHECK IN", record.inTime ?? "--:--", Icons.login_rounded, Colors.green),
        _buildStatTile("CHECK OUT", record.outTime ?? "--:--", Icons.logout_rounded, Colors.orange),
        _buildStatTile("TOTAL HOURS", record.totalHours ?? "0", Icons.timer_rounded, Colors.blue),
        _buildStatTile("STATUS", record.status?.toUpperCase() ?? "COMPLETED", Icons.fact_check_rounded, Colors.purple),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 14.sp),
          ),
          SizedBox(height: 12.h),
          Text(label, style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey)),
          Text(
            value,
            style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRemarksCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sticky_note_2_rounded, color: Color(0xFF26A69A)),
              SizedBox(width: 12.w),
              Text(
                "Entry Remarks",
                style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Divider(height: 30),
          Text(
            record.remarks?.isNotEmpty == true ? record.remarks! : "No additional remarks were provided for this attendance entry.",
            style: GoogleFonts.poppins(fontSize: 13.sp, height: 1.6, color: const Color(0xFF475569)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
    );
  }
}
