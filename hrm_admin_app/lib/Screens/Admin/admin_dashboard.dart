import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../Widgets/bottom_nav_bar.dart';
import '../../Widgets/drawer_screen.dart';
import 'Chat/chat_groups.dart';
import 'PayrollManagement/admin_payroll_management.dart';
import 'admin_approvals_screen.dart';
import '../../Models/leave_api.dart';
import '../../Models/employee_api.dart';
import '../../Utils/shared_prefs_util.dart';

class AdminDashboard extends StatefulWidget {
  final VoidCallback? onBackToHrm;
  final bool isEmbedded;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  const AdminDashboard({super.key, this.onBackToHrm, this.isEmbedded = false, this.scaffoldKey});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  int _pendingLeaveCount = 0;
  bool _isCountLoading = false;

  /// BODIES FOR NAVIGATION
  late final List<Widget> _bodies;

  @override
  void initState() {
    super.initState();
    _bodies = [
      _buildHomeBody(),
      const AdminPayrollManagementScreen(),
      const ChatGroupScreen(),
    ];
    _fetchLeaveCount();
  }

  Future<void> _fetchLeaveCount() async {
    if (!mounted) return;
    setState(() => _isCountLoading = true);
    try {
      final String uid = await SharedPrefsUtil.getUid();
      String? reportingManager;
      try {
        final empResponse = await EmployeeApi.fetchEmployeeDetails(uid: uid);
        if (empResponse.data.isNotEmpty) {
          reportingManager = empResponse.data.first.reportingManager;
        }
      } catch (e) {
        debugPrint("Error fetching reporting manager for count: $e");
      }

      final response = await LeaveApi.fetchLeaveRequests(reportingManager: reportingManager);
      if (mounted) {
        setState(() {
          _pendingLeaveCount = response.data.where((doc) {
            final s = doc.status?.toLowerCase() ?? "";
            return s == "pending" || s == "";
          }).length;
          _isCountLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching leave count: $e");
      if (mounted) setState(() => _isCountLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveKey = widget.scaffoldKey ?? _scaffoldKey;
    return Scaffold(
      key: effectiveKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawerEnableOpenDragGesture: !widget.isEmbedded,
      appBar: (widget.isEmbedded || _currentIndex != 0) ? null : _buildAppBar(),
      drawer: AdminDrawer(onBackToHrm: widget.onBackToHrm),
      body: IndexedStack(index: _currentIndex, children: _bodies),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildHomeBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// GREETING & DATE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14.sp, color: const Color(0xFF26A69A)),
                    SizedBox(width: 8.w),
                    Text(
                      DateFormat('MMM dd, yyyy').format(DateTime.now()),
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF26A69A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          /// QUICK STATS GRID
          Row(
            children: [
              _buildQuickStatCard(
                "Total Employees",
                "128",
                Icons.people_alt_rounded,
                [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
              ),
              SizedBox(width: 14.w),
              _buildQuickStatCard(
                "Active Staff",
                "116",
                Icons.how_to_reg_rounded,
                [const Color(0xFF10B981), const Color(0xFF059669)],
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              _buildQuickStatCard(
                "Pending Leaves",
                _pendingLeaveCount.toString().padLeft(2, '0'),
                Icons.event_busy_rounded,
                [const Color(0xFFF59E0B), const Color(0xFFD97706)],
              ),
              SizedBox(width: 14.w),
              _buildQuickStatCard(
                "Overdue Tasks",
                "04",
                Icons.assignment_late_rounded,
                [const Color(0xFFEF4444), const Color(0xFFDC2626)],
              ),
            ],
          ),
          SizedBox(height: 24.h),

          /// APPROVAL BANNER
          _buildApprovalsCard(),
          SizedBox(height: 30.h),

          /// SECTION TITLE
          Text(
            "Management Hub",
            style: GoogleFonts.outfit(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 16.h),

          /// SHORTCUT GRID
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 20.h,
              crossAxisSpacing: 10.w,
              childAspectRatio: 0.75,
              children: [
                _buildSmallShortcut("Staff", Icons.badge_rounded, const Color(0xFF6366F1)),
                _buildSmallShortcut("Leave", Icons.holiday_village_rounded, const Color(0xFFF59E0B)),
                _buildSmallShortcut("Salary", Icons.account_balance_wallet_rounded, const Color(0xFF10B981)),
                _buildSmallShortcut("Notice", Icons.notifications_active_rounded, const Color(0xFFEC4899)),
                _buildSmallShortcut("Report", Icons.analytics_rounded, const Color(0xFF06B6D4)),
                _buildSmallShortcut("Log", Icons.history_rounded, const Color(0xFF64748B)),
                _buildSmallShortcut("Assets", Icons.inventory_2_rounded, const Color(0xFF8B5CF6)),
                _buildSmallShortcut("More", Icons.grid_view_rounded, const Color(0xFF26A69A)),
              ],
            ),
          ),
          SizedBox(height: 30.h),

          /// SYSTEM ALERTS
          Text(
            "Priority Alerts",
            style: GoogleFonts.outfit(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 16.h),
          _buildAnnouncementBanner(),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  Widget _buildSmallShortcut(String label, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 44.h,
          width: 44.w,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(icon, color: color, size: 22.sp),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(
    String title,
    String count,
    IconData icon,
    List<Color> gradient,
  ) {
    return Expanded(
      child: Container(
        constraints: BoxConstraints(minHeight: 110.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                icon,
                color: Colors.white.withOpacity(0.12),
                size: 70.sp,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18.sp),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count,
                      style: GoogleFonts.outfit(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final effectiveKey = widget.scaffoldKey ?? _scaffoldKey;
    return AppBar(
      backgroundColor: const Color(0xFF26A69A),
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: Colors.white),
        onPressed: () => effectiveKey.currentState?.openDrawer(),
      ),
      centerTitle: true,
      title: Text(
        "HRM Admin",
        style: GoogleFonts.outfit(
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAnnouncementBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 50.h,
            width: 50.w,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFF59E0B), size: 24),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Recent Leave Alerts",
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1E293B),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "$_pendingLeaveCount staff members are requesting leave for tomorrow.",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF64748B),
                    fontSize: 11.sp,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.chevron_right_rounded, color: const Color(0xFF475569), size: 20.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalsCard() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdminApprovalsScreen()),
        );
      },
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF26A69A), Color(0xFF00897B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF26A69A).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 50.h,
              width: 50.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: const Icon(Icons.task_alt_rounded, color: Colors.white, size: 28),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Approvals",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "Manage Leave & Permission requests",
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }

}
