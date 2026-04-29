import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../Models/attendance_api.dart';
import 'mobile_attendance.dart';
import 'office_attendance.dart';
import 'mobile_attendance_detail.dart';
import 'office_attendance_detail.dart';

class AdminAttendanceManagementScreen extends StatefulWidget {
  const AdminAttendanceManagementScreen({super.key});

  @override
  State<AdminAttendanceManagementScreen> createState() =>
      _AdminAttendanceManagementScreenState();
}

class _AdminAttendanceManagementScreenState
    extends State<AdminAttendanceManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<AttendanceData>> _allAttendanceFuture;
  late Future<AttendanceResponse> _mobileAttendanceFuture;
  late Future<AttendanceResponse> _officeAttendanceFuture;
  late Future<AttendanceResponse> _breakAttendanceFuture;
  late Future<AttendanceResponse> _marketingAttendanceFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _refresh();
  }

  void _refresh() {
    setState(() {
      _mobileAttendanceFuture = AttendanceApi.fetchMobileAttendance();
      _officeAttendanceFuture = AttendanceApi.fetchInOfficeAttendance();
      _breakAttendanceFuture = AttendanceApi.fetchBreakAttendance();
      _marketingAttendanceFuture = AttendanceApi.fetchMarketingAttendance();
      _allAttendanceFuture = _fetchAllAttendance();
    });
  }

  Future<List<AttendanceData>> _fetchAllAttendance() async {
    try {
      final results = await Future.wait([
        _mobileAttendanceFuture,
        _officeAttendanceFuture,
        _breakAttendanceFuture,
        _marketingAttendanceFuture,
      ]);

      List<AttendanceData> combined = [];
      combined.addAll(results[0].data);
      combined.addAll(results[1].data);
      combined.addAll(results[2].data);
      combined.addAll(results[3].data);

      combined.sort((a, b) => b.id.compareTo(a.id));
      return combined;
    } catch (e) {
      debugPrint("Error fetching all attendance: $e");
      return [];
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        toolbarHeight: 70.h,
        title: Column(
          children: [
            Text(
              "Attendance Hub",
              style: GoogleFonts.outfit(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              "Real-time monitoring & reports",
              style: GoogleFonts.poppins(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF26A69A), Color(0xFF00897B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: const Icon(Icons.refresh_rounded,
                  color: Colors.white, size: 20),
            ),
            onPressed: _refresh,
          ),
          SizedBox(width: 8.w),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.h),
          child: Container(
            margin: EdgeInsets.only(bottom: 12.h, left: 16.w, right: 16.w),
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              labelColor: const Color(0xFF00897B),
              unselectedLabelColor: Colors.white.withOpacity(0.9),
              labelStyle: GoogleFonts.outfit(
                  fontSize: 13.sp, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.outfit(
                  fontSize: 13.sp, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: "  All Activity  "),
                Tab(text: "  Mobile  "),
                Tab(text: "  In-Office  "),
                Tab(text: "  Breaks  "),
                Tab(text: "  Marketing  "),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildAllTab(),
          _buildMobileTab(),
          _buildOfficeTab(),
          _buildBreakTab(),
          _buildMarketingTab(),
        ],
      ),
    );
  }

  Widget _buildAllTab() {
    return FutureBuilder<List<AttendanceData>>(
      future: _allAttendanceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF26A69A)));
        }
        if (snapshot.hasError)
          return Center(child: Text("Error: ${snapshot.error}"));
        final records = snapshot.data ?? [];
        if (records.isEmpty)
          return const Center(child: Text("No records found"));

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            bool isMobile = record.loc != null ||
                record.selfie != null ||
                record.screenshot != null;
            return isMobile
                ? _buildMobileCard(record)
                : _buildOfficeCard(record);
          },
        );
      },
    );
  }

  Widget _buildMobileTab() {
    return FutureBuilder<AttendanceResponse>(
      future: _mobileAttendanceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF26A69A)));
        }
        if (snapshot.hasError)
          return Center(child: Text("Error: ${snapshot.error}"));
        final records = snapshot.data?.data ?? [];
        if (records.isEmpty)
          return const Center(child: Text("No records found"));

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: records.length,
          itemBuilder: (context, index) => _buildMobileCard(records[index]),
        );
      },
    );
  }

  Widget _buildOfficeTab() {
    return FutureBuilder<AttendanceResponse>(
      future: _officeAttendanceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF26A69A)));
        }
        if (snapshot.hasError)
          return Center(child: Text("Error: ${snapshot.error}"));
        final records = (snapshot.data?.data ?? [])
            .where((r) =>
                (r.employeeName?.isNotEmpty ?? false) ||
                (r.employeeCode?.isNotEmpty ?? false))
            .toList();
        if (records.isEmpty)
          return const Center(child: Text("No valid records found"));

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: records.length,
          itemBuilder: (context, index) => _buildOfficeCard(records[index]),
        );
      },
    );
  }

  Widget _buildMobileCard(AttendanceData record) {
    final bool isCheckOut =
        record.status?.toLowerCase().contains("out") ?? false;
    final Color statusColor =
        isCheckOut ? const Color(0xFFFF9800) : const Color(0xFF4CAF50);

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF26A69A).withOpacity(0.12),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => MobileAttendanceDetailScreen(record: record)),
            ),
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 58.h,
                        width: 58.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16.r),
                          image: (record.selfie != null ||
                                  record.screenshot != null)
                              ? DecorationImage(
                                  image: NetworkImage(
                                      record.selfie ?? record.screenshot!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          border: Border.all(
                              color: const Color(0xFFE2E8F0), width: 1.5),
                        ),
                        child:
                            (record.selfie == null && record.screenshot == null)
                                ? Icon(Icons.person_rounded,
                                    size: 30.sp, color: const Color(0xFF94A3B8))
                                : null,
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.employeeName ?? "Unknown",
                              style: GoogleFonts.outfit(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded,
                                    size: 12.sp,
                                    color: const Color(0xFF26A69A)),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: Text(
                                    record.loc ?? "Location N/A",
                                    style: GoogleFonts.poppins(
                                        fontSize: 11.sp,
                                        color: const Color(0xFF64748B),
                                        fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10.r),
                          border:
                              Border.all(color: statusColor.withOpacity(0.2)),
                        ),
                        child: Text(
                          record.status?.toUpperCase() ?? "IN",
                          style: GoogleFonts.outfit(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18.h),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  SizedBox(height: 18.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTimeInfo("Check In", record.inTime ?? "--:--",
                          const Color(0xFF26A69A)),
                      _buildDetailedInfo("Date", record.date ?? "--/--/--",
                          const Color(0xFF64748B)),
                      _buildTimeInfo("Check Out", record.outTime ?? "--:--",
                          const Color(0xFFF59E0B)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.poppins(
              fontSize: 9.sp,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: GoogleFonts.outfit(
              fontSize: 15.sp, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }

  Widget _buildDetailedInfo(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.poppins(
              fontSize: 9.sp,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: GoogleFonts.outfit(
              fontSize: 13.sp, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  Widget _buildOfficeCard(AttendanceData record) {
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF26A69A).withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => OfficeAttendanceDetailScreen(record: record)),
            ),
            child: Padding(
              padding: EdgeInsets.all(18.w),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        height: 54.h,
                        width: 54.w,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF26A69A).withOpacity(0.1),
                              const Color(0xFF26A69A).withOpacity(0.05)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                              color: const Color(0xFF26A69A).withOpacity(0.1),
                              width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            record.employeeName?.isNotEmpty == true
                                ? record.employeeName![0].toUpperCase()
                                : "?",
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF26A69A),
                              fontWeight: FontWeight.w800,
                              fontSize: 19.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.employeeName ?? "Unknown",
                              style: GoogleFonts.outfit(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(
                                        color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Text(
                                    "ID: ${record.employeeCode ?? 'N/A'}",
                                    style: GoogleFonts.outfit(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0F2F1),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    record.date ?? "--/--/--",
                                    style: GoogleFonts.poppins(
                                      fontSize: 10.sp,
                                      color: const Color(0xFF00796B),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (record.clientName?.isNotEmpty == true ||
                      record.remarks?.isNotEmpty == true) ...[
                    SizedBox(height: 16.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: const Color(0xFFFFECB3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (record.clientName?.isNotEmpty == true)
                            Row(
                              children: [
                                Icon(Icons.business_rounded,
                                    size: 14.sp,
                                    color: const Color(0xFF26A69A)),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    "CLIENT: ${record.clientName}",
                                    style: GoogleFonts.outfit(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1E293B)),
                                  ),
                                ),
                              ],
                            ),
                          if (record.clientName?.isNotEmpty == true &&
                              record.remarks?.isNotEmpty == true)
                            SizedBox(height: 6.h),
                          if (record.remarks?.isNotEmpty == true)
                            Row(
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    size: 14.sp, color: Colors.redAccent),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    "NOTE: ${record.remarks}",
                                    style: GoogleFonts.poppins(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFEF4444)),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 18.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _miniTimeColumn("IN TIME", record.inTime ?? "--:--",
                            const Color(0xFF10B981)),
                        _miniTimeColumn("OUT TIME", record.outTime ?? "--:--",
                            const Color(0xFFF59E0B)),
                        _miniTimeColumn("TOTAL", record.totalHours ?? "0",
                            const Color(0xFF3B82F6)),
                      ],
                    ),
                  ),
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

  Widget _buildBreakTab() {
    return FutureBuilder<AttendanceResponse>(
      future: _breakAttendanceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF26A69A)));
        }
        if (snapshot.hasError)
          return Center(child: Text("Error: ${snapshot.error}"));
        final records = snapshot.data?.data ?? [];
        if (records.isEmpty)
          return const Center(child: Text("No records found"));

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: records.length,
          itemBuilder: (context, index) =>
              _buildOfficeCard(records[index]), // Reusing office card for break
        );
      },
    );
  }

  Widget _buildMarketingTab() {
    return FutureBuilder<AttendanceResponse>(
      future: _marketingAttendanceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF26A69A)));
        }
        if (snapshot.hasError)
          return Center(child: Text("Error: ${snapshot.error}"));
        final records = snapshot.data?.data ?? [];
        if (records.isEmpty)
          return const Center(child: Text("No records found"));

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: records.length,
          itemBuilder: (context, index) => _buildOfficeCard(
              records[index]), // Reusing office card for marketing
        );
      },
    );
  }
}
