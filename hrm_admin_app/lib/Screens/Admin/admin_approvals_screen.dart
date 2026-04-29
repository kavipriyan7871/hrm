import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrm_admin_app/Screens/Admin/LeaveManagement/admin_leave_requests.dart';
import 'package:hrm_admin_app/Screens/Admin/PermissionManagement/admin_permission_requests.dart';
import 'package:hrm_admin_app/Screens/Admin/ExpenseManagement/admin_expense_requests.dart';
import 'package:hrm_admin_app/Models/leave_api.dart';
import 'package:hrm_admin_app/Models/permission_api.dart';
import 'package:hrm_admin_app/Models/expense_api.dart';
import 'package:hrm_admin_app/Models/employee_api.dart';
import 'package:hrm_admin_app/Utils/shared_prefs_util.dart';

class AdminApprovalsScreen extends StatefulWidget {
  const AdminApprovalsScreen({super.key});

  @override
  State<AdminApprovalsScreen> createState() => _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends State<AdminApprovalsScreen> {
  String _selectedFilter = "All";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Approvals",
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Row
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterChip("All"),
                _buildFilterChip("Leave"),
                _buildFilterChip("Permission"),
                _buildFilterChip("Expense"),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          color: isSelected ? const Color(0xFF26A69A) : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedFilter = label;
          });
        }
      },
      selectedColor: const Color(0xFF26A69A).withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: BorderSide(
          color: isSelected ? const Color(0xFF26A69A) : Colors.grey.shade300,
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildBody() {
    if (_selectedFilter == "Leave") {
      return AdminLeaveRequestsScreen(showAppBar: false);
    } else if (_selectedFilter == "Permission") {
      return AdminPermissionRequestsScreen(showAppBar: false);
    } else if (_selectedFilter == "Expense") {
      return const AdminExpenseRequestsScreen(showAppBar: false);
    } else {
      // "All" - Interleaved feed of Leave, Permission, and Expense requests
      return _InterleavedApprovalsFeed();
    }
  }
}

class _InterleavedApprovalsFeed extends StatefulWidget {
  const _InterleavedApprovalsFeed();

  @override
  State<_InterleavedApprovalsFeed> createState() => _InterleavedApprovalsFeedState();
}

class _InterleavedApprovalsFeedState extends State<_InterleavedApprovalsFeed> {
  List<dynamic> _combinedRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAndCombine();
  }

  Future<void> _fetchAndCombine() async {
    setState(() => _isLoading = true);
    try {
      final String uid = await SharedPrefsUtil.getUid();
      final empResponse = await EmployeeApi.fetchEmployeeDetails(uid: uid);
      String? reportingManager;
      if (empResponse.data.isNotEmpty) {
        reportingManager = empResponse.data.first.reportingManager;
      }

      final results = await Future.wait([
        LeaveApi.fetchLeaveRequests(reportingManager: reportingManager),
        PermissionApi.fetchPermissionRequests(reportingManager: reportingManager),
        ExpenseApi.fetchExpenseRequests(),
      ]);

      final List<dynamic> combined = [];
      
      // Process Leaves
      final leaveResp = results[0] as LeaveRequestResponse;
      combined.addAll(leaveResp.data.where((doc) {
        final s = doc.status?.toLowerCase() ?? "";
        return s == "pending" || s == "" || s == "0";
      }).map((e) => {"type": "Leave", "data": e, "id": e.id}));

      // Process Permissions
      final permResp = results[1] as PermissionRequestResponse;
      combined.addAll(permResp.data.where((doc) {
        final s = doc.status?.toLowerCase() ?? "";
        return s == "pending" || s == "" || s == "0";
      }).map((e) => {"type": "Permission", "data": e, "id": e.id}));

      // Process Expenses
      final expResp = results[2] as Map<String, dynamic>;
      final List expList = expResp['data'] ?? [];
      combined.addAll(expList.where((doc) {
        final s = doc['status']?.toString().toLowerCase() ?? "";
        return s == "pending" || s == "" || s == "0";
      }).map((e) => {
        "type": "Expense", 
        "data": e, 
        "id": int.tryParse(e['id']?.toString() ?? "0") ?? 0
      }));

      // Sort by ID descending (Note: This assumes IDs are comparable across types or sequential enough)
      // If IDs aren't chronological across tables, sorting by appliedDate/appDate might be needed
      combined.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));

      if (mounted) {
        setState(() {
          _combinedRequests = combined;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching interleaved approvals: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF26A69A)));
    }

    if (_combinedRequests.isEmpty) {
      return Center(
        child: Text(
          "No pending approvals found.",
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAndCombine,
      color: const Color(0xFF26A69A),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        itemCount: _combinedRequests.length,
        itemBuilder: (context, index) {
          final item = _combinedRequests[index];
          String typeLabel = "Request";
          if (item['type'] == "Leave") typeLabel = "Leave Request";
          if (item['type'] == "Permission") typeLabel = "Permission Request";
          if (item['type'] == "Expense") typeLabel = "Expense Request";
          
          return _buildTypeHeader(context, typeLabel, item['data']);
        },
      ),
    );
  }

  Widget _buildTypeHeader(BuildContext context, String title, dynamic data) {
    Color typeColor = Colors.orange;
    if (title.contains("Leave")) typeColor = Colors.blue;
    if (title.contains("Expense")) typeColor = Colors.purple;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          child: Row(
            children: [
              Container(
                width: 4.w,
                height: 14.h,
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        if (title.contains("Leave"))
          AdminLeaveRequestsScreen(
            showAppBar: false,
            isEmbedded: true,
            specificRequest: data,
          )
        else if (title.contains("Permission"))
          AdminPermissionRequestsScreen(
            showAppBar: false,
            isEmbedded: true,
            specificRequest: data,
          )
        else if (title.contains("Expense"))
          AdminExpenseRequestsScreen(
            showAppBar: false,
            isEmbedded: true,
            specificRequest: data,
          )
      ],
    );
  }
}
