import 'package:flutter/material.dart';
import 'package:hrm/views/main_root.dart';
import 'package:intl/intl.dart';

class NotificationApp extends StatelessWidget {
  const NotificationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const NotificationScreen(),
      theme: ThemeData(primarySwatch: Colors.teal, fontFamily: 'Roboto'),
    );
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String selectedFilter = "All";

  // Sample data with categories
  final List<NotificationItem> notifications = const [
    // Today
    NotificationItem(
      title: "Leave Request Approved",
      subtitle: "Your Leave request for Nov 8-9 Has been Approved By HR",
      icon: (Icons.logout),
      iconColor: Color(0xffF87000),
      time: "Today",
      category: "Leave",
    ),
    NotificationItem(
      title: "Performance Target Reached",
      subtitle: "Congrats! You Achieved 100% of Your Month Target",
      icon: Icons.trending_up,
      iconColor: Color(0xff34C759),
      time: "Today",
      category: "Performance",
    ),
    // Yesterday
    NotificationItem(
      title: "Leave Request Approved",
      subtitle: "Your Leave request for Nov 8-9 Has been Approved By HR",
      icon: Icons.logout,
      iconColor: Colors.orange,
      time: "Yesterday",
      category: "Leave",
    ),
    NotificationItem(
      title: "Performance Target Reached",
      subtitle: "Congrats! You Achieved 100% of Your Month Target",
      icon: Icons.trending_up,
      iconColor: Color(0xff34C759),
      time: "Yesterday",
      category: "Performance",
    ),
    NotificationItem(
      title: "Expense Reimbursement Processed",
      subtitle: "Your On duty Expense claim for ₹2500 has been Approved",
      icon: Icons.currency_rupee,
      iconColor: Color(0xffCA0000),
      time: "Yesterday",
      category: "Expenses",
    ),
    NotificationItem(
      title: "New task Assigned",
      subtitle: "A new client meeting Task has been Assigned by your manager",
      icon: Icons.trending_up,
      iconColor: Color(0xff34C759),
      time: "Yesterday",
      category: "Performance",
    ),
    NotificationItem(
      title: "Ticket Raised",
      subtitle: "Your raised ticket has been Resolved",
      icon: Icons.trending_up,
      iconColor: Color(0xff34C759),
      time: "Yesterday",
      category: "Feedback",
    ),
    NotificationItem(
      title: "System Update Available",
      subtitle:
          "A new version of the app is available. Update now for better performance",
      icon: Icons.system_update,
      iconColor: Color(0xFF2196F3),
      time: "Today",
      category: "System",
    ),
    NotificationItem(
      title: "Payroll Processed",
      subtitle: "Your salary for this month has been processed successfully",
      icon: Icons.account_balance_wallet,
      iconColor: Color(0xFF4CAF50),
      time: "Yesterday",
      category: "Payroll",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double horizontalPadding = size.width * 0.05;

    // Filter notifications based on selected filter
    List<NotificationItem> filteredNotifications = selectedFilter == "All"
        ? notifications
        : notifications.where((n) => n.category == selectedFilter).toList();

    // Group filtered notifications by "Today" and "Yesterday"
    final Map<String, List<NotificationItem>> grouped = {
      "Today": filteredNotifications.where((n) => n.time == "Today").toList(),
      "Yesterday": filteredNotifications
          .where((n) => n.time == "Yesterday")
          .toList(),
    };

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainRoot()),
              (route) => false,
            );
          },
        ),
        title: const Text(
          "Notification",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header Section with filters
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Latest Notification and Date Picker
                Row(
                  children: [
                    const Text(
                      "Latest Notification",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                      },
                      icon: const Icon(
                        Icons.calendar_month,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Pick Date",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF26A69A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 0, // Reduced vertical padding
                        ),
                        minimumSize: const Size(0, 32), // Compact height
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                /// Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip("All"),
                      const SizedBox(width: 8),
                      _buildFilterChip("Leave"),
                      const SizedBox(width: 8),
                      _buildFilterChip("Performance"),
                      const SizedBox(width: 8),
                      _buildFilterChip("Expenses"),
                      const SizedBox(width: 8),
                      _buildFilterChip("Feedback"),
                      const SizedBox(width: 8),
                      _buildFilterChip("Payroll"),
                      const SizedBox(width: 8),
                      _buildFilterChip("System"),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          /// Notification List
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              children: [
                // Today Section
                if (grouped["Today"]!.isNotEmpty) ...[
                  _buildDateHeader("Today"),
                  const SizedBox(height: 8),
                  ...grouped["Today"]!.map((n) => _buildNotificationCard(n)),
                ],

                const SizedBox(height: 20),

                // Yesterday Section
                if (grouped["Yesterday"]!.isNotEmpty) ...[
                  _buildDateHeader("Yesterday"),
                  const SizedBox(height: 8),
                  ...grouped["Yesterday"]!.map(
                    (n) => _buildNotificationCard(n),
                  ),
                ],

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF26A69A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF26A69A) : Colors.black26,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.check, size: 16, color: Colors.white),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String time; // "Today" or "Yesterday"
  final String category; // "Leave", "Performance", "Expenses", "Feedback"

  const NotificationItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.time,
    required this.category,
  });
}
