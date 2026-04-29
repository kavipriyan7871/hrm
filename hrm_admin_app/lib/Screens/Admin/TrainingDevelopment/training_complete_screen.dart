import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class TrainingCompleteScreen extends StatelessWidget {
  const TrainingCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> completed = [
      {
        "name": "Kavi Priyan",
        "title": "Flutter Basics",
        "date": "20 Mar 2024",
        "grade": "A+",
        "certId": "CERT-2045-KP",
        "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Kavi",
      },
      {
        "name": "Arun Kumar",
        "title": "React Native Intro",
        "date": "15 Mar 2024",
        "grade": "A",
        "certId": "CERT-2042-AK",
        "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Arun",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          "Training Completion",
          style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: completed.length,
        itemBuilder: (context, index) => _completeCard(completed[index]),
      ),
    );
  }

  Widget _completeCard(Map<String, dynamic> data) {
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
                     Text(data['title'], style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.teal, fontWeight: FontWeight.w600)),
                   ],
                 ),
               ),
               Icon(Icons.check_circle_outline, color: Colors.green, size: 22.sp),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               _tile("Grade", data['grade']),
               _tile("Completion Date", data['date']),
               _tile("Certificate ID", data['certId']),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
               TextButton.icon(
                 onPressed: () {},
                 icon: Icon(Icons.file_download_outlined, size: 16.sp),
                 label: Text("Certificate", style: GoogleFonts.poppins(fontSize: 11.sp, fontWeight: FontWeight.w600)),
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
