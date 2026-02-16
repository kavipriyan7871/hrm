import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/ticket_api.dart';
import '../home/view_ticket_screen.dart';

class TicketRaise extends StatefulWidget {
  const TicketRaise({super.key});

  @override
  State<TicketRaise> createState() => _TicketRaiseState();
}

class _TicketRaiseState extends State<TicketRaise> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedDepartment;
  bool isLoading = false;
  bool isDeptsLoading = true; // New loading state for depts

  final List<Map<String, dynamic>> _myTickets = [];
  List<String> departmentList = []; // Made dynamic

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    final depts = await TicketApi.fetchDepartments();
    if (mounted) {
      setState(() {
        // Assuming the API returns objects with a "name" or "department_name" key.
        // Fallback to "name" or just use the whole map if needed.
        // Based on typical patterns, let's try to find a likely key.
        // If the list is empty, we might keep it empty or show error.
        departmentList = depts.map<String>((e) {
          return e['department_name']?.toString() ??
              e['name']?.toString() ??
              e.toString();
        }).toList();

        // Remove duplicates and empty strings
        departmentList = departmentList
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();

        isDeptsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Ticket Raise",
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w500),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            _buildField(label: "Subject", controller: _subjectController),
            const SizedBox(height: 20),

            _buildDepartmentDropdown(),
            const SizedBox(height: 20),

            _buildField(
              label: "Description",
              controller: _descriptionController,
              maxLines: 5,
            ),

            const SizedBox(height: 120),

            Center(
              child: SizedBox(
                width: 220,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitTicket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF26A69A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Submit Ticket",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitTicket() async {
    if (_subjectController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    final result = await TicketApi.raiseTicket(
      subject: _subjectController.text.trim(),
      department: _selectedDepartment!,
      description: _descriptionController.text.trim(),
    );

    setState(() => isLoading = false);

    if (result["success"] == true) {
      // Pass empty list to ViewTicketRaisingScreen, as it will fetch its own tickets now
      // Or we can add the new one artificially if we want immediate feedback,
      // but better to let it fetch fresh.
      // However, the original code passed _myTickets.
      _myTickets.add({
        "title": _subjectController.text.trim(),
        "dept": _selectedDepartment!,
        "date": DateTime.now(),
        "priority": "High",
        "status": "Pending",
      });

      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"] ?? "Failed"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SuccessDialog(),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (!context.mounted) return;

      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          // We can remove tickets arg since the screen will fetch them
          builder: (_) => const ViewTicketRaisingScreen(),
        ),
      );
    });
  }

  Widget _buildDepartmentDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Department",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: isDeptsLoading
              ? const SizedBox(
                  height: 50,
                  child: Center(child: CircularProgressIndicator()),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text("Select Department"),
                    value: _selectedDepartment,
                    items: departmentList
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) => setState(() {
                      _selectedDepartment = value;
                    }),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 20),
            Text(
              "Has Been Submitted",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
