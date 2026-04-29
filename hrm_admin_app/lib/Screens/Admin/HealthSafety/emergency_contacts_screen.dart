import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> contactData = [
      {
        "name": "Kavi Priyan",
        "id": "EMP001",
        "contactName": "Sudhakar (Father)",
        "phone": "+91 98765 43210",
        "altPhone": "+91 98765 01234",
        "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Kavi",
      },
      {
        "name": "Arun Kumar",
        "id": "EMP002",
        "contactName": "Deepa (Spouse)",
        "phone": "+91 87654 32109",
        "altPhone": "+91 87654 09876",
        "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Arun",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          "Emergency Contacts",
          style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: contactData.length,
        itemBuilder: (context, index) => _contactCard(contactData[index]),
      ),
    );
  }

  Widget _contactCard(Map<String, dynamic> data) {
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
               Icon(Icons.contact_phone_outlined, color: Colors.orange, size: 20.sp),
            ],
          ),
          const Divider(height: 24),
          _detailRow("Primary Contact", data['contactName']),
          _detailRow("Phone Number", data['phone']),
          _detailRow("Alt Number", data['altPhone']),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
               TextButton.icon(
                 onPressed: () {},
                 icon: Icon(Icons.call, size: 16.sp),
                 label: Text("Quick Call", style: GoogleFonts.poppins(fontSize: 11.sp, fontWeight: FontWeight.w600)),
                 style: TextButton.styleFrom(foregroundColor: Colors.teal),
               ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.blueGrey)),
          Text(value, style: GoogleFonts.poppins(fontSize: 11.sp, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
