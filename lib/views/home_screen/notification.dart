import 'package:flutter/material.dart';
import 'package:hrm/views/main_root.dart';
import '../../services/notification_service.dart';
import 'package:flutter/services.dart';
import '../../models/ticket_api.dart';
import '../../models/expense_api.dart';
import '../home/ticket_raise.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

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
  String? _fcmToken;

  List<Map<String, dynamic>> _ticketHistory = [];
  List<Map<String, dynamic>> _leaveHistory = [];
  List<Map<String, dynamic>> _permissionHistory = [];
  List<Map<String, dynamic>> _expenseHistory = [];
  List<Map<String, dynamic>> _taskHistory = [];
  Map<String, dynamic> _performanceSummary = {};

  bool _isLoading = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadFcmToken();
    _fetchAllHistory();
  }

  Future<void> _fetchAllHistory() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchTicketsData(),
        _fetchLeaveHistoryData(),
        _fetchPermissionHistoryData(),
        _fetchExpenseHistoryData(),
        _fetchPerformanceData(),
        _fetchTaskHistoryData(),
      ]);
    } catch (e) {
      debugPrint("Error in _fetchAllHistory: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchTicketsData() async {
    try {
      final fetchedTickets = await TicketApi.fetchTickets();
      if (mounted) {
        setState(() {
          _ticketHistory = fetchedTickets;
        });
      }
    } catch (e) {
      debugPrint("Error fetching tickets: $e");
    }
  }

  Future<void> _fetchLeaveHistoryData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String uid =
          prefs.getString('login_cus_id') ??
          prefs.getString('server_uid') ??
          prefs.getString('employee_table_id') ??
          prefs.getInt('uid')?.toString() ??
          "";
      final String cid = prefs.getString('cid') ?? "";
      final deviceId = prefs.getString('device_id') ?? "";
      final String lt = prefs.getDouble('lat')?.toString() ?? "0.0";
      final String ln = prefs.getDouble('lng')?.toString() ?? "0.0";

      final response = await http.post(
        Uri.parse("https://erpsmart.in/total/api/m_api/"),
        body: {
          "cid": cid,
          "type": "2052",
          "uid": uid,
          "id": uid,
          "device_id": deviceId,
          "lt": lt,
          "ln": ln,
        },
      );

      debugPrint("API Response (Leave History 2052): ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> fetchedList = [];
        if (data is List) {
          fetchedList = data;
        } else if (data is Map) {
          fetchedList = data['leave_applications'] ?? data['data'] ?? [];
        }
        if (mounted) {
          setState(() {
            _leaveHistory = fetchedList.cast<Map<String, dynamic>>();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching leave history: $e");
    }
  }

  Future<void> _fetchPermissionHistoryData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String uid =
          prefs.getString('login_cus_id') ??
          prefs.getString('server_uid') ??
          prefs.getString('employee_table_id') ??
          prefs.getInt('uid')?.toString() ??
          "";
      final String cid = prefs.getString('cid') ?? "";
      final String? token = prefs.getString('token');
      final deviceId = prefs.getString('device_id') ?? "";
      final String lt = prefs.getDouble('lat')?.toString() ?? "0.0";
      final String ln = prefs.getDouble('lng')?.toString() ?? "0.0";

      final body = {
        "cid": cid,
        "type": "2078",
        "uid": uid,
        "id": uid,
        "token": token ?? "",
        "device_id": deviceId,
        "lt": lt,
        "ln": ln,
      };

      final response = await http.post(
        Uri.parse("https://erpsmart.in/total/api/m_api/"),
        body: body,
      );

      debugPrint("API Response (Permission History 2078): ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> fetchedList = [];
        if (data is List) {
          fetchedList = data;
        } else if (data is Map) {
          fetchedList = data['data'] ?? data['permission_applications'] ?? [];
        }
        if (mounted) {
          setState(() {
            _permissionHistory = fetchedList.cast<Map<String, dynamic>>();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching permission history: $e");
    }
  }

  Future<void> _fetchExpenseHistoryData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String uid =
          prefs.getString('server_uid') ??
          prefs.getString('login_cus_id') ??
          prefs.getString('employee_table_id') ??
          prefs.getInt('uid')?.toString() ??
          "";
      final String cid = prefs.getString('cid') ?? "";
      final String deviceId = prefs.getString('device_id') ?? "";

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 2),
        );
      } catch (_) {}

      final String latValue = position?.latitude.toString() ?? "0.0";
      final String lngValue = position?.longitude.toString() ?? "0.0";

      final now = DateTime.now();

      // Fetch Current Month
      final responseCur = await ExpenseRepo.getExpenses(
        cid: cid,
        uid: uid,
        month: now.month.toString().padLeft(2, '0'),
        year: now.year.toString(),
        deviceId: deviceId,
        lat: latValue,
        lng: lngValue,
      );

      // Fetch Previous Month
      final lastMonth = DateTime(now.year, now.month - 1);
      final responsePrev = await ExpenseRepo.getExpenses(
        cid: cid,
        uid: uid,
        month: lastMonth.month.toString().padLeft(2, '0'),
        year: lastMonth.year.toString(),
        deviceId: deviceId,
        lat: latValue,
        lng: lngValue,
      );

      List<Map<String, dynamic>> combinedExpenses = [];

      void _parseExpenses(Map<String, dynamic> response) {
        if (response["success"] == true || response["error"] == false) {
          final data = response["data"];
          List<dynamic> list = [];
          if (data is Map) {
            list = data["expenses"] ?? data["expense_list"] ?? [];
          } else if (data is List) {
            list = data;
          }
          for (var item in list) {
            if (item is Map<String, dynamic>) {
              combinedExpenses.add(item);
            }
          }
        }
      }

      _parseExpenses(responseCur);
      _parseExpenses(responsePrev);

      if (mounted) {
        setState(() {
          _expenseHistory = combinedExpenses;
        });
      }
    } catch (e) {
      debugPrint("Error fetching expense history: $e");
    }
  }

  Future<void> _fetchPerformanceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cid = prefs.getString('cid') ?? "";
      final String uid =
          prefs.getString('login_cus_id') ??
          prefs.getString('server_uid') ??
          prefs.getString('employee_table_id') ??
          prefs.getInt('uid')?.toString() ??
          "";
      final String deviceId = prefs.getString('device_id') ?? "";
      final String? token = prefs.getString('token');

      DateTime now = DateTime.now();
      String fromDate = DateFormat('yyyy-MM-01').format(now);
      String toDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime(now.year, now.month + 1, 0));

      final response = await http.post(
        Uri.parse("https://erpsmart.in/total/api/m_api/"),
        body: {
          "type": "2075",
          "cid": cid,
          "uid": uid,
          "device_id": deviceId,
          "token": token ?? "",
          "from_date": fromDate,
          "to_date": toDate,
        },
      );

      debugPrint("API Response (Performance Summary): ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['error'] == false) {
          final summary = decoded['summary'];
          final dataMap = decoded['data'];
          
          List<Map<String, dynamic>> tasksFromPerf = [];
          if (dataMap is Map) {
            final completed = dataMap['completed'] as List? ?? [];
            final partial = dataMap['partial'] as List? ?? [];
            final pending = dataMap['pending'] as List? ?? [];
            for (var t in [...completed, ...partial, ...pending]) {
              if (t is Map<String, dynamic>) tasksFromPerf.add(t);
            }
          }

          if (mounted) {
            setState(() {
              if (summary != null) _performanceSummary = summary;
              // Add unique tasks to task history
              for (var newTask in tasksFromPerf) {
                bool exists = _taskHistory.any((old) => 
                  (old['task_id']?.toString() == newTask['task_id']?.toString()) ||
                  (old['id']?.toString() == newTask['task_id']?.toString())
                );
                if (!exists) {
                  _taskHistory.add(newTask);
                }
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching performance summary and tasks: $e");
    }
  }

  Future<void> _fetchTaskHistoryData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cid = prefs.getString('cid') ?? "";
      final String uid =
          prefs.getString('server_uid') ??
          prefs.getString('login_cus_id') ??
          prefs.getString('employee_table_id') ??
          prefs.getInt('uid')?.toString() ??
          "";
      final String deviceId = prefs.getString('device_id') ?? "";
      final String lat = prefs.getDouble('lat')?.toString() ?? "0.0";
      final String lng = prefs.getDouble('lng')?.toString() ?? "0.0";

      final body = {
        "type": "2073",
        "cid": cid,
        "uid": uid,
        "id": uid,
        "device_id": deviceId,
        "lt": lat,
        "ln": lng,
      };

      final response = await http.post(
        Uri.parse("https://erpsmart.in/total/api/m_api/"),
        body: body,
      );

      debugPrint("API Response (Task History 2073): ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> fetchedList = [];
        if (data is List) {
          fetchedList = data;
        } else if (data is Map) {
          if (data["error"] == false || data["success"] == true) {
            fetchedList = data["data"] ?? data["tasks"] ?? [];
          }
        }
        if (mounted) {
          setState(() {
            _taskHistory = fetchedList.cast<Map<String, dynamic>>();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching task history: $e");
    }
  }

  Future<void> _loadFcmToken() async {
    final token = await NotificationService.getFCMToken();
    if (mounted) {
      setState(() {
        _fcmToken = token;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double horizontalPadding = size.width * 0.05;

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
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                          });
                        }
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
                          vertical: 0,
                        ),
                        minimumSize: const Size(0, 32),
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
                      _buildFilterChip(
                        "Leave",
                        count: _leaveHistory.length + _permissionHistory.length,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        "Performance",
                        count: _taskHistory.length,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        "Expenses",
                        count: _expenseHistory.length,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        "Feedback",
                        count: _ticketHistory.length,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip("Payroll"),
                      const SizedBox(width: 8),
                      _buildFilterChip("System"),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // FCM Token Section
                if (_fcmToken != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Your FCM Token:",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.copy,
                                size: 16,
                                color: Colors.teal,
                              ),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: _fcmToken!),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("FCM Token copied"),
                                  ),
                                );
                              },
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _fcmToken!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                if (selectedFilter == "Feedback") ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TicketRaise(),
                          ),
                        ).then((_) => _fetchTicketsData());
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text("Raise New Ticket"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF26A69A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          /// Notification/Ticket List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF26A69A)),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchAllHistory,
                    child: ListView(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      children: _buildHistoryList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHistoryList() {
    List<Widget> items = [];
    final filterDateStr = _selectedDate != null
        ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
        : null;

    // Helper to check if a record matches the selected date
    bool _matchesDate(dynamic record, List<String> dateKeys) {
      if (filterDateStr == null) return true;
      for (var key in dateKeys) {
        final val = record[key]?.toString();
        if (val != null && val.contains(filterDateStr)) return true;
      }
      return false;
    }

    if (selectedFilter == "All") {
      // Create a unified list for sorting
      List<Map<String, dynamic>> allRecords = [];

      allRecords.addAll(
        _leaveHistory
            .where((l) => _matchesDate(l, ["from_date", "date", "created_at"]))
            .map(
              (l) => {...l, "uiType": "leave", "uiDate": l["from_date"] ?? ""},
            ),
      );

      allRecords.addAll(
        _permissionHistory
            .where((p) => _matchesDate(p, ["from_date", "date"]))
            .map(
              (p) => {
                ...p,
                "uiType": "permission",
                "uiDate": p["from_date"] ?? "",
              },
            ),
      );

      allRecords.addAll(
        _taskHistory
            .where((t) => _matchesDate(t, ["due_date", "created_at"]))
            .map(
              (t) => {...t, "uiType": "task", "uiDate": t["due_date"] ?? ""},
            ),
      );

      allRecords.addAll(
        _expenseHistory
            .where((e) => _matchesDate(e, ["expense_date", "date"]))
            .map(
              (e) => {
                ...e,
                "uiType": "expense",
                "uiDate": e["expense_date"] ?? e["date"] ?? "",
              },
            ),
      );

      allRecords.addAll(
        _ticketHistory
            .where((t) => _matchesDate(t, ["date", "created_at"]))
            .map((t) => {...t, "uiType": "ticket", "uiDate": t["date"] ?? ""}),
      );

      // Sort by date descending
      allRecords.sort(
        (a, b) => (b["uiDate"] ?? "").compareTo(a["uiDate"] ?? ""),
      );

      for (var rec in allRecords) {
        switch (rec["uiType"]) {
          case "leave":
            items.add(_buildLeaveRow(rec));
            break;
          case "permission":
            items.add(_buildPermissionRow(rec));
            break;
          case "task":
            items.add(_buildTaskRowForPerformance(rec));
            break;
          case "expense":
            items.add(_buildExpenseRow(rec));
            break;
          case "ticket":
            items.add(_buildTicketRow(rec));
            break;
        }
      }
    } else if (selectedFilter == "Leave") {
      final filteredLeaves = _leaveHistory
          .where((l) => _matchesDate(l, ["from_date", "date"]))
          .toList();
      final filteredPerms = _permissionHistory
          .where((p) => _matchesDate(p, ["from_date", "date"]))
          .toList();

      if (filteredLeaves.isNotEmpty) {
        items.add(_buildSectionHeader("Leave History"));
        items.addAll(filteredLeaves.map((l) => _buildLeaveRow(l)));
      }
      if (filteredPerms.isNotEmpty) {
        items.add(_buildSectionHeader("Permission History"));
        items.addAll(filteredPerms.map((p) => _buildPermissionRow(p)));
      }
    } else if (selectedFilter == "Performance") {
      if (_performanceSummary.isNotEmpty && filterDateStr == null) {
        items.add(_buildSectionHeader("Performance Summary"));
        items.add(_buildPerformanceCard(_performanceSummary));
      }
      final filteredTasks = _taskHistory
          .where((t) => _matchesDate(t, ["due_date", "created_at"]))
          .toList();
      if (filteredTasks.isNotEmpty) {
        items.add(_buildSectionHeader("Task History"));
        items.addAll(filteredTasks.map((t) => _buildTaskRowForPerformance(t)));
      }
    } else if (selectedFilter == "Expenses") {
      final filteredExpenses = _expenseHistory
          .where((e) => _matchesDate(e, ["expense_date", "date"]))
          .toList();
      if (filteredExpenses.isNotEmpty) {
        items.add(_buildSectionHeader("Expense History"));
        items.addAll(filteredExpenses.map((e) => _buildExpenseRow(e)));
      }
    } else if (selectedFilter == "Feedback") {
      final filteredTickets = _ticketHistory
          .where((t) => _matchesDate(t, ["date", "created_at"]))
          .toList();
      if (filteredTickets.isNotEmpty) {
        items.add(_buildSectionHeader("Ticket History"));
        items.addAll(filteredTickets.map((t) => _buildTicketRow(t)));
      }
    }

    if (items.isEmpty) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.only(top: 100),
            child: Text(
              "No records found",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ];
    }

    return items;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1B2C61),
        ),
      ),
    );
  }

  Widget _buildLeaveRow(Map<String, dynamic> leave) {
    String statusRaw =
        (leave["status"] ??
                leave["verify_status"] ??
                leave["approval_status"] ??
                leave["leave_status"] ??
                "")
            .toString()
            .toLowerCase();
    String statusText = "Pending";
    Color statusColor = Colors.orange;

    if (statusRaw == "1" ||
        statusRaw == "approved" ||
        statusRaw == "accept" ||
        statusRaw.contains("approv")) {
      statusText = "Approved";
      statusColor = Colors.green;
    } else if (statusRaw == "2" ||
        statusRaw == "rejected" ||
        statusRaw == "reject") {
      statusText = "Rejected";
      statusColor = Colors.red;
    }

    return _buildHistoryCard(
      icon: Icons.calendar_today,
      iconColor: Colors.blue,
      title: "${leave["leave_type"] ?? "Leave Application"}",
      subtitle: "Duration: ${leave["from_date"]} to ${leave["to_date"]}",
      statusText: statusText,
      statusColor: statusColor,
    );
  }

  Widget _buildPermissionRow(Map<String, dynamic> perm) {
    String statusRaw =
        (perm["status"] ??
                perm["verify_status"] ??
                perm["approval_status"] ??
                "")
            .toString()
            .toLowerCase();
    String statusText = "Pending";
    Color statusColor = Colors.orange;

    if (statusRaw == "1" ||
        statusRaw == "approved" ||
        statusRaw == "accept" ||
        statusRaw.contains("approv")) {
      statusText = "Approved";
      statusColor = Colors.green;
    } else if (statusRaw == "2" ||
        statusRaw == "rejected" ||
        statusRaw.contains("reject")) {
      statusText = "Rejected";
      statusColor = Colors.red;
    }

    return _buildHistoryCard(
      icon: Icons.timer,
      iconColor: Colors.orange,
      title: "Permission: ${perm["permission_type"] ?? "N/A"}",
      subtitle:
          "Date: ${perm["from_date"]} (${perm["from_time"]} - ${perm["to_time"]})",
      statusText: statusText,
      statusColor: statusColor,
    );
  }

  Widget _buildExpenseRow(Map<String, dynamic> expense) {
    String statusRaw =
        (expense["status"] ??
                expense["verify_status"] ??
                expense["approval_status"] ??
                expense["expense_status"] ??
                "")
            .toString()
            .toLowerCase();
    String statusText = "Pending";
    Color statusColor = Colors.orange;

    if (statusRaw == "1" ||
        statusRaw == "approved" ||
        statusRaw == "accept" ||
        statusRaw.contains("approv")) {
      statusText = "Approved";
      statusColor = Colors.green;
    } else if (statusRaw == "2" ||
        statusRaw == "rejected" ||
        statusRaw == "reject") {
      statusText = "Rejected";
      statusColor = Colors.red;
    }

    String claim = expense["amount"]?.toString() ?? "0";
    String approved =
        expense["approved_amt"] ?? expense["approved_amount"] ?? "0";

    return _buildHistoryCard(
      icon: Icons.receipt_long,
      iconColor: Colors.red,
      title:
          "${expense["expense_category"] ?? expense["purpose"] ?? "Expense"}",
      subtitle:
          "Claimed: \u20B9$claim - Approved: \u20B9$approved\nDate: ${expense["expense_date"]}",
      statusText: statusText,
      statusColor: statusColor,
    );
  }

  Widget _buildPerformanceCard(Map<String, dynamic> summary) {
    int total = summary["total"] ?? 0;
    int completed = summary["completed"] ?? 0;
    double percentage = total == 0 ? 0.0 : completed / total;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                "Monthly Performance",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation(Colors.green),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Tasks: $completed/$total Completed",
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Text(
                "${(percentage * 100).toStringAsFixed(0)}%",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTicketRow(Map<String, dynamic> ticket) {
    String status = (ticket["status"] ?? "Pending").toString();
    Color statusColor = status.toLowerCase() == "pending"
        ? Colors.orange
        : Colors.green;

    return _buildHistoryCard(
      icon: Icons.support_agent,
      iconColor: Colors.teal,
      title: "${ticket["subject"] ?? ticket["title"] ?? "Ticket"}",
      subtitle:
          "Dept: ${ticket["department"] ?? "-"} - Date: ${ticket["date"]}",
      statusText: status,
      statusColor: statusColor,
    );
  }

  Widget _buildTaskRowForPerformance(Map<String, dynamic> task) {
    String status = (task["status"] ?? "pending").toString().toLowerCase();
    String approvalStatus = (task["approval_status"] ?? "pending")
        .toString()
        .toLowerCase();

    Color statusColor =
        (status == "done" || status == "completed" || status == "1")
        ? Colors.green
        : (status == "partial" || status == "2" ? Colors.orange : Colors.blue);

    return _buildHistoryCard(
      icon: Icons.assignment_turned_in,
      iconColor: Colors.indigo,
      title: "${task["task_name"] ?? task["title"] ?? "Task"}",
      subtitle:
          "Due: ${task["due_date"] ?? ""} Priority: ${task["priority"] ?? "Normal"}\nApproval: $approvalStatus",
      statusText: status.toUpperCase(),
      statusColor: statusColor,
    );
  }

  Widget _buildHistoryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String statusText,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
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

  Widget _buildFilterChip(String label, {int? count}) {
    final bool isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = label),
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
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.teal : Colors.teal.shade900,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NotificationItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String time;
  final String category;

  const NotificationItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.time,
    required this.category,
  });
}
