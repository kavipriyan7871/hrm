import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrm/views/widgets/user_avatar.dart';
import 'package:hrm/views/home/security.dart';
import 'package:hrm/views/home_screen/employee_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../views/main_root.dart';
import 'expense.dart';
import 'feedback.dart';
import 'notification_alert.dart';
import 'package:hrm/views/home_screen/performance.dart';
import 'package:hrm/views/home_screen/reports.dart';
import 'package:hrm/views/marketing/marketing_selection.dart';
import 'package:hrm/views/home_screen/leave_management.dart';
import '../../models/employee_api.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _allowLocation = true;
  String userName = "Loading...";
  String userCode = "";
  String userMobile = "";
  String userEmail = "";
  String profilePhoto = "";
  String userRole = "";
  bool isLoading = true;
  bool _isAccountSettingsOpen = false;

  @override
  void initState() {
    super.initState();
    _fetchEmployeeDetails();
  }

  Future<void> _fetchEmployeeDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load cached data first for immediate display
      if (mounted) {
        setState(() {
          userName = prefs.getString('name') ?? "User";
          userMobile = prefs.getString('mobile') ?? "";
          profilePhoto = prefs.getString('profile_photo') ?? "";
          userRole = prefs.getString('role_name') ?? "";
          isLoading = false;
        });
      }

      // ✅ Standardized Identifier lookup
      final String uidToUse =
          prefs.getString('login_cus_id') ??
          prefs.getString('uid') ??
          prefs.getString('employee_table_id') ??
          "";

      final String lat = prefs.getDouble('lat')?.toString() ?? "0.0";
      final String lng = prefs.getDouble('lng')?.toString() ?? "0.0";
      final String cid =
          prefs.getString('cid') ?? prefs.getString('cid_str') ?? "";
      final String token = prefs.getString('token') ?? "";
      final String deviceId = prefs.getString('device_id') ?? "";

      final response = await EmployeeApi.getEmployeeDetails(
        uid: uidToUse,
        cid: cid,
        deviceId: deviceId,
        lat: lat,
        lng: lng,
        token: token,
      );

      if (response["error"] == false || response["error"] == "false") {
        if (!mounted) return;
        final profileData = response["data"] ?? {};
        setState(() {
          userName =
              profileData["name"]?.toString() ??
              prefs.getString('name') ??
              "User";
          userCode =
              profileData["employee_code"]?.toString() ??
              prefs.getString('employee_code') ??
              "";
          userMobile =
              profileData["contact_number"]?.toString() ??
              profileData["mobile"]?.toString() ??
              prefs.getString('mobile') ??
              "";
          profilePhoto =
              profileData["profile_photo"]?.toString() ??
              prefs.getString('profile_photo') ??
              "";
          isLoading = false;
        });

        // Save for other screens to use
        await prefs.setString('name', userName);
        await prefs.setString('employee_code', userCode);
        await prefs.setString('mobile', userMobile);
        await prefs.setString(
          'dept',
          profileData["department"]?.toString() ?? "",
        );
        await prefs.setString(
          'employee_type',
          profileData["employee_type"]?.toString() ?? "",
        );
        await prefs.setString(
          'doj',
          profileData["date_of_joining"]?.toString() ?? "",
        );
        await prefs.setString('dob', profileData["dob"]?.toString() ?? "");
        await prefs.setString(
          'address',
          profileData["address"]?.toString() ?? "",
        );
        await prefs.setString('profile_photo', profilePhoto);

        // ✅ IMPORTANT: Save the UID from Employee Details as the authoritative internal ID
        final dynamic returnedCusId =
            profileData["cus_id"] ?? profileData["id"];
        if (returnedCusId != null) {
          final String returnedUidStr = returnedCusId.toString();
          await prefs.setString('employee_table_id', returnedUidStr);
          await prefs.setString('uid', returnedUidStr);
          await prefs.setString(
            'assign_to',
            returnedUidStr,
          ); // Essential for Marketing
          await prefs.setInt('uid_int', int.tryParse(returnedUidStr) ?? 0);
          debugPrint(
            "SYNC => Local UID updated from Profile API: $returnedUidStr",
          );
        }
      } else if (response["error_msg"]?.toString().toLowerCase().contains(
                "session not found",
              ) ==
              true ||
          response["error_msg"]?.toString().toLowerCase().contains(
                "invalid token",
              ) ==
              true) {
        // ✅ AUTO-RECOVER: Clear bad IDs and Token by going back to login
        if (!mounted) return;
        _handleInvalidToken();
      } else {
        if (!mounted) return;
        setState(() {
          userName = prefs.getString('name') ?? "User";
          userMobile = prefs.getString('mobile') ?? "";
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching employee details: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _handleInvalidToken() async {
    final prefs = await SharedPreferences.getInstance();

    final List<String> persistenceKeys = [
      'lat',
      'lng',
      'device_id',
      'app_signature',
      'isCheckedIn',
      'last_checkin_date',
      'last_checkout_date',
      'is_on_break',
      'break_start_time',
      'current_break_id',
      'break_purpose',
      'marketing_attendance_mode',
      'has_done_marketing_today',
      'marketing_check_in_time',
      'checkin_face_profile',
    ];

    final allKeys = prefs.getKeys();
    for (String key in allKeys) {
      if (!persistenceKeys.contains(key)) {
        await prefs.remove(key);
      }
    }

    if (mounted) {
      // ✅ Back to Root (Host app will handle session expiration)
      Navigator.of(
        context,
        rootNavigator: true,
      ).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Logged out successfully.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_isAccountSettingsOpen) {
              setState(() {
                _isAccountSettingsOpen = false;
              });
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainRoot()),
                (route) => false,
              );
            }
          },
        ),
        title: Text(
          _isAccountSettingsOpen ? 'Account Settings' : 'Settings',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Color(0xFF465583)),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: UserAvatar(
                        radius: 35,
                        profileImageUrl: profilePhoto,
                        userName: userName,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                userName,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userMobile,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const EmployeeDetailsScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'View Full Profile',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Active',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _buildAccountSettingSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSettingSection() {
    if (_isAccountSettingsOpen) {
      return Column(
        children: [
          _buildSettingOption(
            "Notification & Alerts",
            "assets/notification.png",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationSettingsScreen(),
              ),
            ),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _buildSettingOptionWithToggle(
            "Allow Location",
            "assets/location.png",
            _allowLocation,
            (val) => setState(() => _allowLocation = val),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _buildSettingOption(
            "Feedback",
            "assets/feedback.png",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FeedbackSupportScreen(),
              ),
            ),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _buildSettingOption(
            "Security",
            "assets/security.png",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SecuritySettingsApp(),
              ),
            ),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
        ],
      );
    }

    return Column(
      children: [
        _buildSettingOption(
          "Account Setting",
          "assets/account.png",
          onTap: () {
            setState(() {
              _isAccountSettingsOpen = true;
            });
          },
        ),
        const Divider(height: 1, indent: 20, endIndent: 20),
        _buildSettingOption(
          "Expense",
          "assets/expense.png",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ExpenseManagementScreen(),
            ),
          ),
        ),
        _buildSettingOption(
          "Leave",
          "assets/leave.png",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LeaveManagementScreen(),
            ),
          ),
        ),
        const Divider(height: 1, indent: 20, endIndent: 20),
        _buildSettingOption(
          "Marketing",
          "assets/marketing.png",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MarketingSelectionScreen(),
            ),
          ),
        ),
        const Divider(height: 1, indent: 20, endIndent: 20),
        _buildSettingOption(
          "Performance",
          "assets/performance.png",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PerformanceScreen()),
          ),
        ),
        const Divider(height: 1, indent: 20, endIndent: 20),
        _buildSettingOption(
          "Report",
          "assets/reports.png",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportsScreen()),
          ),
        ),
        const Divider(height: 1, indent: 20, endIndent: 20),
      ],
    );
  }

  Widget _buildSettingOption(
    String title,
    String iconPath, {
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Image.asset(iconPath, width: 24, height: 24),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isLogout ? Colors.red : Colors.black87,
        ),
      ),
      trailing: isLogout
          ? null
          : const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  Widget _buildSettingOptionWithToggle(
    String title,
    String iconPath,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Image.asset(iconPath, width: 24, height: 24),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: Transform.scale(
        scale: 0.8,
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF233E94), // Dark blue thumb
          activeTrackColor: const Color(0xFFD1D5DB), // Light grey track
          inactiveThumbColor: const Color(0xFF9CA3AF),
          inactiveTrackColor: const Color(0xFFE5E7EB),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }
}
