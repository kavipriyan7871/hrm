import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class SalaryStructureScreen extends StatefulWidget {
  const SalaryStructureScreen({super.key});

  @override
  State<SalaryStructureScreen> createState() => _SalaryStructureScreenState();
}

class _SalaryStructureScreenState extends State<SalaryStructureScreen> {
  final List<Map<String, dynamic>> _salaryStructures = [
    {
      "name": "Kavi Priyan",
      "id": "EMP001",
      "basis": "Monthly",
      "basic": 25000,
      "hra": 5000,
      "conveyance": 2000,
      "other": 1500,
      "total": 33500,
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Kavi",
    },
    {
      "name": "Arun Kumar",
      "id": "EMP002",
      "basis": "Monthly",
      "basic": 18000,
      "hra": 3500,
      "conveyance": 1500,
      "other": 1000,
      "total": 24000,
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Arun",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          "Salary Structure Setup",
          style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _salaryStructures.length,
        itemBuilder: (context, index) => _structureCard(_salaryStructures[index]),
      ),
    );
  }

  Widget _structureCard(Map<String, dynamic> struct) {
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
               CircleAvatar(radius: 20.r, backgroundImage: NetworkImage(struct['photo'])),
               SizedBox(width: 12.w),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(struct['name'], style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                     Text("${struct['id']} | ${struct['basis']}", style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.grey)),
                   ],
                 ),
               ),
               IconButton(onPressed: () {}, icon: Icon(Icons.edit_note_outlined, color: Colors.teal, size: 22.sp)),
            ],
          ),
          const Divider(height: 24),
          _detailRow("Basic Salary", "₹${struct['basic']}"),
          _detailRow("HRA", "₹${struct['hra']}"),
          _detailRow("Conveyance", "₹${struct['conveyance']}"),
          _detailRow("Other Allowances", "₹${struct['other']}"),
          const Divider(),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total Gross Salary", style: GoogleFonts.poppins(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.indigo)),
                Text("₹${struct['total']}", style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.indigo)),
              ],
            ),
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
