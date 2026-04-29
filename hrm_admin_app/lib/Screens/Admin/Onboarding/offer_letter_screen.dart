import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class OfferLetterScreen extends StatefulWidget {
  const OfferLetterScreen({super.key});

  @override
  State<OfferLetterScreen> createState() => _OfferLetterScreenState();
}

class _OfferLetterScreenState extends State<OfferLetterScreen> {
  final List<Map<String, dynamic>> _candidates = [
    {
      "name": "Kavi Priyan",
      "designation": "Software Engineer",
      "ctc": "6.0 LPA",
      "status": "Generated",
      "date": "04 Apr 2024",
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Kavi",
    },
    {
      "name": "Arun Kumar",
      "designation": "HR Generalist",
      "ctc": "4.5 LPA",
      "status": "Pending",
      "date": "03 Apr 2024",
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Arun",
    },
    {
       "name": "Santhosh Mani",
       "designation": "UI/UX Designer",
       "ctc": "5.5 LPA",
       "status": "Generated",
       "date": "02 Apr 2024",
       "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Santhosh",
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          "Offer Letter Generation",
          style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSummaryHeader(),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: _candidates.length,
              itemBuilder: (context, index) => _candidateCard(_candidates[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat("Total Cand.", "12", Colors.blue),
          _stat("Generated", "8", Colors.teal),
          _stat("Pending", "4", Colors.orange),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 20.sp, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.grey)),
      ],
    );
  }

  Widget _candidateCard(Map<String, dynamic> candidate) {
    bool isPending = candidate['status'] == 'Pending';
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
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(radius: 20.r, backgroundImage: NetworkImage(candidate['photo'])),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(candidate['name'], style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                    Text(candidate['designation'], style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: (isPending ? Colors.orange : Colors.green).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  candidate['status'],
                  style: GoogleFonts.poppins(fontSize: 10.sp, fontWeight: FontWeight.bold, color: isPending ? Colors.orange : Colors.green),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Package (CTC)", style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey)),
                  Text(candidate['ctc'], style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.w600)),
                ],
              ),
              if (isPending)
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF26A69A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  child: Text("Generate Letter", style: GoogleFonts.poppins(fontSize: 10.sp, fontWeight: FontWeight.w600)),
                )
              else
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.download, size: 14.sp),
                  label: Text("Download PDF", style: GoogleFonts.poppins(fontSize: 10.sp, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal,
                    side: const BorderSide(color: Colors.teal),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
