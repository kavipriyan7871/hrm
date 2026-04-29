import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'training_schedule_screen.dart';
import 'training_complete_screen.dart';

class TrainingManagementScreen extends StatelessWidget {
  const TrainingManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> trainingFeatures = [
      {
        "title": "Training Schedule",
        "icon": Icons.event_note_outlined,
        "color": const Color(0xFFE3F2FD),
        "target": const TrainingScheduleScreen(),
      },
      {
        "title": "Training Complete",
        "icon": Icons.task_alt_outlined,
        "color": const Color(0xFFE8F5E9),
        "target": const TrainingCompleteScreen(),
      },
      {
        "title": "Training Analytics",
        "icon": Icons.analytics_outlined,
        "color": const Color(0xFFFFF3E0),
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Training & Development",
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: trainingFeatures.length,
        itemBuilder: (context, index) {
          final item = trainingFeatures[index];
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
          if (item['target'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => item['target'] as Widget),
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
