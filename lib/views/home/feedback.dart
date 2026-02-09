import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrm/views/home/ticket_raise.dart';

void main() => runApp(const MaterialApp(home: FeedbackSupportScreen()));

class FeedbackSupportScreen extends StatelessWidget {
  const FeedbackSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final isTablet = width > 600;

    final double horizontalPadding = isTablet ? 32.0 : 20.0;
    final double topPadding = isTablet ? 32.0 : 24.0;
    final double titleFontSize = isTablet ? 26.0 : 22.0;
    final double bodyFontSize = isTablet ? 16.5 : 15.0;
    final double buttonHeight = isTablet ? 64.0 : 56.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Feedback & Support",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: topPadding),

            // Title
            Text(
              "Feedback & Support – HRM Portal",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              "We're here to support you in your HR journey.\n"
                  "Got questions about attendance, payroll, leave, or performance? Find quick answers or connect with our HR team.\n\n"
                  "Call Us Directly",
              style: GoogleFonts.poppins(
                fontSize: bodyFontSize,
                color: Colors.black,
                height: 1.50,
              ),
            ),

            const SizedBox(height: 10),

            // Phone Section (No container, just text + icon)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF26A69A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.phone_outlined,
                    color: const Color(0xFF26A69A),
                    size: isTablet ? 30 : 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Speak with our customer care team for urgent help.",
                        style: GoogleFonts.poppins(
                          fontSize: bodyFontSize,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "HR Helpdesk: +91 98765–43210\nAvailable 9 AM – 6 PM (Mon–Sat)",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Email Section (No container)
            Text(
              "Email Support",
              style: GoogleFonts.poppins(
                fontSize: bodyFontSize,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF26A69A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.email_outlined,
                    color: const Color(0xFF26A69A),
                    size: isTablet ? 30 : 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "For detailed queries or document submissions.",
                        style: GoogleFonts.poppins(
                          fontSize: bodyFontSize,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                      Text(
                        "support@hrm.com",
                        style: GoogleFonts.poppins(
                          fontSize: bodyFontSize + 1,
                          fontWeight: FontWeight.w600,
                          color: const  Color(0xFF26A69A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: size.height * 0.24),

            // Raise a Ticket Button
            Center(
              child: SizedBox(
                width: isTablet ? 420 : double.infinity,
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => TicketRaise(),));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF26A69A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 6,
                  ),
                  child: Text(
                    "Raise a Ticket",
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: size.height * 0.05),
          ],
        ),
      ),
    );
  }
}