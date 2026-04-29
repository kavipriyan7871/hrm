import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'candidate_recruitment.dart';

class JobOpeningsScreen extends StatefulWidget {
  const JobOpeningsScreen({super.key});

  @override
  State<JobOpeningsScreen> createState() => _JobOpeningsScreenState();
}

class _JobOpeningsScreenState extends State<JobOpeningsScreen> {
  // Mock data representing the "Candidate Recruitment" requirements
  final List<Map<String, dynamic>> jobOpenings = [
    {
      "title": "Senior Flutter Developer",
      "department": "IT Department",
      "vacancies": "03",
      "type": "Full Time",
      "experience": "3-5 Years",
      "priority": "High",
      "date": "04-04-2026",
    },
    {
      "title": "HR Executive",
      "department": "HR Department",
      "vacancies": "01",
      "type": "Full Time",
      "experience": "1-2 Years",
      "priority": "Medium",
      "date": "02-04-2026",
    },
    {
      "title": "Marketing Manager",
      "department": "Marketing",
      "vacancies": "02",
      "type": "Contract",
      "experience": "5+ Years",
      "priority": "Low",
      "date": "01-04-2026",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Job Openings",
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSummaryBar(),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: jobOpenings.length,
                itemBuilder: (context, index) {
                  final job = jobOpenings[index];
                  return _buildJobCard(job);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CandidateRequirementForm(),
            ),
          );
        },
        backgroundColor: const Color(0xFF26A69A),
        child: Icon(Icons.add, color: Colors.white, size: 24.w),
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryItem("Total Jobs", "12", Colors.blue),
          _buildSummaryItem("Active", "08", Colors.green),
          _buildSummaryItem("High Priority", "03", Colors.red),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    Color priorityColor = Colors.green;
    if (job['priority'] == 'High') priorityColor = Colors.red;
    if (job['priority'] == 'Medium') priorityColor = Colors.orange;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(Icons.work, color: Colors.blue, size: 24.w),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              job['title'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              job['priority'],
                              style: GoogleFonts.poppins(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: priorityColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        job['department'],
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Wrap(
                        spacing: 12.w,
                        runSpacing: 8.h,
                        children: [
                          _buildJobDetail(
                            Icons.people,
                            "${job['vacancies']} Vacancy",
                          ),
                          _buildJobDetail(Icons.access_time, job['type']),
                          _buildJobDetail(Icons.history, job['experience']),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Request Date: ${job['date']}",
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    "View Details",
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF26A69A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobDetail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.w, color: Colors.grey.shade600),
        SizedBox(width: 4.w),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 11.sp,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
