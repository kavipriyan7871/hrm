import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'client_report_screen.dart';

class ClientTaskDetailScreen extends StatefulWidget {
  final Map<String, dynamic> task;
  final bool isCheckedIn;
  final String? checkInTime;

  const ClientTaskDetailScreen({
    super.key,
    required this.task,
    this.isCheckedIn = false,
    this.checkInTime,
  });

  @override
  State<ClientTaskDetailScreen> createState() => _ClientTaskDetailScreenState();
}

class _ClientTaskDetailScreenState extends State<ClientTaskDetailScreen> {
  late bool isCheckedIn;
  String? checkInTime;

  @override
  void initState() {
    super.initState();
    isCheckedIn = widget.isCheckedIn;
    checkInTime = widget.checkInTime;
  }

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
          "Client Meeting Details",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "CLIENT-MEETING-${widget.task['id'] ?? '001'}",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.task['project_required'] ?? "Strategic Discussion",
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),

            // Visit Status Section
            _buildSection(
              title: "Meeting Status",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCheckedIn ? "Meeting Started at:" : "Ready to begin the client meeting?",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isCheckedIn)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _statusInfo(Icons.access_time, "Start time", checkInTime ?? "10:57:58 AM"),
                          const SizedBox(height: 4),
                          _statusInfo(Icons.location_on_outlined, "Location", "37.7749, -122.4194"),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (!isCheckedIn) {
                        setState(() {
                          isCheckedIn = true;
                          checkInTime = DateFormat('hh:mm:ss a').format(DateTime.now());
                        });
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClientReportScreen(task: widget.task, checkInTime: checkInTime!),
                          ),
                        );
                      }
                    },
                    icon: Icon(isCheckedIn ? Icons.login : Icons.exit_to_app, size: 18),
                    label: Text(isCheckedIn ? "End Meeting & Submit Report" : "Start Client Meeting"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF26A69A),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Meeting Details Section
            _buildSection(
              title: "Meeting Details",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoLabel("Agenda"),
                  Text(
                    widget.task['purpose'] ?? "Quarterly Review and Planning",
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.access_time_outlined, color: Color(0xFF26A69A), size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoLabel("Scheduled Date"),
                          Text(
                            widget.task['date'] ?? "Friday, March 6, 2026",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
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

            const SizedBox(height: 20),

            // Participant Information Section
            _buildSection(
              title: "Participant Information",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoField("Contact Person", widget.task['customer_name'] ?? "Lakshimi"),
                  _infoField("Designation", "Operations Head"),
                  _infoField("Organization", "Smart Gadgets Hub"),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  _infoLabel("Venue"),
                  Text(
                    widget.task['address'] ?? "Main Office, Chennai",
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
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

  Widget _statusInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _infoLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
    );
  }

  Widget _infoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoLabel(label),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
