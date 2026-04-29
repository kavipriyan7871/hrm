import 'package:flutter/material.dart';
import 'package:hrm/views/home/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hrm/views/widgets/user_avatar.dart';
import '../../models/employee_api.dart';
import 'package:flutter/foundation.dart';

class AccountSettingsApp extends StatelessWidget {
  const AccountSettingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AccountSettingsScreen(),
    );
  }
}

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  String name = "";
  String mobile = "";
  String address = "";
  String profilePhoto = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name') ?? "";
      mobile = prefs.getString('mobile') ?? "";
      address = prefs.getString('address') ?? "Not Mentioned";
      profilePhoto = prefs.getString('profile_photo') ?? "";
      isLoading = false;
    });

    try {
      final String uid = prefs.getString('uid') ?? 
                        prefs.getString('login_cus_id') ?? 
                        prefs.getString('employee_table_id') ?? "";
      final String cid = prefs.getString('cid') ?? prefs.getString('cid_str') ?? "";
      final String token = prefs.getString('token') ?? "";
      final String deviceId = prefs.getString('device_id') ?? "";

      final response = await EmployeeApi.getEmployeeDetails(
        uid: uid,
        cid: cid,
        deviceId: deviceId,
        lat: prefs.getDouble('lat')?.toString() ?? "0.0",
        lng: prefs.getDouble('lng')?.toString() ?? "0.0",
        token: token,
      );

      if (response["error"] == false || response["error"] == "false") {
        final profileData = response["data"] ?? {};
        if (mounted) {
          setState(() {
            name = profileData["name"]?.toString() ?? name;
            mobile = profileData["contact_number"]?.toString() ?? profileData["mobile"]?.toString() ?? mobile;
            address = profileData["address"]?.toString() ?? profileData["communication_address"]?.toString() ?? address;
            profilePhoto = profileData["profile_photo"]?.toString() ?? profilePhoto;
          });
        }
        await prefs.setString('name', name);
        await prefs.setString('mobile', mobile);
        await prefs.setString('address', address);
        await prefs.setString('profile_photo', profilePhoto);
      }
    } catch (e) {
      debugPrint("Account Settings Sync Error => $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double horizontalPadding = size.width * 0.05;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xff26A69A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
              (route) => false,
            );
          },
        ),
        title: const Text(
          "Account Settings",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            const Text(
              "Profile Information",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: const Color(0xffFFFFFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xffC4C4C4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    UserAvatar(
                      radius: 60,
                      profileImageUrl: profilePhoto,
                      userName: name,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Profile Photo",
                      style: TextStyle(
                        color: Color(0xff26A69A),
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Basic Details",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow("Name", name),
                    _buildDetailRow("Mobile", mobile),
                    _buildDetailRow("Address", address),
                    const SizedBox(height: 5),
                  ],
                ),
              ),
            ),
            SizedBox(height: size.height * 0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xff414141),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }
}
