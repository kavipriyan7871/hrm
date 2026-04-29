import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrm/views/home/settings.dart';
import 'dart:async';

import 'package:hrm/views/home_screen/performance.dart';
import 'package:hrm/views/home_screen/reports.dart';
import 'package:hrm/views/marketing/marketing_selection.dart';
import 'leave_management.dart';
import 'package:hrm_admin_app/Screens/Admin/admin_dashboard.dart' as admin;
import 'package:hrm_admin_app/Screens/Admin/admin_approvals_screen.dart';
import 'package:hrm_admin_app/Models/leave_api.dart' as admin_api;
import 'package:hrm_admin_app/Models/employee_api.dart' as admin_emp_api;
import 'package:hrm_admin_app/Utils/shared_prefs_util.dart' as admin_prefs;
import 'tasks_list.dart';
import 'notification.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../attendance_history/attendance.dart';
import 'annocement_screen.dart';
import 'permission_form.dart';
import '../home/payroll.dart';
import '../../services/api_client.dart';
import 'package:erp_smart/utils/widgets/dynamic_drawer.dart';
import 'package:erp_smart/utils/widgets/language_selector.dart';

class Dashboard extends StatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onHomePressed;
  const Dashboard({super.key, this.isEmbedded = false, this.onHomePressed});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String userName = "User";
  String userRole = "";
  String roleId = "1";
  final ApiClient _apiClient = ApiClient();
  double _monthlyRate = 0;
  bool isCheckedInByServer = false;
  bool isCheckedInByLocal = false;
  bool isTodayFinished = false;
  bool hasDoneMarketingToday = false;
  bool marketingAttendanceMode = false;
  bool isOnBreak = false;
  String breakPurpose = "";
  Duration breakDuration = Duration.zero;
  Timer? _breakTimer;
  bool isStatusFetching = true;

  bool get isCheckedIn => isCheckedInByServer || isCheckedInByLocal;

  List<dynamic> leaveHistory = [];
  bool isLeaveHistoryLoading = false;

  // Monthly Summary Stats
  int totalPresentDays = 0;
  double leavesTakenThisMonth = 0;
  int totalMonthDays = 0;
  double totalLeaveBalance = 0;
  int _pendingLeaveCount = 0;
  bool _isCountLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _breakTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final prefs = await SharedPreferences.getInstance();
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (mounted) {
      setState(() {
        userName = prefs.getString('name') ?? "User";
        userRole = prefs.getString('role_name') ?? "";
        roleId = prefs.getString('role_id') ?? prefs.getInt('role_id')?.toString() ?? "1";

        // ✅ LOAD LOCAL PERSISTENCE FIRST (FASTER UI)
        isCheckedInByLocal = prefs.getBool('isCheckedIn') ?? false;
        isOnBreak = prefs.getBool('is_on_break') ?? false;

        final String lastCheckIn = prefs.getString('last_checkin_date') ?? "";
        final String lastCheckOut = prefs.getString('last_checkout_date') ?? "";

        // ✅ VALIDATE LOCAL STATE AGAINST TODAY'S DATE
        if (lastCheckIn != today && lastCheckOut != today) {
          // New day, reset local persistence
          isCheckedInByLocal = false;
          _clearAttendancePrefs(prefs);
        } else if (lastCheckOut == today) {
          isTodayFinished = true;
          isCheckedInByLocal = false;
        }

        marketingAttendanceMode =
            prefs.getBool('marketing_attendance_mode') ?? false;
        hasDoneMarketingToday =
            prefs.getBool('has_done_marketing_today') ?? false;

        // ✅ CHECK-IN AND BREAK PERSISTENCE FROM LOCAL PREFS
        final bool isCheckInStored = prefs.getBool('isCheckedIn') ?? false;
        bool isBreakStored = prefs.getBool('is_on_break') ?? false;

        if (isCheckInStored) {
          isCheckedInByLocal = true;
        }

        // ✅ RELAXED SYNC: Always try to restore break if it's in local memory
        if (isBreakStored) {
          isOnBreak = true;
          breakPurpose = prefs.getString('break_purpose') ?? "Break";
          String? startTimeStr = prefs.getString('break_start_time');
          if (startTimeStr != null) {
            try {
              DateTime startTime = DateTime.parse(startTimeStr);
              breakDuration = DateTime.now().difference(startTime);
              _startBreakTimer(startTime);
            } catch (e) {
              isOnBreak = false;
              prefs.setBool('is_on_break', false);
            }
          }
        } else {
          isOnBreak = false;
          _breakTimer?.cancel();
        }
      });
    }

    await _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final prefs = await SharedPreferences.getInstance();

    // ⚡ INSTANT UI: Load from local cache first so the user doesn't wait
    if (mounted) {
      setState(() {
        isCheckedInByLocal = prefs.getBool('isCheckedIn') ?? false;
        // Optional: you can also set other local cached values here
      });
    }

    setState(() => isStatusFetching = true);

    // 🚀 ASYNC INDEPENDENT LOADING: Don't wait for everything to show status
    _backgroundProfileFetch(prefs);
    _fetchLeaveSummary(prefs);
    _fetchLeaveHistory();
    _fetchMonthlyPerformance(prefs);
    _fetchCheckInStatus(prefs);
    _fetchAttendanceStatus2092(prefs);
    _fetchAdminLeaveCount();

    // Mark as not fetching after critical ones or a short timeout
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => isStatusFetching = false);
    });

    // Calculate total days in current month
    DateTime now = DateTime.now();
    setState(() {
      totalMonthDays = DateTime(now.year, now.month + 1, 0).day;
    });
  }

  Future<void> _fetchAdminLeaveCount() async {
    // if (userRole.toLowerCase() != 'admin' && userRole.toLowerCase() != 'super admin') return;
    if (!mounted) return;
    setState(() => _isCountLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String uid = prefs.getString('login_cus_id') ?? 
                         prefs.getString('uid') ?? "";
      
      String? reportingManager;
      try {
        final empResponse = await admin_emp_api.EmployeeApi.fetchEmployeeDetails(uid: uid);
        if (empResponse.data.isNotEmpty) {
          reportingManager = empResponse.data.first.reportingManager;
        }
      } catch (e) {
        debugPrint("Dashboard Error fetching reporting manager for count: $e");
      }

      final response = await admin_api.LeaveApi.fetchLeaveRequests(reportingManager: reportingManager);
      if (mounted) {
        setState(() {
          _pendingLeaveCount = response.data.where((doc) {
            final s = doc.status?.toLowerCase() ?? "";
            return s == "pending" || s == "";
          }).length;
          _isCountLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Dashboard Error fetching admin leave count: $e");
      if (mounted) setState(() => _isCountLoading = false);
    }
  }

  Future<void> _fetchAttendanceStatus2092(SharedPreferences prefs) async {
    try {
      final String cid = prefs.getString('cid') ?? prefs.getString('cid_str') ?? "44555666";
      final String uid = prefs.getString('login_cus_id') ?? prefs.get('uid')?.toString() ?? "145";
      final String lat = prefs.getString('lt') ?? prefs.getDouble('lat')?.toString() ?? "123";
      final String lng = prefs.getString('ln') ?? prefs.getDouble('lng')?.toString() ?? "123";
      final String dId = prefs.getString('device_id') ?? "abc123";
      final String token = prefs.getString('token') ?? "";

      final response = await _apiClient.post({
          "type": "2092",
          "cid": cid,
          "uid": uid,
          "lt": lat,
          "ln": lng,
          "device_id": dId,
          "token": token,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["error"] == false || data["error"] == "false") {
          final bool isServerCheck = data['is_checkedin'] == true;
          final String statusStr = data['status']?.toString().toLowerCase() ?? "";
          
          if (mounted) {
            setState(() {
              if (isServerCheck || statusStr.contains("check in") || statusStr == "checked_in") {
                 isCheckedInByServer = true;
                 isCheckedInByLocal = true;
              } else {
                 isCheckedInByServer = false;
                 isCheckedInByLocal = false;
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching 2092 status: $e");
    }
  }

  Future<void> _clearAttendancePrefs(SharedPreferences prefs) async {
    await prefs.setBool('isCheckedIn', false);
    await prefs.setBool('is_on_break', false);
    await prefs.remove('break_start_time');
    await prefs.setBool('marketing_attendance_mode', false);
    await prefs.setBool('has_done_marketing_today', false);
  }

  Future<void> _backgroundProfileFetch(SharedPreferences prefs) async {
    try {
      final String sessionUid =
          prefs.getString('login_cus_id') ??
          prefs.getString('uid') ??
          prefs.getString('employee_table_id') ??
          prefs.get('uid')?.toString() ??
          "";

      final String cid =
          prefs.getString('cid') ?? prefs.getString('cid_str') ?? "";
      final String lat = prefs.getString('lt') ?? prefs.getDouble('lat')?.toString() ?? "";
      final String lng = prefs.getString('ln') ?? prefs.getDouble('lng')?.toString() ?? "";
      final String deviceId = prefs.getString('device_id') ?? "";

      final body = {
        "type": "2048",
        "cid": cid,
        "uid": sessionUid,
        "id": sessionUid,
        "device_id": deviceId,
        "lt": lat,
        "ln": lng,
        if (prefs.getString('token') != null) "token": prefs.getString('token'),
      };

      final response = await _apiClient.post(body);

      debugPrint("Employee Details API Response (2048) => ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final profileData = data["data"] ?? {};
        if (data["error"] == false || data["error"] == "false") {
          if (mounted) {
            setState(() {
              userName =
                  profileData["name"]?.toString() ??
                  prefs.getString('name') ??
                  "User";
            });
          }
          await prefs.setString('name', userName);
          await prefs.setString(
            'employee_code',
            profileData["employee_code"]?.toString() ?? "",
          );
          await prefs.setString(
            'profile_photo',
            profileData["profile_photo"]?.toString() ?? "",
          );
        }
      }
    } catch (e) {
      debugPrint("Dashboard Background Profile Error => $e");
    }
  }

  List<Map<String, dynamic>> leaveBalanceData = [
    {"type": "Casual", "taken": 0, "total": 12, "balance": "12/12"},
    {"type": "Sick", "taken": 0, "total": 12, "balance": "12/12"},
    {"type": "Earned", "taken": 0, "total": 12, "balance": "12/12"},
    {"type": "Unpaid", "taken": 0, "total": null, "balance": "0/-"},
  ];

  Future<void> _fetchLeaveSummary(SharedPreferences prefs) async {
    try {
      final String uid =
          prefs.getString('login_cus_id') ?? prefs.get('uid')?.toString() ?? "";
      final lat = prefs.getString('lt') ?? prefs.getDouble('lat')?.toString() ?? "";
      final lng = prefs.getString('ln') ?? prefs.getDouble('lng')?.toString() ?? "";

      final response = await _apiClient.post({
          "type": "2051",
          "uid": uid,
          "id": uid,
          "token": prefs.getString('token') ?? "",
      });

      if (response.statusCode == 200) {
        debugPrint("API Response (Leave Summary Dashboard): ${response.body}");
        final data = jsonDecode(response.body);
        if (data['error'] == false) {
          List<dynamic> apiList = [];
          if (data['leave_summary'] != null && data['leave_summary'] is List) {
            apiList = data['leave_summary'];
          } else if (data['data'] != null && data['data'] is List) {
            apiList = data['data'];
          }

          if (mounted) {
            double currentBalance = 0;
            setState(() {
              for (var staticItem in leaveBalanceData) {
                // ... logic to update leaveBalanceData ...
                String staticType = staticItem['type'].toString().toLowerCase();
                var apiItem = apiList.firstWhere((api) {
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
                  if (staticType == "casual") return apiType.contains("casual");
                  if (staticType == "sick") {
                    return apiType.contains("medical") ||
                        apiType.contains("sick");
                  }
                  return apiType.contains(staticType);
                }, orElse: () => null);

                if (apiItem != null) {
                  int taken =
                      int.tryParse(
                        apiItem['leaves_taken_this_year']?.toString() ??
                            apiItem['leave_taken']?.toString() ??
                            "0",
                      ) ??
                      0;
                  int total =
                      int.tryParse(
                        apiItem['max_days_per_year']?.toString() ??
                            apiItem['total_allowed']?.toString() ??
                            "12",
                      ) ??
                      12;
                  staticItem['total'] = total;
                  staticItem['taken'] = taken;
                  staticItem['balance'] = "${total - taken}/$total";
                  if (staticType != "unpaid") {
                    currentBalance += (total - taken);
                  }
                }
              }
              totalLeaveBalance = currentBalance;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching leave summary: $e");
    }
  }

  Future<void> _fetchLeaveHistory() async {
    if (mounted) setState(() => isLeaveHistoryLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String uid =
          prefs.getString('login_cus_id') ?? prefs.get('uid')?.toString() ?? "";
      final String token = prefs.getString('token') ?? "";
      final String lt = prefs.getDouble('lat')?.toString() ?? "0.0";
      final String ln = prefs.getDouble('lng')?.toString() ?? "0.0";

      final response = await _apiClient.post({
          "type": "2052",
          "uid": uid,
          "id": uid,
          "token": token,
      });

      if (response.statusCode == 200) {
        debugPrint("API Response (Leave History Dashboard): ${response.body}");
        final data = jsonDecode(response.body);
        List<dynamic> fetchedList = [];

        if (data is List) {
          fetchedList = data;
        } else if (data['leave_applications'] != null &&
            data['leave_applications'] is List) {
          fetchedList = data['leave_applications'];
        } else if (data['data'] != null && data['data'] is List) {
          fetchedList = data['data'];
        }

        if (data['summary'] != null && data['summary'] is Map) {
          final summary = data['summary'];
          if (mounted) {
            setState(() {
              leavesTakenThisMonth = double.tryParse(summary['approved']?.toString() ??
                                       summary['total']?.toString() ?? "0") ?? 0;
            });
          }
        }

        if (mounted) {
          setState(() {
            // Sort by ID descending — highest ID (latest applied) shows first
            fetchedList.sort((a, b) {
              int idA = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
              int idB = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
              return idB.compareTo(idA);
            });
            leaveHistory = fetchedList;
            
            // Only recalculate if summary was missing or 0
            if (leavesTakenThisMonth == 0) {
              double monthLeaves = 0;
              String currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

              for (var h in fetchedList) {
                String status = (h['status'] ?? "0").toString().toLowerCase();
                bool isApproved =
                    status == "1" ||
                    status.contains("approv") ||
                    status.contains("accept") ||
                    status == "approved";
                if (!isApproved) continue;

                String leaveDate = h['leave_start_date'] ?? h['date'] ?? "";
                if (leaveDate.startsWith(currentMonth)) {
                  num d = num.tryParse(h['leave_taken']?.toString() ?? "1") ?? 1;
                  monthLeaves += d.toDouble();
                }
              }
              leavesTakenThisMonth = monthLeaves;
            }

            // Sync leave balance data with the list
            for (var b in leaveBalanceData) b['taken'] = 0;
            for (var h in fetchedList) {
               String status = (h['status'] ?? "0").toString().toLowerCase();
               if (!(status == "1" || status.contains("approv") || status == "approved")) continue;
               
               String leaveTypeLower = (h['leave_type'] ?? h['reason'] ?? "").toString().toLowerCase();
               num days = num.tryParse(h['leave_taken']?.toString() ?? h['total_days']?.toString() ?? "1") ?? 1;

               for (var b in leaveBalanceData) {
                  String bType = b['type'].toString().toLowerCase();
                  bool match = false;
                  if (bType == "earned") match = leaveTypeLower.contains("privilege") || leaveTypeLower.contains("earned") || leaveTypeLower.contains("al");
                  else if (bType == "casual") match = leaveTypeLower.contains("casual") || leaveTypeLower.contains("cl");
                  else if (bType == "sick") match = leaveTypeLower.contains("medical") || leaveTypeLower.contains("sick") || leaveTypeLower.contains("ml");
                  else if (bType == "unpaid") match = leaveTypeLower.contains("unpaid") || leaveTypeLower.contains("lop");
                  else match = leaveTypeLower.contains(bType);

                  if (match) {
                    b['taken'] = (b['taken'] as num) + days;
                    break;
                  }
               }
            }

            double currentBalance = 0;
            for (var b in leaveBalanceData) {
              num total = b['total'] ?? 12;
              num taken = b['taken'];
              b['balance'] = "${total - taken}/$total";
              if (b['type'].toString().toLowerCase() != "unpaid") {
                 currentBalance += (total - taken);
              }
            }
            totalLeaveBalance = currentBalance;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching leave history: $e");
    } finally {
      if (mounted) setState(() => isLeaveHistoryLoading = false);
    }
  }

  Future<void> _fetchMonthlyPerformance(SharedPreferences prefs) async {
    try {
      final String cid =
          prefs.getString('cid') ?? prefs.getString('cid_str') ?? "";
      final String uid =
          prefs.getString('uid') ??
          prefs.getString('login_cus_id') ??
          prefs.get('uid')?.toString() ??
          "";
      final String deviceId = prefs.getString('device_id') ?? "";
      final String lat = prefs.getString('lt') ?? prefs.getDouble('lat')?.toString() ?? "";
      final String lng = prefs.getString('ln') ?? prefs.getDouble('lng')?.toString() ?? "";
      final String? token = prefs.getString('token');

      DateTime now = DateTime.now();
      String fromDate = DateFormat('yyyy-MM-01').format(now);
      String toDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime(now.year, now.month + 1, 0));

      final response = await _apiClient.post({
          "type": "2075",
          "uid": uid,
          "token": token ?? "",
          "from_date": fromDate,
          "to_date": toDate,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['error'] == false && data['summary'] != null) {
          int total = data['summary']['total'] ?? 0;
          int completed = data['summary']['completed'] ?? 0;
          if (mounted) {
            setState(() {
              _monthlyRate = total == 0 ? 0 : (completed / total) * 100;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching monthly performance: $e");
    }
  }

  Future<void> _fetchCheckInStatus(SharedPreferences prefs) async {
    try {
      final String cid =
          prefs.getString('cid') ?? prefs.getString('cid_str') ?? "";
      final String uid =
          prefs.getString('login_cus_id') ?? prefs.get('uid')?.toString() ?? "";
      final String token = prefs.getString('token') ?? "";
      final String lat = prefs.getDouble('lat')?.toString() ?? "";
      final String lng = prefs.getDouble('lng')?.toString() ?? "";
      final String dId = prefs.getString('device_id') ?? "";

      final response = await _apiClient.post({
          "type": "2064",
          "uid": uid,
          "token": token,
      });

      if (response.statusCode == 200) {
        debugPrint("CheckIn Status API Response (2064) => ${response.body}");
        final data = jsonDecode(response.body);
        if (data["error"] == false || data["error"] == "false") {
          final List<dynamic> records = data["data"] ?? [];
          final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

          // find the record for today - be flexible with date matching
          final todayRecord = records.firstWhere(
            (e) => (e != null && e is Map && (e["date"]?.toString().contains(today) ?? false)) &&
                   e["del"]?.toString() != "1" &&
                   e["is_d"]?.toString() != "1",
            orElse: () => null,
          );

          // Use Summary if available from API (User's JSON shows summary: {total: 13, present: 0})
          int presentCount = 0;
          if (data['summary'] != null && data['summary'] is Map) {
            presentCount = int.tryParse(data['summary']['total']?.toString() ?? "0") ?? 
                           int.tryParse(data['summary']['present']?.toString() ?? "0") ?? 0;
          }

          // If no summary, calculate from records for current month
          if (presentCount == 0 && records.isNotEmpty) {
            String currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
            presentCount = records
                .where(
                  (rec) => (rec['date']?.toString().startsWith(currentMonth) ?? false) &&
                           rec["del"]?.toString() != "1" &&
                           rec["is_d"]?.toString() != "1",
                )
                .length;
          }

          // Helper to check if a time is valid (not empty and not a dummy value)
          bool isTimeValid(dynamic time) {
            if (time == null) return false;
            String t = time.toString().trim().toLowerCase();
            return t.isNotEmpty && t != "null" && t != "00:00:00" && t != "00:00";
          }

          if (todayRecord != null) {
            final String inTimeStr = todayRecord["in_time"]?.toString() ?? "";
            final String outTimeStr = todayRecord["out_time"]?.toString() ?? "";

            final bool hasIn = isTimeValid(inTimeStr);
            final bool hasOut = isTimeValid(outTimeStr);

            if (mounted) {
              setState(() {
                totalPresentDays = presentCount;
                if (hasIn && !hasOut) {
                  // ✅ DATABASE SAYS: CHECKED IN
                  isCheckedInByServer = true;
                  isTodayFinished = false;
                  isCheckedInByLocal = true; // Sync local state too!
                } else if (hasIn && hasOut) {
                  // ✅ DATABASE SAYS: COMPLETED
                  isCheckedInByServer = false;
                  isTodayFinished = true;
                  isCheckedInByLocal = false;
                } else {
                  // ✅ DATABASE SAYS: NO RECORD
                  isCheckedInByServer = false;
                  isTodayFinished = false;
                  isCheckedInByLocal = false;
                }
                marketingAttendanceMode =
                    prefs.getBool('marketing_attendance_mode') ?? false;
              });
            }
            
            // ✅ FETCH MARKETING STATUS FROM SERVER (SYCHRONIZE WITH POSTMAN)
            await _syncMarketingStatusFromServer(cid, uid, dId, token);
            
            await prefs.setBool('isCheckedIn', isCheckedInByServer);
            if (hasIn) await prefs.setString('last_checkin_date', today);
            if (hasOut) await prefs.setString('last_checkout_date', today);

            // ✅ SYNC BREAK STATUS FROM SERVER
            final String serverStatus =
                todayRecord["status"]?.toString().toLowerCase() ?? "";
            final bool serverSaysOnBreak = serverStatus.contains("break");

            if (mounted) {
              setState(() {
                if (isCheckedInByServer) {
                  if (serverSaysOnBreak) {
                    isOnBreak = true;
                  } else {
                    // ✅ SAFE STOP: Only stop break if local prefs ALSO confirm not on break
                    final bool localSaysOnBreak =
                        prefs.getBool('is_on_break') ?? false;
                    if (!localSaysOnBreak) {
                      isOnBreak = false;
                      _breakTimer?.cancel();
                    }
                    // If local says on break, keep running — local wins
                  }
                } else {
                  // Checked out — definitely end break
                  isOnBreak = false;
                  _breakTimer?.cancel();
                }
              });
            }

            // Sync Preference — only clear if server confirmed checkout
            if (!isCheckedInByServer) {
              await prefs.setBool('is_on_break', false);
              await prefs.remove('break_start_time');
            } else if (serverSaysOnBreak) {
              await prefs.setBool('is_on_break', true);
            }
            final String serverWorkMode =
                todayRecord["wrk_mde"]?.toString().toLowerCase() ?? "";

            if (serverWorkMode.isNotEmpty) {
              bool isMkt = serverWorkMode == "marketing";
              await prefs.setBool('marketing_attendance_mode', isMkt);

              if (isMkt) {
                // If chosen marketing, check if they actually did a marketing check-in
                final historyResp = await _apiClient.post({
                    "type": "2062",
                    "uid": uid,
                    "token": token,
                });
                final hData = jsonDecode(historyResp.body);
                if (hData['error'] == false) {
                  final List records = hData['data'] ?? [];
                  final hasOpenRecord = records.any(
                    (r) =>
                        r['date'] == today &&
                        r['status']?.toString().toLowerCase() == "open",
                  );
                  if (mounted) {
                    setState(() {
                      hasDoneMarketingToday = hasOpenRecord;
                      marketingAttendanceMode = isMkt;
                    });
                  }
                  await prefs.setBool(
                    'has_done_marketing_today',
                    hasOpenRecord,
                  );
                }
              } else {
                if (mounted) {
                  setState(() {
                    marketingAttendanceMode = isMkt;
                  });
                }
              }
            }
          } else {
            // ✅ NO RECORD ON SERVER FOR TODAY - FORCE RESET LOCAL STATE
            if (mounted) {
              setState(() {
                totalPresentDays = presentCount;
                isCheckedInByServer = false;
                isTodayFinished = false;
                isOnBreak = false;
                _breakTimer?.cancel();
                marketingAttendanceMode = false;
                hasDoneMarketingToday = false;
                isCheckedInByLocal = false;
              });
            }
            await prefs.setBool('isCheckedIn', false);
            await prefs.remove('last_checkin_date');
            await prefs.remove('last_checkout_date');
            await prefs.setBool('is_on_break', false);
            await prefs.remove('break_start_time');
            await prefs.setBool('marketing_attendance_mode', false);
            await prefs.setBool('has_done_marketing_today', false);
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching checkin status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;

    bool isTablet = w >= 600 && w < 1024;
    bool isDesktop = w >= 1024;

    double padding = w * 0.04;
    double boxRadius = w * 0.03;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer:const DynamicDrawer(moduleName: "HRM"),
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        elevation: 0,
        title: Text(
          "HRM App",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: isTablet ? 26 : (isDesktop ? 28 : 20),
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: Icon(Icons.menu, size: w * 0.07, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          }
        ),
        actions: const [],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF26A69A),
        onRefresh: () async {
          await _initializeApp();
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: padding,
            right: padding,
            top: padding,
            bottom: padding + 80, // Extra padding for bottom nav space
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            if (!isCheckedIn && !isTodayFinished && !isStatusFetching) ...[
              _buildCheckInReminderCard(context, w),
              SizedBox(height: h * 0.02),
            ],
            if (isCheckedIn &&
                !isTodayFinished &&
                marketingAttendanceMode &&
                !hasDoneMarketingToday) ...[
              _buildMarketingCheckInReminderCard(context, w),
              SizedBox(height: h * 0.02),
            ],
            if (isOnBreak) ...[
              _buildBreakInProgressCard(context, w),
              SizedBox(height: h * 0.02),
            ],
            _buildModernSummaryCards(w, h),
            SizedBox(height: h * 0.02),
            if (roleId != '3') ...[
              _buildApprovalsCard(w, h),
              SizedBox(height: h * 0.02),
            ],

            SizedBox(height: h * 0.02),
            Container(
              padding: EdgeInsets.all(w * 0.03),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2C61),
                borderRadius: BorderRadius.circular(boxRadius),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.campaign,
                    color: Colors.white,
                    size: isTablet ? 36 : 30,
                  ),
                  SizedBox(width: w * 0.03),
                  Expanded(
                    child: Text(
                      "Company Announcement\nNew HR policy updates available.",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: isTablet ? 18 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1B2C61),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnnouncementScreen(userName: userName),
                      ),
                    ),

                    child: Text(
                      "View",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isTablet ? 16 : 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: h * 0.02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Your Task",
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TasksListScreen(),
                    ),
                  ),
                  icon: const Icon(
                    Icons.arrow_circle_right_outlined,
                    color: Color(0xFF26A69A),
                    size: 28,
                  ),
                ),
              ],
            ),
            SizedBox(height: h * 0.01),
            taskCard(),
            SizedBox(height: h * 0.02),
            Text(
              "Your Target",
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: h * 0.01),
            targetBox(),
            SizedBox(height: h * 0.02),
            Container(
              padding: EdgeInsets.all(w * 0.04),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFF24D7B3)],
                ),
                borderRadius: BorderRadius.circular(boxRadius),
                boxShadow: const [
                  BoxShadow(
                    offset: Offset(0, 10),
                    blurRadius: 5,
                    color: Colors.black12,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Image.asset(
                    "assets/frame.png",
                    height: isTablet ? 90 : 70,
                    width: isTablet ? 50 : 35,
                  ),
                  SizedBox(width: w * 0.04),
                  Expanded(
                    child: Text(
                      "Almost there! Push through the last 25% and claim your success!!",
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 18 : 14,
                        color: const Color(0xff1B2C61),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: h * 0.02),
            Text(
              "Leave Summary",
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: h * 0.01),
            leaveReport(),
            if (leaveHistory.isNotEmpty) ...[
              SizedBox(height: h * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recent Activity",
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LeaveManagementScreen(),
                      ),
                    ).then((_) => _initializeApp()),
                    child: Text(
                      "View All",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF26A69A),
                      ),
                    ),
                  ),
                ],
              ),
              isLeaveHistoryLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(
                          color: Color(0xFF26A69A),
                        ),
                      ),
                    )
                  : _buildRecentLeaveHistory(w),
            ],
            SizedBox(height: h * 0.03),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildModernSummaryCards(double w, double h) {
    return Column(
      children: [
        Row(
          children: [
            _statCard(
              "Present Days",
              "$totalPresentDays",
              "Days",
              const [Color(0xFF10B981), Color(0xFF059669)],
              Icons.verified_user_rounded,
              w,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AttendanceScreen()),
              ).then((_) => _initializeApp()),
            ),
            SizedBox(width: w * 0.03),
            _statCard(
              "Leave",
              leavesTakenThisMonth.toStringAsFixed(0),
              "Taken",
              const [Color(0xFFF59E0B), Color(0xFFD97706)],
              Icons.event_busy_rounded,
              w,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LeaveManagementScreen()),
              ).then((_) => _initializeApp()),
            ),
          ],
        ),
        SizedBox(height: w * 0.03),
        Row(
          children: [
            _statCard(
              "Permission",
              "Apply",
              "Request",
              const [Color(0xFF6366F1), Color(0xFF4F46E5)],
              Icons.timer_rounded,
              w,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PermissionForm()),
              ).then((_) => _initializeApp()),
            ),
            SizedBox(width: w * 0.03),
            _statCard(
              "Payroll",
              "View",
              "Payslip",
              const [Color(0xFFEC4899), Color(0xFFDB2777)],
              Icons.payments_rounded,
              w,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PayrollScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(
    String label,
    String value,
    String subLabel,
    List<Color> colors,
    IconData icon,
    double w,
    VoidCallback? onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(w * 0.04),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors.last.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(icon, color: Colors.white.withOpacity(0.4), size: 18),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subLabel,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalsCard(double w, double h) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdminApprovalsScreen()),
        );
      },
      borderRadius: BorderRadius.circular(w * 0.03),
      child: Container(
        padding: EdgeInsets.all(w * 0.04),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF26A69A), Color(0xFF00897B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(w * 0.03),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF26A69A).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: w * 0.12,
              width: w * 0.12,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(w * 0.03),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.task_alt_rounded, color: Colors.white, size: w * 0.07),
                  if (_pendingLeaveCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _pendingLeaveCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: w * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Approvals",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Manage Leave & Permission requests",
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }

  Widget menuBox(
    BuildContext context,
    double width,
    String title,
    String asset,
    Gradient gradient, {
    bool isFullWidth = false,
  }) {
    double w = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () async {
        Widget? target;
        if (title == "Admin") {
          target = admin.AdminDashboard(
            onBackToHrm: () {
              Navigator.pop(context);
            },
          );
        } else if (title == "Reports") {
          target = const ReportsScreen();
        } else if (title == "Marketing") {
          target = const MarketingSelectionScreen();
        } else if (title == "Performance") {
          target = const PerformanceScreen();
        } else if (title == "Leave") {
          target = const LeaveManagementScreen();
        }
        if (target != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => target!),
          ).then((_) => _initializeApp());
        }
      },
      child: Container(
        width: width,
        padding: EdgeInsets.all(isFullWidth ? w * 0.06 : w * 0.03),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(w * 0.03),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: isFullWidth
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(asset, height: w * 0.15),
                  SizedBox(width: w * 0.04),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: w * 0.06,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Image.asset(asset, height: w * 0.12),
                  SizedBox(height: w * 0.02),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: w * 0.035,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCheckInReminderCard(BuildContext context, double w) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Attendance Pending",
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            height: 24,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AttendanceScreen()),
              ).then((_) => _initializeApp()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF26A69A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                "Check-in",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketingCheckInReminderCard(BuildContext context, double w) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB74D), Color(0xFFFFA726)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Mkt Attendance Pending",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            height: 24,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MarketingSelectionScreen(),
                ),
              ).then((_) => _initializeApp()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFFFA726),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                "Check-in",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget taskCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 10),
            blurRadius: 6,
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Task Completion Rate",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "${_monthlyRate.toStringAsFixed(0)}%",
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) => _buildDashboardProgressBar(
              progress: _monthlyRate / 100,
              color: const Color(0xFF26A69A),
              width: constraints.maxWidth,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _monthlyRate >= 80
                ? "Excellent performance! Keep it up!"
                : (_monthlyRate >= 50
                      ? "Good progress, keep pushing!"
                      : "Tasks need more focus this month."),
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget targetBox() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 10),
            blurRadius: 10,
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset("assets/target.png", height: 25, width: 25),
              const SizedBox(width: 8),
              Text(
                "Your Target Completion",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) => _buildDashboardProgressBar(
              progress: _monthlyRate / 100,
              color: const Color(0xffEC6E2D),
              width: constraints.maxWidth,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "${_monthlyRate.toStringAsFixed(0)}% Completed",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xffEC6E2D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardProgressBar({
    required double progress,
    required Color color,
    required double width,
  }) {
    const double barHeight = 10;
    const double iconSize = 24;
    return SizedBox(
      height: iconSize,
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          Container(
            height: barHeight,
            width: width,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(barHeight / 2),
            ),
          ),
          Container(
            height: barHeight,
            width: width * (progress > 1 ? 1 : (progress < 0 ? 0 : progress)),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(barHeight / 2),
            ),
          ),
          Positioned(
            left:
                (width * (progress > 1 ? 1 : (progress < 0 ? 0 : progress))) -
                (iconSize / 2),
            child: Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.local_fire_department,
                  size: 14,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget leaveReport() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 10),
            blurRadius: 10,
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        children: leaveBalanceData
            .where(
              (item) =>
                  item['type'] == 'Casual' ||
                  item['type'] == 'Sick' ||
                  item['type'] == 'Unpaid',
            )
            .map((item) {
              String displayType;
              String asset = "assets/casual_leave.png";
              if (item['type'] == "Sick")
                displayType = "Medical Leave";
              else if (item['type'] == "Unpaid")
                displayType = "Unpaid Leave (LOP)";
              else
                displayType = "${item['type']} Leave";
              num taken = item['taken'] as num;
              String balanceLine = item['type'] == 'Unpaid'
                  ? "LOP Days: $taken"
                  : "Balance: ${((item['total'] as num? ?? 12) - taken).clamp(0, 99)} / ${item['total'] ?? 12} Days";
              return Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Row(
                  children: [
                    Image.asset(
                      asset,
                      height: 60,
                      width: 60,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.event_busy,
                        size: 48,
                        color: Color(0xFF26A69A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "$displayType:\nTaken: $taken Day\n$balanceLine",
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            })
            .toList(),
      ),
    );
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _startBreakTimer(DateTime startTime) {
    _breakTimer?.cancel();
    _breakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted)
        setState(() => breakDuration = DateTime.now().difference(startTime));
    });
  }

  Widget _buildBreakInProgressCard(BuildContext context, double w) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: w * 0.04),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF9C4), Color(0xFFFFF59D)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.yellow.shade700.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.yellow.shade700.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AttendanceScreen()),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                "assets/cup.png",
                width: 24,
                height: 24,
                color: Colors.orange.shade800,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "On Break (${formatDuration(breakDuration)})",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade700,
                    ),
                  ),
                  Text(
                    "Purpose: $breakPurpose",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.brown.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.brown.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLeaveHistory(double w) {
    final recentItems = leaveHistory.take(3).toList();
    return Column(
      children: recentItems.map((item) {
        String status = (item['status'] ?? "0").toString().toLowerCase();
        Color statusColor = Colors.orange;
        String statusText = "Pending";
        bool isApproved =
            (status == "1" ||
            status == "accept" ||
            status == "approved" ||
            status.contains("approv"));
        bool isRejected =
            (status == "2" ||
            status == "reject" ||
            status == "rejected" ||
            status.contains("reject"));
        if (isApproved) {
          statusColor = Colors.green;
          statusText = "Approved";
        } else if (isRejected) {
          statusColor = Colors.red;
          statusText = "Rejected";
        }
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['leave_type'] ?? "General Leave",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B2C61),
                      ),
                    ),
                    Text(
                      "${item['leave_start_date']} to ${item['leave_end_date']}",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _syncMarketingStatusFromServer(
      String cid, String uid, String dId, String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getString('lt') ?? prefs.getDouble('lat')?.toString() ?? "";
      final lng = prefs.getString('ln') ?? prefs.getDouble('lng')?.toString() ?? "";

      final response = await _apiClient.post({
          "type": "2062", // Marketing history type
          "uid": uid,
          "token": token,
      });

      final data = jsonDecode(response.body);
      if (data["error"] == false) {
        final List<dynamic> records = data["data"] ?? [];
        final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

        final todayRecord = records.firstWhere(
          (e) => e["date"] == today,
          orElse: () => null,
        );

        if (mounted) {
          setState(() {
            hasDoneMarketingToday = todayRecord != null;
          });
          await prefs.setBool('has_done_marketing_today', hasDoneMarketingToday);
        }
      }
    } catch (e) {
      debugPrint("Error syncing marketing status: $e");
    }
  }
}
