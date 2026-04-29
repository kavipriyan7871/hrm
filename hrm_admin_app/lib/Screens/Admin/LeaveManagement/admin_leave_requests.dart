import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../Models/leave_api.dart';
import '../../../Models/employee_api.dart';
import '../../../Utils/shared_prefs_util.dart';

class AdminLeaveRequestsScreen extends StatefulWidget {
  final bool showAppBar;
  final bool isEmbedded;
  final LeaveRequestData? specificRequest;
  const AdminLeaveRequestsScreen({
    super.key,
    this.showAppBar = true,
    this.isEmbedded = false,
    this.specificRequest,
  });

  @override
  State<AdminLeaveRequestsScreen> createState() =>
      _AdminLeaveRequestsScreenState();
}

class _AdminLeaveRequestsScreenState extends State<AdminLeaveRequestsScreen> {
  List<LeaveRequestData>? _allRequests;
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
      // 1. Get current UID
      final String uid = await SharedPrefsUtil.getUid();
      
      // 2. Fetch employee details to get reporting_manager
      String? reportingManager;
      try {
        final empResponse = await EmployeeApi.fetchEmployeeDetails(uid: uid);
        if (empResponse.data.isNotEmpty) {
          reportingManager = empResponse.data.first.reportingManager;
          debugPrint("Found reporting manager for UID $uid: $reportingManager");
        }
      } catch (e) {
        debugPrint("Error fetching employee details for reporting manager: $e");
      }

      // 3. Fetch leave requests with reporting_manager filter
      final response = await LeaveApi.fetchLeaveRequests(reportingManager: reportingManager);
      
