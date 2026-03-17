import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrm/views/home/settings.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hrm/views/security/register_face_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecuritySettingsApp extends StatelessWidget {
  const SecuritySettingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SecuritySettingsScreen(),
      theme: ThemeData(primarySwatch: Colors.teal, fontFamily: 'Roboto'),
    );
  }
}

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool biometricEnabled = false;
  bool appFaceEnabled = false;
  bool pinProtection = false;
  bool isBiometricSupported = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkBiometricSupport();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      biometricEnabled = prefs.getBool('auth_biometric_enabled') ?? false;
      appFaceEnabled = prefs.getBool('auth_app_face_enabled') ?? false;
      pinProtection = prefs.getBool('auth_pin_enabled') ?? false;
    });
  }

  Future<void> _checkBiometricSupport() async {
    try {
      final bool canCheckBiometrics = await auth.canCheckBiometrics;
      final bool isDeviceSupported = await auth.isDeviceSupported();
      final List<BiometricType> availableBiometrics = await auth
          .getAvailableBiometrics();

      debugPrint("Biometric Check:");
      debugPrint(" - canCheckBiometrics: $canCheckBiometrics");
      debugPrint(" - isDeviceSupported: $isDeviceSupported");
      debugPrint(" - availableBiometrics: $availableBiometrics");

      setState(() {
        // More lenient check
        isBiometricSupported =
            canCheckBiometrics ||
            isDeviceSupported ||
            availableBiometrics.isNotEmpty;
      });
    } catch (e) {
      debugPrint("Biometric support check failed: $e");
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    // 1. Enabling Biometric
    if (value) {
      if (!isBiometricSupported) {
        _showBiometricNotSupportedDialog();
        return;
      }

      try {
        final bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Scan your fingerprint to register it for this app',
          biometricOnly: true,
        );

        if (didAuthenticate) {
          final prefs = await SharedPreferences.getInstance();
          // Store a unique token to identify this registration
          final String bioToken = DateTime.now().millisecondsSinceEpoch
              .toString();
          await prefs.setBool('auth_biometric_enabled', true);
          await prefs.setString('auth_bio_token', bioToken);
          setState(() {
            biometricEnabled = true;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Biometric (Face/Fingerprint) registered successfully!',
                ),
                backgroundColor: Color(0xff26A69A),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
        // If didAuthenticate == false â†’ user cancelled â†’ do nothing silently
      } on PlatformException catch (e) {
        debugPrint(
          "PlatformException enabling biometric: ${e.code} - ${e.message}",
        );
        // Silently ignore userCancelled
      } catch (e) {
        final errStr = e.toString();
        if (errStr.contains('userCanceled') ||
            errStr.contains('userCancelled')) {
          // User simply cancelled the dialog - do nothing
          return;
        }
        debugPrint("Error enabling biometric: $e");
      }
    }
    // 2. Disabling Biometric
    else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auth_biometric_enabled', false);
      await prefs.remove('auth_bio_token');
      setState(() {
        biometricEnabled = false;
      });
    }
  }

  Future<void> _toggleAppFaceLock(bool value) async {
    if (value) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RegisterAppFaceScreen()),
      );
      if (result == true) {
        setState(() => appFaceEnabled = true);
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auth_app_face_enabled', false);
      await prefs.remove('auth_app_face_profile');
      setState(() => appFaceEnabled = false);
    }
  }

  Future<void> _showBiometricNotSupportedDialog() async {
    // Verify specific reasons for failure
    final bool canCheck = await auth.canCheckBiometrics;
    final bool isDev = await auth.isDeviceSupported();
    final List<BiometricType> avail = await auth.getAvailableBiometrics();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Biometric Not Supported"),
        content: Text(
          "Your device does not support biometric authentication or it is not set up.\n\n"
          "Debug Info:\n"
          "- Can Check: $canCheck\n"
          "- Device Supported: $isDev\n"
          "- Available: $avail\n\n"
          "Please ensure you have a fingerprint/face ID enrolled in your device settings.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      // Check if PIN is already set
      final String? savedPin = prefs.getString('auth_pin_code');
      if (savedPin == null || savedPin.isEmpty) {
        // Show dialog to set PIN
        _showSetPinDialog();
      } else {
        await prefs.setBool('auth_pin_enabled', true);
        setState(() => pinProtection = true);
      }
    } else {
      await prefs.setBool('auth_pin_enabled', false);
      await prefs.remove('auth_pin_code'); // Remove the stored PIN
      setState(() => pinProtection = false);
    }
  }

  void _showSetPinDialog() {
    String newPin = "";
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Set App PIN",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Enter a 4-digit PIN to secure the app.",
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                onChanged: (val) => newPin = val,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "PIN",
                  counterText: "",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPin.length == 4) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('auth_pin_code', newPin);
                  await prefs.setBool('auth_pin_enabled', true);
                  setState(() => pinProtection = true);
                  if (mounted) Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("PIN must be 4 digits")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff26A69A),
              ),
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
        title: Text(
          "Security",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ENCRYPTED BANNER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD).withValues(alpha: 0.8), // Light blue
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF90CAF9)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: Color(0xFF4285F4), // Google Blue
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Your data is encrypted",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "All your attendance data is securely encrypted and stored",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // AUTHENTICATION CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // CARD HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 20,
                        color: Colors.black87,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Authentication",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // BIOMETRIC ITEM
                  // APP FACE LOCK (NEW)
                  _buildToggleRow(
                    icon: Icons.face_retouching_natural_rounded,
                    iconBgColor: const Color(0xFFCE93D8), // Light Purple
                    title: "Custom Face Lock",
                    subtitle: "Set up face for app security",
                    value: appFaceEnabled,
                    onChanged: _toggleAppFaceLock,
                  ),

                  const SizedBox(height: 20),

                  // BIOMETRIC ITEM
                  _buildToggleRow(
                    icon: Icons.fingerprint,
                    iconBgColor: const Color(0xFF8C9EFF), // Light Indigo/Blue
                    title: "System Biometric Lock",
                    subtitle: "Use device fingerprint or face",
                    value: biometricEnabled,
                    onChanged: _toggleBiometric,
                  ),

                  const SizedBox(height: 20),

                  // PIN ITEM
                  _buildToggleRow(
                    icon: Icons.key_rounded,
                    iconBgColor: const Color(0xFF80CBC4), // Teal-ish
                    title: "PIN Protection",
                    subtitle: "Require PIN to open app",
                    value: pinProtection,
                    onChanged: _togglePin,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        // ICON CIRCLE
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),

        // TEXT
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),

        // SWITCH
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: value,
            activeThumbColor: const Color(0xff1B2C61),
            activeTrackColor: const Color(0xff1B2C61).withValues(alpha: 0.2),
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.grey.shade200,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

