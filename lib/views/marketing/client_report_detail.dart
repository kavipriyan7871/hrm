import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ClientReportDetailScreen extends StatelessWidget {
  final int reportIndex;
  const ClientReportDetailScreen({super.key, required this.reportIndex});

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
          "Report #$reportIndex view",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Marketing Team Visit Management",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            _buildVisitToggle(context),
            _buildDetailCard(),
            const SizedBox(height: 20),
            _buildBottomActions(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitToggle(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                // Navigate back to management if needed
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(color: Colors.transparent),
                alignment: Alignment.center,
                child: Text(
                  "Visit Management",
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF26A69A),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                "Visit History",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF26A69A).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Report #$reportIndex",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF81C784),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "Needs followup",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Product Demo - Tech Solutions",
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _iconTextRow(
            Icons.person_outline,
            "Akhil Mohan",
            Icons.business_outlined,
            "Tech Solutions",
          ),
          const SizedBox(height: 12),
          _iconTextRow(
            Icons.calendar_today_outlined,
            "Wed, Mar 4, 2026",
            Icons.access_time,
            "50 minutes",
          ),

          const Divider(height: 24),

          _sectionTitle("Meeting Notes"),
          const SizedBox(height: 4),
          _sectionContent("meeting with next meet up"),

          const SizedBox(height: 12),
          _sectionTitle("Product Interest"),
          const SizedBox(height: 4),
          _sectionContent("features"),

          const SizedBox(height: 12),
          _sectionTitle("Next Follow-up"),
          const SizedBox(height: 4),
          _sectionContent("Sunday, May 3, 2026"),

          const Divider(height: 24),
          _sectionTitle("Visit Timeline"),
          const SizedBox(height: 8),
          _buildTimelineBox(),

          const SizedBox(height: 16),
          _sectionTitle("Attachment"),
          const SizedBox(height: 6),
          _buildPlaceholderBox("No Attacment Found"),

          const SizedBox(height: 16),
          _sectionTitle("Client Signature"),
          const SizedBox(height: 6),
          _buildSignatureBox(),
        ],
      ),
    );
  }

  Widget _iconTextRow(
    IconData icon1,
    String text1,
    IconData icon2,
    String text2,
  ) {
    return Row(
      children: [
        Icon(icon1, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text1,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text("•", style: TextStyle(color: Colors.grey)),
        ),
        Icon(icon2, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text2,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  Widget _sectionContent(String content) {
    return Text(
      content,
      style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
    );
  }

  Widget _buildTimelineBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _timelineItem(
                  "Check-in",
                  "3:31:20 PM",
                  "37.7787, -122.4216",
                ),
              ),
              Expanded(
                child: _timelineItem(
                  "Check-out",
                  "4:31:21 PM",
                  "Duration: 59 minutes",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timelineItem(String label, String time, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade700),
        ),
        Text(
          time,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        Text(
          sub,
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _buildPlaceholderBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildSignatureBox() {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      alignment: Alignment.center,
      child: Image.network(
        "https://www.sigpluspro.com/images/sigpluspro/Signature.png",
        height: 50,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.gesture, color: Colors.grey),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF26A69A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {},
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
              label: Text(
                "Export PDF",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF26A69A),
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Color(0xFF26A69A)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {},
              icon: const Icon(Icons.share_outlined, size: 20),
              label: Text(
                "Share",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
