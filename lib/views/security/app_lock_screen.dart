import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hrm/views/main_root.dart';
import 'package:hrm/views/security/face_auth_verification.dart';

class AppLockScreen extends StatefulWidget {
  final bool isBiometricEnabled;
  final bool isAppFaceEnabled;
  final bool isPinEnabled;
  final String? savedPin;

  const AppLockScreen({
    super.key,
    required this.isBiometricEnabled,
    required this.isAppFaceEnabled,
    required this.isPinEnabled,
    this.savedPin,
  });

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen>
    with SingleTickerProviderStateMixin {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const _teal = Color(0xff26A69A);

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isBiometricEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _authenticateBiometric(context);
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _authenticateBiometric(BuildContext context) async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);
    try {
      // ignore: deprecated_member_use_from_same_package
      final authenticated = await auth.authenticate(
        localizedReason: 'Secure Authentication Required',
        // Using direct parameters as observed in the project's security settings
        biometricOnly: true,
      );
      if (authenticated && mounted) _navigateToHome();
    } catch (e) {
      debugPrint("Biometric Error: $e");
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainRoot()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final biometricOnlyMode = widget.isBiometricEnabled && !widget.isPinEnabled;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, _teal.withValues(alpha: 0.04)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // ─── HEADER ───
                          Padding(
                            padding: const EdgeInsets.only(top: 32, bottom: 8),
                            child: _buildHeader(biometricOnlyMode),
                          ),

                          // ─── BODY ───
                          Expanded(
                            child: biometricOnlyMode
                                ? _buildBiometricOnlyUI()
                                : _buildPinLockUI(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── HEADER ───────────────────────────
  Widget _buildHeader(bool biometricOnlyMode) {
    return Column(
      children: [
        // App Icon
        Container(
          height: 96,
          width: 96,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _teal.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
            ],
            border: Border.all(color: _teal.withValues(alpha: 0.12), width: 2),
          ),
          child: Image.asset(
            'assets/icons/app_icon.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.lock_person_rounded, size: 40, color: _teal),
          ),
        ),

        const SizedBox(height: 16),

        // Title
        Text(
          "HRM PORTAL",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: _teal,
          ),
        ),

        const SizedBox(height: 8),

        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: _teal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _teal.withValues(alpha: 0.2)),
          ),
          child: Text(
            biometricOnlyMode ? "FACE / FINGERPRINT" : "SECURE PIN LOCK",
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: _teal,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── PIN LOCK UI ───────────────────────────
  Widget _buildPinLockUI() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ScreenLock(
        correctString: widget.savedPin ?? '',
        onUnlocked: _navigateToHome,
        useBlur: false,
        title: const SizedBox.shrink(),
        config: const ScreenLockConfig(backgroundColor: Colors.transparent),
        secretsConfig: SecretsConfig(
          spacing: 12, // Reduced from 20 to prevent overflow
          padding: const EdgeInsets.symmetric(vertical: 20),
          secretConfig: SecretConfig(
            borderColor: _teal.withValues(alpha: 0.45),
            enabledColor: _teal,
            disabledColor: Colors.white,
            size: 14, // Slightly smaller
            borderSize: 2,
          ),
        ),
        keyPadConfig: KeyPadConfig(
          buttonConfig: KeyPadButtonConfig(
            buttonStyle: OutlinedButton.styleFrom(
              backgroundColor: _teal.withValues(alpha: 0.04),
              foregroundColor: _teal,
              textStyle: GoogleFonts.poppins(
                fontSize: 22, // Slightly smaller
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.zero,
              elevation: 0,
              side: BorderSide(color: _teal.withValues(alpha: 0.1)),
            ),
          ),
          actionButtonConfig: KeyPadButtonConfig(
            buttonStyle: OutlinedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: _teal,
              shape: const RoundedRectangleBorder(),
              elevation: 0,
              side: BorderSide.none,
              shadowColor: Colors.transparent,
            ),
          ),
          displayStrings: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
        ),
        customizedButtonChild:
            (widget.isBiometricEnabled || widget.isAppFaceEnabled)
            ? _buildPinAuthIcons()
            : null,
        customizedButtonTap: () {
          // Fallback tap if user hits the button area but misses the small icons
          if (widget.isBiometricEnabled) {
            _authenticateBiometric(context);
          } else if (widget.isAppFaceEnabled) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FaceAuthVerificationScreen(),
              ),
            );
          }
        },
      ),
    );
  }

  // ─────────────────────────── AUTH ICONS (inside PIN pad) ───────────────────────────
  Widget _buildPinAuthIcons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isBiometricEnabled)
          _buildSmallPulseIcon(
            icon: Icons.fingerprint_rounded,
            onTap: () => _authenticateBiometric(context),
          ),
        if (widget.isBiometricEnabled && widget.isAppFaceEnabled)
          const SizedBox(height: 4), // Reduced from 8 to fit better
        if (widget.isAppFaceEnabled)
          _buildSmallPulseIcon(
            icon: Icons.face_unlock_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FaceAuthVerificationScreen(),
              ),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────── BIOMETRIC-ONLY UI ───────────────────────────
  Widget _buildBiometricOnlyUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),

        // Icons row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.isBiometricEnabled)
              _buildBigPulseIcon(
                icon: Icons.fingerprint_rounded,
                onTap: () => _authenticateBiometric(context),
              ),
            if (widget.isBiometricEnabled && widget.isAppFaceEnabled)
              const SizedBox(width: 48),
            if (widget.isAppFaceEnabled)
              _buildBigPulseIcon(
                icon: Icons.face_unlock_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FaceAuthVerificationScreen(),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 36),

        Text(
          "TAP TO UNLOCK",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _teal,
            letterSpacing: 2.5,
          ),
        ),

        const SizedBox(height: 10),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            "Use your face or fingerprint to continue",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.5,
              color: _teal.withValues(alpha: 0.55),
            ),
          ),
        ),

        const Spacer(flex: 3),
      ],
    );
  }

  // ─────────────────────────── REUSABLE WIDGETS ───────────────────────────

  Widget _buildBigPulseIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (_, __) => Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _teal.withValues(alpha: 0.07),
              border: Border.all(
                color: _teal.withValues(
                  alpha: 0.2 + _pulseController.value * 0.1,
                ),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _teal.withValues(
                    alpha: 0.12 + _pulseController.value * 0.08,
                  ),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(icon, size: 52, color: _teal),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallPulseIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
        ), // Removed vertical padding
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (_, __) => Transform.scale(
            scale: _pulseAnimation.value,
            child: Icon(
              icon,
              size: 24,
              color: _teal,
            ), // Reduced from 28 to fit better
          ),
        ),
      ),
    );
  }
}
