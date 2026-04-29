import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'salary_generation_screen.dart';
import 'salary_structure_screen.dart';
import 'advance_salary_screen.dart';
import 'earnings_report_screen.dart';
import 'payslip_generation_screen.dart';
import 'payroll_report_screen.dart';

class AdminPayrollManagementScreen extends StatelessWidget {
  const AdminPayrollManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Payroll Management",
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
                title: "Salary Generation",
                icon: Icons.payments_outlined,
                color: const Color(0xFFE3F2FD),
                iconColor: const Color(0xFF1976D2),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SalaryGenerationScreen(),
                  ),
                ),
              ),
              _buildFeatureCard(
                 context,
                 title: "Salary Structure Setup",
                 icon: Icons.settings_suggest_outlined,
                 color: const Color(0xFFFFF3E0),
                 iconColor: const Color(0xFFF57C00),
                 onTap: () => Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (context) => const SalaryStructureScreen(),
                   ),
                 ),
               ),
               _buildFeatureCard(
                 context,
                 title: "Advance",
                 icon: Icons.account_balance_wallet_outlined,
                 color: const Color(0xFFFFEBEE),
                 iconColor: const Color(0xFFD32F2F),
                 onTap: () => Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (context) => const AdvanceSalaryScreen(),
                   ),
                 ),
               ),
               _buildFeatureCard(
                 context,
                 title: "Earnings",
                 icon: Icons.add_chart_outlined,
                 color: const Color(0xFFF3E5F5),
                 iconColor: const Color(0xFF7B1FA2),
                 onTap: () => Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (context) => const EarningsReportScreen(),
                   ),
                 ),
               ),
               _buildFeatureCard(
                 context,
                 title: "Pay Slip Generation",
                 icon: Icons.description_outlined,
                 color: const Color(0xFFE0F7FA),
                 iconColor: const Color(0xFF00ACC1),
                 onTap: () => Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (context) => const PayslipGenerationScreen(),
                   ),
                 ),
               ),
               _buildFeatureCard(
                 context,
                 title: "Salary Report",
                 icon: Icons.assignment_outlined,
                 color: const Color(0xFFF1F8E9),
                 iconColor: const Color(0xFF558B2F),
                 onTap: () => Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (context) => const PayrollReportScreen(),
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
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
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
                    fontSize: 15.sp,
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
