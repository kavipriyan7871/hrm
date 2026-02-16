import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hrm/models/expense_api.dart';
import 'package:hrm/views/widgets/profile_card.dart';

class AddExpense extends StatefulWidget {
  const AddExpense({super.key});

  @override
  State<AddExpense> createState() => _AddExpenseState();
}

class _AddExpenseState extends State<AddExpense> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedPurpose;
  bool _isLoading = false;
  File? _receiptImage;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width > 600;
    final horizontalPadding = isTablet ? 24.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.pop(context, true), // Return true to refresh
        ),
        title: Text(
          "Add Expense",
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 22 : 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            _buildDropdownField(
              context: context,
              label: "Expense Category",
              hint: "Select Purpose",
              value: _selectedPurpose,
              isTablet: isTablet,
              items: const [
                'New Lead',
                'Close',
                'New Business Pitch',
                'Meeting',
                'Travel',
                'Food',
                'Transport',
                'Others',
              ],
              onChanged: (value) {
                setState(() => _selectedPurpose = value);
              },
            ),

            SizedBox(height: isTablet ? 20 : 16),

            _buildLabeledField(
              context: context,
              label: "Enter Amount",
              hint: "Enter Amount",
              controller: _amountController,
              isTablet: isTablet,
              keyboardType: TextInputType.number,
            ),

            SizedBox(height: isTablet ? 20 : 16),

            _buildLabeledField(
              context: context,
              label: "Description",
              hint: "Enter Description",
              controller: _descriptionController,
              isTablet: isTablet,
            ),

            SizedBox(height: isTablet ? 20 : 16),

            _buildLabeledField(
              context: context,
              label: "Date",
              hint: "Date",
              controller: _dateController,
              isTablet: isTablet,
              prefixIcon: Icons.calendar_today_outlined,
              isDateField: true,
            ),

            SizedBox(height: isTablet ? 20 : 16),

            Text(
              "Attach Receipt",
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            GestureDetector(
              onTap: _pickImage,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: DottedBorder(
                  color: Colors.grey.shade400,
                  strokeWidth: 1.5,
                  dashPattern: const [6, 4],
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(8),
                  child: Container(
                    width: 360,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _receiptImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _receiptImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.document_scanner_outlined,
                                size: 36,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Attach Receipt",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),

            SizedBox(height: isTablet ? 80 : 60),

            Center(
              child: SizedBox(
                width: 200,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF26A69A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Add Expense",
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Reusable field builders...
  Widget _buildLabeledField({
    required BuildContext context,
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool isTablet,
    IconData? prefixIcon,
    bool isDateField = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          readOnly: isDateField,
          keyboardType: keyboardType,
          onTap: isDateField ? () => _selectDate(context) : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey.shade500,
              fontSize: isTablet ? 14 : 13,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: const Color(0xFF26A69A),
                    size: isTablet ? 22 : 20,
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isTablet ? 16 : 14,
            ),
          ),
          style: GoogleFonts.poppins(fontSize: isTablet ? 14 : 13),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required BuildContext context,
    required String label,
    required String hint,
    required String? value,
    required bool isTablet,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(
                hint,
                style: GoogleFonts.poppins(color: Colors.grey.shade500),
              ),
              items: items
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e, style: GoogleFonts.poppins()),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF26A69A)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      // Format as YYYY-MM-DD for standard API
      setState(() {
        _dateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Show dialog to choose source
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (image != null) {
                    setState(() => _receiptImage = File(image.path));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null) {
                    setState(() => _receiptImage = File(image.path));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _submitForm() async {
    final amount = _amountController.text.trim();
    final purpose = _selectedPurpose ?? "Expense";
    final description = _descriptionController.text.trim();
    final date = _dateController.text.trim();

    if (amount.isEmpty ||
        _selectedPurpose == null ||
        description.isEmpty ||
        date.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final uid =
          prefs.getString('employee_table_id') ??
          prefs.getInt('uid')?.toString() ??
          "";
      final cid = prefs.getString('cid') ?? "21472147";

      String? deviceId = prefs.getString('device_id');
      if (deviceId == null) {
        final deviceInfo = DeviceInfoPlugin();
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id;
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor;
        } else {
          deviceId = "unknown_device";
        }
      }

      final position = await _determinePosition();

      final response = await ExpenseRepo.addExpense(
        cid: cid,
        uid: uid,
        amount: amount,
        description:
            description, // Consider merging purpose if needed: "$purpose - $description"
        purpose: purpose,
        expenseDate: date,
        deviceId: deviceId!,
        lat: position.latitude.toString(),
        lng: position.longitude.toString(),
        receiptImage: _receiptImage,
      );

      print("Add Expense Response in UI: $response");

      if (!mounted) return;

      if (response["error"] == false) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) =>
              SuccessExpenseDialog(amount: amount, purpose: purpose),
        );

        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            Navigator.pop(context); // Close dialog
            Navigator.pop(context, true); // Go back and signal refresh
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response["error_msg"] ?? "Failed to add expense"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error adding expense: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class SuccessExpenseDialog extends StatelessWidget {
  final String amount;
  final String purpose;

  const SuccessExpenseDialog({
    super.key,
    required this.amount,
    required this.purpose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/ticket_success.png', height: 80, width: 80),
            const SizedBox(height: 32),
            Text(
              "Your Expense For '$purpose' Worth",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "₹$amount Has Been Submitted",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
