import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrm/views/widgets/profile_card.dart';

import 'add_expense.dart';

class ExpenseManagementScreen extends StatelessWidget {
  const ExpenseManagementScreen({super.key});

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
          "Expense Management",
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 22 : 19,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // // ==================== PROFILE CARD ====================
            // ProfileInfoCard(
            //   name: "Harish",
            //   employeeId: "1023",
            //   designation: "Supervisor",
            //   profileImagePath: "assets/profile.png",
            // ),

            // const SizedBox(height: 20),

            // ==================== SUMMARY CARDS ====================
            Row(
              children: [
                Expanded(child: _buildSummaryCard("Total", "₹ 2150", const Color(0xFF26A69A))),
                const SizedBox(width: 12),
                Expanded(child: _buildSummaryCard("Approved", "₹ 1200", const Color(0xFF4CAF50))),
                const SizedBox(width: 12),
                Expanded(child: _buildSummaryCard("Pending", "₹ 650", const Color(0xFFFF9800))),
              ],
            ),

            const SizedBox(height: 30),

                        _buildExpenseItem(
              context: context,
              icon: Icons.currency_rupee_outlined,
              iconColor: Colors.green,
              title: "Travel Expense",
              date: "Nov 5, 2025",
              amount: "₹ 1200",
              status: "Approved",
              statusColor: const Color(0xff05D817),
            ),

            const SizedBox(height: 16),

            _buildExpenseItem(
              context: context,
              icon: Icons.restaurant,
              iconColor: Colors.orange,
              title: "Lunch",
              date: "Nov 5, 2025",
              amount: "₹ 1200",
              status: "Pending",
              statusColor: const Color(0xffF87000),
            ),

            const SizedBox(height: 16),

            _buildExpenseItem(
              context: context,
              icon: Icons.local_mall,
              iconColor: Colors.red,
              title: "Office Stationery",
              date: "Nov 5, 2025",
              amount: "₹ 1200",
              status: "Pending",
              statusColor: const Color(0xffCA0000),
            ),

            const SizedBox(height: 100),

                        Container(
                          margin: EdgeInsets.only(
                            left: 150,
                          ),
                          child: SizedBox(
                                        width:200,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => AddExpense(),));
                                          },
                                          icon: const Icon(Icons.add, size: 20),
                                          label: Text(
                                            "Add Expense",
                                            style: GoogleFonts.poppins(
                                              fontSize: isTablet ? 18 : 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF26A69A),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            elevation: 4,
                                          ),
                                        ),
                                      ),
                        ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Summary Card
  Widget _buildSummaryCard(String title, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.teal,
        ),
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
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
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Individual Expense Item
  Widget _buildExpenseItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String date,
    required String amount,
    required String status,
    required Color statusColor,
  }) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isTablet ? 28 : 24,
            backgroundColor: iconColor.withOpacity(0.2),
            child: Icon(icon, color: iconColor, size: isTablet ? 32 : 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 15 : 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}