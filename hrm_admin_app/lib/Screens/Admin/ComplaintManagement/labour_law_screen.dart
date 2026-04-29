import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class LabourLawScreen extends StatefulWidget {
  const LabourLawScreen({super.key});

  @override
  State<LabourLawScreen> createState() => _LabourLawScreenState();
}

class _LabourLawScreenState extends State<LabourLawScreen> {
  final List<Map<String, dynamic>> _laws = [
    {
      "title": "Minimum Wages Act",
      "article": "Section 3(1)",
      "desc": "Ensuring fair remuneration across different tiers of employment.",
      "color": Colors.red,
    },
    {
      "title": "Factories Act",
      "article": "Section 41-H",
      "desc": "Provisions regarding health, safety, and welfare of workers.",
      "color": Colors.orange,
    },
    {
       "title": "Maternity Benefit Act",
       "article": "Section 5",
       "desc": "Protecting the employment of women during maternity leave.",
       "color": Colors.pink,
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          "Labour Law & Regulations",
          style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _laws.length,
        itemBuilder: (context, index) => _lawCard(_laws[index]),
      ),
    );
  }

  Widget _lawCard(Map<String, dynamic> law) {
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
              Container(width: 4, height: 24, decoration: BoxDecoration(color: law['color'] as Color, borderRadius: BorderRadius.circular(2))),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(law['title'], style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                    Text(law['article'], style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Icon(Icons.gavel, color: Colors.grey.shade400, size: 20.sp),
            ],
          ),
          const Divider(height: 24),
          Text(law['desc'], style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.black87)),
          SizedBox(height: 12.h),
          InkWell(
            onTap: () {},
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("Read Full Act", style: GoogleFonts.poppins(fontSize: 11.sp, fontWeight: FontWeight.w600, color: const Color(0xFF26A69A))),
                Icon(Icons.chevron_right, color: const Color(0xFF26A69A), size: 16.sp),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
