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
  int? _selectedMonth; // Null means All/Annual

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
    if (!mounted) return;
    setState(() => isBalanceLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getInt('uid') ?? 1;
      final lat = prefs.getDouble('lat')?.toString() ?? "145";
      final lng = prefs.getDouble('lng')?.toString() ?? "145";

      final response = await http
          .post(
            Uri.parse("https://erpsmart.in/total/api/m_api/"),
            body: {
              "cid": prefs.getString('cid') ?? "",
              "device_id": prefs.getString('device_id') ?? "",
              "lt": lat,
              "ln": lng,
              "type": "2051",
              "uid": uid.toString(),
              "id": uid.toString(),
            },
          )
          .timeout(const Duration(seconds: 20));

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

          if (!mounted) return;
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

      // Also fetch history immediately so it's ready
      await _fetchLeaveHistory();
    } catch (e) {
      debugPrint("Error fetching leave summary: $e");
    } finally {
      if (mounted) setState(() => isBalanceLoading = false);
    }
  }

  Future<void> _fetchLeaveHistory() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getInt('uid') ?? 1;
      final empCode = prefs.getString('employee_code') ?? ""; // GET CODE
      final lat = prefs.getDouble('lat')?.toString() ?? "145";
      final lng = prefs.getDouble('lng')?.toString() ?? "145";

      final response = await http
          .post(
            Uri.parse("https://erpsmart.in/total/api/m_api/"),
            body: {
              "cid": prefs.getString('cid') ?? "",
              "device_id": prefs.getString('device_id') ?? "",
              "lt": lat,
              "ln": lng,
              "type": "2052",
              "uid": uid.toString(),
              "id": uid.toString(),
            },
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> fetchedList = [];

        if (data is List) {
          fetchedList = data;
        } else {
          // 1. Try to get History List from Map
          if (data['leave_applications'] != null &&
              data['leave_applications'] is List) {
            fetchedList = data['leave_applications'];
          } else if (data["data"] != null && data["data"] is List) {
            fetchedList = data["data"];
          } else if (data['error'] == false && data['data'] != null) {
            // Fallback if data is in 'data' but maybe not directly a list?
            // Or if we need to support old structure
            if (data['data'] is List) fetchedList = data['data'];
          }

          // 2. Try to get Leave Summary (for the cards)
          if (data['leave_summary'] != null && data['leave_summary'] is List) {
            final summaryList = data['leave_summary'];
            // Update local balance data
            for (var staticItem in leaveBalanceData) {
              String staticType = staticItem['type'].toString().toLowerCase();
              dynamic apiItem = summaryList.firstWhere((api) {
                String apiType =
                    (api['leave_type_name'] ??
                            api['leave_type'] ??
                            api['type'] ??
                            "")
                        .toString()
                        .toLowerCase();
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
                      apiItem['leaves_taken_this_year']?.toString() ?? "0",
                    ) ??
                    0;
                int total =
                    int.tryParse(
                      apiItem['max_days_per_year']?.toString() ?? "12",
                    ) ??
                    12;
                staticItem['taken'] = taken;
                staticItem['total'] = total;
                staticItem['balance'] = "${total - taken}/$total";
              }
            }
          }
        }
        // FILTER BY EMPLOYEE CODE
        if (empCode.isNotEmpty) {
          fetchedList = fetchedList.where((item) {
            final itemCode = item['employee_uid']?.toString() ?? "";
            return itemCode == empCode;
          }).toList();
        }

        historyData = fetchedList;
        _calculateBalances();
      }
    } catch (e) {
      debugPrint("Error fetching leave history: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _calculateBalances_Old() {
    for (var b in leaveBalanceData) {
      b['taken'] = 0;
    }
    for (var h in historyData) {
      // âœ… Only count APPROVED leaves in balance/taken
      String status = (h['status'] ?? "0").toString().toLowerCase();
      bool isApproved =
          status == "1" ||
          status.contains("approv") ||
          status.contains("accept");
      if (!isApproved) continue;

      // --- Date Filter Logic ---
      if (_selectedMonth != null) {
        try {
          // Parse date. Format usually YYYY-MM-DD
          String dateStr =
              (h['leave_start_date'] ?? h['date'] ?? h['f_date'] ?? "")
                  .toString();
          if (dateStr.isEmpty) continue;

          DateTime? date = DateTime.tryParse(dateStr);
          if (date != null) {
            if (date.month != _selectedMonth) continue;
          }
        } catch (e) {
          continue;
        }
      }

      // Get Days
      num days = 0;
      if (h['no_of_days'] != null) {
        days = num.tryParse(h['no_of_days'].toString()) ?? 0;
      } else if (h['total_days'] != null) {
        days = num.tryParse(h['total_days'].toString()) ?? 0;
      } else if (h['days'] != null) {
        days = num.tryParse(h['days'].toString()) ?? 0;
      } else {
        days = 1;
      }

      // Get Type
      String type = (h['leave_type'] ?? h['reason'] ?? "")
          .toString()
          .toLowerCase();

      // Match and Add
      for (var b in leaveBalanceData) {
        String bType = b['type'].toString().toLowerCase();
        bool match = false;

        if (bType == "earned") {
          match = type.contains("privilege") || type.contains("earned");
        } else if (bType == "casual") {
          match = type.contains("casual");
        } else if (bType == "sick") {
          match = type.contains("medical") || type.contains("sick");
        } else {
          match = type.contains(bType);
        }

        if (match) {
          b['taken'] = (b['taken'] as num) + days;
          break;
        }
      }
    }

    // 3. Update Balance Strings
    for (var b in leaveBalanceData) {
      num taken = b['taken'];
      String bType = b['type'].toString().toLowerCase();
      if (bType == "unpaid") {
        b['balance'] = "$taken/-";
      } else {
        num total = b['total'] ?? 12; // Default if null
        b['balance'] = "${total - taken}/$total";
      }
    }

    setState(() {});
  }

  void _calculateBalances() {
    // 1. Reset 'taken' count locally (keep 'total' from API/Static)
    for (var b in leaveBalanceData) {
      b['taken'] = 0;
    }

    // Map of Month -> List of Leaves
    Map<int, List<Map<String, dynamic>>> monthlyLeaves = {};

    for (var h in historyData) {
      String status = (h['status'] ?? "0").toString().toLowerCase();

      // âœ… Strictly only count "accept" or "approved" leaves in balance cards
      bool isApproved =
          status == "1" || status == "accept" || status.contains("approv");
      if (!isApproved) continue;

      DateTime? date;
      try {
        String dateStr =
            (h['leave_start_date'] ?? h['date'] ?? h['f_date'] ?? "")
                .toString();
        if (dateStr.isNotEmpty) date = DateTime.tryParse(dateStr);
      } catch (e) {
        /* ignore */
      }

      if (date == null) continue;

      // âœ… Only count leaves for the current year in the annual summary
      int currentYear = DateTime.now().year;
      if (date.year != currentYear) continue;

      if (_selectedMonth != null && date.month != _selectedMonth) continue;

      num days = 0;
      if (h['no_of_days'] != null) {
        days = num.tryParse(h['no_of_days'].toString()) ?? 0;
      } else if (h['total_days'] != null) {
        days = num.tryParse(h['total_days'].toString()) ?? 0;
      } else if (h['days'] != null) {
        days = num.tryParse(h['days'].toString()) ?? 0;
      } else {
        days = 1;
      }

      String type = (h['leave_type'] ?? h['reason'] ?? "")
          .toString()
          .toLowerCase();

      if (!monthlyLeaves.containsKey(date.month)) {
        monthlyLeaves[date.month] = [];
      }
      monthlyLeaves[date.month]!.add({'type': type, 'days': days});
    }

    // Apply Rules Per Month
    monthlyLeaves.forEach((month, leaves) {
      num monthlyTotalPaid = 0;
      num monthlyUnpaidDirect = 0;
      List<Map<String, dynamic>> paidLeavesList = [];

      for (var leave in leaves) {
        String type = leave['type'];
        num days = leave['days'];

        if (type.contains("unpaid") ||
            type.contains("loss") ||
            type.contains("lop") ||
            type.contains("without pay")) {
          monthlyUnpaidDirect += days;
        } else {
          monthlyTotalPaid += days;
          paidLeavesList.add(leave);
        }
      }

      num allowed = 2; // Limit per user requirement
      num excess = 0;
      if (monthlyTotalPaid > allowed) {
        excess = monthlyTotalPaid - allowed;
      }

      _addToBalance("unpaid", monthlyUnpaidDirect + excess);

      num remainingQuota = allowed;
      for (var leave in paidLeavesList) {
        String type = leave['type'];
        num days = leave['days'];
        num daysToAttribute = 0;

        if (remainingQuota > 0) {
          if (remainingQuota >= days) {
            daysToAttribute = days;
            remainingQuota -= days;
          } else {
            daysToAttribute = remainingQuota;
            remainingQuota = 0;
          }
        }

        if (daysToAttribute > 0) _addToBalance(type, daysToAttribute);
      }
    });

    // 3. Update Balance Strings
    for (var b in leaveBalanceData) {
      num taken = b['taken'];
      String bType = b['type'].toString().toLowerCase();
      if (bType == "unpaid") {
        b['balance'] = "$taken/-";
      } else {
        num total = b['total'] ?? 12; // Default if null
        b['balance'] = "${total - taken}/$total";
      }
    }

    if (!mounted) return;
    setState(() {});
  }

  void _addToBalance(String apiType, num days) {
    for (var b in leaveBalanceData) {
      String bType = b['type'].toString().toLowerCase();
      bool match = false;
      if (bType == "earned") {
        match =
            apiType.contains("privilege") ||
            apiType.contains("earned") ||
            apiType.contains(" el") ||
            apiType.contains("annual") ||
            apiType.contains(" al");
      } else if (bType == "casual") {
        match = apiType.contains("casual") || apiType.contains(" cl");
      } else if (bType == "sick") {
        match =
            apiType.contains("medical") ||
            apiType.contains("sick") ||
            apiType.contains(" ml");
      } else if (bType == "unpaid") {
        match = apiType.contains("unpaid") || apiType.contains("lop");
      } else {
        match = apiType.contains(bType);
      }

      if (match) {
        b['taken'] = (b['taken'] as num) + days;
        break; // Add to first matching category
      }
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
      body: Column(
        children: [
          const SizedBox(height: 12),

          // FIXED TABS
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
                        if (historyData.isEmpty || true) {
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

          const SizedBox(height: 10),

          // SCROLLABLE BODY
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  selectedTab == 0
                      ? isBalanceLoading
                            ? const Center(child: CircularProgressIndicator())
                            : Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 16,
                                      right: 16,
                                      bottom: 10,
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: PopupMenuButton<int>(
                                        offset: const Offset(0, 40),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        onSelected: (int? value) {
                                          setState(() {
                                            _selectedMonth = value;
                                          });
                                          _calculateBalances();
                                        },
                                        itemBuilder: (context) {
                                          const months = [
                                            "January",
                                            "February",
                                            "March",
                                            "April",
                                            "May",
                                            "June",
                                            "July",
                                            "August",
                                            "September",
                                            "October",
                                            "November",
                                            "December",
                                          ];
                                          return [
                                            const PopupMenuItem(
                                              value: null,
                                              child: Text("All Months"),
                                            ),
                                            ...List.generate(12, (index) {
                                              return PopupMenuItem(
                                                value: index + 1,
                                                child: Text(months[index]),
                                              );
                                            }),
                                          ];
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xff26A69A),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.sort,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                _selectedMonth == null
                                                    ? "Sort by"
                                                    : [
                                                        "Jan",
                                                        "Feb",
                                                        "Mar",
                                                        "Apr",
                                                        "May",
                                                        "Jun",
                                                        "Jul",
                                                        "Aug",
                                                        "Sep",
                                                        "Oct",
                                                        "Nov",
                                                        "Dec",
                                                      ][_selectedMonth! - 1],
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  LeaveBalanceGrid(leaveData: leaveBalanceData),
                                  const SizedBox(height: 24),
                                  const HolidayListCard(),
                                  const SizedBox(height: 24),
                                ],
                              )
                      : isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            LeaveHistoryList(history: historyData),
                            const SizedBox(height: 20),
                          ],
                        ),
                ],
              ),
            ),
          ),

          // FIXED BOTTOM BUTTON
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: ApplyLeaveButton(),
          ),
        ],
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
                    color: Colors.grey.withValues(alpha: 0.15),
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
            statusRaw == "accept" ||
            statusRaw.contains("approv")) {
          status = "Approved";
          statusColor = const Color(0xff05D817);
          statusBgColor = const Color(0xffE8F5E8);
        } else if (statusRaw == "2" ||
            statusRaw == "reject" ||
            statusRaw.contains("reject")) {
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
                color: Colors.grey.withValues(alpha: 0.1),
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
