import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hrm/views/login_section/login_screen.dart';
import 'package:hrm/views/login_section/sign-in_whatsapp.dart';
import 'package:hrm/views/login_section/sign-up.dart';
import 'otp_popup.dart';

import '../../models/login_api.dart';

class SmsLogin extends StatefulWidget {
  const SmsLogin({super.key});

  @override
  State<SmsLogin> createState() => _SmsLoginState();
}

class _SmsLoginState extends State<SmsLogin> {
  final TextEditingController _emailController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double height = size.height;
    final double width = size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: height * 0.13),

                /// Logo
                Center(
                  child: Image.asset(
                    'assets/logo.png',
                    width: width * 0.55,
                    fit: BoxFit.contain,
                  ),
                ),

                SizedBox(height: height * 0.05),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Sign in",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),

                SizedBox(height: height * 0.01),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Manage your customers, sales & business anywhere.",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),

                SizedBox(height: height * 0.05),

                /// Mobile Field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Enter Mobile Number",
                    labelStyle: TextStyle(color: Colors.black54),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black26),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xff26A69A)),
                    ),
                  ),
                ),

                SizedBox(height: height * 0.05),

                /// Next Button
                SizedBox(
                  width: 280,
                  height: height * 0.06,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _sendOtpApi,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff26A69A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : const Text(
                            "Next",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                SizedBox(height: height * 0.04),

                /// OR Divider
                Row(
                  children: const [
                    Expanded(child: Divider(color: Colors.black26)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "or continue with",
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.black26)),
                  ],
                ),

                SizedBox(height: height * 0.03),

                /// WhatsApp & Mail
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => WhatsappLogin()),
                          );
                        },
                        icon: const Icon(
                          FontAwesomeIcons.whatsapp,
                          color: Colors.green,
                          size: 28,
                        ),
                        label: const Text(
                          "WhatsApp",
                          style: TextStyle(color: Colors.black),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xff26A69A)),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => LoginScreen()),
                          );
                        },
                        icon: const Icon(
                          Icons.mail_outline,
                          size: 20,
                          color: Color(0xFF26A69A),
                        ),
                        label: const Text(
                          "Via Mail",
                          style: TextStyle(color: Colors.black),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xff26A69A)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: height * 0.04),

                /// Sign Up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don’t Have an Account? ",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SignupScreen()),
                        );
                      },
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xff000080),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: height * 0.06),

                /// Terms
                const Text(
                  "By Continuing you agree to our\nTerms and Conditions",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ SEND OTP API
  Future<void> _sendOtpApi() async {
    if (_emailController.text.isEmpty) {
      _snack("Please enter mobile number", false);
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('lat')?.toString() ?? "145";
      final lng = prefs.getDouble('lng')?.toString() ?? "145";

      final response = await LoginApi.sendOtp(
        mobile: _emailController.text.trim(),
        cid: "21472147",
        type: "2000",
        deviceId: "12345",
        lat: lat,
        lng: lng,
        appSignature: "smart123",
      );

      debugPrint("OTP API RESPONSE => $response");

      final bool isSuccess =
          response["error"] == false ||
          response["error"] == "false" ||
          response["status"] == true ||
          response["status"] == 1;

      if (isSuccess) {
        _snack(
          response["error_msg"] ??
              response["message"] ??
              "OTP sent successfully",
          true,
        );

        final String cusId = response["cus_id"]?.toString() ?? "";

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) {
            return OtpBottomSheet(
              phoneNumber: _emailController.text.trim(),
              cusId: cusId,
            );
          },
        );
      } else {
        _snack(
          response["error_msg"] ?? response["message"] ?? "OTP failed",
          false,
        );
      }
    } catch (e) {
      debugPrint("OTP ERROR => $e");
      _snack("Server error", false);
    }

    setState(() => isLoading = false);
  }

  void _snack(String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}
