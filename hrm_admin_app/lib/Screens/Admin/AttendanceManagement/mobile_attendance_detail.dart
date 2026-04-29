import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../Models/attendance_api.dart';

class MobileAttendanceDetailScreen extends StatelessWidget {
  final AttendanceData record;
  const MobileAttendanceDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Attendance Details",
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
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// HEADER WITH IMAGES
            _buildImagesSection(context),

            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// EMPLOYEE INFO CARD
                  _buildEmployeeCard(),
                  SizedBox(height: 24.h),

                  /// ATTENDANCE LOGS
                  _buildSectionTitle("Log Details"),
                  SizedBox(height: 12.h),
                  _buildDetailGrid(),
                  SizedBox(height: 24.h),

                  /// LOCATION CARD
                  _buildSectionTitle("Location Trace"),
                  SizedBox(height: 12.h),
                  _buildLocationCard(),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesSection(BuildContext context) {
    return Container(
      height: 300.h,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF26A69A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          PageView(
            children: [
              if (record.selfie != null) _buildFullImage(context, record.selfie!, "Selfie Verification"),
              if (record.screenshot != null) _buildFullImage(context, record.screenshot!, "Transport/Location Photo"),
              if (record.selfie == null && record.screenshot == null)
                const Center(child: Icon(Icons.no_photography_rounded, color: Colors.white54, size: 60)),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Swipe to view verification photos",
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 10.sp),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullImage(BuildContext context, String url, String label) {
    return GestureDetector(
      onTap: () => _showImagePreview(context, url),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.3), Colors.transparent, Colors.black.withOpacity(0.5)],
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
              child: Text(label, style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.bold, color: const Color(0xFF26A69A))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30.r,
            backgroundColor: const Color(0xFFE0F2F1),
            child: Text(
              record.employeeName?.isNotEmpty == true ? record.employeeName![0].toUpperCase() : "?",
              style: GoogleFonts.outfit(fontSize: 24.sp, fontWeight: FontWeight.bold, color: const Color(0xFF26A69A)),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.employeeName ?? "Unknown Employee",
                  style: GoogleFonts.outfit(fontSize: 18.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                ),
                Text(
                  "Employee ID: ${record.uid}",
                  style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.badge_rounded, color: const Color(0xFF64748B), size: 20.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      childAspectRatio: 2.5,
      children: [
        _buildInfoTile("Date", record.date ?? "N/A", Icons.calendar_today_rounded, Colors.blue),
        _buildInfoTile("Status", record.status?.toUpperCase() ?? "N/A", Icons.info_outline, Colors.orange),
        _buildInfoTile("Check In", record.inTime ?? "--:--", Icons.login_rounded, Colors.green),
        _buildInfoTile("Check Out", record.outTime ?? "--:--", Icons.logout_rounded, Colors.red),
        _buildInfoTile("Work Mode", record.workMode?.toUpperCase() ?? "OFFICE", Icons.work_outline, Colors.indigo),
        _buildInfoTile("Transport", record.transportId?.toUpperCase() ?? "NONE", Icons.directions_bus_filled_rounded, Colors.purple),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey)),
                Text(value, style: GoogleFonts.outfit(fontSize: 13.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.location_on_rounded, color: Colors.red),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Current Address", style: GoogleFonts.outfit(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                    Text(record.loc ?? "Location not captured", style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          if (record.approvalStatus != null) ...[
            const Divider(height: 30),
            Row(
              children: [
                Icon(Icons.verified_user_rounded, color: Colors.green, size: 16.sp),
                SizedBox(width: 8.w),
                Text("Verification Status: ${record.approvalStatus}", style: GoogleFonts.poppins(fontSize: 11.sp, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
    );
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
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
              child: IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context)),
            ),
            Flexible(child: ClipRRect(borderRadius: BorderRadius.circular(16.r), child: InteractiveViewer(child: Image.network(imageUrl, fit: BoxFit.contain)))),
          ],
        ),
      ),
    );
  }
}
