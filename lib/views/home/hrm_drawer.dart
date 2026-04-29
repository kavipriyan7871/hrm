import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'settings.dart';
import 'expense.dart';
import '../home_screen/leave_management.dart';
import '../marketing/marketing_selection.dart';
import '../home_screen/performance.dart';
import '../home_screen/reports.dart';
import 'payroll.dart';
import 'ticket_raise.dart';
// import 'feedback.dart';
// import 'notification_alert.dart';
// import 'security.dart';
// import '../widgets/user_avatar.dart';
// import '../main_root.dart';
import '../home_screen/employee_detail.dart';
import 'package:hrm_admin_app/Screens/Admin/Onboarding/onboarding_management.dart';
import 'package:hrm_admin_app/Screens/Admin/PerformanceManagement/performance_management.dart';
import 'package:hrm_admin_app/Screens/Admin/TrainingDevelopment/training_management.dart';
import 'package:hrm_admin_app/Screens/Admin/HealthSafety/health_safety_management.dart';
import 'package:hrm_admin_app/Screens/Admin/RecuritmentScreens/recruitment.dart';
import 'package:hrm_admin_app/Screens/Admin/LeaveManagement/admin_leave_management.dart';
import 'package:hrm_admin_app/Screens/Admin/PermissionManagement/admin_permission_management.dart';
import 'package:hrm_admin_app/Screens/Admin/ExpenseManagement/admin_expense_management.dart';
import 'package:hrm_admin_app/Screens/Admin/PayrollManagement/admin_payroll_management.dart';
import 'package:hrm_admin_app/Screens/Admin/ComplaintManagement/admin_complaint_management.dart';
import 'package:hrm_admin_app/Screens/Admin/EmployeeManagement/admin_employee_details.dart';
import 'package:hrm_admin_app/Screens/Admin/AttendanceManagement/admin_attendance_management.dart';

class HRMDrawer extends StatefulWidget {
  final VoidCallback? onHomePressed;
  const HRMDrawer({super.key, this.onHomePressed});

  @override
  State<HRMDrawer> createState() => _HRMDrawerState();
}

class _HRMDrawerState extends State<HRMDrawer> {
  String userName = "User";
  String userRole = "";
  String profilePhoto = "";
  String userEmail = "";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('name') ?? "User";
      userRole = prefs.getString('role_name') ?? "Employee";
      profilePhoto = prefs.getString('profile_photo') ?? "";
      userEmail = prefs.getString('email') ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      width: MediaQuery.of(context).size.width * 0.85,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [

                // _buildSectionHeader("Account & Profile"),
                _buildDrawerItem(
                  icon: Icons.person_outline_rounded,
                  title: "Employee Details",
                  onTap: () => _navigate(const EmployeeDetailsScreen()),
                ),
                // _buildDrawerItem(
                //   icon: Icons.settings_outlined,
                //   title: "Account Settings",
                //   onTap: () => _navigate(const SettingsScreen()),
                // ),
                // _buildDrawerItem(
                //   icon: Icons.security_outlined,
                //   title: "Security & Privacy",
                //   onTap: () => _navigate(const SecuritySettingsApp()),
                // ),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                // _buildSectionHeader("Work Management"),
                _buildDrawerItem(
                  icon: Icons.receipt_long_outlined,
                  title: "Expense Management",
                  onTap: () => _navigate(const ExpenseManagementScreen()),
                ),
                _buildDrawerItem(
                  icon: Icons.event_available_outlined,
                  title: "Leave Management",
                  onTap: () => _navigate(const LeaveManagementScreen()),
                ),
                _buildDrawerItem(
                  icon: Icons.campaign_outlined,
                  title: "Marketing Attendance",
                  onTap: () => _navigate(const MarketingSelectionScreen()),
                ),
                _buildDrawerItem(
                  icon: Icons.payments_outlined,
                  title: "Payroll & Salary",
                  onTap: () => _navigate(const PayrollScreen()),
                ),

                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                // _buildSectionHeader("Performance & Analytics"),
                _buildDrawerItem(
                  icon: Icons.speed_outlined,
                  title: "My Performance",
                  onTap: () => _navigate(const PerformanceScreen()),
                ),
                _buildDrawerItem(
                  icon: Icons.analytics_outlined,
                  title: "Reports & Insights",
                  onTap: () => _navigate(const ReportsScreen()),
                ),

                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                // _buildSectionHeader("Support & Help"),
                _buildDrawerItem(
                  icon: Icons.confirmation_number_outlined,
                  title: "Raise a Ticket",
                  onTap: () => _navigate(const TicketRaise()),
                ),
                // _buildDrawerItem(
                //   icon: Icons.notifications_active_outlined,
                //   title: "Notifications",
                //   onTap: () => _navigate(const NotificationSettingsScreen()),
                // ),
                // _buildDrawerItem(
                //   icon: Icons.feedback_outlined,
                //   title: "App Feedback",
                //   onTap: () => _navigate(const FeedbackSupportScreen()),
                // ),
                // if (userRole.toLowerCase() == 'admin' || userRole.toLowerCase() == 'super admin') ...[
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  _buildSectionHeader("Management Hub"),
                  _buildDrawerItem(
                    icon: Icons.badge_outlined,
                    title: "Admin Employee Details",
                    onTap: () => _navigate(const AdminEmployeeFeatureScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.fact_check_rounded,
                    title: "Attendance Management",
                    onTap: () => _navigate(const AdminAttendanceManagementScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.event_note_outlined,
                    title: "Leave Approvel Management",
                    onTap: () => _navigate(const AdminLeaveManagementScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.person_search_outlined,
                    title: "Recruitment",
                    onTap: () => _navigate(const RecruitmentScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.how_to_reg_outlined,
                    title: "Onboarding",
                    onTap: () => _navigate(const OnboardingManagementScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.gavel_outlined,
                    title: "Complaints",
                    onTap: () => _navigate(const AdminComplaintManagementScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.payments_outlined,
                    title: "Payroll",
                    onTap: () => _navigate(const AdminPayrollManagementScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.admin_panel_settings_outlined,
                    title: "Permissions",
                    onTap: () => _navigate(const AdminPermissionManagementScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.account_balance_wallet_outlined,
                    title: "Expense",
                    onTap: () => _navigate(const AdminExpenseManagementScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.speed_outlined,
                    title: "Performance",
                    onTap: () => _navigate(const PerformanceManagementScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.school_outlined,
                    title: "Training",
                    onTap: () => _navigate(const TrainingManagementScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.health_and_safety_outlined,
                    title: "Health & Safety",
                    onTap: () => _navigate(const HealthSafetyManagementScreen()),
                  ),
                // ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: 40.h,
        bottom: 20.h,
        left: 24.w,
        right: 24.w,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF26A69A),
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(40)),
        gradient: LinearGradient(
          colors: [Color(0xFF26A69A), Color(0xFF4DB6AC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            userName,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            userRole,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (userEmail.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              userEmail,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 24.w, top: 20.h, bottom: 8.h),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: Colors.grey[400],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF465583), size: 24.sp),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF2C3E50),
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey, size: 16.sp),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 4.h),
      visualDensity: VisualDensity.compact,
    );
  }

  void _navigate(Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
}
