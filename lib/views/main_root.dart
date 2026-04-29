import 'package:flutter/material.dart';
import 'package:hrm/views/chat/chat.dart';
import 'package:hrm/views/widgets/bottom_nav.dart';
import 'attendance_history/attendance.dart';
import 'home/payroll.dart';
import 'home_screen/dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hrm/models/employee_api.dart';
import 'package:flutter/foundation.dart';

class MainRoot extends StatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onHomePressed;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const MainRoot({
    super.key,
    this.isEmbedded = false,
    this.onHomePressed,
    this.scaffoldKey,
  });

  @override
  State<MainRoot> createState() => _MainRootState();
}

class _MainRootState extends State<MainRoot> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _preFetchUserProfile();
  }

  Future<void> _preFetchUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // ✅ SESSION UID: Use login_cus_id for authentication (priority)
      final String sessionUid = prefs.getString('login_cus_id') ?? 
                                prefs.getString('uid') ?? 
                                prefs.getString('employee_table_id') ?? 
                                prefs.get('uid')?.toString() ??
                                "";

      final String lat = prefs.getString('lt') ?? prefs.getDouble('lat')?.toString() ?? "";
      final String lng = prefs.getString('ln') ?? prefs.getDouble('lng')?.toString() ?? "";
      final String deviceId = prefs.getString('device_id') ?? "";
      final String cid = prefs.getString('cid') ?? prefs.getString('cid_str') ?? "";
      final String token = prefs.getString('token') ?? "";
      
      final body = {
        "type": "2048",
        "cid": cid,
        "uid": sessionUid,
        "id": sessionUid,
        "cus_id": sessionUid,
        "device_id": deviceId,
        "lt": lat,
        "ln": lng,
        if (token != null && token.isNotEmpty) "token": token,
      };

      debugPrint("Employee Details API Request (2048) => $body");
      final response = await EmployeeApi.getEmployeeDetails(
        uid: sessionUid,
        cid: cid,
        deviceId: deviceId,
        lat: lat,
        lng: lng,
        token: token,
      );

      debugPrint("Employee Details API Response (2048) => $response");

      if (response["error"] == false || response["error"] == "false") {
        final profileData = response["data"] ?? {};
        // Save profile data for all screens to use immediately
        await prefs.setString('name', profileData["name"]?.toString() ?? "User");
        await prefs.setString('employee_code', profileData["employee_code"]?.toString() ?? "");
        await prefs.setString('mobile', profileData["contact_number"]?.toString() ?? profileData["mobile"]?.toString() ?? "");
        await prefs.setString('profile_photo', profileData["profile_photo"]?.toString() ?? "");
        
        // Internal IDs (for reference only, do NOT overwrite session uid)
        final dynamic returnedCusId = profileData["cus_id"] ?? profileData["id"] ?? response["uid"];
        if (returnedCusId != null) {
          final String returnedUidStr = returnedCusId.toString();
          // We save it as db_id_reference/db_uid_reference instead of overwriting uid
          await prefs.setString('db_id_reference', returnedUidStr);
          await prefs.setString('db_uid_reference', returnedUidStr);
        }
        debugPrint("MainRoot => Profile Persisted: ${profileData["name"]}");
      }
    } catch (e) {
      debugPrint("MainRoot Prefetch Error => $e");
    }
  }

  late final List<Widget> _screens = [
    Dashboard(isEmbedded: widget.isEmbedded, onHomePressed: widget.onHomePressed),
    AttendanceScreen(),
    PayrollScreen(),
    ChatProjectsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    assert(_screens.length == 4);
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: AppBottomNav(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
