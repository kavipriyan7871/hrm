import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class PayslipGenerationScreen extends StatefulWidget {
  const PayslipGenerationScreen({super.key});

  @override
  State<PayslipGenerationScreen> createState() => _PayslipGenerationScreenState();
}

class _PayslipGenerationScreenState extends State<PayslipGenerationScreen> {
  final List<Map<String, dynamic>> _payslipData = [
    {
      "name": "Kavi Priyan",
      "id": "EMP001",
      "month": "March 2024",
      "amount": "₹32,500",
      "status": "Generated",
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Kavi",
    },
    {
      "name": "Arun Kumar",
      "id": "EMP002",
      "month": "March 2024",
      "amount": "₹22,800",
      "status": "Ready",
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Arun",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          "Pay Slip Generation",
          style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _payslipData.length,
        itemBuilder: (context, index) => _payslipCard(_payslipData[index]),
      ),
    );
  }

  Widget _payslipCard(Map<String, dynamic> data) {
    bool isGenerated = data['status'] == 'Generated';
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
                     Text("${data['id']} | ${data['month']}", style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.grey)),
                   ],
                 ),
               ),
               Text(data['amount'], style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.indigo)),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: isGenerated 
                   ? OutlinedButton.icon(
                       onPressed: () {},
                       icon: Icon(Icons.file_download_outlined, size: 18.sp),
                       label: Text("Download PDF", style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600)),
                       style: OutlinedButton.styleFrom(
                         foregroundColor: Colors.teal,
                         side: const BorderSide(color: Colors.teal),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                       ),
                     )
                   : ElevatedButton.icon(
                       onPressed: () {
                         setState(() => data['status'] = 'Generated');
                       },
                       icon: Icon(Icons.auto_awesome, size: 18.sp),
                       label: Text("Generate Pay Slip", style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600)),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: const Color(0xFF26A69A),
                         foregroundColor: Colors.white,
                         elevation: 0,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                       ),
                     )
              ),
              if (isGenerated) ...[
                SizedBox(width: 12.w),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.share_outlined, color: Colors.blueGrey, size: 20.sp),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                )
              ]
            ],
          ),
        ],
      ),
    );
  }
}
