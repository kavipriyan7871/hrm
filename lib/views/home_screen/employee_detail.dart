import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String? employeeTableId;

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: profilePhoto.isNotEmpty
                      ? NetworkImage(profilePhoto)
                      : const AssetImage("assets/profile.png") as ImageProvider,
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
                      color: Colors.black.withOpacity(0.12),
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
            child: PersonDetails(),
          ),
          accordion(
            icon: Icons.school,
            title: "Educational Details",
            open: edu,
            onTap: () => setState(() => edu = !edu),
            child: EducationDetails(),
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
        row("Experience", "1 Year"),
        row("DOJ", doj),
      ],
    );
  }

  Widget PersonDetails() {
    return Column(
      children: [
        row("Date of Birth", dob),
        row("Age", "-"),
        row("Gender", gender),
        row("Address", address),
        row("Phone Number", mobile),
      ],
    );
  }

  Widget EducationDetails() {
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
