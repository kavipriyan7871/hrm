import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminEmployeeFeatureScreen extends StatelessWidget {
  const AdminEmployeeFeatureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Employee Management",
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              _buildFeatureCard(
                context,
                title: "Employee Details",
                icon: Icons.badge_outlined,
                color: const Color(0xFFE3F2FD),
                iconColor: const Color(0xFF1976D2),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminEmployeeListScreen(),
                  ),
                ),
              ),
              _buildFeatureCard(
                context,
                title: "Confirmation Process",
                icon: Icons.assignment_turned_in_outlined,
                color: const Color(0xFFE8F5E9),
                iconColor: const Color(0xFF388E3C),
                onTap: () {},
              ),
              _buildFeatureCard(
                context,
                title: "Transfer Management",
                icon: Icons.swap_horiz_outlined,
                color: const Color(0xFFFFF3E0),
                iconColor: const Color(0xFFF57C00),
                onTap: () {},
              ),
              _buildFeatureCard(
                context,
                title: "Resignation Process",
                icon: Icons.exit_to_app_outlined,
                color: const Color(0xFFFFEBEE),
                iconColor: const Color(0xFFD32F2F),
                onTap: () {},
              ),
              _buildFeatureCard(
                context,
                title: "Employee History",
                icon: Icons.history_outlined,
                color: const Color(0xFFF3E5F5),
                iconColor: const Color(0xFF7B1FA2),
                onTap: () {},
              ),
              _buildFeatureCard(
                context,
                title: "Memo & Termination",
                icon: Icons.warning_amber_outlined,
                color: const Color(0xFFEFEBE9),
                iconColor: const Color(0xFF5D4037),
                onTap: () {},
              ),
              _buildFeatureCard(
                context,
                title: "SOP",
                icon: Icons.description_outlined,
                color: const Color(0xFFE0F7FA),
                iconColor: const Color(0xFF00ACC1),
                onTap: () {},
              ),
              _buildFeatureCard(
                context,
                title: "Performance Management",
                icon: Icons.trending_up_outlined,
                color: const Color(0xFFF1F8E9),
                iconColor: const Color(0xFF558B2F),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
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
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: iconColor, size: 28.sp),
              ),
              SizedBox(width: 20.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14.sp,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminEmployeeListScreen extends StatefulWidget {
  const AdminEmployeeListScreen({super.key});

  @override
  State<AdminEmployeeListScreen> createState() =>
      _AdminEmployeeListScreenState();
}

class _AdminEmployeeListScreenState extends State<AdminEmployeeListScreen> {
  final List<Map<String, dynamic>> _employees = [
    {
      "id": "EMP001",
      "name": "Kavi Priyan",
      "designation": "Android Developer",
      "dept": "Development",
      "status": "Active",
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Kavi",
    },
    {
      "id": "EMP002",
      "name": "Arun Kumar",
      "designation": "Manager",
      "dept": "HR",
      "status": "Active",
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Arun",
    },
    {
      "id": "EMP003",
      "name": "Santhosh Mani",
      "designation": "UI Designer",
      "dept": "Creative",
      "status": "On Leave",
      "photo": "https://api.dicebear.com/7.x/avataaars/png?seed=Santhosh",
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
          "Employee Directory",
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: _employees.length,
              itemBuilder: (context, index) => _employeeCard(_employees[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Colors.white,
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search Employee...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _employeeCard(Map<String, dynamic> emp) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminEmployeeDetailsScreen(employee: emp),
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50.r,
              height: 50.r,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                image: DecorationImage(
                  image: NetworkImage(emp['photo']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emp['name'],
                    style: GoogleFonts.poppins(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${emp['id']} | ${emp['designation']}",
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      emp['dept'],
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class AdminEmployeeDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> employee;
  const AdminEmployeeDetailsScreen({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          employee['name'],
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildUpperProfile(),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  _infoSection("Professional Information", [
                    _detailRow(
                      Icons.badge_outlined,
                      "Employee ID",
                      employee['id'],
                    ),
                    _detailRow(
                      Icons.business_outlined,
                      "Department",
                      employee['dept'],
                    ),
                    _detailRow(
                      Icons.work_outline,
                      "Designation",
                      employee['designation'],
                    ),
                    _detailRow(
                      Icons.calendar_month_outlined,
                      "Joining Date",
                      "15 May 2023",
                    ),
                    _detailRow(
                      Icons.timer_outlined,
                      "Shift",
                      "Morning (09 - 06)",
                    ),
                  ]),
                  _infoSection("Contact Information", [
                    _detailRow(
                      Icons.phone_outlined,
                      "Mobile",
                      "+91 98765 43210",
                    ),
                    _detailRow(
                      Icons.email_outlined,
                      "Official Email",
                      "${employee['name'].toString().toLowerCase().replaceAll(' ', '.')}@company.com",
                    ),
                    _detailRow(
                      Icons.location_on_outlined,
                      "Location",
                      "Chennai, India",
                    ),
                  ]),
                  _infoSection("Statutory Details", [
                    _detailRow(
                      Icons.account_balance_outlined,
                      "Account No",
                      "XXXX XXXX 5567",
                    ),
                    _detailRow(
                      Icons.credit_card_outlined,
                      "PAN Card",
                      "ABCDE1234F",
                    ),
                    _detailRow(
                      Icons.assignment_ind_outlined,
                      "Aadhar No",
                      "XXXX XXXX 8890",
                    ),
                  ]),
                  _buildActionMenus(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpperProfile() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF26A69A),
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: CircleAvatar(
                  radius: 55.r,
                  backgroundColor: Colors.white,
                  backgroundImage: NetworkImage(employee['photo']),
                ),
              ),
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16.sp,
                ), // Status indicator
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            employee['name'],
            style: GoogleFonts.poppins(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            employee['designation'],
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _profileAction(Icons.call, "Call", Colors.green),
              SizedBox(width: 20.w),
              _profileAction(Icons.mail, "Email", Colors.orange),
              SizedBox(width: 20.w),
              _profileAction(Icons.message, "Chat", Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profileAction(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20.sp),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10.sp,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _infoSection(String title, List<Widget> children) {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16.w, top: 16.h, bottom: 8.h),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF26A69A),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: Colors.blueGrey.shade400),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionMenus() {
    return Column(
      children: [
        _menuTile(Icons.history_outlined, "Employment History"),
        _menuTile(Icons.insights_outlined, "Performance Track"),
        _menuTile(Icons.folder_shared_outlined, "Document Vault"),
        _menuTile(Icons.security_outlined, "Role & Permissions"),
      ],
    );
  }

  Widget _menuTile(IconData icon, String title) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF26A69A), size: 22.sp),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14.sp,
          color: Colors.grey,
        ),
        onTap: () {},
      ),
    );
  }
}
