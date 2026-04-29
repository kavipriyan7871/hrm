import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_leave_requests.dart';
import 'admin_leave_status.dart';
import 'admin_leave_report.dart';
import 'apply_leave.dart';

class AdminLeaveManagementScreen extends StatelessWidget {
  const AdminLeaveManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Leaves Management",
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              _buildFeatureCard(
                context,
                title: "Leave report",
                icon: Icons.assessment_outlined,
                color: const Color(0xFFE8F5E9),
                iconColor: const Color(0xFF388E3C),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminLeaveReportScreen(),
                  ),
                ),
              ),
              _buildFeatureCard(
                context,
                title: "Leave Request",
                icon: Icons.forward_to_inbox_outlined,
                color: const Color(0xFFFFF3E0),
                iconColor: const Color(0xFFF57C00),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminLeaveRequestsScreen(),
                  ),
                ),
              ),
              _buildFeatureCard(
                context,
                title: "Leave Status",
                icon: Icons.check_circle_outline,
                color: const Color(0xFFF3E5F5),
                iconColor: const Color(0xFF7B1FA2),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminLeaveStatusScreen(),
                  ),
                ),
              ),
              _buildFeatureCard(
                context,
                title: "Apply Leave",
                icon: Icons.edit_calendar_outlined,
                color: const Color(0xFFE0F2F1),
                iconColor: const Color(0xFF00897B),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ApplyLeaveScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 25.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: iconColor, size: 28.sp),
              ),
              SizedBox(width: 20.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14.sp,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
