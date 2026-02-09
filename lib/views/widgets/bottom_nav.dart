import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      decoration: const BoxDecoration(
        color: Color(0xFF26A69A),
      ),
      child: Row(
        children: [
          _buildNavItem(
            index: 0,
            iconPath: "assets/icons/home.png",
            label: "Home",
          ),
          _buildNavItem(
            index: 1,
            iconPath: "assets/icons/attendance.png",
            label: "Attendance",
          ),
          _buildNavItem(
            index: 2,
            iconPath: "assets/icons/payroll.png",
            label: "Payroll",
          ),
          _buildNavItem(
            index: 3,
            iconPath: "assets/icons/chat.png",
            label: "Chat",
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String iconPath,
    required String label,
  }) {
    final isSelected = selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Image.asset(
                  iconPath,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                height: 2,
                width: 30,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}