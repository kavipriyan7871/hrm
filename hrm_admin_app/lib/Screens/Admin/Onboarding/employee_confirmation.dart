import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class EmployeeConfirmationScreen extends StatefulWidget {
  const EmployeeConfirmationScreen({super.key});

  @override
  State<EmployeeConfirmationScreen> createState() => _EmployeeConfirmationScreenState();
}

class _EmployeeConfirmationScreenState extends State<EmployeeConfirmationScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Employee Confirmation",
          style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("General Information"),
              SizedBox(height: 16.h),
              _buildTextField("Employee Name", "Enter employee name", Icons.person_outline),
              _buildTextField("Employee ID", "Enter employee ID", Icons.badge_outlined),
              _buildTextField("Department", "Enter department", Icons.business_outlined),
              _buildTextField("Designation", "Enter designation", Icons.work_outline),
              
              SizedBox(height: 24.h),
              _buildSectionTitle("Confirmation Details"),
              SizedBox(height: 16.h),
              _buildTextField("Start Date (Intern/Trainee)", "YYYY-MM-DD", Icons.calendar_today_outlined),
              _buildTextField("End Date (Intern/Trainee)", "YYYY-MM-DD", Icons.calendar_month_outlined),
              _buildTextField("Confirmation Date", "YYYY-MM-DD", Icons.event_available_outlined),
              _buildTextField("Status", "Confirmed / Extension / Terminated", Icons.info_outline),
              _buildTextField("Confirmation Letter", "PDF / Document reference", Icons.description_outlined),
              
              SizedBox(height: 24.h),
              _buildSectionTitle("Additional Information"),
              SizedBox(height: 16.h),
              _buildTextField("Remarks / Comments", "Enter additional remarks", Icons.comment_outlined, maxLines: 3),
              
              SizedBox(height: 40.h),
              _buildSubmitButton(),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: EdgeInsets.only(left: 8.w),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: const Color(0xFF26A69A), width: 4.w)),
      ),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 6.h),
          TextFormField(
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.black26),
              prefixIcon: Icon(icon, color: const Color(0xFF26A69A), size: 20.sp),
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: () {
          // Submit logic here
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF26A69A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          elevation: 2,
        ),
        child: Text(
          "Generate Confirmation",
          style: GoogleFonts.poppins(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
