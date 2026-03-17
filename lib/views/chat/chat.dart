import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main_root.dart';
import 'chat_view.dart';
import '../../models/employee_api.dart';
import '../../services/notification_service.dart';

class ChatProjectsScreen extends StatefulWidget {
  const ChatProjectsScreen({super.key});

  @override
  State<ChatProjectsScreen> createState() => _ChatProjectsScreenState();
}

class _ChatProjectsScreenState extends State<ChatProjectsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String? currentUserId;
  String? userRole;
  String? userMobile;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? mobile = prefs.getString('mobile')?.trim();
    int? uidInt = prefs.getInt('uid');

    // Safety: If mobile is missing but we have a UID, fetch it now
    if ((mobile == null || mobile.isEmpty) && uidInt != null && uidInt != 0) {
      debugPrint("CHAT: Mobile missing, fetching from API for UID: $uidInt");
      try {
        final res = await EmployeeApi.getEmployeeDetails(
          uid: uidInt.toString(),
          cid: prefs.getString('cid') ?? "",
          deviceId: prefs.getString('device_id') ?? "",
          lat: "145",
          lng: "145",
          token: prefs.getString('token'),
        );
        if (res["error"] == false) {
          final data = res["data"] ?? res;
          String? rawMobile = (data["contact_number"] ?? data["mobile"])
              ?.toString();
          if (rawMobile != null) {
            mobile = rawMobile.replaceAll(RegExp(r'\D'), '');
            if (mobile.length > 10) {
              mobile = mobile.substring(mobile.length - 10);
            }
          }
          if (mobile != null && mobile.isNotEmpty) {
            await prefs.setString('mobile', mobile);
            debugPrint("CHAT: Recovered mobile number: $mobile");
          }
        }
      } catch (e) {
        debugPrint("CHAT: Recovery error => $e");
      }
    }

    setState(() {
      currentUserId = mobile ?? "";
      userRole = prefs.getString('employee_type') ?? "";
      userMobile = mobile ?? "";
    });

    // Save FCM Token for notifications
    if (mobile != null && mobile.isNotEmpty) {
      NotificationService.saveTokenToFirestore(mobile);
    }

    // Automatically register specific numbers as Super Admin in Firebase Console
    if (userMobile == "9047244021" || userMobile == "7871281698") {
      try {
        String docId = uidInt?.toString() ?? userMobile!;
        await _firestore.collection('system_roles').doc(docId).set({
          'mobile': userMobile,
          'uid': uidInt?.toString() ?? "unknown",
          'role': 'super_admin',
          'name': prefs.getString('name') ?? "Super Admin User",
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint("SUPER ADMIN SYNCED TO FIREBASE");
      } catch (e) {
        debugPrint("SUPER ADMIN SYNC ERROR => $e");
      }
    }
  }

  void _showCreateGroupDialog() {
    final TextEditingController groupNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Group'),
        content: TextField(
          controller: groupNameController,
          decoration: const InputDecoration(hintText: 'Group Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF26A69A),
            ),
            onPressed: () async {
              String groupName = groupNameController.text.trim();
              if (groupName.isNotEmpty) {
                try {
                  final prefs = await SharedPreferences.getInstance();
                  String creatorName = prefs.getString('name') ?? "User";
                  String? rawMobile = prefs.getString('mobile');
                  String mobile =
                      rawMobile?.replaceAll(RegExp(r'\D'), '') ?? "";
                  if (mobile.length > 10) {
                    mobile = mobile.substring(mobile.length - 10);
                  }

                  DocumentReference
                  groupRef = await _firestore.collection('chat_groups').add({
                    'name': groupName,
                    'creator': creatorName,
                    'creator_id': mobile,
                    'members_list': [mobile], // Track members by mobile number
                    'created_at': FieldValue.serverTimestamp(),
                    'last_message': 'Group created',
                    'last_message_time': FieldValue.serverTimestamp(),
                  });

                  // Add creator as super admin in the members subcollection
                  await groupRef.collection('members').doc(mobile).set({
                    'name': creatorName,
                    'id': mobile,
                    'role': 'superAdmin',
                    'added_at': FieldValue.serverTimestamp(),
                  });

                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Group "$groupName" created successfully'),
                    ),
                  );
                } catch (e) {
                  debugPrint("FIRESTORE ERROR => $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Database'),
        content: const Text(
          'This will delete ALL groups and messages forever. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final groups = await _firestore.collection('chat_groups').get();
        for (var groupDoc in groups.docs) {
          // 1. Delete Messages subcollection
          final messages = await groupDoc.reference
              .collection('messages')
              .get();
          for (var msg in messages.docs) {
            await msg.reference.delete();
          }

          // 2. Delete Members subcollection
          final members = await groupDoc.reference.collection('members').get();
          for (var mem in members.docs) {
            await mem.reference.delete();
          }

          // 3. Delete the group document itself
          await groupDoc.reference.delete();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Firebase fully cleared! Start fresh now.'),
            ),
          );
        }
      } catch (e) {
        debugPrint("CLEAR ALL ERROR => $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double padding = size.width * 0.045;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            onPressed: _clearAllData,
            tooltip: 'Clear All Data',
          ),
        ],
      ),
      body: currentUserId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chat_groups')
                  .where('members_list', arrayContains: currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No groups found. You are not a member of any group.',
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  );
                }

                // Manual Sort to avoid Index error
                final docs = snapshot.data!.docs.toList();
                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = aData['last_message_time'] as Timestamp?;
                  final bTime = bData['last_message_time'] as Timestamp?;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime);
                });

                return Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Groups',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            "Showing all chats",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // --- SEARCH BAR ---
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() => _searchQuery = val.toLowerCase());
                          },
                          decoration: const InputDecoration(
                            hintText: "Search groups...",
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            border: InputBorder.none,
                            icon: Icon(
                              Icons.search,
                              size: 20,
                              color: Colors.teal,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Expanded(
                        child: ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            var groupData =
                                docs[index].data() as Map<String, dynamic>;
                            String groupName = groupData['name'] ?? 'No Name';

                            // Search Filter
                            if (_searchQuery.isNotEmpty &&
                                !groupName.toLowerCase().contains(
                                  _searchQuery,
                                )) {
                              return const SizedBox.shrink();
                            }

                            String groupId = docs[index].id;
                            String lastMsg = groupData['last_message'] ?? '';

                            int unreadCount = 0;
                            if (currentUserId != null) {
                              final count =
                                  groupData['unread_$currentUserId'] ?? 0;
                              if (count is int) unreadCount = count;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: StreamBuilder<QuerySnapshot>(
                                stream: _firestore
                                    .collection('chat_groups')
                                    .doc(groupId)
                                    .collection('members')
                                    .snapshots(),
                                builder: (context, memberSnapshot) {
                                  String currentSubtitle = lastMsg;

                                  if (memberSnapshot.hasData) {
                                    var typingMembers = memberSnapshot
                                        .data!
                                        .docs
                                        .where((doc) {
                                          var data =
                                              doc.data()
                                                  as Map<String, dynamic>;
                                          return data['is_typing'] == true &&
                                              doc.id != currentUserId;
                                        })
                                        .toList();

                                    if (typingMembers.isNotEmpty) {
                                      currentSubtitle =
                                          typingMembers.length == 1
                                          ? "${typingMembers[0]['name']} is typing..."
                                          : "${typingMembers.length} people are typing...";
                                    }
                                  }

                                  return _projectCard(
                                    context,
                                    groupId: groupId,
                                    avatarText: groupName.isNotEmpty
                                        ? groupName[0].toUpperCase()
                                        : 'G',
                                    title: groupName,
                                    subtitle: currentSubtitle,
                                    unreadCount: unreadCount,
                                    isTyping: currentSubtitle.contains(
                                      "typing...",
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton:
          (userMobile == "9047244021" || userMobile == "7871281698")
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF26A69A),
              onPressed: _showCreateGroupDialog,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _projectCard(
    BuildContext context, {
    required String groupId,
    required String avatarText,
    required String title,
    required String subtitle,
    required int unreadCount,
    bool isTyping = false,
  }) {
    final Size size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ChatDetailScreen(groupId: groupId, groupName: title),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: isTyping
                          ? const Color(0xFF26A69A)
                          : Colors.grey.shade600,
                      fontWeight: isTyping
                          ? FontWeight.w500
                          : FontWeight.normal,
                      fontStyle: isTyping ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(6),
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
              ),
            const Icon(Icons.arrow_right, color: Color(0xFF2AA89A), size: 33),
          ],
        ),
      ),
    );
  }
}
