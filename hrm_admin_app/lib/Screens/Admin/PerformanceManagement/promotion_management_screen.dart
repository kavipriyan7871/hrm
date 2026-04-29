import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class PromotionManagementScreen extends StatelessWidget {
  const PromotionManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> promotions = [
      {
        "name": "Kavi Priyan",
        "id": "EMP001",
        "currentRole": "Junior Developer",
        "targetRole": "Senior Developer",
        "score": "92/100",
        "status": "Shortlisted",
        "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Kavi",
      },
      {
        "name": "Arun Kumar",
        "id": "EMP002",
        "currentRole": "HR Executive",
        "targetRole": "HR Manager",
        "score": "88/100",
        "status": "Review Pending",
        "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Arun",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          "Promotion Management",
          style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: promotions.length,
        itemBuilder: (context, index) => _promotionCard(promotions[index]),
      ),
    );
  }

  Widget _promotionCard(Map<String, dynamic> data) {
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
               _badge(data['status'], Colors.indigo),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               _tile("Current Role", data['currentRole']),
               Icon(Icons.arrow_right_alt, color: Colors.grey),
               _tile("Target Role", data['targetRole']),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Text("Appraisal Score", style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey)),
                    Text(data['score'], style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.teal)),
                 ],
               ),
               ElevatedButton(
                 onPressed: () {},
                 style: ElevatedButton.styleFrom(
                   backgroundColor: const Color(0xFF26A69A),
                   foregroundColor: Colors.white,
                   elevation: 0,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                 ),
                 child: Text("Recommend", style: GoogleFonts.poppins(fontSize: 11.sp, fontWeight: FontWeight.w600)),
               ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey)),
        Text(value, style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6.r)),
      child: Text(text, style: GoogleFonts.poppins(fontSize: 10.sp, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
