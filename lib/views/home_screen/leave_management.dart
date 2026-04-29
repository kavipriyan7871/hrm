import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/leave_api.dart';
import 'leave_application.dart';
import 'permission_form.dart';
import '../../models/permission_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LeaveManagementMode {
  selection,
  leaveDashboard,
  leaveForm,
  permissionDashboard,
  permissionForm,
}

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  LeaveManagementMode _currentMode = LeaveManagementMode.selection;
  int selectedTab = 0; // 0 = Summary, 1 = History
  List<dynamic> leaveHistoryData = [];
  List<dynamic> permissionHistoryData = [];
  bool isLoading = false;
  bool isBalanceLoading = false;

  final Color appThemeColor = const Color(0xff26A69A); // Main Green Color

  List<Map<String, dynamic>> leaveBalanceData = [
    {
      "type": "Casual",
      "taken": 0,
      "total": 12,
      "balance": "12/12",
      "gradient": [const Color(0xFFF5F5F5), const Color(0xFFD4D6FF)],
      "progressColor": const Color(0xff8388FF),
    },
    {
      "type": "Sick",
      "taken": 0,
      "total": 12,
      "balance": "12/12",
      "gradient": [const Color(0xFFF5F5F5), const Color(0xFFD4FEFF)],
      "progressColor": const Color(0xff59FAFF),
    },
    {
      "type": "Earned",
      "taken": 0,
      "total": 12,
      "balance": "12/12",
      "gradient": [const Color(0xFFF5F5F5), const Color(0xFFF4D4FF)],
      "progressColor": const Color(0xffD679F8),
    },
    {
      "type": "Maternity",
      "taken": 0,
      "total": 12,
      "balance": "12/12",
      "gradient": [const Color(0xFFFFF5F5), const Color(0xFFFFD4D4)],
      "progressColor": const Color(0xFFFB6065),
    },
    {
      "type": "Unpaid",
      "taken": 0,
      "total": null,
      "balance": "-/-",
      "gradient": [const Color(0xFFF5FFF5), const Color(0xFFD4FFD4)],
      "progressColor": const Color(0xFF26A69A),
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchLeaveSummary();
  }

  Future<void> _fetchLeaveSummary() async {
    if (!mounted) return;
    setState(() => isBalanceLoading = true);
    try {
      final res = await LeaveService.getLeaveSummary();
      if (res['error'] == false) {
        List<dynamic> apiList = res['leave_summary'] ?? [];
        setState(() {
          for (var staticItem in leaveBalanceData) {
            String staticType = staticItem['type'].toString().toLowerCase();
            var apiItem = apiList.firstWhere((api) {
              String apiType = (api['leave_type'] ?? "").toString().toLowerCase();
              if (staticType == "earned")
                return apiType.contains("earned") || apiType.contains("annual") || apiType.contains("al");
              if (staticType == "casual")
                return apiType.contains("casual") || apiType.contains("cl");
              if (staticType == "sick")
                return apiType.contains("medical") || apiType.contains("ml") || apiType.contains("sick");
              if (staticType == "maternity")
                return apiType.contains("maternity");
              if (staticType == "unpaid")
                return apiType.contains("unpaid") || apiType.contains("lop");
              return apiType.contains(staticType);
            }, orElse: () => null);

            if (apiItem != null) {
              int taken = int.tryParse(apiItem['leaves_taken_this_year']?.toString() ?? "0") ?? 0;
              int total = int.tryParse(apiItem['max_days_per_year']?.toString() ?? "12") ?? 12;
              staticItem['taken'] = taken;
              staticItem['total'] = total;
              staticItem['balance'] = "${total - taken}/$total";
            }
          }
        });
      }
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
      final res = await LeaveService.getLeaveHistory();
      if (res['error'] == false) {
        List<dynamic> fetchedList = res['leave_applications'] ?? res['data'] ?? [];
        // Sort by ID descending — highest ID (latest applied) shows first
        fetchedList.sort((a, b) {
          int idA = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
          int idB = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
          return idB.compareTo(idA);
        });
        setState(() {
          leaveHistoryData = fetchedList.where((item) {
            final String delFlag = item['del']?.toString() ?? "";
            final String isDFlag = item['is_d']?.toString() ?? "";
            return delFlag != "1" && isDFlag != "1";
          }).toList();
          _calculateBalances();
        });
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _calculateBalances() {
    for (var b in leaveBalanceData) b['taken'] = 0;
    for (var h in leaveHistoryData) {
      String status = (h['status'] ?? "0").toString().toLowerCase();
      bool isApproved = (status == "1" || status == "accept" || status == "approved" || status.contains("approv"));
      if (!isApproved) continue;

      num days = 1;
      if (h['leave_taken'] != null && h['leave_taken'].toString().isNotEmpty && h['leave_taken'].toString() != "null") {
        days = num.tryParse(h['leave_taken'].toString()) ?? 1;
      } else if (h['total_days'] != null && h['total_days'].toString().isNotEmpty && h['total_days'].toString() != "null") {
        days = num.tryParse(h['total_days'].toString()) ?? 1;
      }
      String type = (h['leave_type'] ?? "").toString().toLowerCase();

      for (var b in leaveBalanceData) {
        String bType = b['type'].toString().toLowerCase();
        bool match = false;
        if (bType == "earned") match = type.contains("privilege") || type.contains("earned") || type.contains("al");
        else if (bType == "casual") match = type.contains("casual") || type.contains("cl");
        else if (bType == "sick") match = type.contains("medical") || type.contains("sick") || type.contains("ml");
        else if (bType == "unpaid") match = type.contains("unpaid") || type.contains("lop");
        else match = type.contains(bType);

        if (match) {
          b['taken'] = (b['taken'] as num) + days;
          break;
        }
      }
    }
    for (var b in leaveBalanceData) {
      num taken = b['taken'];
      if (b['type'].toString().toLowerCase() == "unpaid") b['balance'] = "$taken/-";
      else b['balance'] = "${(b['total'] ?? 12) - taken}/${b['total'] ?? 12}";
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = "Leave Management";
    if (_currentMode == LeaveManagementMode.leaveDashboard) title = "Leave Request";
    if (_currentMode == LeaveManagementMode.leaveForm) title = "Apply Leave";
    if (_currentMode == LeaveManagementMode.permissionDashboard) title = "Permission Request";
    if (_currentMode == LeaveManagementMode.permissionForm) title = "Apply Permission";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: appThemeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            if (_currentMode == LeaveManagementMode.selection) {
              Navigator.pop(context);
            } else if (_currentMode == LeaveManagementMode.leaveForm) {
              setState(() => _currentMode = LeaveManagementMode.leaveDashboard);
            } else if (_currentMode == LeaveManagementMode.permissionForm) {
              setState(() => _currentMode = LeaveManagementMode.permissionDashboard);
            } else {
              setState(() => _currentMode = LeaveManagementMode.selection);
            }
          },
        ),
        title: Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_currentMode) {
      case LeaveManagementMode.selection:
        return _buildSelectionMode();
      case LeaveManagementMode.leaveDashboard:
        return RefreshIndicator(
          onRefresh: () async {
            await _fetchLeaveSummary();
            await _fetchLeaveHistory();
          },
          color: appThemeColor,
          child: _buildDashboardMode(),
        );
      case LeaveManagementMode.permissionDashboard:
        return RefreshIndicator(
          onRefresh: () async => await _fetchPermissionHistory(),
          color: appThemeColor,
          child: _buildDashboardMode(),
        );
      case LeaveManagementMode.leaveForm:
        return const SingleChildScrollView(padding: EdgeInsets.all(20), child: LeaveForm());
      case LeaveManagementMode.permissionForm:
        return const SingleChildScrollView(padding: EdgeInsets.all(20), child: PermissionForm());
    }
  }

  Widget _buildSelectionMode() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text("Welcome back!", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1B2C61))),
          Text("Select a category to manage your requests.", style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF64748B))),
          const SizedBox(height: 32),
          _selectionCardResponsive("Leave Request", "Total Leave: 12 Days Yearly", "Manage balance & history", Icons.event_note_rounded, appThemeColor, () {
            setState(() { _currentMode = LeaveManagementMode.leaveDashboard; selectedTab = 0; });
            _fetchLeaveSummary();
          }),
          const SizedBox(height: 20),
          _selectionCardResponsive("Permission Request", "Total Permission: 2/Month", "Apply personal permission", Icons.more_time_rounded, appThemeColor, () {
            setState(() { _currentMode = LeaveManagementMode.permissionDashboard; selectedTab = 0; });
            _fetchPermissionHistory();
          }),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _selectionCardResponsive(String title, String subtitle, String desc, IconData icon, Color color, VoidCallback onTap) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 10))],
            border: Border.all(color: color.withOpacity(0.1), width: 1.5),
          ),
          child: Stack(
            children: [
              Positioned(top: -30, right: -30, child: CircleAvatar(radius: 70, backgroundColor: color.withOpacity(0.04))),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: color, size: 28)),
                    const Spacer(),
                    Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1B2C61))),
                    const SizedBox(height: 4),
                    Text(subtitle, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                    Text(desc, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF94A3B8))),
                  ],
                ),
              ),
              Positioned(bottom: 20, right: 20, child: CircleAvatar(radius: 20, backgroundColor: color, child: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardMode() {
    return Column(
      children: [
        _buildTabs(appThemeColor),
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                (_currentMode == LeaveManagementMode.permissionDashboard || selectedTab == 1)
                    ? (isLoading ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())) : _buildHistoryList())
                    : (isBalanceLoading ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())) : _buildSummaryGrid()),
                const SizedBox(height: 20),
                _buildHolidayListCard(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        _buildApplyButton(appThemeColor),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTabs(Color themeColor) {
    if (_currentMode == LeaveManagementMode.permissionDashboard) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(30)),
        child: Row(children: [_tabItem(0, "Summary", themeColor), _tabItem(1, "History", themeColor)]),
      ),
    );
  }

  Widget _tabItem(int index, String label, Color themeColor) {
    bool isSelected = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isSelected ? themeColor : Colors.transparent, borderRadius: BorderRadius.circular(30)),
          child: Text(label, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.grey.shade600)),
        ),
      ),
    );
  }

  Widget _buildSummaryGrid() {
    bool isLeave = _currentMode == LeaveManagementMode.leaveDashboard;
    List<Map<String, dynamic>> dataList = isLeave ? leaveBalanceData : [];
    if (!isLeave) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Detailed summaries available in the history list.")));
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.1),
      itemCount: dataList.length,
      itemBuilder: (context, index) => _balanceCard(dataList[index]),
    );
  }

  Widget _balanceCard(Map<String, dynamic> data) {
    num taken = data['taken'] ?? 0;
    num total = data['total'] ?? 12;
    double progress = total == 0 ? 0 : (taken / total).clamp(0.0, 1.0);
    String balanceText = data['balance'] ?? "0/0";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [CircleAvatar(radius: 4, backgroundColor: data['progressColor']), const SizedBox(width: 8), Text(data['type'], style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1B2C61)))]),
                const SizedBox(height: 10),
                _balanceInfoRow("Taken", ": $taken"),
                const SizedBox(height: 4),
                _balanceInfoRow("Balance", ": $balanceText"),
              ],
            ),
          ),
          const Spacer(),
          Container(
            height: 6,
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
            child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: progress, child: Container(decoration: BoxDecoration(color: data['progressColor'], borderRadius: BorderRadius.circular(10)))),
          ),
        ],
      ),
    );
  }

  Widget _balanceInfoRow(String label, String value) {
    return Row(children: [SizedBox(width: 60, child: Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)))), Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1B2C61)))]);
  }

  Widget _buildHolidayListCard() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), decoration: BoxDecoration(color: const Color(0xFFFFB7B7).withOpacity(0.3), borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.calendar_month, color: Color(0xFF1B2C61), size: 28), const SizedBox(width: 16), Expanded(child: Text("Holiday List", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1B2C61)))), const Icon(Icons.arrow_right, color: Color(0xFF1B2C61))])));
  }

  Widget _buildHistoryList() {
    bool isLeave = _currentMode == LeaveManagementMode.leaveDashboard;
    List<dynamic> dataToUse = isLeave ? leaveHistoryData : permissionHistoryData;
    if (dataToUse.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No records found")));
    return ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20), itemCount: dataToUse.length, itemBuilder: (context, index) => _historyCard(dataToUse[index]));
  }

  Widget _buildApplyButton(Color themeColor) {
    bool isLeave = _currentMode == LeaveManagementMode.leaveDashboard;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: () => setState(() => _currentMode = isLeave
              ? LeaveManagementMode.leaveForm
              : LeaveManagementMode.permissionForm),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: Text(
            isLeave ? "Apply for Leave" : "Apply for Permission",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _fetchPermissionHistory() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final res = await PermissionApi.getPermissionHistory();
      debugPrint("PERMISSION HISTORY API RESULT: $res");
      if (res['error'].toString() == "false") {
        List<dynamic> permList = [];
        if (res['data'] is List) {
          permList = res['data'];
        } else if (res['data'] is Map) {
          permList = res['data']['permission_history'] ?? 
                     res['data']['history'] ?? 
                     res['data']['data'] ?? [];
        } else {
          permList = res['permission_history'] ?? res['data'] ?? [];
        }

        if (permList is! List) permList = [];
        
        // Sort by ID descending — highest ID (latest applied) shows first
        permList.sort((a, b) {
          int idA = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
          int idB = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
          return idB.compareTo(idA);
        });
        setState(() {
          permissionHistoryData = permList;
        });
      }
    } catch (e) {
      debugPrint("Error fetching permission history: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _historyCard(Map<String, dynamic> item) {
    bool isLeave = _currentMode == LeaveManagementMode.leaveDashboard;
    String status = (item['status'] ?? "Pending").toString().toLowerCase();
    Color statusColor = Colors.orange;

    if (status.contains("approv") || status == "accept" || status == "1" || status == "approved") {
      statusColor = Colors.green;
      status = "Approved";
    } else if (status.contains("reject") || status == "2" || status == "decline" || status == "rejected") {
      statusColor = Colors.red;
      status = "Rejected";
    } else {
      status = "Pending";
    }

    String title = "";
    String subtitle = "";
    String dateRange = "";
    String days = "";

    if (isLeave) {
      title = (item['leave_type'] ?? "Leave Request").toString();
      subtitle = (item['reason'] ?? "").toString();
      dateRange = "${item['leave_start_date']} to ${item['leave_end_date']}";
      days = " (${item['total_days'] ?? '0'} Days)";
    } else {
      // Permission History mapping based on type 2078
      title = (item['permission_type_name'] != null && item['permission_type_name'].toString().trim().isNotEmpty)
          ? item['permission_type_name'].toString()
          : (item['reason'] ?? "Permission Request").toString();
      
      subtitle = (item['reason'] ?? "").toString();
      
      String date = item['permission_date'] ?? item['applied_date'] ?? item['app_date'] ?? item['date'] ?? "-";
      String startTime = item['from_time'] ?? item['start_time'] ?? "";
      String endTime = item['end_time'] ?? item['to_time'] ?? "";
      
      dateRange = date;
      if (startTime.isNotEmpty && startTime != "-") dateRange += " at $startTime";
      if (endTime.isNotEmpty && endTime != "-") dateRange += " - $endTime";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "$title$days",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B2C61),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                dateRange,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          if (subtitle.isNotEmpty && subtitle != title) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF94A3B8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
