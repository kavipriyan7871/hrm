import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CandidateRequirementForm extends StatefulWidget {
  const CandidateRequirementForm({super.key});

  @override
  State<CandidateRequirementForm> createState() =>
      _CandidateRequirementFormState();
}

class _CandidateRequirementFormState extends State<CandidateRequirementForm> {
  final _formKey = GlobalKey<FormState>();

  // Form Field Controllers
  final TextEditingController _dateOfApprovalController =
      TextEditingController();
  final TextEditingController _noOfVacanciesController =
      TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _qualificationController =
      TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _requestDateController = TextEditingController(
    text: DateFormat('dd-MM-yyyy').format(DateTime.now()),
  );
  final TextEditingController _requestedByController = TextEditingController();

  // Dropdown Values
  String? selectedDepartment;
  String? selectedJobType;
  String? selectedLocation;
  String? selectedPriority;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Candidate Requirement",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("Add New Record"),
                const SizedBox(height: 20),

                // Form Layout: Column of fields (can be made multiple columns for tablet if needed)
                _buildDropdownField(
                  label: "Job Type",
                  value: selectedJobType,
                  items: ["Full Time", "Part Time", "Contract", "Freelance"],
                  onChanged: (val) => setState(() => selectedJobType = val),
                  hint: "Select Job Type",
                ),

                _buildDatePickerField(
                  label: "Date Of Approval",
                  controller: _dateOfApprovalController,
                  context: context,
                ),

                _buildDropdownField(
                  label: "Location",
                  value: selectedLocation,
                  items: ["Chennai", "Bangalore", "Hyderabad", "Remote"],
                  onChanged: (val) => setState(() => selectedLocation = val),
                  hint: "Select Location",
                ),

                _buildDropdownField(
                  label: "Department",
                  value: selectedDepartment,
                  items: ["IT", "HR", "Sales", "Marketing", "Finance"],
                  onChanged: (val) => setState(() => selectedDepartment = val),
                  hint: "Select Department",
                ),

                _buildTextField(
                  label: "Request Date",
                  controller: _requestDateController,
                  readOnly: true,
                ),

                _buildTextField(
                  label: "No of Vacancies",
                  controller: _noOfVacanciesController,
                  keyboardType: TextInputType.number,
                  hint: "Enter number of vacancies",
                ),

                _buildDropdownField(
                  label: "Priority",
                  value: selectedPriority,
                  items: ["High", "Medium", "Low"],
                  onChanged: (val) => setState(() => selectedPriority = val),
                  hint: "Select Priority",
                ),

                _buildTextField(
                  label: "Experience Required",
                  controller: _experienceController,
                  hint: "e.g. 2-5 Years",
                ),

                _buildTextField(
                  label: "Requested By",
                  controller: _requestedByController,
                  hint: "Name of requester",
                ),

                _buildTextField(
                  label: "Qualification",
                  controller: _qualificationController,
                  hint: "e.g. B.E / B.Tech",
                ),

                _buildTextField(
                  label: "Skills Required",
                  controller: _skillsController,
                  maxLines: 3,
                  hint: "List critical skills",
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Saving Requirement...'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF1E88E5,
                      ), // Blue Save Button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Save",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add, size: 20, color: Color(0xFF1E88E5)),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E88E5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey.shade400,
                fontSize: 13,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            items: items
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, style: GoogleFonts.poppins(fontSize: 14)),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey.shade400,
                fontSize: 13,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required TextEditingController controller,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            readOnly: true,
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() {
                  controller.text = DateFormat('yyyy-MM-dd').format(picked);
                });
              }
            },
            decoration: InputDecoration(
              suffixIcon: const Icon(Icons.calendar_month, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
