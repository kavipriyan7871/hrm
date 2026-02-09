import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileInfoCard extends StatelessWidget {
  final String name;
  final String employeeId;
  final String designation;
  final String? profileImagePath;

  const ProfileInfoCard({
    super.key,
    required this.name,
    required this.employeeId,
    required this.designation,
    this.profileImagePath = 'assets/profile.png',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
        ),
        color: const Color(0xffEEEABC),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundImage: AssetImage(profileImagePath!),
            backgroundColor: Colors.transparent,
            onBackgroundImageError: (_, __) {},
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Name: $name',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Employee Id: $employeeId',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Designation: $designation',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
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
}
