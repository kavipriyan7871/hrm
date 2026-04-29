import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'service_task_detail.dart';
import 'service_visit_screen.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  bool isLoading = true;
  List<dynamic> enquiriesList = [];
  int todayEnquiryCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDummyData();
  }

  void _loadDummyData() {
    setState(() {
      isLoading = false;
      enquiriesList = [
        {
          'id': '101',
          'customer_name': 'Tech Solutions',
          'meeting_time': '10:30 AM',
          'project_required': 'Server Maintenance',
          'type': 'New',
          'company_name': 'Tech Solutions Corp',
          'mobile_no': '+91 9876543210',
          'email': 'contact@techsolutions.com',
          'address': '123 Tech Park, Bangalore',
          'lat': '12.9716',
          'lng': '77.5946',
        },
        {
          'id': '102',
          'customer_name': 'Green Energy Ltd',
          'meeting_time': '02:15 PM',
          'project_required': 'Solar Panel Installation',
          'type': 'API',
          'company_name': 'Green Energy Group',
          'mobile_no': '+91 8765432109',
          'email': 'info@greenenergy.com',
          'address': '456 Eco Way, Chennai',
          'lat': '13.0827',
          'lng': '80.2707',
        },
      ];
      todayEnquiryCount = enquiriesList.length;
    });
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
          "Services",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 50.0),
                child: CircularProgressIndicator(color: Color(0xFF26A69A)),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  _buildVisitToggle(),
                  _buildTopFilterSection(),
                  // _buildSummaryCard(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      "Today Follow-up List",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  _buildTasksList(),
                ],
              ),
            ),
    );
  }

  Widget _buildVisitToggle() {
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
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF26A69A),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                "Visit Management",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ServiceVisitScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(color: Colors.transparent),
                alignment: Alignment.center,
                child: Text(
                  "Visit History",
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopFilterSection() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _filterCircle(Icons.group, const Color(0xFF26A69A), true),
              _filterCircle(Icons.sync, Colors.grey.shade100, false),
              _filterCircle(Icons.logout, Colors.grey.shade100, false),
              _filterCircle(Icons.shuffle, Colors.grey.shade100, false),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _filterButton("Today", true),
              _filterButton("Re\nSchedule", false),
              _filterButton("up\nComing", false),
              _filterButton("Missed", false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterCircle(IconData icon, Color color, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(
        icon,
        color: isActive ? Colors.white : Colors.teal.shade700,
        size: 24,
      ),
    );
  }

  Widget _filterButton(String text, bool isActive) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF26A69A) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: isActive ? Colors.white : Colors.teal.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Widget _buildSummaryCard() {
  //   return Center(
  //     child: Container(
  //       width: 200,
  //       margin: const EdgeInsets.symmetric(vertical: 8),
  //       padding: const EdgeInsets.all(16),
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(12),
  //         border: Border.all(color: Colors.grey.shade200),
  //       ),
  //       child: Column(
  //         children: [
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               const Icon(Icons.calendar_today, size: 40, color: Colors.black),
  //               const SizedBox(width: 8),
  //               Expanded(
  //                 child: Text(
  //                   "Today Follow-up",
  //                   style: GoogleFonts.poppins(
  //                     fontSize: 14,
  //                     fontWeight: FontWeight.w500,
  //                     color: const Color(0xFF26A69A),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: 12),
  //           Container(
  //             padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
  //             decoration: BoxDecoration(
  //               color: const Color(0xFF26A69A),
  //               borderRadius: BorderRadius.circular(8),
  //             ),
  //             child: Text(
  //               todayEnquiryCount.toString(),
  //               style: GoogleFonts.poppins(
  //                 color: Colors.white,
  //                 fontSize: 18,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildTasksList() {
    return enquiriesList.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "No follow-ups found for today",
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
          )
        : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: enquiriesList.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final task = enquiriesList[index];
              return _buildTaskCard(task);
            },
          );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    String status = task['type']?.toString() ?? 'new';
    Color statusColor =
        (status.toLowerCase() == 'new' || status.toLowerCase() == 'api')
        ? const Color(0xFF81C784)
        : const Color(0xFFFFB74D);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _infoRow(
                      Icons.person_outline,
                      "Name",
                      task['customer_name'] ?? "Unknown",
                    ),
                    _infoRow(
                      Icons.adjust_outlined,
                      "Lead No",
                      task['id']?.toString() ?? "N/A",
                    ),
                    _infoRow(
                      Icons.calendar_today_outlined,
                      "Time",
                      task['meeting_time'] ?? "--:--",
                    ),
                    _infoRow(
                      Icons.track_changes_outlined,
                      "Purpose",
                      task['project_required'] ?? "General",
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toLowerCase(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceTaskDetailScreen(task: task),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "View Full Detail",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.indigo.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.double_arrow,
                    size: 10,
                    color: Colors.indigo.shade900,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black87),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
            ),
          ),
          Text(
            ": $value",
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

