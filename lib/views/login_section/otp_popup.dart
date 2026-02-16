import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/login_api.dart';
import '../../models/employee_api.dart';
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
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

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
    _otpController.dispose();
    _otpFocusNode.dispose();
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

              Center(
                child: SizedBox(
                  height: height * 0.065,
                  width: width,
                  child: Stack(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          return _buildOtpDigitBox(
                            index,
                            width * 0.12,
                            height * 0.065,
                            width * 0.045,
                          );
                        }),
                      ),
                      Positioned.fill(
                        child: TextField(
                          controller: _otpController,
                          focusNode: _otpFocusNode,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          autofocus: true,
                          showCursor: false,
                          enableInteractiveSelection: false,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          style: const TextStyle(color: Colors.transparent),
                          decoration: const InputDecoration(
                            counterText: "",
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            fillColor: Colors.transparent,
                            filled: true,
                          ),
                          onChanged: (value) {
                            setState(() {});
                            if (value.length == 6) {
                              _verifyOtpApi();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: height * 0.02),

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

  Widget _buildOtpDigitBox(
    int index,
    double width,
    double height,
    double fontSize,
  ) {
    String text = "";
    if (_otpController.text.length > index) {
      text = _otpController.text[index];
    }

    final bool isFocused = index == _otpController.text.length;
    final bool isFilled = index < _otpController.text.length;

    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isFocused || isFilled
              ? const Color(0xFF26A69A)
              : Colors.grey.shade400,
          width: isFocused ? 2 : 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  /// ✅ VERIFY OTP API – DEBUG PRINTS ADDED
  Future<void> _verifyOtpApi() async {
    String otp = _otpController.text;

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

      /// 🔍 DEBUG – FULL RESPONSE
      debugPrint("VERIFY OTP RESPONSE => $response");

      final bool isSuccess =
          response["error"] == false ||
          response["error"] == "false" ||
          response["status"] == true ||
          response["status"] == 1;

      if (isSuccess) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        String? employeeId;

        // robustly find UID
        if (response["data"] != null && response["data"] is Map) {
          final data = response["data"];
          employeeId = (data["uid"] ?? data["id"] ?? data["user_id"])
              ?.toString();
          await prefs.setString("name", data["name"] ?? "User");
        }

        // If not found in data, check root level
        if (employeeId == null) {
          employeeId =
              (response["uid"] ?? response["id"] ?? response["user_id"])
                  ?.toString();
        }

        employeeId ??= widget.cusId;

        // --- NEW LOGIC START: Fetch from EmployeeApi to get the "correct" UID ---
        try {
          if (employeeId != null) {
            debugPrint(
              "Fetching EmployeeDetails to confirm UID for: $employeeId",
            );
            final empRes = await EmployeeApi.getEmployeeDetails(
              uid: employeeId,
              cid: "21472147",
              deviceId: "123456",
              lat: lat,
              lng: lng,
            );

            debugPrint("OTP Employee Fetch Response: $empRes");

            if (empRes["error"] == false) {
              final empData = empRes["data"] ?? empRes;
              String? apiUid =
                  (empData["uid"] ?? empData["id"] ?? empData["user_id"])
                      ?.toString();

              if (apiUid != null && apiUid.isNotEmpty) {
                debugPrint(
                  "Updating UID from EmployeeApi: $employeeId -> $apiUid",
                );
                employeeId = apiUid;
              }

              // Also update name from this authoritative source if available
              if (empData["name"] != null) {
                await prefs.setString("name", empData["name"].toString());
              }
            }
          }
        } catch (e) {
          debugPrint("Error fetching employee details in OTP popup: $e");
        }
        // --- NEW LOGIC END ---

        /// 🔍 DEBUG – BEFORE STORE
        debugPrint("EMPLOYEE ID BEFORE STORE => $employeeId");

        if (employeeId != null && employeeId.isNotEmpty) {
          await prefs.setString("employee_table_id", employeeId);
          await prefs.setInt("uid", int.tryParse(employeeId) ?? 0);
          await prefs.setString("cid", "21472147");

          /// 🔍 DEBUG – AFTER STORE
          debugPrint(
            "PREF employee_table_id => ${prefs.getString("employee_table_id")}",
          );
          debugPrint("PREF uid => ${prefs.getInt("uid")}");
        }

        _snack("OTP verified successfully", true);

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
        _snack("Failed to resend OTP", false);
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
