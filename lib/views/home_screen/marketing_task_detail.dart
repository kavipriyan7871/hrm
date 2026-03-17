import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'marketing_checkin.dart';

class MarketingTaskDetailScreen extends StatelessWidget {
  final Map<String, dynamic> task;

  const MarketingTaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Task Details",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "TASK-${task['id'] ?? '001'}",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${task['project_required'] ?? 'Task'} - ${task['customer_name'] ?? 'Client'}",
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),

            // Visit Status Section
            _buildSection(
              title: "Visit Status",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ready to start your visit?",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MarketingCheckInScreen(task: task),
                        ),
                      );
                    },
                    icon: const Icon(Icons.exit_to_app, size: 20),
                    label: const Text("Check in to Visit"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF26A69A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Task Details Section
            _buildSection(
              title: "Task Details",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoLabel("Description"),
                  Text(
                    task['project_required']?.toString() ?? "N/A",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Color(0xFF26A69A),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoLabel("Scheduled Date"),
                          Text(
                            "${task['meeting_date'] ?? task['date'] ?? ''} ${task['meeting_time'] ?? ''}"
                                    .trim()
                                    .isEmpty
                                ? "N/A"
                                : "${task['meeting_date'] ?? task['date'] ?? ''} ${task['meeting_time'] ?? ''}"
                                    .trim(),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Client Information Section
            _buildSection(
              title: "Client Information",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoLabel("Name"),
                  _infoText(task['customer_name'] ?? "N/A"),
                  const SizedBox(height: 12),
                  _infoLabel("Company"),
                  _infoText(task['company_name'] ?? task['client_company'] ?? "N/A"),
                  const SizedBox(height: 12),
                  _infoLabel("Phone"),
                  _infoText(task['mobile_no'] ?? task['phone'] ?? "N/A"),
                  const SizedBox(height: 12),
                  _infoLabel("Email"),
                  _infoText(task['email'] ?? task['cus_email'] ?? "N/A"),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  _infoLabel("Address"),
                  _infoText(task['address'] ?? task['customer_address'] ?? "N/A"),
                  const SizedBox(height: 4),
                  if (task['lat'] != null && task['lng'] != null)
                    Text(
                      "Coordinates: ${task['lat']}, ${task['lng']}",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _infoLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
      ),
    );
  }

  Widget _infoText(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
    );
  }
}
