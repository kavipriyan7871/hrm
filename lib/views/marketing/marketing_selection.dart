import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrm/views/marketing/client_screen.dart';
import 'package:hrm/views/marketing/service_screen.dart';
// import 'marketing_screen.dart';
import 'marketing_checkin.dart';

class MarketingSelectionScreen extends StatelessWidget {
  const MarketingSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double padding = w * 0.04;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Marketing",
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.info_outline), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: padding, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              "Access your specialized workflow management tools.",
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF49454F),
              ),
            ),
            const SizedBox(height: 32),
            _selectionTile(
              context,
              "Marketing",
              "Maximize leads, track visits, and optimize sales conversions.",
              "assets/marketing.png",
              const Color(0xFF26A69A),
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MarketingCheckInScreen(),
                  ),
                );
              },
            ),
            _selectionTile(
              context,
              "Service Support",
              "Handle field service reports and customer requests seamlessly.",
              "assets/performance.png",
              const Color(0xFF673AB7),
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ServiceScreen(),
                  ),
                );
              },
            ),
            _selectionTile(
              context,
              "Client Meeting",
              "Coordinate and finalize high-priority client interactions.",
              "assets/icons/calender.png",
              const Color(0xFF1976D2),
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ClientScreen()),
                );
              },
            ),
            // _selectionTile(
            //   context,
            //   "Store Visitor",
            //   "Monitor and manage store visitor activities and reports.",
            //   "assets/location.png",
            //   const Color(0xFFFF9800),
            //   () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => const VisitStoreScreen(),
            //       ),
            //     );
            //   },
            // ),
            // const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _selectionTile(
    BuildContext context,
    String title,
    String description,
    String assetPath,
    Color accentColor,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: accentColor.withValues(alpha: 0.04),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Image.asset(
                    assetPath,
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1C1E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          height: 1.4,
                          color: const Color(0xFF49454F),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: accentColor.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
