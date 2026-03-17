import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'marketing_checkout.dart';

class MarketingCheckInScreen extends StatefulWidget {
  final Map<String, dynamic>? task;

  const MarketingCheckInScreen({super.key, this.task});

  @override
  State<MarketingCheckInScreen> createState() => _MarketingCheckInScreenState();
}

class _MarketingCheckInScreenState extends State<MarketingCheckInScreen> {
  // Hardcoded values as per the requested exact UI
  final String taskId = "001";
  final String purpose = "Product Demo";
  final String clientName = "Tech Solutions";

  final String checkInTimeStr = "3/3/2026, 10:57:58 AM";
  final String checkInLocationStr = "37.7777, -122.4161";

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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "TASK-$taskId",
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "$purpose - $clientName",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),

            // Visit Status Card
            _buildSectionCard(
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
                  const SizedBox(height: 14),
                  // The Grey Box from your image
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Check-in time",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          checkInTimeStr,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Location: $checkInLocationStr",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CheckoutScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.exit_to_app, size: 20),
                    label: const Text("Check out & Submit Report"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF26A69A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(155, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Task Details Card
            _buildSectionCard(
              title: "Task Details",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel("Description"),
                  Text(
                    purpose.toLowerCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1, color: Color(0xFFEEEEEE)),
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
                          _fieldLabel("Scheduled Date"),
                          Text(
                            "Tuesday, March 3, 2026",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
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

            const SizedBox(height: 16),

            // Client Information Card
            _buildSectionCard(
              title: "Client Information",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel("Name"),
                  _fieldValue("Akhil"),
                  const SizedBox(height: 12),
                  _fieldLabel("Company"),
                  _fieldValue("Tech Solutions Inc"),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                  ),
                  _fieldLabel("Company"),
                  _fieldValue("Tech Solutions Inc"),
                  const SizedBox(height: 12),
                  _fieldLabel("Phone"),
                  _fieldValue("+1234567891"),
                  const SizedBox(height: 12),
                  _fieldLabel("Email"),
                  _fieldValue("akhil@techsolutions.com"),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                  ),
                  _fieldLabel("Address"),
                  _fieldValue("Coimbatore"),
                  const SizedBox(height: 4),
                  Text(
                    "Coordinates: 37.7749, -122.4194",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
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

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500),
      ),
    );
  }

  Widget _fieldValue(String value) {
    return Text(
      value,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }
}
