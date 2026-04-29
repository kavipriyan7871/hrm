import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class PerformanceReportsScreen extends StatelessWidget {
  const PerformanceReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> reports = [
      {
        "name": "Kavi Priyan",
        "id": "EMP001",
        "productivity": "95%",
        "quality": "90%",
        "rating": "4.8/5.0",
        "trend": "Up",
        "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Kavi",
      },
      {
        "name": "Arun Kumar",
        "id": "EMP002",
        "productivity": "82%",
        "quality": "85%",
        "rating": "4.2/5.0",
        "trend": "Stable",
        "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Arun",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          "Performance Reports",
          style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: reports.length,
        itemBuilder: (context, index) => _performanceCard(reports[index]),
      ),
    );
  }

  Widget _performanceCard(Map<String, dynamic> data) {
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
        children: [
          Row(
            children: [
               CircleAvatar(radius: 20.r, backgroundImage: NetworkImage(data['photo'])),
               SizedBox(width: 12.w),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(data['name'], style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                     Text(data['id'], style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.grey)),
                   ],
                 ),
               ),
               Icon(
                 data['trend'] == 'Up' ? Icons.trending_up : Icons.trending_flat,
                 color: data['trend'] == 'Up' ? Colors.green : Colors.orange,
                 size: 24.sp,
               ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               _tile("Productivity", data['productivity']),
               _tile("Quality Index", data['quality']),
               Column(
                 children: [
                    Text("Overall Rating", style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey)),
                    Row(
                      children: [
                         Icon(Icons.star, color: Colors.amber, size: 14.sp),
                         SizedBox(width: 4.w),
                         Text(data['rating'], style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                      ],
                    ),
                 ],
               ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
               TextButton.icon(
                 onPressed: () {},
                 icon: Icon(Icons.analytics_outlined, size: 16.sp),
                 label: Text("Deep Analysis", style: GoogleFonts.poppins(fontSize: 11.sp, fontWeight: FontWeight.w600)),
                 style: TextButton.styleFrom(foregroundColor: Colors.teal),
               ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tile(String label, String value) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey)),
        Text(value, style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
