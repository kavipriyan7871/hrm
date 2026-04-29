import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../Models/employee_api.dart';

class ResignationProcessScreen extends StatefulWidget {
  const ResignationProcessScreen({super.key});

  @override
  State<ResignationProcessScreen> createState() =>
      _ResignationProcessScreenState();
}

class _ResignationProcessScreenState extends State<ResignationProcessScreen> {
  List<ResignationData> _resignationRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchResignations();
  }

  Future<void> _fetchResignations() async {
    setState(() => _isLoading = true);
    try {
      final response = await EmployeeApi.fetchResignationProcess();
      if (mounted) {
        setState(() {
          _resignationRequests = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching resignations: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          "Resignation Process",
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchResignations,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _resignationRequests.isEmpty
            ? const Center(child: Text("No records found"))
            : ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: _resignationRequests.length,
                itemBuilder: (context, index) =>
                    _buildResignationCard(_resignationRequests[index]),
              ),
      ),
    );
  }

  Widget _buildResignationCard(ResignationData request) {
    bool isPending =
        request.exitApproval.toLowerCase() != 'yes' &&
        request.exitApproval.toLowerCase() != 'approved';
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.teal.withOpacity(0.1),
                ),
                child: Icon(Icons.person, color: Colors.teal, size: 22.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.employeeName.isEmpty
                          ? "No Name"
                          : request.employeeName,
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "ID: ${request.employeeId} | ${request.department}",
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: (isPending ? Colors.orange : Colors.green).withOpacity(
                    0.1,
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  request.exitApproval.isEmpty
                      ? "Pending"
                      : request.exitApproval,
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: isPending ? Colors.orange : Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _info("Submitted Date", request.dtime.split(' ')[0]),
              _info("Last Working Day", request.lastWrkDate),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            "Reason for Resignation:",
            style: GoogleFonts.poppins(
              fontSize: 10.sp,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            request.exitReason.isEmpty ? "Not mentioned" : request.exitReason,
            style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.black87),
          ),
          if (request.remark.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              "Remark: ${request.remark}",
              style: GoogleFonts.poppins(
                fontSize: 11.sp,
                color: Colors.blueGrey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (isPending) ...[
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      foregroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      "Hold",
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF26A69A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      "Approve",
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _info(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.grey),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
