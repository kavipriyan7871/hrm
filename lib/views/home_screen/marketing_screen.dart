import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'marketing_task_detail.dart';
import 'marketing_visit_screen.dart';
import '../../models/marketing_api.dart';
import '../../models/employee_api.dart';
import '../../services/device_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MarketingScreen extends StatefulWidget {
  const MarketingScreen({super.key});

  @override
  State<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends State<MarketingScreen> {
  bool isLoading = true;
  List<dynamic> enquiriesList = [];
  int todayEnquiryCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMarketingEnquiries();
  }

  Future<void> _loadMarketingEnquiries() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String cid = prefs.getString('cid') ?? "";
      String deviceId = await DeviceService.getDeviceId();
      Map<String, String> location = await DeviceService.getLocation();
      String token = prefs.getString('token') ?? "";
      int? uidInt = prefs.getInt('uid');
      String uid = uidInt?.toString() ?? prefs.getString('uid') ?? "";

      // 1. Try to get the TECHNICAL ID (31) from cache first for speed
      String? cachedAssignTo = prefs.getString('assign_to');
      String assignTo = cachedAssignTo ?? uid;

      if (cachedAssignTo == null) {
        // Only fetch mapping if not in cache
        try {
          final empDetails = await EmployeeApi.getEmployeeDetails(
            uid: uid,
            cid: cid,
            deviceId: deviceId,
            lat: location['lat']!,
            lng: location['ln']!,
            token: token,
          );

          if (empDetails['error'] == false) {
            assignTo = empDetails['uid']?.toString() ?? uid;
            await prefs.setString('assign_to', assignTo); // Cache for next time
            debugPrint("FETCHED & CACHED ASSIGN_TO: $assignTo");
          }
        } catch (e) {
          debugPrint("Error fetching ID mapping: $e");
        }
      } else {
        debugPrint("USING CACHED ASSIGN_TO: $assignTo");
      }

      debugPrint(
        "Marketing Screen Params: cid=$cid, uid=$uid, assignTo=$assignTo, token=$token",
      );

      final response = await MarketingApi.fetchEnquiries(
        uid: uid,
        cid: cid,
        deviceId: deviceId,
        lat: location['lat']!,
        lng: location['ln']!,
        assignTo: assignTo,
        token: token,
      );

      if (response['error'] == false) {
        setState(() {
          enquiriesList = response['data'] ?? [];
          todayEnquiryCount =
              response['summary']?['total'] ?? enquiriesList.length;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['error_msg'] ?? "Failed to load enquiries",
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error loading enquiries: $e");
      setState(() => isLoading = false);
    }
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
          "Today Task",
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
                    child: Text(
                      "Marketing Team Visit Management",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  _buildVisitToggle(),
                  _buildTopFilterSection(),
                  _buildSummaryCard(),
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
                    builder: (context) => const MarketingVisitScreen(),
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

  Widget _buildSummaryCard() {
    return Center(
      child: Container(
        width: 200,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today, size: 40, color: Colors.black),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Today Follow-up",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF26A69A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF26A69A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                todayEnquiryCount.toString(),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                    builder: (context) => MarketingTaskDetailScreen(task: task),
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