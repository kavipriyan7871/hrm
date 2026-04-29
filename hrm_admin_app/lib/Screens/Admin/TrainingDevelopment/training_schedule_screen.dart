import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class TrainingScheduleScreen extends StatelessWidget {
  const TrainingScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> schedules = [
      {
        "title": "Flutter Advanced Patterns",
        "trainer": "Suresh Mani",
        "date": "10 Apr 2024",
        "time": "10:00 AM - 01:00 PM",
        "mode": "Online (MS Teams)",
        "status": "Upcoming",
      },
      {
        "title": "Soft Skills Workshop",
        "trainer": "Priya Dharshini",
        "date": "12 Apr 2024",
        "time": "02:30 PM - 04:30 PM",
        "mode": "Conference Room A",
        "status": "Upcoming",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          "Training Schedule",
          style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: schedules.length,
        itemBuilder: (context, index) => _scheduleCard(schedules[index]),
      ),
    );
  }

  Widget _scheduleCard(Map<String, dynamic> data) {
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
               Expanded(child: Text(data['title'], style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.teal))),
               _badge(data['status'], Colors.blue),
            ],
          ),
          const Divider(height: 24),
          _rowItem(Icons.person_outline, "Trainer", data['trainer']),
          _rowItem(Icons.calendar_today_outlined, "Date", data['date']),
          _rowItem(Icons.access_time, "Timeline", data['time']),
          _rowItem(Icons.location_on_outlined, "Venue/Mode", data['mode']),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
               ElevatedButton(
                 onPressed: () {},
                 style: ElevatedButton.styleFrom(
                   backgroundColor: const Color(0xFF26A69A),
                   foregroundColor: Colors.white,
                   elevation: 0,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                 ),
                 child: Text("Join / Attend", style: GoogleFonts.poppins(fontSize: 11.sp, fontWeight: FontWeight.w600)),
               ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rowItem(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: Colors.blueGrey),
          SizedBox(width: 8.w),
          Text("$label: ", style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey)),
          Text(value, style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w500)),
        ],
      ),
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
