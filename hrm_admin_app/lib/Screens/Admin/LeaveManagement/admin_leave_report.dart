import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../Models/leave_api.dart';

class AdminLeaveReportScreen extends StatefulWidget {
  const AdminLeaveReportScreen({super.key});

  @override
  State<AdminLeaveReportScreen> createState() => _AdminLeaveReportScreenState();
}

class _AdminLeaveReportScreenState extends State<AdminLeaveReportScreen> {
  List<LeaveRequestData>? _reportData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final response = await LeaveApi.fetchLeaveRequests();
      setState(() {
        // Only show Accepted/Approved leaves in the Report
        _reportData = response.data.where((r) {
          final s = r.status?.toLowerCase();
          return s == 'accept' || s == 'approved';
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching report: $e");
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? d) {
    if (d == null || d.isEmpty) return "N/A";
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          "Leave Report",
          style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading && _reportData == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterBar(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshData,
                    child: (_reportData == null || _reportData!.isEmpty)
                        ? const Center(child: Text("No records found."))
                        : ListView.builder(
                            padding: EdgeInsets.all(16.w),
                            itemCount: _reportData!.length,
                            itemBuilder: (context, index) =>
                                _buildReportCard(_reportData![index]),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 16.sp, color: Colors.blueGrey),
                  SizedBox(width: 8.w),
                  Text("Month: April 2024", style: GoogleFonts.poppins(fontSize: 12.sp)),
                  const Spacer(),
                  Icon(Icons.arrow_drop_down, size: 20.sp),
                ],
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: const Color(0xFF26A69A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.filter_list, color: const Color(0xFF26A69A), size: 20.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(LeaveRequestData record) {
    Color statusColor = Colors.green; // Default for report (assuming accepted)
    String statusText = record.status ?? "Accepted";

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22.r,
                  backgroundColor: const Color(0xFFE0F2F1),
                  child: Text(
                    record.employeeName.isNotEmpty
                        ? record.employeeName[0].toUpperCase()
                        : "?",
                    style: TextStyle(
                      color: const Color(0xFF26A69A),
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.employeeName,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${record.employeeId ?? 'ID'} | ${record.department ?? 'Dept'}",
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.poppins(
                      color: statusColor,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _detailCol("Leave Type", record.leaveType),
                _detailCol(
                  "Duration",
                  "${_formatDate(record.leaveStartDate)} - ${_formatDate(record.leaveEndDate)}",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey)),
        Text(value, style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
