import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main_root.dart';
import 'chat_view.dart';

class ChatProjectsScreen extends StatefulWidget {
  const ChatProjectsScreen({super.key});

  @override
  State<ChatProjectsScreen> createState() => _ChatProjectsScreenState();
}

class _ChatProjectsScreenState extends State<ChatProjectsScreen> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double padding = size.width * 0.045;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F7),
        appBar: AppBar(
          backgroundColor: Color(0xFF26A69A),
          foregroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainRoot()),
                    (route) => false,
              );
            },
          ),
          title: Text(
            'Chat',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ),
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            const Text(
              'Projects',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            /// Project Cards
            _projectCard(
              context,
              avatarText: 'C',
              title: 'Chit Mobile app',
              subtitle: 'Build chit app features',
            ),
            const SizedBox(height: 12),

            _projectCard(
              context,
              avatarText: 'H',
              title: 'HRM App',
              subtitle: 'HRM App Upgrade',
            ),
            const SizedBox(height: 12),

            _projectCard(
              context,
              avatarText: 'H',
              title: 'HR',
              subtitle: 'HR Management',
            ),
          ],
        ),
      ),
    );
  }

  Widget _projectCard(
      BuildContext context, {
        required String avatarText,
        required String title,
        required String subtitle,
      }) {
    final Size size = MediaQuery.of(context).size;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          /// Avatar
          Container(
            width: size.width * 0.11,
            height: size.width * 0.11,
            decoration: const BoxDecoration(
              color: Color(0xFFDFF3F1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              avatarText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),

          const SizedBox(width: 14),

          /// Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.arrow_right,
              color: Color(0xFF2AA89A),
              size: 33,
            ),
            onPressed: () {
              if (title == 'HRM App') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChatDetailScreen(),
                  ),
                );
              }
            },
          ),


        ],
      ),
    );
  }
}
