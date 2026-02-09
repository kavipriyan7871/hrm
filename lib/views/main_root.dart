import 'package:flutter/material.dart';
import 'package:hrm/views/chat/chat.dart';
import 'package:hrm/views/widgets/bottom_nav.dart';
import 'attendance_history/attendance.dart';
import 'home/payroll.dart';
import 'home_screen/dashboard.dart';

class MainRoot extends StatefulWidget {
  const MainRoot({super.key});

  @override
  State<MainRoot> createState() => _MainRootState();
}

class _MainRootState extends State<MainRoot> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    Dashboard(),
    AttendanceScreen(),
    PayrollScreen(),
    ChatProjectsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    assert(_screens.length == 4);
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: AppBottomNav(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