      setState(() {
        // Only show PENDING requests or requests with no status set yet
        _allRequests = response.data.where((doc) {
          final s = doc.status?.toLowerCase() ?? "";
          return s == "pending" || s == "";
        }).toList();

        // Sort by ID descending to show latest first
        _allRequests?.sort((a, b) => b.id.compareTo(a.id));
        
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching leave requests: $e");
      setState(() {
        _isLoading = false;
      });
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
          "Leave Requests",
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ) : null,
      body: _buildBodyContent(),
    );
  }

  Widget _buildBodyContent() {
    if (widget.specificRequest != null) {
      return _buildRequestCard(widget.specificRequest!, 0);
    }

    if (_isLoading && _allRequests == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_allRequests == null || _allRequests!.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Text(
            "No leave requests found.",
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
        return GestureDetector(
          onTap: () => _showLeavePreview(_allRequests![index]),
          child: _buildRequestCard(_allRequests![index], index),
        );
      },
    );

    return Column(
      children: [
        _buildSummaryBar(_allRequests!),
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

  Widget _buildSummaryBar(List<LeaveRequestData> requests) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem("Pending Total", "${requests.length}", Colors.blue),
          _summaryItem(
            "Recent",
            "${requests.isEmpty ? 0 : 1}",
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildRequestCard(LeaveRequestData request, int index) {
    final TextEditingController rejectReasonController =
        TextEditingController();

    String dateRange =
        "${_formatDate(request.leaveStartDate)} - ${_formatDate(request.leaveEndDate)}";
    if (request.totalDays != null && request.totalDays!.isNotEmpty) {
      dateRange += " (${request.totalDays} Days)";
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE0F2F1),
                child: Text(
                  request.employeeName.isNotEmpty
                      ? request.employeeName[0].toUpperCase()
                      : "?",
                  style: const TextStyle(
                    color: Color(0xFF26A69A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.employeeName,
                      style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          request.leaveType,
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            color: const Color(0xFF26A69A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (request.attachment != null &&
                            request.attachment!.isNotEmpty) ...[
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.attach_file,
                            size: 14.sp,
                            color: Colors.grey,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    request.appliedDate ?? "N/A",
                    style: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      color: Colors.grey,
                    ),
                  ),
                  if (request.status != null)
                    Container(
                      margin: EdgeInsets.only(top: 4.h),
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          request.status!,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        request.status!,
                        style: GoogleFonts.poppins(
                          fontSize: 10.sp,
                          color: _getStatusColor(request.status!),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          _rowInfo(Icons.calendar_month_outlined, dateRange),
          SizedBox(height: 8.h),
          _rowInfo(
            Icons.notes_outlined,
            request.reason ?? "No reason provided",
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showRejectDialog(
                    context,
                    request,
                    rejectReasonController,
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    "Reject",
                    style: GoogleFonts.poppins(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _approveRequest(context, request),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    "Approve",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accept':
      case 'approved':
        return Colors.green;
      case 'reject':
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _approveRequest(BuildContext context, LeaveRequestData request) async {
    final response = await LeaveApi.updateLeaveStatus(
      leaveId: request.id.toString(),
      status: "approved",
    );

    if (response['error'] == false) {
      if (mounted) {
        setState(() {
          _allRequests?.removeWhere((r) => r.id == request.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Leave Approved for ${request.employeeName}!"),
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

  void _showLeavePreview(LeaveRequestData request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Leave Details",
                    style: GoogleFonts.poppins(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF26A69A),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Employee Info Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30.r,
                          backgroundColor: const Color(0xFFE0F2F1),
                          child: Text(
                            request.employeeName.isNotEmpty
                                ? request.employeeName[0].toUpperCase()
                                : "?",
                            style: TextStyle(
                              fontSize: 24.sp,
                              color: const Color(0xFF26A69A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 15.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.employeeName,
                                style: GoogleFonts.poppins(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (request.employeeId != null)
                                Text(
                                  "ID: ${request.employeeId}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.sp,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 25.h),

                    // Leave Information Grid
                    _buildDetailRow("Leave Type", request.leaveType),
                    _buildDetailRow("Applied Date", request.appliedDate ?? "N/A"),
                    _buildDetailRow(
                      "Start Date",
                      request.leaveStartDate ?? "N/A",
                    ),
                    _buildDetailRow("End Date", request.leaveEndDate ?? "N/A"),
                    _buildDetailRow("Total Days", request.totalDays ?? "N/A"),
                    _buildDetailRow(
                      "Balance Leave",
                      request.balanceLeave ?? "N/A",
                    ),

                    SizedBox(height: 15.h),
                    Text(
                      "Reason",
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        request.reason ?? "No reason provided",
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    // Image Section
                    if (request.attachment != null &&
                        request.attachment!.isNotEmpty) ...[
                      SizedBox(height: 25.h),
                      Text(
                        "Attachment",
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 10.h),
                      _buildImagePreview(request.attachment!),
                    ],
                    SizedBox(height: 30.h),
                  ],
                ),
              ),
            ),

            // Action Buttons at Bottom
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        final TextEditingController rejectReasonController =
                            TextEditingController();
                        _showRejectDialog(
                          context,
                          request,
                          rejectReasonController,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        "Reject",
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 15.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _approveRequest(context, request);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        backgroundColor: Colors.green,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        "Approve",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// Build all possible URLs to try for a given attachment filename/path
  List<String> _buildAttachmentUrls(String file) {
    if (file.startsWith('http')) return [file];

    final List<String> urls = [];
    final String baseTotal = "https://erpsmart.in/total";
    final String baseRoot = "https://erpsmart.in";
    final String filename = file.split('/').last;

    if (file.startsWith('uploads/')) {
      // e.g. "uploads/leave_attachments/leave_xxx.png"
      urls.add("$baseTotal/$file");                                       // /total/uploads/leave_attachments/...
      urls.add("$baseRoot/$file");                                         // /uploads/leave_attachments/...
      urls.add("$baseTotal/v2/$file");                                    // /total/v2/uploads/leave_attachments/...
      urls.add("$baseTotal/v2/uploads/leave_attachments/$filename");      // /total/v2/uploads/leave_attachments/<filename>
      urls.add("$baseTotal/uploads/$filename");                           // /total/uploads/<filename>
    } else {
      // simple filename like "leave_2_20260402_163816.jpg"
      urls.add("$baseTotal/v2/uploads/$file");                          // /total/v2/uploads/<file>
      urls.add("$baseTotal/uploads/$file");                             // /total/uploads/<file>
      urls.add("$baseRoot/uploads/$file");                              // /uploads/<file>
      urls.add("$baseTotal/uploads/leave_attachments/$file");           // /total/uploads/leave_attachments/<file>
      urls.add("$baseTotal/v2/uploads/leave_attachments/$file");        // /total/v2/uploads/leave_attachments/<file>
    }
    return urls;
  }

  Widget _buildImagePreview(String attachment) {
    List<String> files = attachment
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (files.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: files.map((file) {
        final List<String> urlsToTry = _buildAttachmentUrls(file);
        // Log all URLs to console to help identify working path
        debugPrint("[Attachment] Trying URLs for '$file':");
        for (var u in urlsToTry) debugPrint("  → $u");

        return _AttachmentWidget(
          file: file,
          urlsToTry: urlsToTry,
        );
      }).toList(),
    );
  }

  void _showRejectDialog(
    BuildContext context,
    LeaveRequestData request,
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
              final response = await LeaveApi.updateLeaveStatus(
                leaveId: request.id.toString(),
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
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }
}

/// A widget that tries multiple image URLs in sequence, then falls back to an
/// "Open in Browser" button so the admin can view the file directly.
class _AttachmentWidget extends StatefulWidget {
  final String file;
  final List<String> urlsToTry;

  const _AttachmentWidget({required this.file, required this.urlsToTry});

  @override
  State<_AttachmentWidget> createState() => _AttachmentWidgetState();
}

class _AttachmentWidgetState extends State<_AttachmentWidget> {
  int _currentIndex = 0;
  bool _allFailed = false;

  @override
  Widget build(BuildContext context) {
    if (_allFailed || widget.urlsToTry.isEmpty) {
      return _buildFallbackButton();
    }

    final String currentUrl = widget.urlsToTry[_currentIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 250.h,
          margin: EdgeInsets.only(bottom: 8.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Image.network(
              currentUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                debugPrint("[Attachment] FAILED: $currentUrl → $error");
                // Try next URL
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      if (_currentIndex < widget.urlsToTry.length - 1) {
                        _currentIndex++;
                      } else {
                        _allFailed = true;
                      }
                    });
                  }
                });
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  debugPrint("[Attachment] SUCCESS: $currentUrl");
                  return child;
                }
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                    color: const Color(0xFF26A69A),
                  ),
                );
              },
            ),
          ),
        ),
        // Always show "Open in Browser" below the image for direct access
        _buildOpenButton(widget.urlsToTry.first),
        SizedBox(height: 15.h),
      ],
    );
  }

  Widget _buildFallbackButton() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 15.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.insert_drive_file_outlined,
              color: Colors.orange.shade700, size: 40.sp),
          SizedBox(height: 8.h),
          Text(
            "Cannot preview image",
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade800,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            widget.file.split('/').last,
            style: GoogleFonts.poppins(
              fontSize: 10.sp,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 12.h),
          // Show buttons for each URL to test
          ...widget.urlsToTry.take(2).map((url) => Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: _buildOpenButton(url),
          )),
        ],
      ),
    );
  }

  Widget _buildOpenButton(String url) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final uri = Uri.parse(url);
          try {
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              debugPrint("[Attachment] Cannot launch: $url");
            }
          } catch (e) {
            debugPrint("[Attachment] Launch error: $e");
          }
        },
        icon: Icon(Icons.open_in_new, size: 16.sp),
        label: Text(
          "Open Attachment",
          style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF26A69A),
          side: const BorderSide(color: Color(0xFF26A69A)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          padding: EdgeInsets.symmetric(vertical: 10.h),
        ),
      ),
    );
  }
}
