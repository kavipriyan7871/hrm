import 'package:flutter/material.dart';
import 'package:hrm/views/login_section/login_screen.dart';
import 'package:hrm/views/login_section/sign-in_sms.dart';
import 'package:hrm/views/login_section/sign-up.dart';
import '../../models/login_api.dart';
import 'otp_popup.dart';

class WhatsappLogin extends StatefulWidget {
  const WhatsappLogin({super.key});

  @override
  State<WhatsappLogin> createState() => _WhatsappLoginState();
}

class _WhatsappLoginState extends State<WhatsappLogin> {
  final TextEditingController _emailController = TextEditingController();
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    // MediaQuery
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

                /// Sign in title
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

                /// Subtitle
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Manage your customers, sales & business anywhere.",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),

                SizedBox(height: height * 0.05),

                /// Email Field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Enter WhatsApp Number",
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
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (_emailController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please enter WhatsApp number"),
                                ),
                              );
                              return;
                            }

                            setState(() => isLoading = true);

                            try {
                              final response = await LoginApi.sendOtp(
                                mobile: _emailController.text.trim(),
                                cid: "21472147",
                                type: "2000",
                                deviceId: "12345",
                                lat: "145",
                                lng: "145",
                                appSignature: "smart123",
                              );

                              if (response["error"] == false) {
                                final String cusId =
                                    response["cus_id"]?.toString() ?? "";
                                if (mounted) {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) {
                                      return OtpBottomSheet(
                                        phoneNumber: _emailController.text
                                            .trim(),
                                        cusId: cusId,
                                      );
                                    },
                                  );
                                }
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        response["error_msg"] ??
                                            "Failed to send OTP",
                                      ),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Server Error")),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => isLoading = false);
                              }
                            }
                          },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff26A69A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
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

                // Spacer(),
                SizedBox(height: height * 0.04),

                /// OR Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.black26)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "or continue with",
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.black26)),
                  ],
                ),

                SizedBox(height: height * 0.03),

                /// WhatsApp & SMS Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(),
                            ),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SmsLogin()),
                          );
                        },
                        icon: const Icon(
                          Icons.phone_android,
                          size: 20,
                          color: Color(0xFF26A69A),
                        ),
                        label: const Text(
                          "Via SMS",
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

                /// Sign Up Text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don’t Have an Account? ",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignupScreen(),
                          ),
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

                /// Terms & Conditions
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    text: "By Continuing you agree to our\n",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(
                        text: "Terms and Conditions",
                        style: TextStyle(
                          color: Color(0xFF2BAE9E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // SizedBox(height: height * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
