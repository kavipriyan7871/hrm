import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../Models/attendance_api.dart';
import 'office_attendance_detail.dart';

class OfficeAttendanceScreen extends StatefulWidget {
  const OfficeAttendanceScreen({super.key});

  @override
  State<OfficeAttendanceScreen> createState() => _OfficeAttendanceScreenState();
}

class _OfficeAttendanceScreenState extends State<OfficeAttendanceScreen> {
  late Future<AttendanceResponse> _attendanceFuture;

  @override
  void initState() {
    super.initState();
    _attendanceFuture = AttendanceApi.fetchInOfficeAttendance();
  }

  void _refresh() {
    setState(() {
      _attendanceFuture = AttendanceApi.fetchInOfficeAttendance();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          "In-Office Attendance",
          style: GoogleFonts.outfit(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF26A69A),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<AttendanceResponse>(
        future: _attendanceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF26A69A)));
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
            return const Center(child: Text("No records found"));
          }

          // Filter out records where employee name or code is missing (based on your observation of many empty objects in the mock data)
          final records = snapshot.data!.data.where((r) => 
            (r.employeeName?.isNotEmpty ?? false) || (r.employeeCode?.isNotEmpty ?? false)
          ).toList();

          if (records.isEmpty) {
            return const Center(child: Text("No valid records found"));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OfficeAttendanceDetailScreen(record: record)),
                ),
                child: _buildOfficeAttendanceCard(record),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOfficeAttendanceCard(AttendanceData record) {
    return Container(
      margin: EdgeInsets.only(bottom: 18.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF26A69A).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OfficeAttendanceDetailScreen(record: record)),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        height: 52.h,
                        width: 52.w,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [const Color(0xFF26A69A).withOpacity(0.1), const Color(0xFF26A69A).withOpacity(0.05)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: const Color(0xFF26A69A).withOpacity(0.1)),
                        ),
                        child: Center(
                          child: Text(
                            record.employeeName?.isNotEmpty == true ? record.employeeName![0].toUpperCase() : "?", 
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF26A69A), 
                              fontWeight: FontWeight.w800,
                              fontSize: 18.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.employeeName?.isNotEmpty == true ? record.employeeName! : "Unknown Employee", 
                              style: GoogleFonts.outfit(
                                fontSize: 16.sp, 
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                "EMP ID: ${record.employeeCode ?? 'N/A'}", 
                                style: GoogleFonts.outfit(
                                  fontSize: 10.sp, 
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            record.date ?? "N/A", 
                            style: GoogleFonts.poppins(
                              fontSize: 10.sp, 
                              color: const Color(0xFF3B82F6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Container(
                            height: 6.h,
                            width: 24.w,
                            decoration: BoxDecoration(
                              color: const Color(0xFF26A69A).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _miniTimeColumn("IN TIME", record.inTime ?? "--:--", const Color(0xFF10B981)),
                        Container(height: 20.h, width: 1, color: const Color(0xFFE2E8F0)),
                        _miniTimeColumn("OUT TIME", record.outTime ?? "--:--", const Color(0xFFF59E0B)),
                        Container(height: 20.h, width: 1, color: const Color(0xFFE2E8F0)),
                        _miniTimeColumn("TOT HRS", record.totalHours ?? "0", const Color(0xFF3B82F6)),
                      ],
                    ),
                  ),
                  if (record.remarks?.isNotEmpty == true) ...[
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Icon(Icons.notes_rounded, size: 14.sp, color: const Color(0xFF94A3B8)),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            record.remarks!,
                            style: GoogleFonts.poppins(
                              fontSize: 11.sp,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniTimeColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label, 
          style: GoogleFonts.poppins(
            fontSize: 8.sp, 
            fontWeight: FontWeight.w600, 
            color: const Color(0xFF94A3B8),
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value, 
          style: GoogleFonts.outfit(
            fontSize: 15.sp, 
            fontWeight: FontWeight.w700, 
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
