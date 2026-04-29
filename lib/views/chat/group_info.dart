import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { superAdmin, admin, member }

class GroupMember {
  final String id;
  final String name;
  UserRole role;
  final String avatar;

  GroupMember({
    required this.id,
    required this.name,
    required this.role,
    required this.avatar,
  });
}

class GroupInfoScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupInfoScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  UserRole currentRole = UserRole.member;
  String? currentUserId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserInfo();
  }

  Future<void> _loadCurrentUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      currentUserId = prefs.getString('mobile') ?? "unknown";
      String? mobile = prefs.getString('mobile');

      // Check if this is the hardcoded Super Admin
      if (mobile == "9047244021" || mobile == "7871281698") {
        setState(() {
          currentRole = UserRole.superAdmin;
        });
        return;
      }

      // Fetch my role in this group with a 10-second timeout
      DocumentSnapshot memberDoc = await _firestore
          .collection('chat_groups')
          .doc(widget.groupId)
          .collection('members')
          .doc(currentUserId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (memberDoc.exists) {
        String roleStr =
            (memberDoc.data() as Map<String, dynamic>)['role'] ?? 'member';
        setState(() {
          currentRole = _parseRole(roleStr);
        });
      }
    } catch (e) {
      debugPrint("INFO LOAD ERROR => $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Connection issue: ${e.toString()}"),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  UserRole _parseRole(String role) {
    switch (role) {
      case 'superAdmin':
        return UserRole.superAdmin;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.member;
    }
  }

  String _roleToString(UserRole role) {
    return role.name;
  }

  void _makeAdmin(GroupMember member) async {
    await _firestore
        .collection('chat_groups')
        .doc(widget.groupId)
        .collection('members')
        .doc(member.id)
        .update({'role': 'admin'});
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${member.name} is now an Admin')));
  }

  void _removeAdmin(GroupMember member) async {
    await _firestore
        .collection('chat_groups')
        .doc(widget.groupId)
        .collection('members')
        .doc(member.id)
        .update({'role': 'member'});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${member.name} is no longer an Admin')),
    );
  }

  void _makeSuperAdmin(GroupMember member) async {
    await _firestore
        .collection('chat_groups')
        .doc(widget.groupId)
        .collection('members')
        .doc(member.id)
        .update({'role': 'superAdmin'});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${member.name} is now a Super Admin')),
    );
  }

  void _removeSuperAdmin(GroupMember member) async {
    await _firestore
        .collection('chat_groups')
        .doc(widget.groupId)
        .collection('members')
        .doc(member.id)
        .update({'role': 'admin'});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${member.name} is no longer a Super Admin but still Admin',
        ),
      ),
    );
  }

  void _removeMember(GroupMember member) async {
    await _firestore
        .collection('chat_groups')
        .doc(widget.groupId)
        .collection('members')
        .doc(member.id)
        .delete();

    // Sync with top-level list
    await _firestore.collection('chat_groups').doc(widget.groupId).update({
      'members_list': FieldValue.arrayRemove([member.id]),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${member.name} removed from group')),
    );
  }

  void _deleteGroup() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
          'Are you sure you want to delete this group? This action cannot be undone and all messages will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final groupRef = _firestore
            .collection('chat_groups')
            .doc(widget.groupId);

        // 1. Delete Messages subcollection
        final messages = await groupRef.collection('messages').get();
        for (var msg in messages.docs) {
          await msg.reference.delete();
        }

        // 2. Delete Members subcollection
        final members = await groupRef.collection('members').get();
        for (var mem in members.docs) {
          await mem.reference.delete();
        }

        // 3. Delete the group document itself
        await groupRef.delete();

        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Group and all history deleted from Firebase'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        debugPrint("DELETE ERROR => $e");
      }
    }
  }

  Future<void> _addMemberDialog() async {
    final TextEditingController mobileController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    String fetchedName = "";
    String? fetchedUid; // To store the real database ID
    String? fetchedMobile; // The real mobile number extracted from API
    bool isSearching = false;
    bool showManualNameInput = false;
    UserRole selectedRole = UserRole.member;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Add New Member',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: mobileController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: 'Enter Mobile Number',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search, color: Color(0xFF26A69A)),
                      onPressed: isSearching
                          ? null
                          : () async {
                              String mobile = mobileController.text.trim();
                              if (mobile.isEmpty || mobile.length < 10) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Enter a valid 10-digit mobile number",
                                    ),
                                  ),
                                );
                                return;
                              }

                              setDialogState(() => isSearching = true);

                              String finalName = "";

                              try {
                                // First check system_roles
                                final roleQuery = await _firestore
                                    .collection('system_roles')
                                    .where('mobile', isEqualTo: mobile)
                                    .limit(1)
                                    .get();
                                if (roleQuery.docs.isNotEmpty) {
                                  finalName =
                                      roleQuery.docs.first.data()['name'] ?? "";
                                }

                                // If not found, search across all existing group members
                                if (finalName.isEmpty) {
                                  final membersQuery = await _firestore
                                      .collectionGroup('members')
                                      .where('id', isEqualTo: mobile)
                                      .limit(1)
                                      .get();
                                  if (membersQuery.docs.isNotEmpty) {
                                    finalName =
                                        membersQuery.docs.first
                                            .data()['name'] ??
                                        "";
                                  }
                                }
                              } catch (e) {
                                debugPrint("Search User Error => $e");
                              }

                              await Future.delayed(
                                const Duration(milliseconds: 300),
                              );

                              setDialogState(() {
                                fetchedMobile = mobile;
                                if (finalName.isNotEmpty) {
                                  fetchedName = finalName;
                                  showManualNameInput =
                                      false; // Name found, hide input
                                } else {
                                  fetchedName = ""; // Require manual entry
                                  showManualNameInput = true;
                                }
                                isSearching = false;
                              });
                            },
                    ),
                  ],
                ),
                if (showManualNameInput) ...[
                  const SizedBox(height: 15),
                  TextField(
                    controller: nameController,
                    onChanged: (val) {
                      setDialogState(() => fetchedName = val.trim());
                    },
                    decoration: const InputDecoration(
                      hintText: 'Enter Participant Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                if (fetchedName.isNotEmpty && !showManualNameInput) ...[
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Found User:',
                          style: TextStyle(fontSize: 12, color: Colors.teal),
                        ),
                        Text(
                          fetchedName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "ID: ${fetchedUid ?? 'N/A'}${fetchedMobile != null ? ' | Ph: $fetchedMobile' : ''}",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 15),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select Role:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DropdownButton<UserRole>(
                  isExpanded: true,
                  value: selectedRole,
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedRole = val);
                  },
                  items: [
                    const DropdownMenuItem(
                      value: UserRole.member,
                      child: Text('Member'),
                    ),
                    const DropdownMenuItem(
                      value: UserRole.admin,
                      child: Text('Admin'),
                    ),
                    const DropdownMenuItem(
                      value: UserRole.superAdmin,
                      child: Text('Super Admin'),
                    ),
                  ],
                ),
              ],
            ),
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
              onPressed: (fetchedName.isEmpty)
                  ? null
                  : () async {
                      String activeMobile =
                          fetchedMobile ?? mobileController.text.trim();
                      activeMobile = activeMobile.replaceAll(RegExp(r'\D'), '');
                      if (activeMobile.length > 10) {
                        activeMobile = activeMobile.substring(
                          activeMobile.length - 10,
                        );
                      }

                      // Using the Mobile Number for consistency across log-ins (WhatsApp Style)
                      await _firestore
                          .collection('chat_groups')
                          .doc(widget.groupId)
                          .collection('members')
                          .doc(activeMobile)
                          .set({
                            'name': fetchedName,
                            'id': activeMobile,
                            'mobile': activeMobile,
                            'role': _roleToString(selectedRole),
                            'added_at': FieldValue.serverTimestamp(),
                          });

                      // Sync with top-level list for filtering (Authoritative Mobile)
                      await _firestore
                          .collection('chat_groups')
                          .doc(widget.groupId)
                          .update({
                            'members_list': FieldValue.arrayUnion([
                              activeMobile,
                            ]),
                          });

                      if (!mounted) return;
                      Navigator.pop(context);
                    },
              child: const Text(
                'Add Member',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2AA89A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Group Info',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chat_groups')
            .doc(widget.groupId)
            .collection('members')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List<GroupMember> membersList = snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String name = data['name'] ?? 'No Name';
            return GroupMember(
              id: doc.id,
              name: name,
              role: _parseRole(data['role'] ?? 'member'),
              avatar: name.isNotEmpty ? name[0].toUpperCase() : '?',
            );
          }).toList();

          return Column(
            children: [
              _buildHeader(membersList.length),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      '${membersList.length} Members',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    if (currentRole == UserRole.superAdmin ||
                        currentRole == UserRole.admin)
                      TextButton.icon(
                        onPressed: _addMemberDialog,
                        icon: const Icon(
                          Icons.person_add_alt_1,
                          size: 20,
                          color: Color(0xFF2AA89A),
                        ),
                        label: Text(
                          'Add',
                          style: GoogleFonts.poppins(
                            color: Color(0xFF2AA89A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: membersList.length,
                  itemBuilder: (context, index) {
                    final member = membersList[index];
                    return _memberTile(member);
                  },
                ),
              ),
              if (currentRole == UserRole.admin ||
                  currentRole == UserRole.superAdmin) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: Text(
                    'Delete Group',
                    style: GoogleFonts.poppins(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: _deleteGroup,
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(int memberCount) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFDFF3F1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              widget.groupName.isNotEmpty
                  ? widget.groupName[0].toUpperCase()
                  : 'G',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2AA89A),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.groupName.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Group · $memberCount Members',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _memberTile(GroupMember member) {
    bool isMe = member.id == currentUserId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getBgColor(member.avatar),
          child: Text(
            member.avatar,
            style: const TextStyle(color: Colors.black),
          ),
        ),
        title: Text(
          member.name + (isMe ? ' (You)' : ''),
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        subtitle: member.role != UserRole.member
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: member.role == UserRole.superAdmin
                      ? Colors.amber.shade100
                      : Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: member.role == UserRole.superAdmin
                        ? Colors.amber
                        : const Color(0xFF2AA89A),
                  ),
                ),
                child: Text(
                  member.role == UserRole.superAdmin ? 'Super Admin' : 'Admin',
                  style: TextStyle(
                    fontSize: 10,
                    color: member.role == UserRole.superAdmin
                        ? Colors.amber.shade900
                        : const Color(0xFF2AA89A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        trailing: _buildTrailingActions(member),
      ),
    );
  }

  Widget? _buildTrailingActions(GroupMember member) {
    if (member.id == currentUserId) return null;

    if (currentRole == UserRole.superAdmin) {
      if (member.role == UserRole.superAdmin) return null;

      return PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'remove_member') _removeMember(member);
          if (value == 'make_admin') _makeAdmin(member);
          if (value == 'remove_admin') _removeAdmin(member);
          if (value == 'make_super_admin') _makeSuperAdmin(member);
          if (value == 'remove_super_admin') _removeSuperAdmin(member);
        },
        itemBuilder: (context) => [
          if (member.role == UserRole.member) ...[
            const PopupMenuItem(
              value: 'make_admin',
              child: Text('Make Group Admin'),
            ),
            const PopupMenuItem(
              value: 'make_super_admin',
              child: Text('Make Super Admin'),
            ),
          ],
          if (member.role == UserRole.admin) ...[
            const PopupMenuItem(
              value: 'remove_admin',
              child: Text('Dismiss as Admin'),
            ),
            const PopupMenuItem(
              value: 'make_super_admin',
              child: Text('Make Super Admin'),
            ),
          ],
          if (member.role == UserRole.superAdmin)
            const PopupMenuItem(
              value: 'remove_super_admin',
              child: Text('Dismiss as Super Admin'),
            ),
          const PopupMenuItem(
            value: 'remove_member',
            child: Text('Remove Member', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    }

    if (currentRole == UserRole.admin) {
      if (member.role == UserRole.superAdmin) return null;
      if (member.role == UserRole.admin) return null;

      return PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'remove_member') _removeMember(member);
          if (value == 'make_admin') _makeAdmin(member);
          if (value == 'make_super_admin') _makeSuperAdmin(member);
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'make_admin',
            child: Text('Make Group Admin'),
          ),
          const PopupMenuItem(
            value: 'make_super_admin',
            child: Text('Make Super Admin'),
          ),
          const PopupMenuItem(
            value: 'remove_member',
            child: Text('Remove Member', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    }

    return null;
  }

  Color _getBgColor(String avatar) {
    List<Color> colors = [
      const Color(0xFFDFF3F1),
      const Color(0xFFF6D9E3),
      const Color(0xFFFFF1C1),
      Colors.blue.shade50,
      Colors.orange.shade50,
    ];
    return colors[avatar.codeUnitAt(0) % colors.length];
  }
}
