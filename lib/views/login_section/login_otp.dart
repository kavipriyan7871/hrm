import 'package:flutter/material.dart';

class LoginOtpScreen extends StatefulWidget {
  const LoginOtpScreen({super.key});

  @override
  State<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends State<LoginOtpScreen> {
  final List<TextEditingController> otpControllers =
  List.generate(6, (_) => TextEditingController());

  final List<FocusNode> focusNodes =
  List.generate(6, (_) => FocusNode());



  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double width = size.width;
    final double height = size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: height * 0.06),

                /// Logo
                Center(
                  child: Image.asset(
                    'assets/images/smart.png',
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

                SizedBox(height: height * 0.008),

                /// Subtitle
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Manage your customers, sales & business anywhere.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),

                SizedBox(height: height * 0.025),

                /// Email + edit
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: const [
                      Text(
                        "xyz@gmail.com",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.edit,
                        size: 16,
                        color: Color(0xFF2BAE9E),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: height * 0.03),

                /// OTP boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: width * 0.11,
                      height: width * 0.11,
                      child: TextField(
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        decoration: InputDecoration(
                          counterText: "",
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF2BAE9E),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF2BAE9E),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                SizedBox(height: height * 0.015),

                /// Resend OTP
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Resend OTP in 30 Sec",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.teal.shade600,
                    ),
                  ),
                ),

                SizedBox(height: height * 0.035),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2BAE9E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Verify",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: height * 0.03),

                /// Divider with text
                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        "or continue with",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),

                SizedBox(height: height * 0.025),

                /// Sign in using password
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2BAE9E)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Sign in Using Password",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2BAE9E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: height * 0.03),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
