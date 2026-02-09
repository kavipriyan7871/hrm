import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrm/views/home/security.dart';
import 'package:hrm/views/login_section/sign-up.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main_root.dart';
import 'account_setting.dart';
import 'expense.dart';
import 'feedback.dart';
import 'notification_alert.dart';

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEmployeeDetails();
  }

  Future<void> _fetchEmployeeDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int uid = prefs.getInt('uid') ?? 0;
      // Using "145" as fallback to match the successful snippet provided for this API
      final String lat = prefs.getDouble('lat')?.toString() ?? "145";
      final String lng = prefs.getDouble('lng')?.toString() ?? "145";

      // Get Device ID
      String deviceId = "123456"; // Default/Fallback device ID
      try {
        final deviceInfo = DeviceInfoPlugin();
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id;
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor ?? "123456";
        }
      } catch (e) {
        debugPrint("Could not get real device ID, using fallback: $e");
      }

      debugPrint("FETCHING EMP DETAILS FOR UID: $uid, DEVICE: $deviceId");

      final response = await EmployeeApi.getEmployeeDetails(
        uid: uid == 0 ? "9" : uid.toString(), // Using 9 as fallback if uid is 0
        cid: "21472147",
        deviceId: deviceId,
        lat: lat == "0.0" ? "145" : lat,
        lng: lng == "0.0" ? "145" : lng,
      );

      if (response["error"] == false || response["error"] == "false") {
        setState(() {
          userName = response["name"] ?? "User";
          userCode = response["employee_code"] ?? "";
          userMobile = response["contact_number"] ?? "";
          profilePhoto = response["profile_photo"] ?? "";
          isLoading = false;
        });

        // Save for other screens to use
        await prefs.setString('name', userName);
        await prefs.setString('employee_code', userCode);
        await prefs.setString('mobile', userMobile);
        await prefs.setString('dept', response["department"] ?? "");
        await prefs.setString('employee_type', response["employee_type"] ?? "");
        await prefs.setString('doj', response["date_of_joining"] ?? "");
        await prefs.setString('dob', response["dob"] ?? "");
        await prefs.setString('address', response["address"] ?? "");
        await prefs.setString('profile_photo', profilePhoto);
      } else {
        setState(() {
          userName = prefs.getString('name') ?? "User";
          userMobile = prefs.getString('mobile') ?? "";
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching employee details: $e");
      setState(() => isLoading = false);
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
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainRoot()),
              (route) => false,
            );
          },
        ),
        title: Text(
          'Settings',
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
                        image: DecorationImage(
                          image: profilePhoto.isNotEmpty
                              ? NetworkImage(profilePhoto)
                              : const AssetImage('assets/profile.png')
                                    as ImageProvider,
                          fit: BoxFit.cover,
                        ),
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
                              const SizedBox(width: 8),
                              const Text(
                                'Edit',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.edit,
                                color: Colors.white70,
                                size: 12,
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
                              const Text(
                                'View Full Profile',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
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
    return Column(
      children: [
        _buildSettingOption(
          "Account Setting",
          "assets/account.png",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AccountSettingsApp()),
          ),
        ),
        const Divider(height: 1, indent: 20, endIndent: 20),
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
          "Expense",
          "assets/expense.png",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ExpenseManagementScreen(),
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
        _buildSettingOption(
          "Logout",
          "assets/logout.png",
          isLogout: true,
          onTap: () => _showLogoutConfirmation(context),
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
          activeColor: const Color(0xFF233E94), // Dark blue thumb
          activeTrackColor: const Color(0xFFD1D5DB), // Light grey track
          inactiveThumbColor: const Color(0xFF9CA3AF),
          inactiveTrackColor: const Color(0xFFE5E7EB),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Are you sure want to Logout?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 45,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.black54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            "NO",
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: SizedBox(
                        height: 45,
                        child: ElevatedButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs
                                .clear(); // Optional: clear data on logout

                            if (mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignupScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff233E94),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            "YES",
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
