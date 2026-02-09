// payroll_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrm/views/widgets/profile_card.dart';
import '../main_root.dart';

class PayrollScreen extends StatelessWidget {
  const PayrollScreen({super.key});

  static const Color tealColor = Color(0xFF26A69A);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (context)=> MainRoot()),
        (route)=> false,
        );
        return false;
      },

    child:  Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: tealColor,
        foregroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainRoot()),
                  (route) => false,
            );
          },
        ),
        title: Text(
          'Payroll',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.more_vert),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Card
              // const ProfileInfoCard(
              //   name: "Harish",
              //   employeeId: "1023",
              //   designation: "Supervisor",
              //   profileImagePath: 'assets/profile.png',
              // ),
              // const SizedBox(height: 20),

              // Teal Container with 4 White Cards
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: tealColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "October Month Salary Details",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildWhiteInnerCard("Monthly", "₹30000")),
                        const SizedBox(width: 16),
                        Expanded(child: _buildWhiteInnerCard("Per Day", "₹1071")),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildWhiteInnerCard("Days Worked", "28 Days")),
                        const SizedBox(width: 16),
                        Expanded(child: _buildWhiteInnerCard("Leave days", "4 Days")),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Earnings
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Earnings",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildEarningsRow("Bonus", "₹ 3000"),
                    _buildEarningsDivider(),
                    _buildEarningsRow("Allowance", "₹ 10000"),
                    _buildEarningsDivider(),
                    _buildEarningsRow("Incentive", "₹ 3000"),

                    const SizedBox(height: 20),

                    // Green Incentive Box with Star Image
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xff34C759),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            "assets/star.png",
                            height: 40,
                            width: 40,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "You Got Incentive Because",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  "You Achieved Your Target",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Breakdown Section with Custom Colors
              Text(
                "Breakdown",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildBreakdownRow("Monthly salary", "₹30000", valueColor: Colors.green.shade700),
                    _buildBreakdownRow("Per Day Salary", ""),
                    _buildBreakdownRow("Days Worked", "28", valueColor: Colors.black87),
                    _buildBreakdownRow("Bonus", "-"),
                    _buildBreakdownRow("Allowance", "-"),
                    _buildBreakdownRow("Incentive", "₹3000", valueColor: Colors.orange.shade700),
                    const Divider(height: 32),
                    _buildBreakdownRow("Gross", "₹30000", isBold: true, valueColor: Colors.black87),
                    const SizedBox(height: 8),
                    _buildBreakdownRow("Per Day leave Deduction", "-"),
                    _buildBreakdownRow("Total Deduction", "₹3000", valueColor: Colors.red.shade700),
                    const Divider(height: 32),
                    _buildBreakdownRow("Gross Pay", "₹30000", isBold: true, valueColor: Colors.green.shade700),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton("Download", Icons.download, tealColor),
                  _buildActionButton("Share", Icons.share, tealColor),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ));
  }

  // White Cards inside Teal Container
  Widget _buildWhiteInnerCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 16, color: tealColor, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: tealColor),
          ),
        ],
      ),
    );
  }

  // Earnings Row
  Widget _buildEarningsRow(String title, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87)),
          Text(
            amount,
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsDivider() => Divider(color: Colors.grey.shade300, height: 1);

  // Updated Breakdown Row with Custom Color Support
  Widget _buildBreakdownRow(
      String label,
      String value, {
        bool isBold = false,
        Color? valueColor,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Action Buttons
  Widget _buildActionButton(String text, IconData icon, Color color) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 20),
      label: Text(text, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}