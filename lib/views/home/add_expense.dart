import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';
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
          onPressed: () => Navigator.pop(context),
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

            // ProfileInfoCard(
            //   name: "Harish",
            //   employeeId: "1023",
            //   designation: "Supervisor",
            //   profileImagePath: "assets/profile.png",
            // ),

            // SizedBox(height: isTablet ? 30 : 20),
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

            Align(
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
                  child: Column(
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

            SizedBox(height: isTablet ? 80 : 60),

            Center(
              child: SizedBox(
                width: 200,
                height: 55,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF26A69A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
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
      setState(() {
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  // DYNAMIC SUBMIT WITH REAL DATA
  void _submitForm() {
    final amount = _amountController.text.trim();
    final purpose = _selectedPurpose ?? "Expense";

    if (amount.isEmpty ||
        _selectedPurpose == null ||
        _descriptionController.text.trim().isEmpty ||
        _dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SuccessExpenseDialog(amount: amount, purpose: purpose),
    );

    // Auto close dialog + go back after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.pop(context); // Go back to previous screen
      }
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

// DYNAMIC SUCCESS DIALOG — SHOWS REAL ENTERED DATA
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
            // Custom Success Image
            Image.asset('assets/ticket_success.png', height: 80, width: 80),

            const SizedBox(height: 32),

            // Success Text
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