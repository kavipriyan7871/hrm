import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Screens/Admin/Onboarding/onboarding_management.dart';
import '../Screens/Admin/PerformanceManagement/performance_management.dart';
import '../Screens/Admin/TrainingDevelopment/training_management.dart';
import '../Screens/Admin/HealthSafety/health_safety_management.dart';
import '../Screens/Admin/RecuritmentScreens/recruitment.dart';
import '../Screens/Admin/LeaveManagement/admin_leave_management.dart';
import '../Screens/Admin/PermissionManagement/admin_permission_management.dart';
import '../Screens/Admin/ExpenseManagement/admin_expense_management.dart';
import '../Screens/Admin/PayrollManagement/admin_payroll_management.dart';
import '../Screens/Admin/ComplaintManagement/admin_complaint_management.dart';
import '../Screens/Admin/EmployeeManagement/admin_employee_details.dart';
import '../Screens/Admin/AttendanceManagement/admin_attendance_management.dart';

class AdminDrawer extends StatelessWidget {
  final VoidCallback? onBackToHrm;
  const AdminDrawer({super.key, this.onBackToHrm});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // _buildDrawerItem(Icons.dashboard_outlined, "Dashboard", () => Navigator.pop(context)),
                // _buildDrawerItem(Icons.person_outline, "My Profile", () {}),
                // _buildDrawerItem(Icons.notifications_none, "Notifications", () {}),
                // _buildDrawerItem(Icons.settings_outlined, "Settings", () {}),
                // _buildDrawerItem(Icons.help_outline, "Help & Support", () {}),
                _buildDrawerItem(Icons.home_outlined, "HRM", () {
                  if (onBackToHrm != null) {
                    onBackToHrm!();
                  } else {
                    Navigator.pop(context);
                  }
                }),

                // _buildDrawerItem(
                //   Icons.logout,
                //   "Logout",
                //   () => _handleLogout(context),
                //   color: Colors.red,
                // ),
                const Divider(),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  child: Text(
                    "Management Hub",
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                _buildDrawerItem(
                  Icons.badge_outlined,
                  "Employee Details",
                  () => _navigate(context, const AdminEmployeeFeatureScreen()),
                ),
                _buildDrawerItem(
                  Icons.fact_check_rounded,
                  "Attendance Management",
                  () => _navigate(context, const AdminAttendanceManagementScreen()),
                ),
                _buildDrawerItem(
                  Icons.event_note_outlined,
                  "Leave Management",
                  () => _navigate(context, const AdminLeaveManagementScreen()),
                ),
                _buildDrawerItem(
                  Icons.person_search_outlined,
                  "Recruitment",
                  () => _navigate(context, const RecruitmentScreen()),
                ),
                _buildDrawerItem(
                  Icons.how_to_reg_outlined,
                  "Onboarding",
                  () => _navigate(context, const OnboardingManagementScreen()),
                ),
                _buildDrawerItem(
                  Icons.gavel_outlined,
                  "Complaints",
                  () => _navigate(
                    context,
                    const AdminComplaintManagementScreen(),
                  ),
                ),
                _buildDrawerItem(
                  Icons.payments_outlined,
                  "Payroll",
                  () =>
                      _navigate(context, const AdminPayrollManagementScreen()),
                ),
                _buildDrawerItem(
                  Icons.admin_panel_settings_outlined,
                  "Permissions",
                  () => _navigate(
                    context,
                    const AdminPermissionManagementScreen(),
                  ),
                ),
                _buildDrawerItem(
                  Icons.account_balance_wallet_outlined,
                  "Expense",
                  () =>
                      _navigate(context, const AdminExpenseManagementScreen()),
                ),
                _buildDrawerItem(
                  Icons.speed_outlined,
                  "Performance",
                  () => _navigate(context, const PerformanceManagementScreen()),
                ),
                _buildDrawerItem(
                  Icons.school_outlined,
                  "Training",
                  () => _navigate(context, const TrainingManagementScreen()),
                ),
                _buildDrawerItem(
                  Icons.health_and_safety_outlined,
                  "Health & Safety",
                  () =>
                      _navigate(context, const HealthSafetyManagementScreen()),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Text(
              "Version 1.0.2",
              style: GoogleFonts.poppins(
                fontSize: 10.sp,
                color: Colors.black38,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: 60.h,
        bottom: 30.h,
        left: 20.w,
        right: 20.w,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF26A69A),
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            "assets/images/logo.png",
            height: 50.h,
            errorBuilder: (_, __, ___) => Icon(
              Icons.business,
              color: Colors.white,
              size: 50.sp,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            "Global ERP",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "HRM Management System",
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color color = Colors.black87,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22.sp),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14.sp,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _navigate(BuildContext context, Widget target) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => target));
  }

  // Future<void> _handleLogout(BuildContext context) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.clear();
  //   if (context.mounted) {
  //     Navigator.pushAndRemoveUntil(
  //       context,
  //       MaterialPageRoute(builder: (_) => const LoginScreen()),
  //       (route) => false,
  //     );
  //   }
  // }
}
