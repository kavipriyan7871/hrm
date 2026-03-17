import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppBottomNav extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? rawMobile = prefs.getString('mobile');
    String? mobile = rawMobile?.replaceAll(RegExp(r'\D'), '');
    if (mobile != null && mobile.length > 10) {
      mobile = mobile.substring(mobile.length - 10);
    }
    setState(() {
      currentUserId = mobile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      decoration: const BoxDecoration(color: Color(0xFF26A69A)),
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
            isChat: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String iconPath,
    required String label,
    bool isChat = false,
  }) {
    final isSelected = widget.selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTap(index),
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Image.asset(iconPath, color: Colors.white),
                  ),
                  if (isChat && currentUserId != null)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('chat_groups')
                            .where('members_list', arrayContains: currentUserId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox.shrink();

                          int unreadCount = 0;
                          for (var doc in snapshot.data!.docs) {
                            final data = doc.data() as Map<String, dynamic>;
                            final count = data['unread_$currentUserId'] ?? 0;
                            if (count is int) {
                              unreadCount += count;
                            }
                          }

                          if (unreadCount == 0) return const SizedBox.shrink();

                          return Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
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
