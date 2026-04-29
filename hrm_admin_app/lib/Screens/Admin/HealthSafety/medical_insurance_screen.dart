import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class MedicalInsuranceScreen extends StatelessWidget {
  const MedicalInsuranceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> insuranceData = [
      {
        "name": "Kavi Priyan",
        "id": "EMP001",
        "policy": "Star Health Comprehensive",
        "sumInsured": "₹5,00,000",
        "premium": "₹12,500/yr",
        "validity": "31 Mar 2025",
        "status": "Active",
        "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Kavi",
      },
      {
        "name": "Arun Kumar",
        "id": "EMP002",
        "policy": "HDFC Ergo Family Floater",
        "sumInsured": "₹3,00,000",
        "premium": "₹9,800/yr",
        "validity": "01 Jan 2025",
        "status": "Active",
        "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Arun",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          "Medical Insurance Details",
          style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: insuranceData.length,
        itemBuilder: (context, index) => _insuranceCard(insuranceData[index]),
      ),
    );
  }

  Widget _insuranceCard(Map<String, dynamic> data) {
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
               _badge(data['status'], Colors.green),
            ],
          ),
          const Divider(height: 24),
          _detailRow("Insurance Policy", data['policy']),
          _detailRow("Sum Insured", data['sumInsured']),
          _detailRow("Premium", data['premium']),
          _detailRow("Valid Until", data['validity']),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
               TextButton.icon(
                 onPressed: () {},
                 icon: Icon(Icons.download_outlined, size: 16.sp),
                 label: Text("Policy Copy", style: GoogleFonts.poppins(fontSize: 11.sp, fontWeight: FontWeight.w600)),
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

  Widget _badge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6.r)),
      child: Text(text, style: GoogleFonts.poppins(fontSize: 10.sp, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
