import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class InterviewManagementScreen extends StatefulWidget {
  const InterviewManagementScreen({super.key});

  @override
  State<InterviewManagementScreen> createState() =>
      _InterviewManagementScreenState();
}

class _InterviewManagementScreenState extends State<InterviewManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCandidateForNew;
  String _selectedMode = "Online";
  final _meetController = TextEditingController();

  final List<String> _candidatesList = [
    "Kavi Priyan",
    "Arun Kumar",
    "Santhosh Mani",
    "Prakash Raj",
  ];

  final List<Map<String, dynamic>> _interviews = [
    {
      "candidate": "Kavi Priyan",
      "role": "Android Developer",
      "phone": "+919876543210",
      "time": "10:30 AM",
      "date": "Today",
      "round": "Technical Round 1",
      "mode": "Online",
      "status": "Upcoming",
      "meetLink": "https://meet.google.com/abc-defg-hij",
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Kavi",
    },
    {
      "candidate": "Arun Kumar",
      "role": "Node JS Expert",
      "phone": "+918877665544",
      "time": "02:00 PM",
      "date": "Today",
      "round": "Managerial Round",
      "mode": "Offline",
      "status": "Upcoming",
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Arun",
    },
    {
      "candidate": "Santhosh Mani",
      "role": "UI UX Designer",
      "phone": "+919988776655",
      "time": "Yesterday",
      "date": "03-Apr",
      "round": "Final HR Round",
      "mode": "Online",
      "status": "Completed",
      "result": "Selected",
      "score": "4.5/5",
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Santhosh",
    },
  ];

  Future<void> _sendWhatsAppMessage(
    String phone,
    String name,
    String round,
    String? link,
  ) async {
    String message =
        "Hello $name,\n\nYour $round interview has been scheduled.\n\n";
    if (link != null && link.isNotEmpty) {
      message += "Google Meet Link: $link\n\nPlease join on time. Thank you!";
    } else {
      message +=
          "Our team will contact you shortly with the details. Thank you!";
    }

    final url =
        "https://wa.me/${phone.replaceAll('+', '').replaceAll(' ', '')}?text=${Uri.encodeComponent(message)}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch WhatsApp")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Interview Management",
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: "Upcoming"),
            Tab(text: "Finished"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInterviewList("Upcoming"),
          _buildInterviewList("Completed"),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showScheduleDialog(),
        backgroundColor: const Color(0xFF26A69A),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          "Schedule",
          style: TextStyle(color: Colors.white, fontSize: 14.sp),
        ),
      ),
    );
  }

  Widget _buildInterviewList(String filter) {
    var list = _interviews.where((e) => e['status'] == filter).toList();
    if (list.isEmpty) {
      return Center(
        child: Text(
          "No records found",
          style: TextStyle(color: Colors.grey, fontSize: 14.sp),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: list.length,
      itemBuilder: (context, index) => _interviewCard(list[index]),
    );
  }

  Widget _interviewCard(Map<String, dynamic> item) {
    bool isUpcoming = item['status'] == "Upcoming";
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25.r,
                backgroundImage: NetworkImage(item['photo']),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['candidate'],
                      style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${item['role']} • ${item['mode']}",
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isUpcoming
                      ? Colors.blue.withOpacity(0.1)
                      : (item['result'] == 'Selected'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  item['round'],
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: isUpcoming
                        ? Colors.blue
                        : (item['result'] == 'Selected'
                              ? Colors.green
                              : Colors.red),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14.sp, color: Colors.grey),
                  SizedBox(width: 4.w),
                  Text(
                    item['date'],
                    style: TextStyle(fontSize: 12.sp, color: Colors.black87),
                  ),
                  SizedBox(width: 12.w),
                  Icon(Icons.access_time, size: 14.sp, color: Colors.grey),
                  SizedBox(width: 4.w),
                  Text(
                    item['time'],
                    style: TextStyle(fontSize: 12.sp, color: Colors.black87),
                  ),
                ],
              ),
              if (!isUpcoming)
                Text(
                  item['result'],
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: item['result'] == 'Selected'
                        ? Colors.green
                        : Colors.red,
                  ),
                )
              else
                Row(
                  children: [
                    if (item['mode'] == "Online")
                      IconButton(
                        onPressed: () => _sendWhatsAppMessage(
                          item['phone'] ?? "",
                          item['candidate'],
                          item['round'],
                          item['meetLink'],
                        ),
                        icon: const Icon(Icons.share, color: Colors.green),
                        tooltip: "Send Invite",
                      ),
                    InkWell(
                      onTap: () => _showFeedbackDialog(item['candidate']),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF26A69A),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          "Process Result",
                          style: GoogleFonts.poppins(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(String name) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20.w,
          right: 20.w,
          top: 20.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Decision: $name",
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: const Divider(),
            ),
            _buildDialogField(
              "Technical Competency Score (1-5)",
              Icons.star_outline,
            ),
            SizedBox(height: 12.h),
            _buildDialogField(
              "Final Review Comments",
              Icons.notes,
              maxLines: 3,
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showFinalStatusSnackbar("Rejected");
                    },
                    child: const Text("Rejected"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
                SizedBox(width: 15.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showFinalStatusSnackbar("Moved to Next Round");
                    },
                    child: const Text("Next Round"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF26A69A),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  void _showFinalStatusSnackbar(String status) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Candidate $status!"),
        backgroundColor: status.contains("Rejected")
            ? Colors.red
            : Colors.green,
      ),
    );
  }

  void _showScheduleDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20.w,
            right: 20.w,
            top: 20.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Schedule Round",
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 15.h),
              _buildDropdownField(
                "Choose Candidate",
                _candidatesList,
                _selectedCandidateForNew,
                (val) => setModalState(() => _selectedCandidateForNew = val),
              ),
              SizedBox(height: 12.h),
              Text(
                "Interview Mode:",
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  _modeRadio(
                    "Online",
                    "Online",
                    _selectedMode,
                    (val) => setModalState(() => _selectedMode = val!),
                  ),
                  _modeRadio(
                    "Offline",
                    "Offline",
                    _selectedMode,
                    (val) => setModalState(() => _selectedMode = val!),
                  ),
                ],
              ),
              if (_selectedMode == "Online") ...[
                SizedBox(height: 12.h),
                _buildDialogField(
                  "Google Meet Link",
                  Icons.video_call_outlined,
                  controller: _meetController,
                ),
              ],
              SizedBox(height: 12.h),
              _buildDialogField(
                "Targeted Round (e.g. HR Round)",
                Icons.layers_outlined,
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Confirm & Invite"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF26A69A),
                  ),
                ),
              ),
              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeRadio(
    String title,
    String value,
    String current,
    Function(String?) onChanged,
  ) {
    return Expanded(
      child: RadioListTile<String>(
        title: Text(title, style: TextStyle(fontSize: 13.sp)),
        value: value,
        groupValue: current,
        onChanged: onChanged,
        activeColor: const Color(0xFF26A69A),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildDropdownField(
    String hint,
    List<String> items,
    String? value,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(fontSize: 13.sp)),
          isExpanded: true,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: TextStyle(fontSize: 14.sp)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDialogField(
    String hint,
    IconData icon, {
    int maxLines = 1,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey),
        prefixIcon: Icon(icon, size: 18.sp, color: const Color(0xFF26A69A)),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
