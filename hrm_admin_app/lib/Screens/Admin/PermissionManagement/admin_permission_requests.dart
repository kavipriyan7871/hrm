import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../Models/permission_api.dart';
import '../../../Models/employee_api.dart';
import '../../../Utils/shared_prefs_util.dart';

class AdminPermissionRequestsScreen extends StatefulWidget {
  final bool showAppBar;
  final bool isEmbedded;
  final PermissionRequestData? specificRequest;
  const AdminPermissionRequestsScreen({
    super.key,
    this.showAppBar = true,
    this.isEmbedded = false,
    this.specificRequest,
  });

  @override
  State<AdminPermissionRequestsScreen> createState() => _AdminPermissionRequestsScreenState();
}

class _AdminPermissionRequestsScreenState extends State<AdminPermissionRequestsScreen> {
  List<PermissionRequestData>? _allRequests;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String uid = await SharedPrefsUtil.getUid();
      
      String? reportingManager;
      try {
        final empResponse = await EmployeeApi.fetchEmployeeDetails(uid: uid);
        if (empResponse.data.isNotEmpty) {
          reportingManager = empResponse.data.first.reportingManager;
        }
      } catch (e) {
        debugPrint("Error fetching employee details for reporting manager: $e");
      }

      final response = await PermissionApi.fetchPermissionRequests(reportingManager: reportingManager);
      
      setState(() {
        _allRequests = response.data.where((doc) {
          final s = doc.status?.toLowerCase() ?? "";
          // '0' is usually the pending code from the ERP server
          return s == "pending" || s == "" || s == "0";
        }).toList();

        _allRequests?.sort((a, b) => b.id.compareTo(a.id));
        
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching permission requests: $e");
      if(mounted){
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "N/A";
    try {
      DateTime dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEmbedded) {
      return _buildBodyContent();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: widget.showAppBar ? AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Permission Requests",
          style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
      ) : null,
      body: _buildBodyContent(),
    );
  }

  Widget _buildBodyContent() {
    if (widget.specificRequest != null) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: _buildRequestCard(widget.specificRequest!),
      );
    }

    if (_isLoading && _allRequests == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_allRequests == null || _allRequests!.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Text(
            "No permission requests found.",
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ),
      );
    }

    final listContent = ListView.builder(
      padding: EdgeInsets.all(16.w),
      shrinkWrap: widget.isEmbedded,
      physics: widget.isEmbedded ? const NeverScrollableScrollPhysics() : null,
      itemCount: _allRequests!.length,
      itemBuilder: (context, index) {
        return _buildRequestCard(_allRequests![index]);
      },
    );

    return Column(
      children: [
        _buildSummaryBar(),
        if (widget.isEmbedded)
          listContent
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: listContent,
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem("Pending", "${_allRequests?.length ?? 0}", Colors.orange),
          _summaryItem("Recent", "${(_allRequests?.isEmpty ?? true) ? 0 : 1}", Colors.green),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.grey)),
      ],
    );
  }

  Widget _buildRequestCard(PermissionRequestData request) {
    final TextEditingController rejectReasonController = TextEditingController();
    
    // Formatting the displayed time slightly
    String timeStr = "N/A";
    if (request.startTime != null && request.endDate != null) {
      timeStr = "${request.startTime} - ${request.endDate}";
    } else if (request.startTime != null) {
      timeStr = request.startTime!;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE0F7FA),
                child: Text(
                  request.employeeName.isNotEmpty ? request.employeeName[0].toUpperCase() : "?",
                  style: const TextStyle(color: Color(0xFF00ACC1), fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.employeeName, style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.bold)),
                    Text(
                      request.permissionType ?? "Permission Request",
                      style: GoogleFonts.poppins(fontSize: 12.sp, color: const Color(0xFF00ACC1), fontWeight: FontWeight.w600)
                    ),
                  ],
                ),
              ),
              Text(_formatDate(request.appDate), style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.grey)),
            ],
          ),
          const Divider(height: 24),
          _rowInfo(Icons.access_time_outlined, timeStr),
          SizedBox(height: 8.h),
          _rowInfo(Icons.info_outline, request.reason ?? "No Reason"),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showRejectDialog(context, request, rejectReasonController),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                  child: Text("Reject", style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600)),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _approveRequest(context, request),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  ),
                  child: Text("Approve", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _approveRequest(BuildContext context, PermissionRequestData request) async {
    final response = await PermissionApi.updatePermissionStatus(
      permissionId: request.id.toString(),
      status: "approved",
    );

    if (response['error'] == false) {
      if (mounted) {
        setState(() {
          _allRequests?.removeWhere((r) => r.id == request.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Permission Approved for ${request.employeeName}!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        final errorMsg =
            response['error_msg'] ?? response['debug'] ?? response['message'] ?? "Update failed";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to approve: $errorMsg"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showRejectDialog(
    BuildContext context,
    PermissionRequestData request,
    TextEditingController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Reject Request",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Reason for Rejection:",
              style: GoogleFonts.poppins(fontSize: 13.sp),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Type reason here...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final response = await PermissionApi.updatePermissionStatus(
                permissionId: request.id.toString(),
                status: "rejected",
                rejectReason: controller.text.trim(),
              );
              
              if (mounted) {
                Navigator.pop(context);
                if (response['error'] == false) {
                  setState(() {
                    _allRequests?.removeWhere((r) => r.id == request.id);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Request Rejected: ${controller.text}"),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  final errorMsg =
                      response['error_msg'] ??
                      response['debug'] ??
                      response['message'] ??
                      "Update failed";
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Failed to reject: $errorMsg"),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Reject", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _rowInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: Colors.grey),
        SizedBox(width: 8.w),
        Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey.shade700))),
      ],
    );
  }
}
