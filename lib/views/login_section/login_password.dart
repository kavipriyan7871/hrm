import 'package:flutter/material.dart';
import 'package:hrm/views/login_section/sign-up.dart';

import 'login_otp.dart';

class LoginPasswordScreen extends StatefulWidget {
  const LoginPasswordScreen({super.key});

  @override
  State<LoginPasswordScreen> createState() => _LoginPasswordScreenState();
}

class _LoginPasswordScreenState extends State<LoginPasswordScreen> {
  bool _isPasswordVisible = false;
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

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
                    'assets/logo.png',
                    width: width * 0.55,
                    fit: BoxFit.contain,
                  ),
                ),

                SizedBox(height: height * 0.05),

                /// Sign in
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

                /// Email display
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

                SizedBox(height: height * 0.02),

                /// Password field
                ///
                TextField(
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: "Enter password",
                    labelStyle: const TextStyle(color: Colors.black54),

                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),

                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black26),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF2BAE9E)),
                    ),
                  ),
                ),




                SizedBox(height: height * 0.01),

                /// Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2BAE9E),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: height * 0.02),

                /// Sign In button (44px height)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context)=>   SignupScreen(),
                      ),
                    );

                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2BAE9E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Sign In",
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

                /// OTP button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () {Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context)=>   LoginOtpScreen(),
                      ),
                    );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2BAE9E)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Sign in Using email OTP",
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