import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../TaskManagement/admin_task_assign.dart';
import 'promotion_management_screen.dart';
import 'performance_reports_screen.dart';

class PerformanceManagementScreen extends StatelessWidget {
  const PerformanceManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> performanceFeatures = [
      {
        "title": "Promotion Management",
        "icon": Icons.trending_up,
        "color": const Color(0xFFE3F2FD),
        "target": const PromotionManagementScreen(),
      },
      {
        "title": "Appraisal Templates",
        "icon": Icons.description_outlined,
        "color": const Color(0xFFE8F5E9),
      },
      {
        "title": "Task Setting",
        "icon": Icons.assignment_outlined,
        "color": const Color(0xFFFFF3E0),
        "target": const AdminTaskAssignScreen(),
      },
      {
        "title": "Manager Evaluation",
        "icon": Icons.rate_review_outlined,
        "color": const Color(0xFFF3E5F5),
      },
      {
        "title": "Project Allocation",
        "icon": Icons.account_tree_outlined,
        "color": const Color(0xFFFFEBEE),
      },
      {
        "title": "Performance Reports",
        "icon": Icons.analytics_outlined,
        "color": const Color(0xFFE0F7FA),
        "target": const PerformanceReportsScreen(),
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Performance Management",
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: performanceFeatures.length,
        itemBuilder: (context, index) {
          final item = performanceFeatures[index];
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
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.black38,
          size: 14.sp,
        ),
        onTap: () {
          if (item['target'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => item['target']),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("${item['title']} coming soon!")),
            );
          }
        },
      ),
    );
  }
}
