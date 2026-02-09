import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/login_api.dart';
import '../main_root.dart';

class OtpBottomSheet extends StatefulWidget {
  final String phoneNumber;
  final String cusId;

  const OtpBottomSheet({
    super.key,
    required this.phoneNumber,
    required this.cusId,
  });

  @override
  State<OtpBottomSheet> createState() => _OtpBottomSheetState();
}

class _OtpBottomSheetState extends State<OtpBottomSheet> {
  final List<TextEditingController> controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

  bool isLoading = false;
  Timer? _timer;
  int _start = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _start = 60;
    _canResend = false;
    _timer?.cancel();

    _timer = Timer.periodic(oneSec, (Timer timer) {
      if (_start == 0) {
        setState(() {
          timer.cancel();
          _canResend = true;
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in controllers) {
      c.dispose();
    }
    for (var f in focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.06,
          vertical: height * 0.02,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Row(
                children: [
                  CircleAvatar(
                    radius: width * 0.05,
                    backgroundColor: Colors.grey.shade300,
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        size: width * 0.04,
                        color: Colors.black54,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  SizedBox(width: width * 0.04),
                  Text(
                    "Verify with OTP",
                    style: TextStyle(
                      fontSize: width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),

              SizedBox(height: height * 0.03),

              /// Message
              RichText(
                text: TextSpan(
                  text: "Waiting to automatically detect an OTP sent to \n",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: width * 0.038,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: "${widget.phoneNumber}. ",
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: "Wrong Number?",
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              SizedBox(height: height * 0.03),

              /// OTP Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (index) => _otpBox(
                    index,
                    width * 0.12,
                    height * 0.065,
                    width * 0.045,
                  ),
                ),
              ),

              SizedBox(height: height * 0.02),

              /// Resend & Timer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _canResend ? _resendOtpApi : null,
                    child: Text(
                      "Resend OTP",
                      style: TextStyle(
                        color: _canResend
                            ? const Color(0xFF26A69A)
                            : Colors.black54,
                        fontSize: width * 0.035,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    "00:${_start.toString().padLeft(2, '0')}",
                    style: TextStyle(
                      color: const Color(0xFF26A69A),
                      fontSize: width * 0.035,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              SizedBox(height: height * 0.04),

              /// Verify button
              SizedBox(
                width: double.infinity,
                height: height * 0.06,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _verifyOtpApi,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF26A69A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : Text(
                          "Verify",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: width * 0.045,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              SizedBox(height: height * 0.02),
            ],
          ),
        ),
      ),
    );
  }

  /// OTP BOX
  Widget _otpBox(int index, double width, double height, double fontSize) {
    return SizedBox(
      width: width,
      height: height,
      child: TextField(
        controller: controllers[index],
        focusNode: focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: "",
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF26A69A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF26A69A), width: 2),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF26A69A)),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  /// ✅ VERIFY OTP API
  Future<void> _verifyOtpApi() async {
    String otp = controllers.map((e) => e.text).join();

    if (otp.length != 6) {
      _snack("Enter valid OTP", false);
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('lat')?.toString() ?? "145";
      final lng = prefs.getDouble('lng')?.toString() ?? "145";

      final response = await LoginApi.verifyOtp(
        mobile: widget.phoneNumber,
        otp: otp,
        cid: "21472147",
        type: "2001",
        deviceId: "12345",
        lat: lat,
        lng: lng,
        appSignature: "smart123",
      );

      debugPrint("VERIFY OTP RESPONSE => $response");

      final bool isSuccess =
          response["error"] == false ||
          response["error"] == "false" ||
          response["status"] == true ||
          response["status"] == 1;

      if (isSuccess) {
        _snack("OTP verified successfully", true);

        final prefs = await SharedPreferences.getInstance();

        /// ✅ MARK USER AS LOGGED IN (THIS IS THE KEY)
        await prefs.setBool('isLoggedIn', true);

        // Store user data (already you are doing)
        String? userIdStr;
        if (response["data"] != null) {
          final userData = response["data"];
          userIdStr = (userData["uid"] ?? userData["id"])?.toString();
          await prefs.setString('name', userData["name"]?.toString() ?? "User");
        }

        userIdStr ??= (response["cus_id"] ?? widget.cusId)?.toString();

        if (userIdStr != null && userIdStr.isNotEmpty) {
          await prefs.setInt('uid', int.tryParse(userIdStr) ?? 0);
        }

        /// GO TO DASHBOARD
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => MainRoot()),
          (route) => false,
        );
      } else {
        _snack(
          response["error_msg"] ?? response["message"] ?? "Invalid OTP",
          false,
        );
      }
    } catch (e) {
      debugPrint("VERIFY OTP ERROR => $e");
      _snack("Server error", false);
    }

    setState(() => isLoading = false);
  }

  /// 🔄 RESEND OTP API
  Future<void> _resendOtpApi() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('lat')?.toString() ?? "145";
      final lng = prefs.getDouble('lng')?.toString() ?? "145";

      final response = await LoginApi.sendOtp(
        mobile: widget.phoneNumber,
        cid: "21472147",
        type: "2000",
        deviceId: "12345",
        lat: lat,
        lng: lng,
        appSignature: "smart123",
      );

      debugPrint("RESEND OTP RESPONSE => $response");

      final bool isSuccess =
          response["error"] == false ||
          response["error"] == "false" ||
          response["status"] == true ||
          response["status"] == 1;

      if (isSuccess) {
        _snack("OTP Resent Successfully", true);
        startTimer();
      } else {
        _snack(
          response["error_msg"] ??
              response["message"] ??
              "Failed to resend OTP",
          false,
        );
      }
    } catch (e) {
      debugPrint("RESEND OTP ERROR => $e");
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
