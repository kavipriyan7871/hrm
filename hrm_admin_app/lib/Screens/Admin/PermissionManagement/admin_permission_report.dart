import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminPermissionReportScreen extends StatefulWidget {
  const AdminPermissionReportScreen({super.key});

  @override
  State<AdminPermissionReportScreen> createState() => _AdminPermissionReportScreenState();
}

class _AdminPermissionReportScreenState extends State<AdminPermissionReportScreen> {
  final List<Map<String, dynamic>> _permissionLogs = [
    {
      "name": "Kavi Priyan",
      "id": "EMP001",
      "dept": "Development",
      "time": "09:30 AM - 10:30 AM",
      "date": "04 Apr 2024",
      "reason": "Personal work at bank",
      "status": "Approved",
      "decidedBy": "HR",
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Kavi",
    },
    {
      "name": "Arun Kumar",
      "id": "EMP002",
      "dept": "HR",
      "time": "02:00 PM - 03:00 PM",
      "date": "03 Apr 2024",
      "reason": "Family emergency",
      "status": "Rejected",
      "decidedBy": "Admin",
      "rejectReason": "High workload currently",
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Arun",
    },
    {
      "name": "Santhosh Mani",
      "id": "EMP003",
      "dept": "Creative",
      "time": "11:00 AM - 12:00 PM",
      "date": "02 Apr 2024",
      "reason": "Medical checkup",
      "status": "Approved",
      "decidedBy": "MD",
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Santhosh",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          "Permission Report",
          style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600),
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
              itemCount: _permissionLogs.length,
              itemBuilder: (context, index) => _buildReportCard(_permissionLogs[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    int approved = _permissionLogs.where((p) => p['status'] == 'Approved').length;
    int rejected = _permissionLogs.length - approved;
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statCol("Approved", "$approved", Colors.green),
          _statCol("Rejected", "$rejected", Colors.red),
          _statCol("Total Processed", "${_permissionLogs.length}", Colors.blue),
        ],
      ),
    );
  }

  Widget _statCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.grey)),
      ],
    );
  }

  Widget _buildReportCard(Map<String, dynamic> log) {
    bool isApproved = log['status'] == 'Approved';
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 22.r, backgroundImage: NetworkImage(log['photo'])),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log['name'], style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                    Text("${log['id']} | ${log['dept']}", style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: (isApproved ? Colors.green : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  log['status'],
                  style: GoogleFonts.poppins(fontSize: 10.sp, fontWeight: FontWeight.bold, color: isApproved ? Colors.green : Colors.red),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _detail("Time", log['time']),
              _detail("Date", log['date']),
              _detail("Authority", log['decidedBy']),
            ],
          ),
          SizedBox(height: 12.h),
          Text("Reason:", style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey, fontWeight: FontWeight.w600)),
          Text(log['reason'], style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.black87)),
          if (!isApproved) ...[
            SizedBox(height: 8.h),
            Text("Rejection Reason:", style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.red.shade300, fontWeight: FontWeight.w600)),
            Text(log['rejectReason'], style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.red.shade900)),
          ]
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey)),
        Text(value, style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
