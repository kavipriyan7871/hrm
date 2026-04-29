import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hrm/views/widgets/user_avatar.dart';
import '../../models/employee_api.dart';
import 'package:flutter/foundation.dart';

class EmployeeDetailsScreen extends StatefulWidget {
  const EmployeeDetailsScreen({super.key});

  @override
  State<EmployeeDetailsScreen> createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen> {
  bool emp = false;
  bool personal = false;
  bool edu = false;

  String userName = "User";
  String dept = "";
  String employeeType = "";
  String doj = "";
  String dob = "";
  String address = "";
  String gender = "";
  String mobile = "";
  String profilePhoto = "";
  String institutionName = "";
  String qualification = "";
  String specification = "";
  String passedOut = "";
  String bloodGroup = "";
  String emergencyName = "";
  String emergencyNumber = "";
  String? employeeTableId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployeeData();
  }

  Future<void> _loadEmployeeData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('name') ?? "User";
      dept = prefs.getString('dept') ?? "Flutter Team";
      employeeType = prefs.getString('employee_type') ?? "Permanent";
      doj = prefs.getString('doj') ?? "";
      dob = prefs.getString('dob') ?? "";
      address = prefs.getString('address') ?? "";
      gender = prefs.getString('gender') ?? "";
      mobile = prefs.getString('mobile') ?? "";
      profilePhoto = prefs.getString('profile_photo') ?? "";
      institutionName = prefs.getString('institution_name') ?? "";
      qualification = prefs.getString('qualification') ?? "";
      specification = prefs.getString('specification') ?? "";
      passedOut = prefs.getString('passed_out') ?? "";
      bloodGroup = prefs.getString('blood_group') ?? "";
      emergencyName = prefs.getString('emergency_name') ?? "";
      emergencyNumber = prefs.getString('emergency_number') ?? "";
      isLoading = false;
    });

    try {
      final String uid =
          prefs.getString('uid') ??
          prefs.getString('login_cus_id') ??
          prefs.get('uid')?.toString() ??
          "";

      final String cid =
          prefs.getString('cid') ?? prefs.getString('cid_str') ?? "";
      final String token = prefs.getString('token') ?? "";
      final String deviceId = prefs.getString('device_id') ?? "";
      final String lat = prefs.getDouble('lat')?.toString() ?? "0.0";
      final String lng = prefs.getDouble('lng')?.toString() ?? "0.0";

      debugPrint("FETCHING EMPLOYEE DETAILS FOR UID => $uid");
      debugPrint("FETCHING EMPLOYEE DETAILS FOR CID => $cid");
      debugPrint("FETCHING EMPLOYEE DETAILS WITH TOKEN => $token");

      final response = await EmployeeApi.getEmployeeDetails(
        uid: uid,
        cid: cid,
        deviceId: deviceId,
        lat: lat,
        lng: lng,
        token: token,
      );

      if (response["error"] == true || response["error"] == "true") {
        debugPrint("EMPLOYEE DETAILS ERROR RESPONSE => $response");
      }

      if (response["error"] == false || response["error"] == "false") {
        // Data is already saved in EmployeeApi, but we update the UI
        final profileData = response["data"] ?? {};
        if (mounted) {
          setState(() {
            String extract(String? val) {
              if (val == null || val.trim().isEmpty || val == "0" || val == "null") return "N/A";
              return val.trim();
            }

            userName = extract(profileData["name"]?.toString());
            if (userName == "N/A") userName = prefs.getString("name") ?? "User";
            
            String fetchedDept = extract(profileData["department_name"]?.toString());
            if (fetchedDept == "N/A") fetchedDept = extract(profileData["department"]?.toString());
            dept = fetchedDept == "N/A" ? "N/A" : fetchedDept;
            
            employeeType = extract(profileData["employee_type"]?.toString());
            doj = extract(profileData["date_of_joining"]?.toString());
            dob = extract(profileData["dob"]?.toString());
            
            String fetchedAddr = extract(profileData["address"]?.toString());
            if (fetchedAddr == "N/A") fetchedAddr = extract(profileData["primary_address"]?.toString());
            if (fetchedAddr == "N/A") fetchedAddr = extract(profileData["communication_address"]?.toString());
            address = fetchedAddr == "N/A" ? "N/A" : fetchedAddr;
            
            gender = extract(profileData["gender"]?.toString());
            mobile = extract(profileData["contact_number"]?.toString());
            profilePhoto = extract(profileData["profile_photo"]?.toString()) == "N/A" ? profilePhoto : extract(profileData["profile_photo"]?.toString());
            institutionName = extract(profileData["institution_name"]?.toString());
            qualification = extract(profileData["qualification"]?.toString());
            specification = extract(profileData["specification"]?.toString());
            passedOut = extract(profileData["passed_out"]?.toString());
            bloodGroup = extract(profileData["blood_group"]?.toString());
            emergencyName = extract(profileData["emergency_contact_name"]?.toString());
            emergencyNumber = extract(profileData["emergency_contact_number"]?.toString());
          });
        }
      }
    } catch (e) {
      debugPrint("Employee Details Sync Error => $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: const Color(0xFF0AA18E),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Employee Details",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            _profileHeader(context),
            const SizedBox(height: 80),
            _accordionSection(),
          ],
        ),
      ),
    );
  }

  Widget _profileHeader(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.28,
      width: size.width,
      decoration: const BoxDecoration(
        color: Color(0xFF0AA18E),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(46),
          bottomRight: Radius.circular(46),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 20,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.lightGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Active",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          /// PROFILE IMAGE
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: UserAvatar(
                  radius: 46,
                  profileImageUrl: profilePhoto,
                  userName: userName,
                ),
              ),
            ),
          ),

          /// NAME CARD
          Positioned(
            bottom: -40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 220,
                height: 95,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dept,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accordionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          accordion(
            icon: Icons.badge,
            title: "Employee Details",
            open: emp,
            onTap: () => setState(() => emp = !emp),
            child: details(),
          ),
          accordion(
            icon: Icons.person,
            title: "Personal Details",
            open: personal,
            onTap: () => setState(() => personal = !personal),
            child: personDetails(),
          ),
          accordion(
            icon: Icons.school,
            title: "Educational Details",
            open: edu,
            onTap: () => setState(() => edu = !edu),
            child: educationDetails(),
          ),
        ],
      ),
    );
  }

  Widget accordion({
    required IconData icon,
    required String title,
    required bool open,
    required VoidCallback onTap,
    Widget? child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFE6F6F4),
              child: Icon(icon, color: const Color(0xFF0AA18E)),
            ),
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0AA18E),
                fontSize: 14,
              ),
            ),
            trailing: Icon(
              open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            ),
            onTap: onTap,
          ),
          if (open && child != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
        ],
      ),
    );
  }

  Widget details() {
    return Column(
      children: [
        row("Employee Name", userName),
        row("Department", dept),
        row("Shift", "General"),
        row("Employee Type", employeeType),
        row("Employee Status", "Active"),
        row("Experience", "N/A"),
        // Removed DOJ as requested by user
      ],
    );
  }

  Widget personDetails() {
    return Column(
      children: [
        row("DOB", dob), // Renamed to DOB as requested
        row("Gender", gender),
        row("Blood Group", bloodGroup),
        row("Address", address),
        row("Phone Number", mobile),
        row("Emergency Name", emergencyName),
        row("Emergency No", emergencyNumber),
      ],
    );
  }

  Widget educationDetails() {
    return Column(
      children: [
        row("Institution Name", institutionName),
        row("Degree/Diploma", qualification),
        row("Specification", specification),
        row("Passed Out", passedOut),
      ],
    );
  }

  Widget row(String l, String r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            r,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
