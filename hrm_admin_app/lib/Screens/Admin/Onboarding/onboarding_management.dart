import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../EmployeeManagement/employee_confirmation.dart';
import 'offer_letter_screen.dart';
import 'document_verification_screen.dart';
import 'joining_process_screen.dart';

class OnboardingManagementScreen extends StatelessWidget {
  const OnboardingManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> onboardingFeatures = [
      {
        "title": "Offer Letter",
        "icon": Icons.description_outlined,
        "color": const Color(0xFFE3F2FD),
        "target": const OfferLetterScreen(),
      },
      {
        "title": "Document Verification",
        "icon": Icons.verified_user_outlined,
        "color": const Color(0xFFE8F5E9),
        "target": const DocumentVerificationScreen(),
      },
      {
        "title": "Joining Process",
        "icon": Icons.handshake_outlined,
        "color": const Color(0xFFF3E5F5),
        "target": const JoiningProcessScreen(),
      },
      {
        "title": "Employee Confirmation",
        "icon": Icons.how_to_reg_outlined,
        "color": const Color(0xFFF1F8E9),
        "target": const EmployeeConfirmationScreen(),
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Onboarding Management",
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: onboardingFeatures.length,
        itemBuilder: (context, index) {
          final item = onboardingFeatures[index];
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
              MaterialPageRoute(builder: (_) => item['target']),
            );
          }
        },
      ),
    );
  }
}
