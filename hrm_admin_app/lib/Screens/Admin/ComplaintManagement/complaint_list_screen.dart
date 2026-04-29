import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class EmployeeComplaintListScreen extends StatefulWidget {
  const EmployeeComplaintListScreen({super.key});

  @override
  State<EmployeeComplaintListScreen> createState() => _EmployeeComplaintListScreenState();
}

class _EmployeeComplaintListScreenState extends State<EmployeeComplaintListScreen> {
  final List<Map<String, dynamic>> _complaints = [
    {
      "id": "TKT-1024",
      "name": "Kavi Priyan",
      "dept": "Development",
      "subject": "System Hardware Issue",
      "status": "In-Progress",
      "date": "04 Apr 2024",
      "priority": "High",
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Kavi",
    },
    {
      "id": "TKT-0985",
      "name": "Arun Kumar",
      "dept": "HR",
      "subject": "Workspace Airconditioning",
      "status": "Open",
      "date": "03 Apr 2024",
      "priority": "Medium",
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Arun",
    },
    {
       "id": "TKT-0812",
       "name": "Santhosh Mani",
       "dept": "Creative",
       "subject": "Team Communication Delay",
       "status": "Closed",
       "date": "28 Mar 2024",
       "priority": "Low",
       "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Santhosh",
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          "Employee Complaints",
          style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildStatusTabs(),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: _complaints.length,
              itemBuilder: (context, index) => _complaintCard(_complaints[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabs() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: [
            _tab("All", true),
            _tab("Open", false),
            _tab("In-Progress", false),
            _tab("Closed", false),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, bool active) {
    return Container(
      margin: EdgeInsets.only(right: 8.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF26A69A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: active ? Colors.white : Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _complaintCard(Map<String, dynamic> ticket) {
    Color statusColor;
    switch (ticket['status']) {
      case 'Open': statusColor = Colors.orange; break;
      case 'In-Progress': statusColor = Colors.blue; break;
      case 'Closed': statusColor = Colors.green; break;
      default: statusColor = Colors.grey;
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(ticket['id'], style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.bold, color: const Color(0xFF26A69A))),
              _badge(ticket['status'], statusColor),
            ],
          ),
          SizedBox(height: 12.h),
          Text(ticket['subject'], style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          Row(
            children: [
              CircleAvatar(radius: 12.r, backgroundImage: NetworkImage(ticket['photo'])),
              SizedBox(width: 8.w),
              Text(ticket['name'], style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w500)),
              const Spacer(),
              Text(ticket['date'], style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.grey)),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               _rowInfo("Priority", ticket['priority'], ticket['priority'] == 'High' ? Colors.red : Colors.blueGrey),
               ElevatedButton(
                 onPressed: () => _showStatusUpdateSheet(ticket),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: const Color(0xFFF1F5F9),
                   foregroundColor: const Color(0xFF26A69A),
                   elevation: 0,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                 ),
                 child: Text("Update Status", style: GoogleFonts.poppins(fontSize: 11.sp, fontWeight: FontWeight.w600)),
               )
             ],
          ),
        ],
      ),
    );
  }

  void _showStatusUpdateSheet(Map<String, dynamic> ticket) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Update Ticket Status", style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            Text(ticket['id'], style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey)),
            SizedBox(height: 20.h),
            _statusOption("Open", Colors.orange),
            _statusOption("In-Progress", Colors.blue),
            _statusOption("Closed", Colors.green),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _statusOption(String status, Color color) {
    return ListTile(
      leading: CircleAvatar(radius: 6, backgroundColor: color),
      title: Text(status, style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w500)),
      onTap: () {
        // In a real app, update state/API here
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Status updated to $status"),
            backgroundColor: const Color(0xFF26A69A),
          ),
        );
      },
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6.r)),
      child: Text(text, style: GoogleFonts.poppins(fontSize: 10.sp, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _rowInfo(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey)),
        Text(value, style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
