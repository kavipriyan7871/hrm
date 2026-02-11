import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrm/views/main_root.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'leave_application.dart';

void main() => runApp(const MaterialApp(home: LeaveManagementScreen()));

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  int selectedTab = 0; // 0 = Summary, 1 = History
  List<dynamic> historyData = [];
  bool isLoading = false;
  bool isBalanceLoading = false;

  // Static list structure matching original design
  List<Map<String, dynamic>> leaveBalanceData = [
    {
      "type": "Casual",
      "taken": 0,
      "total": 12,
      "balance": "12/12",
      "gradient": [const Color(0xFFF5F5F5), const Color(0xFFD4D6FF)],
      "progressColor": const Color(0xff8388FF),
      "titleColor": const Color(0xff1B2C61),
    },
    {
      "type": "Sick",
      "taken": 0,
      "total": 12,
      "balance": "12/12",
      "gradient": [const Color(0xFFF5F5F5), const Color(0xFFD4FEFF)],
      "progressColor": const Color(0xff59FAFF),
      "titleColor": const Color(0xff1B2C61),
    },
    {
      "type": "Earned",
      "taken": 0,
      "total": 12,
      "balance": "12/12",
      "gradient": [const Color(0xFFF5F5F5), const Color(0xFFF4D4FF)],
      "progressColor": const Color(0xffD679F8),
      "titleColor": const Color(0xff1B2C61),
    },
    {
      "type": "Maternity",
      "taken": 0,
      "total": 12,
      "balance": "12/12",
      "gradient": [const Color(0xFFF5F5F5), const Color(0xFFFFD4D5)],
      "progressColor": const Color(0xffFB6065),
      "titleColor": const Color(0xff1B2C61),
    },
    {
      "type": "Unpaid",
      "taken": 0,
      "total": null,
      "balance": "-/-",
      "gradient": [const Color(0xFFF5F5F5), const Color(0xFFA8EA9F)],
      "progressColor": const Color(0xFF00B894),
      "titleColor": const Color(0xff1B2C61),
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchLeaveSummary();
    // Pre-fetch history if needed, or wait until tab switch
  }

  Future<void> _fetchLeaveSummary() async {
    setState(() => isBalanceLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getInt('uid') ?? 1;
      final lat = prefs.getDouble('lat')?.toString() ?? "145";
      final lng = prefs.getDouble('lng')?.toString() ?? "145";

      final response = await http.post(
        Uri.parse("https://erpsmart.in/total/api/m_api/"),
        body: {
          "cid": "21472147",
          "device_id": "123456",
          "lt": lat,
          "ln": lng,
          "type": "2051",
          "uid": uid.toString(),
          "id": uid.toString(),
        },
      );

      debugPrint("LEAVE SUMMARY RESPONSE (2051): ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['error'] == false) {
          List<dynamic> apiList = [];

          // Check for 'leave_summary' at root level (as per User JSON)
          if (data['leave_summary'] != null && data['leave_summary'] is List) {
            apiList = data['leave_summary'];
          } else if (data['data'] != null && data['data'] is List) {
            apiList = data['data'];
          } else if (data['data'] != null &&
              data['data'] is Map &&
              data['data']['leave_summary'] != null) {
            apiList = data['data']['leave_summary'];
          }

          setState(() {
            // Iterate through our static list and update values if API has matching type
            for (var staticItem in leaveBalanceData) {
              String staticType = staticItem['type'].toString().toLowerCase();

              // Find matching item in API list
              var apiItem = apiList.firstWhere((api) {
                String apiType =
                    (api['leave_type_name'] ??
                            api['leave_type'] ??
                            api['type'] ??
                            "")
                        .toString()
                        .toLowerCase();
                // Loose matching
                if (staticType == "earned") {
                  return apiType.contains("privilege") ||
                      apiType.contains("earned");
                }
                if (staticType == "casual") {
                  return apiType.contains("casual");
                }
                if (staticType == "sick") {
                  return apiType.contains("medical") ||
                      apiType.contains("sick");
                }
                return apiType.contains(staticType);
              }, orElse: () => null);

              if (apiItem != null) {
                int taken =
                    int.tryParse(
                      apiItem['leaves_taken_this_year']
                              ?.toString() ?? // User JSON key
                          apiItem['leave_taken']?.toString() ??
                          apiItem['taken']?.toString() ??
                          "0",
                    ) ??
                    0;
                int total =
                    int.tryParse(
                      apiItem['max_days_per_year']
                              ?.toString() ?? // User JSON key
                          apiItem['total_allowed']?.toString() ??
                          apiItem['total']?.toString() ??
                          "12",
                    ) ??
                    12; // Default to 12 if missing or 0 might be better

                staticItem['taken'] = taken;
                staticItem['total'] = total;
                staticItem['balance'] = "${total - taken}/$total";
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching leave summary: $e");
    } finally {
      setState(() => isBalanceLoading = false);
    }
  }

  Future<void> _fetchLeaveHistory() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getInt('uid') ?? 1;
      final empCode = prefs.getString('employee_code') ?? ""; // GET CODE
      final lat = prefs.getDouble('lat')?.toString() ?? "145";
      final lng = prefs.getDouble('lng')?.toString() ?? "145";

      final response = await http.post(
        Uri.parse("https://erpsmart.in/total/api/m_api/"),
        body: {
          "cid": "21472147",
          "device_id": "123456",
          "lt": lat,
          "ln": lng,
          "type": "2052",
          "uid": uid.toString(),
          "id": uid.toString(),
        },
      );

      debugPrint("LEAVE HISTORY RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> fetchedList = [];

        if (data is List) {
          fetchedList = data;
        } else if (data['leave_applications'] != null &&
            data['leave_applications'] is List) {
          fetchedList = data['leave_applications'];
        } else if (data["data"] != null && data["data"] is List) {
          fetchedList = data["data"];
        } else if (data['error'] == false && data['data'] != null) {
          fetchedList = data['data'];
        }

        // FILTER BY EMPLOYEE CODE
        if (empCode.isNotEmpty) {
          fetchedList = fetchedList.where((item) {
            final itemCode = item['employee_uid']?.toString() ?? "";
            return itemCode == empCode;
          }).toList();
        }

        setState(() => historyData = fetchedList);
      }
    } catch (e) {
      debugPrint("Error fetching leave history: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xff26A69A),
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
          'Leave Management',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // const ProfileSection(),
            const SizedBox(height: 12),

            // TABS
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: selectedTab == 0
                                ? const Color(0xff26A69A)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Text(
                            "Leave Summary",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: selectedTab == 0
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => selectedTab = 1);
                          if (historyData.isEmpty) {
                            _fetchLeaveHistory();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: selectedTab == 1
                                ? const Color(0xff26A69A)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Text(
                            "Leave History",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: selectedTab == 1
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            selectedTab == 0
                ? isBalanceLoading
                      ? const Center(child: CircularProgressIndicator())
                      : LeaveBalanceGrid(leaveData: leaveBalanceData)
                : isLoading
                ? const Center(child: CircularProgressIndicator())
                : LeaveHistoryList(history: historyData),

            if (selectedTab == 0) ...[
              const SizedBox(height: 40),
              const HolidayListCard(),
              const SizedBox(height: 40),
              const ApplyLeaveButton(),
              const SizedBox(height: 40),
            ] else
              const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// class ProfileSection extends StatelessWidget {
//   const ProfileSection({super.key});
//   @override Widget build(BuildContext context) => Padding(
//     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//     child: ProfileInfoCard(name: 'Harsh', employeeId: '1023', designation: 'Supervisor', profileImagePath: 'assets/profile.png'),
//   );
// }

class LeaveBalanceGrid extends StatelessWidget {
  final List<Map<String, dynamic>> leaveData;
  const LeaveBalanceGrid({super.key, required this.leaveData});

  // Replaced original static list with passed data
  // No list here

  @override
  Widget build(BuildContext context) {
    final double cardWidth = (MediaQuery.of(context).size.width - 48 - 20) / 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        children: leaveData.map((data) {
          final progress = data["total"] == null
              ? 0.0
              : (data["taken"] as num) / (data["total"] as num);
          return SizedBox(
            width: cardWidth,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: data["gradient"],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ${data["type"]}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: data["titleColor"],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Taken    : ${data["taken"]} Days',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Balance : ${data["balance"]}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation(data["progressColor"]),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class LeaveHistoryList extends StatelessWidget {
  final List<dynamic> history;
  const LeaveHistoryList({super.key, this.history = const []});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            "No leave history found",
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        // Parse date range
        String dateRange = item["date"] ?? item["f_date"] ?? "-";
        if (item["leave_start_date"] != null &&
            item["leave_end_date"] != null) {
          dateRange =
              "${item["leave_start_date"]} To ${item["leave_end_date"]}";
        }

        // Handle leave_type
        String type = "Leave";
        if (item["leave_type"] != null) {
          type = item["leave_type"];
        } else if (item["reason"] != null) {
          type = item["reason"];
        }

        final statusRaw = item["status"]?.toString().toLowerCase() ?? "pending";

        String status = "Pending";
        Color statusColor = const Color(0xffF87000);
        Color statusBgColor = const Color(0xffFFF3E0);

        if (statusRaw == "1" ||
            statusRaw.contains("accept") ||
            statusRaw.contains("approv")) {
          status = "Approved";
          statusColor = const Color(0xff05D817);
          statusBgColor = const Color(0xffE8F5E8);
        } else if (statusRaw == "2" || statusRaw.contains("reject")) {
          status = "Rejected";
          statusColor = Colors.red;
          statusBgColor = const Color(0xffFFEBEE);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10), // Increased padding
                decoration: BoxDecoration(
                  color: Colors.grey.shade50, // Slight background
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/leavearrow.png', // Ensure this asset exists
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.description, color: Color(0xff26A69A)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type, // Main Title: Leave Type
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateRange, // Subtitle: Date Range
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ApplyLeaveButton extends StatelessWidget {
  const ApplyLeaveButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SizedBox(
        width: 280,
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LeaveApplication()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff26A69A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 6,
          ),
          child: Text(
            'Apply Leave / Permission',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class HolidayListCard extends StatelessWidget {
  const HolidayListCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xffF5ACAC),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.event_note_outlined,
                color: Color(0xff1B2C61),
                size: 26,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Holiday List',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff1B2C61),
                  ),
                ),
              ),
              const Icon(Icons.arrow_right, size: 35, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }
}
