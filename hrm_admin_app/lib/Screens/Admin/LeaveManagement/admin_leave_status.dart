import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminLeaveStatusScreen extends StatefulWidget {
  const AdminLeaveStatusScreen({super.key});

  @override
  State<AdminLeaveStatusScreen> createState() => _AdminLeaveStatusScreenState();
}

class _AdminLeaveStatusScreenState extends State<AdminLeaveStatusScreen> {
  final List<Map<String, dynamic>> _processedLeaves = [
    {
      "name": "Kavi Priyan",
      "type": "Sick Leave",
      "duration": "2 Days (04-05 Apr)",
      "status": "Approved",
      "processedBy": "TL",
      "date": "02 Apr 2024",
      "reason": "Fever and cold symptom",
    },
    {
      "name": "Arun Kumar",
      "type": "Casual Leave",
      "duration": "1 Day (10 Apr)",
      "status": "Rejected",
      "processedBy": "HR",
      "date": "01 Apr 2024",
      "reason": "Personal work at hometown",
      "rejectReason": "Insufficient staff for that day",
    },
    {
      "name": "Santhosh Mani",
      "type": "Annual Leave",
      "duration": "5 Days (15-19 Apr)",
      "status": "Approved",
      "processedBy": "MD",
      "date": "28 Mar 2024",
      "reason": "Family vacation",
    },
    {
       "name": "Deepak Raj",
       "type": "Casual Leave",
       "duration": "1 Day (12 Apr)",
       "status": "Approved",
       "processedBy": "HR",
       "date": "03 Apr 2024",
       "reason": "Medical Checkup",
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: Text(
          "Leave Status History",
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSummaryHeader(),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: _processedLeaves.length,
              itemBuilder: (context, index) => _buildStatusCard(_processedLeaves[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    int approved = _processedLeaves.where((l) => l['status'] == 'Approved').length;
    int rejected = _processedLeaves.where((l) => l['status'] == 'Rejected').length;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem("Total Processed", "${_processedLeaves.length}", Colors.teal),
          _summaryItem("Approved", "$approved", Colors.green),
          _summaryItem("Rejected", "$rejected", Colors.red),
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
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11.sp,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(Map<String, dynamic> leave) {
    bool isApproved = leave['status'] == 'Approved';

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isApproved ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                child: Icon(
                  isApproved ? Icons.check_circle_outline : Icons.cancel_outlined,
                  color: isApproved ? Colors.green : Colors.red,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leave['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      leave['type'],
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isApproved ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  leave['status'],
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _infoRow(Icons.event_note, "Duration", leave['duration']),
          SizedBox(height: 8.h),
          _infoRow(Icons.person_search_outlined, "${leave['status']} By", leave['processedBy'], isBold: true),
          SizedBox(height: 8.h),
          _infoRow(Icons.notes, "Staff Reason", leave['reason']),
          if (!isApproved && leave['rejectReason'] != null) ...[
            SizedBox(height: 8.h),
            _infoRow(Icons.warning_amber_rounded, "Reject Reason", leave['rejectReason'], color: Colors.red),
          ],
          SizedBox(height: 12.h),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "Processed on: ${leave['date']}",
              style: GoogleFonts.poppins(
                fontSize: 10.sp,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String text, {bool isBold = false, Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 14.sp, color: color ?? Colors.blueGrey),
        SizedBox(width: 8.w),
        Text(
          "$label: ",
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            color: Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
