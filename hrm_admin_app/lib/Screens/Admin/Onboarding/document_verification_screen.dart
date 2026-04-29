import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class DocumentVerificationScreen extends StatefulWidget {
  const DocumentVerificationScreen({super.key});

  @override
  State<DocumentVerificationScreen> createState() => _DocumentVerificationScreenState();
}

class _DocumentVerificationScreenState extends State<DocumentVerificationScreen> {
  final List<Map<String, dynamic>> _candidates = [
    {
      "name": "Kavi Priyan",
      "id": "CAND001",
      "pancard": true,
      "aadhar": true,
      "degree": true,
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Kavi",
    },
    {
      "name": "Arun Kumar",
      "id": "CAND002",
      "pancard": true,
      "aadhar": true,
      "degree": false,
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Arun",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          "Document Verification",
          style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _candidates.length,
        itemBuilder: (context, index) => _candidateCard(_candidates[index]),
      ),
    );
  }

  Widget _candidateCard(Map<String, dynamic> candidate) {
    bool isComplete = candidate['pancard'] && candidate['aadhar'] && candidate['degree'];
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
                    Text(candidate['id'], style: GoogleFonts.poppins(fontSize: 11.sp, color: Colors.grey)),
                  ],
                ),
              ),
              if (isComplete)
                const Icon(Icons.check_circle, color: Colors.green)
              else
                const Icon(Icons.warning_amber, color: Colors.orange),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _docItem("PAN Card", candidate['pancard']),
              _docItem("Aadhar Card", candidate['aadhar']),
              _docItem("Degree Cert.", candidate['degree']),
            ],
          ),
          if (!isComplete) ...[
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF26A69A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                minimumSize: Size(double.infinity, 36.h),
              ),
              child: Text("Request Pending Documents", style: GoogleFonts.poppins(fontSize: 11.sp, fontWeight: FontWeight.w600)),
            ),
          ]
        ],
      ),
    );
  }

  Widget _docItem(String label, bool verified) {
    return Column(
      children: [
        Icon(verified ? Icons.verified : Icons.error_outline, color: verified ? Colors.green : Colors.grey.shade300, size: 20.sp),
        SizedBox(height: 4.h),
        Text(label, style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.blueGrey)),
      ],
    );
  }
}
