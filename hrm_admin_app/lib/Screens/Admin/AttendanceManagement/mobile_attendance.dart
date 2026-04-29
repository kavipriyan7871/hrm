import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../Models/attendance_api.dart';
import 'mobile_attendance_detail.dart';

class MobileAttendanceScreen extends StatefulWidget {
  const MobileAttendanceScreen({super.key});

  @override
  State<MobileAttendanceScreen> createState() => _MobileAttendanceScreenState();
}

class _MobileAttendanceScreenState extends State<MobileAttendanceScreen> {
  late Future<AttendanceResponse> _attendanceFuture;

  @override
  void initState() {
    super.initState();
    _attendanceFuture = AttendanceApi.fetchMobileAttendance();
  }

  void _refresh() {
    setState(() {
      _attendanceFuture = AttendanceApi.fetchMobileAttendance();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          "Mobile Attendance",
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

          final records = snapshot.data!.data;

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MobileAttendanceDetailScreen(record: record)),
                ),
                child: _buildAttendanceCard(record),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceData record) {
    final bool isCheckOut = record.status?.toLowerCase().contains("out") ?? false;
    final Color statusColor = isCheckOut ? const Color(0xFFFF9800) : const Color(0xFF4CAF50);
    
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF26A69A).withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.r),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MobileAttendanceDetailScreen(record: record)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(18.w),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => _showImagePreview(record.selfie ?? record.screenshot),
                            child: Container(
                              height: 64.h,
                              width: 64.w,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20.r),
                                image: (record.selfie != null || record.screenshot != null)
                                    ? DecorationImage(
                                        image: NetworkImage(record.selfie ?? record.screenshot!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                              ),
                              child: (record.selfie == null && record.screenshot == null)
                                  ? Icon(Icons.person_rounded, size: 32.sp, color: const Color(0xFF94A3B8))
                                  : null,
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.employeeName ?? "Unknown Employee",
                                  style: GoogleFonts.outfit(
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_rounded, size: 12.sp, color: const Color(0xFF64748B)),
                                    SizedBox(width: 4.w),
                                    Expanded(
                                      child: Text(
                                        record.loc ?? "Location not available",
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.sp,
                                          color: const Color(0xFF64748B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Wrap(
                                  spacing: 6.w,
                                  runSpacing: 6.h,
                                  children: [
                                    _buildChip(
                                      record.workMode?.toUpperCase() ?? "OFFICE",
                                      const Color(0xFF6366F1),
                                    ),
                                    if (record.transportId != null && record.transportId!.isNotEmpty)
                                      _buildChip(
                                        record.transportId!.toUpperCase(),
                                        const Color(0xFF8B5CF6),
                                      ),
                                    _buildChip(
                                      record.status?.toUpperCase() ?? "IN",
                                      statusColor,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                record.date ?? "",
                                style: GoogleFonts.poppins(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  _miniTimeColumn("IN", record.inTime ?? "--:--", const Color(0xFF10B981)),
                                  SizedBox(width: 12.w),
                                  _miniTimeColumn("OUT", record.outTime ?? "--:--", const Color(0xFFFF9800)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (record.screenshot != null && record.screenshot!.isNotEmpty && record.screenshot != record.selfie)
                Padding(
                  padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 18.h),
                  child: GestureDetector(
                    onTap: () => _showImagePreview(record.screenshot),
                    child: Container(
                      height: 120.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.r),
                        image: DecorationImage(
                          image: NetworkImage(record.screenshot!),
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r),
                          gradient: LinearGradient(
                            colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        alignment: Alignment.bottomRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 4.w),
                            Text(
                              "View Screen",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _miniTimeColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 8.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFCBD5E1),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showImagePreview(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.white,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image_rounded, size: 50, color: Colors.grey),
                          SizedBox(height: 10),
                          Text("Failed to load image"),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
