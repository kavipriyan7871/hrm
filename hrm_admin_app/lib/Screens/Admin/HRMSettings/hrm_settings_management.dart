import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class HRMSettingsManagementScreen extends StatelessWidget {
  const HRMSettingsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> settingsFeatures = [
      {"title": "Location", "icon": Icons.location_on_outlined, "color": const Color(0xFFE3F2FD)},
      {"title": "Status (task)", "icon": Icons.task_alt_outlined, "color": const Color(0xFFE8F5E9)},
      {"title": "Approved by", "icon": Icons.how_to_reg_outlined, "color": const Color(0xFFFFF3E0)},
      {"title": "Permission type", "icon": Icons.admin_panel_settings_outlined, "color": const Color(0xFFF3E5F5)},
      {"title": "Purpose of visit", "icon": Icons.meeting_room_outlined, "color": const Color(0xFFFFEBEE)},
      {"title": "Deduction Type", "icon": Icons.money_off_outlined, "color": const Color(0xFFE0F7FA)},
      {"title": "Department", "icon": Icons.business_outlined, "color": const Color(0xFFEFEBE9)},
      {"title": "Document Type", "icon": Icons.file_present_outlined, "color": const Color(0xFFFFF9DB)},
      {"title": "Designation", "icon": Icons.work_outline, "color": const Color(0xFFE7F5FF)},
      {"title": "Job type", "icon": Icons.badge_outlined, "color": const Color(0xFFFFECEC)},
      {"title": "Priority", "icon": Icons.priority_high_outlined, "color": const Color(0xFFEBFAFF)},
      {"title": "Leave Types", "icon": Icons.event_busy_outlined, "color": const Color(0xFFF3E5F5)},
      {"title": "Allowance Type", "icon": Icons.payments_outlined, "color": const Color(0xFFE8F5E9)},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "HRM Settings",
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: settingsFeatures.length,
        itemBuilder: (context, index) {
          final item = settingsFeatures[index];
          return _buildFeatureItem(context, item);
        },
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, Map<String, dynamic> item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: item['color'],
            shape: BoxShape.circle,
          ),
          child: Icon(
            item['icon'],
            color: const Color(0xFF263238),
            size: 22.sp,
          ),
        ),
        title: Text(
          item['title'],
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        trailing: Container(
          padding: EdgeInsets.all(4.w),
          decoration: const BoxDecoration(
            color: Color(0xFF26A69A),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_forward_ios,
            color: Colors.white,
            size: 10.sp,
          ),
        ),
        onTap: () {
          // Future implementations for sub-features
        },
      ),
    );
  }
}
