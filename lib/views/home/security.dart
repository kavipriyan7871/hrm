import 'package:flutter/material.dart';
import 'package:hrm/views/home/settings.dart';

class SecuritySettingsApp extends StatelessWidget {
  const SecuritySettingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SecuritySettingsScreen(),
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Roboto',
      ),
    );
  }
}

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool biometricEnabled = true;
  bool pinProtection = true;
  bool locationAccess = true;
  bool cameraAccess = false;
  bool dataEncryption = true;
  bool activityTracking = true;
  bool shareAnalytics = true;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xff26A69A),
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
          "Security",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ENCRYPTED BANNER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xff407BFF)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, color: Color(0xff407BFF), size: 32),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Your data is encrypted",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "All your attendance data is securely encrypted and stored",
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 🔵 AUTHENTICATION CARD
            _buildSectionCard(
              titleIcon: Icons.lock_outline,
              title: "Authentication",
              children: [
                _buildSwitchTile(
                  icon: Icons.fingerprint,
                  color: Colors.blue.shade100,
                  title: "Biometric Authentication",
                  subtitle: "Use fingerprint or face ID",
                  value: biometricEnabled,
                  onChanged: (val) => setState(() => biometricEnabled = val),
                ),
                _buildSwitchTile(
                  icon: Icons.key_rounded,
                  color: Colors.teal.shade100,
                  title: "PIN Protection",
                  subtitle: "Require PIN to open app",
                  value: pinProtection,
                  onChanged: (val) => setState(() => pinProtection = val),
                ),
                _buildActionTile(
                  icon: Icons.vpn_key,
                  title: "Change Password",
                  subtitle: "Update your account password",
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 🟡 APP PERMISSION CARD
            _buildSectionCard(
              titleIcon: Icons.security,
              title: "App permission",
              children: [
                _buildSwitchTile(
                  icon: Icons.location_on,
                  color: Colors.orange.shade100,
                  title: "Location Access",
                  subtitle: "Allow app to access your location",
                  value: locationAccess,
                  onChanged: (val) => setState(() => locationAccess = val),
                ),
                _buildSwitchTile(
                  icon: Icons.camera_alt,
                  color: Colors.purple.shade100,
                  title: "Camera Access",
                  subtitle: "Allow app to access camera",
                  value: cameraAccess,
                  onChanged: (val) => setState(() => cameraAccess = val),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 🟢 DATA PRIVACY CARD
            _buildSectionCard(
              titleIcon: Icons.privacy_tip_outlined,
              title: "Data Privacy",
              children: [
                _buildSwitchTile(
                  icon: Icons.shield_moon_outlined,
                  color: Colors.indigo.shade100,
                  title: "Data Encryption",
                  subtitle: "Encrypt all stored data",
                  value: dataEncryption,
                  onChanged: (val) => setState(() => dataEncryption = val),
                ),
                _buildSwitchTile(
                  icon: Icons.notifications_active,
                  color: Colors.green.shade100,
                  title: "Activity Tracking",
                  subtitle: "Track app usage for improvement",
                  value: activityTracking,
                  onChanged: (val) => setState(() => activityTracking = val),
                ),
                _buildSwitchTile(
                  icon: Icons.telegram_outlined,
                  color: Colors.cyan.shade100,
                  title: "Share Analytics",
                  subtitle: "Share anonymous usage data",
                  value: shareAnalytics,
                  onChanged: (val) => setState(() => shareAnalytics = val),
                ),
                _buildActionTile(
                  icon: Icons.download,
                  title: "Download My Data",
                  subtitle: "Export all your personal data",
                  trailing: const Icon(Icons.download_outlined, size: 30),
                  onTap: () {},
                ),
                _buildActionTile(
                  icon: Icons.delete_forever,
                  color: const Color(0xffFF0B0B),
                  title: "Clear History",
                  subtitle: "Delete all attendance records",
                  titleColor: Colors.black,
                  subtitleColor: Colors.black,
                  trailing: const Icon(Icons.delete, color: Color(0xffFF0B0B)),
                  onTap: () {},
                ),
              ],
            ),

            SizedBox(height: screenHeight * 0.05),
          ],
        ),
      ),
    );
  }

  // SECTION CARD → NOW WITH SEPARATE ICON FOR TITLE
  Widget _buildSectionCard({
    required IconData titleIcon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffE0E0E0)),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(titleIcon, size: 22, color: Colors.black87),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  // SWITCH TILE
  Widget _buildSwitchTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      secondary: CircleAvatar(
        radius: 22,
        backgroundColor: color,
        child: Icon(icon, color: Colors.black54, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xff1B2C61),
      inactiveTrackColor: const Color(0xffD9D9D9),
      activeTrackColor: const Color(0xffD9D9D9),
    );
  }

  // ACTION TILE
  Widget _buildActionTile({
    required IconData icon,
    Color? color,
    required String title,
    required String subtitle,
    Widget? trailing,
    Color? titleColor,
    Color? subtitleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: titleColor ?? Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: subtitleColor ?? Colors.black54,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.lock, size: 30, color: Color(0xff1B2C61)),
      onTap: onTap,
    );
  }
}
