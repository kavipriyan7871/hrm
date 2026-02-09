import 'package:flutter/material.dart';

class ChatDetailScreen extends StatelessWidget {
  const ChatDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2AA89A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'HRM APP',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2),
            Text(
              '6 Members',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,color: Colors.white),
            ),
          ],
        ),
        actions: const [
          Icon(Icons.info_outline, color: Colors.white),
          SizedBox(width: 12),
          Icon(Icons.more_vert, color: Colors.white),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          /// Today Badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xffA6FFF7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Today',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF2AA89A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// Chat Messages
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _leftMessage(
                  context,
                  avatar: 'H',
                  name: 'Harish',
                  message: 'Welcome to Chit project!',
                  time: '11:20am',
                  bgColor: const Color(0xFFDFF3F1),
                ),

                _rightMessage(
                  context,
                  message: 'Please find the latest mockups',
                  time: '11:23am',
                ),

                _leftMessage(
                  context,
                  avatar: 'S',
                  name: 'Sanjay',
                  message: 'Welcome to Chit project!',
                  time: '11:25am',
                  bgColor: const Color(0xFFF6D9E3),
                ),

                _leftMessage(
                  context,
                  avatar: 'N',
                  name: 'Naveen',
                  message:
                  'Please find the latest mockups\n\nWe can use Firebase for Mockup',
                  time: '11:27am',
                  bgColor: const Color(0xFFFFF1C1),
                ),
              ],
            ),
          ),

          /// Input Bar
          _chatInput(context),
        ],
      ),
    );
  }

  Widget _leftMessage(
      BuildContext context, {
        required String avatar,
        required String name,
        required String message,
        required String time,
        required Color bgColor,
      }) {
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: bgColor,
            child: Text(
              avatar,
              style: const TextStyle(color: Colors.black),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: size.width * 0.65,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rightMessage(
      BuildContext context, {
        required String message,
        required String time,
      }) {
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: size.width * 0.6,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE6E0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(message, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatInput(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'What would you like to know?',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade400,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),

              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 22,
                    color: Colors.black87,
                  ),
                  const SizedBox(width: 18),
                  Icon(
                    Icons.mic_none,
                    size: 22,
                    color: Colors.black87,
                  ),
                  const SizedBox(width: 18),
                  Icon(
                    Icons.emoji_emotions_outlined,
                    size: 22,
                    color: Colors.black87,
                  ),
                  const Spacer(),
                  Container(
                    width: size.width * 0.1,
                    height: size.width * 0.1,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color(0xffB3B3B3),
                        width: 2,
                      )
                    ),
                    child: const Icon(
                      Icons.arrow_upward,
                      size: 24,
                      color: Color(0xffB3B3B3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
