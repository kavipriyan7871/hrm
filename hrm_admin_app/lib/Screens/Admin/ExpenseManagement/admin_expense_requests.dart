import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../Utils/shared_prefs_util.dart';
import '../../../Models/expense_api.dart';
import 'dart:convert';

class AdminExpenseRequestsScreen extends StatefulWidget {
  final bool showAppBar;
  final bool isEmbedded;
  final dynamic specificRequest;

  const AdminExpenseRequestsScreen({
    super.key,
    this.showAppBar = true,
    this.isEmbedded = false,
    this.specificRequest,
  });

  @override
  State<AdminExpenseRequestsScreen> createState() =>
      _AdminExpenseRequestsScreenState();
}

class _AdminExpenseRequestsScreenState
    extends State<AdminExpenseRequestsScreen> {
  List<dynamic> _expenseRequests = [];
  bool _isLoading = true;
  String _error = "";

  @override
  void initState() {
    super.initState();
    _fetchExpenseRequests();
  }

  Future<void> _fetchExpenseRequests() async {
    if (widget.specificRequest != null) {
      if (mounted) {
        setState(() {
          _expenseRequests = [widget.specificRequest];
          _isLoading = false;
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final res = await ExpenseApi.fetchExpenseRequests();

      if (mounted) {
        if (res['error'] == false || res['error'] == "false") {
          setState(() {
            _expenseRequests = res['data'] ?? [];
            
            // Sort by ID descending (Newest first)
            _expenseRequests.sort((a, b) {
              int idA = int.tryParse(a['id']?.toString() ?? "0") ?? 0;
              int idB = int.tryParse(b['id']?.toString() ?? "0") ?? 0;
              return idB.compareTo(idA);
            });

            _isLoading = false;
          });
        } else {
          setState(() {
            _error = res['message'] ?? "Failed to load requests";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showAppBar) {
      return _buildContent();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Expense Requests",
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFF26A69A)))
        : _error.isNotEmpty
            ? Center(child: Text(_error))
            : Column(
                children: [
                  if (!widget.isEmbedded) _buildSummaryBar(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _fetchExpenseRequests,
                      color: const Color(0xFF26A69A),
                      child: ListView.builder(
                        padding: EdgeInsets.all(widget.isEmbedded ? 0 : 16.w),
                        shrinkWrap: widget.isEmbedded,
                        physics: widget.isEmbedded
                            ? const NeverScrollableScrollPhysics()
                            : const AlwaysScrollableScrollPhysics(),
                        itemCount: _expenseRequests.length,
                        itemBuilder: (context, index) {
                          return _buildRequestCard(_expenseRequests[index]);
                        },
                      ),
                    ),
                  ),
                ],
              );
  }

  Widget _buildSummaryBar() {
    double totalAmt = 0;
    int pendingCount = 0;
    for (var req in _expenseRequests) {
      String status = (req['status'] ?? "").toString().toLowerCase();
      double amt = double.tryParse(req['amount']?.toString() ?? "0") ?? 0;
      totalAmt += amt;
      if (status == "pending") pendingCount++;
    }

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem("Total Exp", "₹ ${totalAmt.toStringAsFixed(0)}", Colors.blue),
          _summaryItem("Pending", "$pendingCount", Colors.orange),
          _summaryItem("List Size", "${_expenseRequests.length}", Colors.green),
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

  Widget _buildRequestCard(dynamic request) {
    final String name = request['employee_name'] ?? "Unknown";
    final String amount = request['amount']?.toString() ?? "0";
    final String status = (request['status'] ?? "pending").toString().toLowerCase();
    
    final TextEditingController approveAmountController = TextEditingController(
      text: amount.replaceAll(',', ''),
    );
    final TextEditingController rejectReasonController =
        TextEditingController();

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
                backgroundColor: const Color(0xFFF3E5F5),
                child: Text(
                  name.isNotEmpty ? name[0] : "E",
                  style: const TextStyle(
                    color: Color(0xFF7B1FA2),
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
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      request['expense_type'] ?? "Miscellaneous",
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: const Color(0xFF7B1FA2),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₹ $amount",
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    request['expense_date'] ?? "-",
                    style: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _rowInfo(Icons.history_edu_outlined, request['purpose'] ?? "No purpose provided"),
              _buildStatusBadge(status),
            ],
          ),
          if (request['attachements'] != null && request['attachements'].toString() != "[]" && request['attachements'].toString() != "null") ...[
            SizedBox(height: 12.h),
            _buildAttachmentPreview(request['attachements']),
          ],
          if (status == "pending") ...[
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
                    onPressed: () => _showApproveDialog(
                      context,
                      request,
                      approveAmountController,
                    ),
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
        ],
      ),
    );
  }

  void _showApproveDialog(
    BuildContext context,
    dynamic request,
    TextEditingController controller,
  ) {
    String selectedRole = "MD";
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            "Approve Expense",
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
                "Select Approver Role:",
                style: GoogleFonts.poppins(fontSize: 13.sp),
              ),
              SizedBox(height: 8.h),
              _buildRoleDropdown(
                selectedRole,
                (val) => setDialogState(() => selectedRole = val!),
              ),
              SizedBox(height: 16.h),
              Text(
                "Claimed: ₹ ${request['amount']}",
                style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.grey),
              ),
              SizedBox(height: 8.h),
              Text(
                "Enter Approved Amount:",
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: "₹ ",
                  hintText: "Enter amount...",
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
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Approved by $selectedRole: ₹ ${controller.text}",
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                "Approve",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(
    BuildContext context,
    dynamic request,
    TextEditingController controller,
  ) {
    String selectedRole = "MD";
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            "Reject Expense",
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
                "Select Role to Reject:",
                style: GoogleFonts.poppins(fontSize: 13.sp),
              ),
              SizedBox(height: 8.h),
              _buildRoleDropdown(
                selectedRole,
                (val) => setDialogState(() => selectedRole = val!),
              ),
              SizedBox(height: 16.h),
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
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Rejected by $selectedRole: ${controller.text}",
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                "Reject",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleDropdown(String current, Function(String?) onChanged) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          isExpanded: true,
          style: GoogleFonts.poppins(
            color: const Color(0xFF26A69A),
            fontWeight: FontWeight.w600,
          ),
          items: ["MD", "HR", "TL"].map((String type) {
            return DropdownMenuItem<String>(value: type, child: Text(type));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status == "approved") color = Colors.green;
    if (status == "rejected") color = Colors.red;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAttachmentPreview(dynamic attachments) {
    List<String> urls = [];
    try {
      if (attachments is String) {
        var decoded = jsonDecode(attachments);
        if (decoded is List) {
          urls = decoded.map((e) => e.toString()).toList();
        }
      } else if (attachments is List) {
        urls = attachments.map((e) => e.toString()).toList();
      }
    } catch (e) {
      debugPrint("Error parsing attachments: $e");
    }

    if (urls.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Attachments:",
          style: GoogleFonts.poppins(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          height: 80.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: urls.length,
            itemBuilder: (context, index) {
              String url = urls[index];
              // Handle escaped slashes if any
              url = url.replaceAll("\\/", "/");
              
              return GestureDetector(
                onTap: () => _showImageDialog(context, url),
                child: Container(
                  width: 80.w,
                  margin: EdgeInsets.only(right: 8.w),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade100,
                        child: Icon(Icons.broken_image, color: Colors.grey, size: 24.sp),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showImageDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            SizedBox(height: 16.h),
            CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16.sp, color: Colors.grey),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
