import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const MaterialApp(home: NotificationSettingsScreen()));

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // Toggle states
  bool _reportsAlert = true;
  bool _systemUpdates = false;
  bool _accountSecurity = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final isTablet = width > 600;

    final double horizontalPadding = isTablet ? 32.0 : 20.0;
    final double topPadding = isTablet ? 30.0 : 20.0;
    final double titleFontSize = isTablet ? 26.0 : 22.0;
    final double subtitleFontSize = isTablet ? 16.0 : 14.5;
    final double itemTitleFontSize = isTablet ? 18.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notification & Alert",
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 22 : 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: topPadding),

            // Main Title
            Text(
              "Notification & Alerts",
              style: GoogleFonts.poppins(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 12),

            // Subtitle Description
            Text(
              "You'll receive alerts here about important updates. Customize your preferences in Settings.",
              style: GoogleFonts.poppins(
                fontSize: subtitleFontSize,
                color: Colors.black87,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

            // Toggle Items
            _buildToggleItem(
              title: "Reports Alerts",
              value: _reportsAlert,
              isTablet: isTablet,
              itemTitleFontSize: itemTitleFontSize,
              showThumbIcons: true,
              onChanged: (val) => setState(() => _reportsAlert = val),
            ),

            const SizedBox(height: 20),

            _buildToggleItem(
              title: "System Updates",
              value: _systemUpdates,
              isTablet: isTablet,
              itemTitleFontSize: itemTitleFontSize,
              onChanged: (val) => setState(() => _systemUpdates = val),
            ),

            const SizedBox(height: 20),

            _buildToggleItem(
              title: "Account & Security Alerts",
              value: _accountSecurity,
              isTablet: isTablet,
              itemTitleFontSize: itemTitleFontSize,
              onChanged: (val) => setState(() => _accountSecurity = val),
            ),

            SizedBox(height: height * 0.1),
          ],
        ),
      ),
    );
  }

  // Reusable Toggle Row Widget
  Widget _buildToggleItem({
    required String title,
    required bool value,
    required bool isTablet,
    required double itemTitleFontSize,
    required Function(bool) onChanged,
    bool showThumbIcons = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 20,
        vertical: isTablet ? 22 : 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: itemTitleFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Transform.scale(
            scale: isTablet ? 1.3 : 1.1,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: const Color(0xff6750A4),
              inactiveThumbColor: const Color(0xFF79747E),
              inactiveTrackColor: const Color(0xFFE1DDF1),
              trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.transparent;
                }
                return const Color(0xFF79747E);
              }),
              thumbIcon: WidgetStateProperty.resolveWith<Icon?>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.selected)) {
                  if (showThumbIcons) {
                    return const Icon(
                      Icons.check,
                      color: Color(0xff6750A4),
                      size: 20,
                    );
                  }
                  return const Icon(null);
                }
                if (showThumbIcons) {
                  return const Icon(Icons.close, color: Colors.white, size: 20);
                }
                return const Icon(null);
              }),
            ),
          ),
        ],
      ),
    );
  }
}