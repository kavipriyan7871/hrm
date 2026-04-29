import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_messages.dart';

class ChatGroupScreen extends StatelessWidget {
  const ChatGroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> chatGroups = [
      {"name": "Admin Only", "lastMsg": "Update the pending leaves", "time": "12:30 PM", "unread": 3},
      {"name": "Marketing Team", "lastMsg": "The campaign is live", "time": "11:15 AM", "unread": 0},
      {"name": "Engineering Hub", "lastMsg": "New deployment successful", "time": "09:45 AM", "unread": 5},
      {"name": "Sales Force", "lastMsg": "Monthly target reached!", "time": "Yesterday", "unread": 0},
      {"name": "General", "lastMsg": "Welcome to the new team members", "time": "Yesterday", "unread": 1},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Admin Chat Hub",
          style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        itemCount: chatGroups.length,
        itemBuilder: (context, index) {
          final group = chatGroups[index];
          return _buildChatTile(context, group);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF26A69A),
        child: const Icon(Icons.group_add_outlined, color: Colors.white),
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, Map<String, dynamic> group) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      leading: CircleAvatar(
        radius: 25.r,
        backgroundColor: const Color(0xFFE0F2F1),
        child: Text(
          group['name'][0],
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF26A69A),
            fontSize: 18.sp,
          ),
        ),
      ),
      title: Text(
        group['name'],
        style: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        group['lastMsg'],
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: 12.sp,
          color: Colors.black54,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            group['time'],
            style: GoogleFonts.poppins(fontSize: 10.sp, color: Colors.black38),
          ),
          if (group['unread'] > 0) ...[
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: const Color(0xFF26A69A),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                group['unread'].toString(),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatMessageScreen(groupName: group['name'])),
        );
      },
    );
  }
}
