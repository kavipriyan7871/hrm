import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class HRPoliciesScreen extends StatefulWidget {
  const HRPoliciesScreen({super.key});

  @override
  State<HRPoliciesScreen> createState() => _HRPoliciesScreenState();
}

class _HRPoliciesScreenState extends State<HRPoliciesScreen> {
  final List<Map<String, dynamic>> _policies = [
    {
      "title": "Leave Policy 2024",
      "category": "Attendance",
      "date": "01 Jan 2024",
      "icon": Icons.event_note,
      "color": Colors.teal,
    },
    {
      "title": "Remote Work Guidelines",
      "category": "Operations",
      "date": "15 Jan 2024",
      "icon": Icons.home_work_outlined,
      "color": Colors.blue,
    },
    {
      "title": "Code of Conduct",
      "category": "General",
      "date": "01 Mar 2024",
      "icon": Icons.assignment_outlined,
      "color": Colors.purple,
    },
    {
       "title": "Sexual Harassment Prevention",
       "category": "Safety",
       "date": "10 Mar 2024",
       "icon": Icons.security_outlined,
       "color": Colors.red,
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          "HR Policies",
          style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _policies.length,
        itemBuilder: (context, index) => _policyCard(_policies[index]),
      ),
    );
  }

  Widget _policyCard(Map<String, dynamic> policy) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: (policy['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(policy['icon'], color: policy['color'] as Color, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(policy['title'], style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                Text("${policy['category']} | ${policy['date']}", style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.visibility_outlined, color: Colors.blueGrey, size: 20.sp),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
          ),
        ],
      ),
    );
  }
}
