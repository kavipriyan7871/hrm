import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'group_info.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/chat_storage_service.dart';
import 'media_widgets.dart';

class ChatDetailScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const ChatDetailScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? currentUserId;
  String? currentUserName;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  // String? _recordingPath;
  bool _isUploading = false;
  bool _isComposing = false;
  Timer? _typingTimer;
  bool _isTyping = false;

  StreamSubscription<DocumentSnapshot>? _groupSub;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? rawMobile = prefs.getString('mobile');
    String mobile = rawMobile?.replaceAll(RegExp(r'\D'), '') ?? "unknown";
    if (mobile != "unknown" && mobile.length > 10) {
      mobile = mobile.substring(mobile.length - 10);
    }
    setState(() {
      currentUserId = mobile;
      currentUserName = prefs.getString('name') ?? "User";
    });

    _clearUnreadCount();
    _setupReadListener();
    _updateTypingStatus(false);
  }

  void _updateTypingStatus(bool typing) {
    if (currentUserId == null || currentUserId == "unknown") return;
    if (_isTyping == typing) return;

    _isTyping = typing;
    _firestore
        .collection('chat_groups')
        .doc(widget.groupId)
        .collection('members')
        .doc(currentUserId)
        .set({
          'is_typing': typing,
          'name': currentUserName,
        }, SetOptions(merge: true));
  }

  Future<void> _clearUnreadCount() async {
    if (currentUserId == null || currentUserId == "unknown") return;
    try {
      await _firestore.collection('chat_groups').doc(widget.groupId).update({
        'unread_$currentUserId': 0,
      });
    } catch (_) {}
  }

  void _setupReadListener() {
    _groupSub = _firestore
        .collection('chat_groups')
        .doc(widget.groupId)
        .snapshots()
        .listen((doc) {
          if (doc.exists && currentUserId != null) {
            final data = doc.data() as Map<String, dynamic>;
            final count = data['unread_$currentUserId'] ?? 0;
            if (count is int && count > 0) {
              _clearUnreadCount();
            }
          }
        });
  }

  @override
  void dispose() {
    _updateTypingStatus(false);
    _groupSub?.cancel();
    _typingTimer?.cancel();
    _messageController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _sendMessage({
    String? text,
    String? fileUrl,
    String type = 'text',
  }) async {
    String messageText = text ?? _messageController.text.trim();
    if (messageText.isEmpty && fileUrl == null) return;

    if (text == null) {
      _messageController.clear();
      setState(() => _isComposing = false);
      _updateTypingStatus(false);
    }

    try {
      Map<String, dynamic> messageData = {
        'sender_id': currentUserId,
        'sender_name': currentUserName,
        'text': messageText,
        'type': type,
        'file_url': fileUrl,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('chat_groups')
          .doc(widget.groupId)
          .collection('messages')
          .add(messageData);

      // Update last message in group doc
      String lastMsgDisplay = type == 'text'
          ? messageText
          : '[${type.toUpperCase()}]';

      // --- PUSH NOTIFICATION LOGIC AND UNREAD COUNTS ---
      var membersSnapshot = await _firestore
          .collection('chat_groups')
          .doc(widget.groupId)
          .collection('members')
          .get();

      Map<String, dynamic> unreadUpdates = {};
      List<String> recipientTokens = [];

      for (var doc in membersSnapshot.docs) {
        String memberMobile = doc.id;
        if (memberMobile != currentUserId) {
          unreadUpdates['unread_$memberMobile'] = FieldValue.increment(1);

          var tokenDoc = await _firestore
              .collection('user_tokens')
              .doc(memberMobile)
              .get();
          if (tokenDoc.exists) {
            String? token = tokenDoc.get('fcmToken');
            if (token != null) recipientTokens.add(token);
          }
        }
      }

      await _firestore.collection('chat_groups').doc(widget.groupId).update({
        'last_message': lastMsgDisplay,
        'last_message_time': FieldValue.serverTimestamp(),
        ...unreadUpdates,
      });

      if (recipientTokens.isNotEmpty) {
        await _firestore.collection('notification_triggers').add({
          'tokens': recipientTokens,
          'title': '${widget.groupName}: $currentUserName',
          'body': lastMsgDisplay,
          'senderId': currentUserId,
          'groupId': widget.groupId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("SEND ERROR => $e");
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      setState(() => _isUploading = true);
      String? url = await ChatStorageService.uploadFile(
        file: File(pickedFile.path),
        groupId: widget.groupId,
        type: 'image',
      );
      setState(() => _isUploading = false);

      if (url != null) {
        _sendMessage(fileUrl: url, type: 'image');
      }
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _isUploading = true);
      String? url = await ChatStorageService.uploadFile(
        file: File(pickedFile.path),
        groupId: widget.groupId,
        type: 'video',
      );
      setState(() => _isUploading = false);

      if (url != null) {
        _sendMessage(fileUrl: url, type: 'video');
      }
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() => _isUploading = true);
      String? url = await ChatStorageService.uploadFile(
        file: File(result.files.single.path!),
        groupId: widget.groupId,
        type: 'file',
      );
      setState(() => _isUploading = false);

      if (url != null) {
        _sendMessage(
          fileUrl: url,
          type: 'file',
          text: result.files.single.name,
        );
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        String filePath =
            '${directory.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';

        const config = RecordConfig();
        await _audioRecorder.start(config, path: filePath);

        setState(() {
          _isRecording = true;
          // _recordingPath = filePath;
        });
        debugPrint("Recording started: $filePath");
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("START REC ERROR => $e");
      setState(() => _isRecording = false);
    }
  }

  Future<void> _stopRecording() async {
    try {
      if (!_isRecording) return;

      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);

      if (path != null) {
        File file = File(path);
        if (await file.exists()) {
          setState(() => _isUploading = true);
          String? url = await ChatStorageService.uploadFile(
            file: file,
            groupId: widget.groupId,
            type: 'audio',
          );
          setState(() => _isUploading = false);

          if (url != null) {
            _sendMessage(fileUrl: url, type: 'audio');
          }
        }
      }
    } catch (e) {
      debugPrint("STOP REC ERROR => $e");
      setState(() {
        _isRecording = false;
        _isUploading = false;
      });
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.image, color: Colors.teal),
                title: const Text('Image'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.teal),
                title: const Text('Video'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.insert_drive_file,
                  color: Colors.teal,
                ),
                title: const Text('File'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _clearChat() async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Clear Chat'),
            content: const Text(
              'Are you sure you want to clear this chat? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Clear', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      var snapshot = await _firestore
          .collection('chat_groups')
          .doc(widget.groupId)
          .collection('messages')
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      await _firestore.collection('chat_groups').doc(widget.groupId).update({
        'last_message': '',
        'last_message_time': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat cleared successfully')),
        );
      }
    } catch (e) {
      debugPrint("Error clearing chat: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupInfoScreen(
                  groupId: widget.groupId,
                  groupName: widget.groupName,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.groupName.toUpperCase(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('chat_groups')
                    .doc(widget.groupId)
                    .collection('members')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();

                  var members = snapshot.data!.docs;
                  var typingMembers = members.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return data['is_typing'] == true && doc.id != currentUserId;
                  }).toList();

                  if (typingMembers.isNotEmpty) {
                    String typingText = typingMembers.length == 1
                        ? '${typingMembers[0]['name']} is typing...'
                        : '${typingMembers.length} people are typing...';
                    return Text(
                      typingText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  }

                  int count = members.length;
                  return Text(
                    '$count Members',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupInfoScreen(
                    groupId: widget.groupId,
                    groupName: widget.groupName,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'clear_chat') {
                _clearChat();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'clear_chat',
                  child: Text('Clear Chat'),
                ),
              ];
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          /// Chat Messages Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chat_groups')
                  .doc(widget.groupId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var docs = snapshot.data!.docs;
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isMe = data['sender_id'] == currentUserId;

                    Timestamp? currentTs = data['timestamp'] as Timestamp?;
                    bool showDateHeader = false;
                    String dateLabel = "";

                    if (currentTs != null) {
                      DateTime currentDate = currentTs.toDate();

                      if (index == docs.length - 1) {
                        showDateHeader = true;
                        dateLabel = _getFormattedDate(currentDate);
                      } else {
                        Timestamp? nextTs = docs[index + 1].data() != null
                            ? (docs[index + 1].data()
                                      as Map<String, dynamic>)['timestamp']
                                  as Timestamp?
                            : null;

                        if (nextTs != null) {
                          DateTime nextDate = nextTs.toDate();
                          if (currentDate.day != nextDate.day ||
                              currentDate.month != nextDate.month ||
                              currentDate.year != nextDate.year) {
                            showDateHeader = true;
                            dateLabel = _getFormattedDate(currentDate);
                          }
                        }
                      }
                    }

                    return Column(
                      children: [
                        if (showDateHeader) ...[
                          const SizedBox(height: 20),
                          _buildDateBadge(dateLabel),
                          const SizedBox(height: 12),
                        ],
                        isMe
                            ? _rightMessage(context, data)
                            : _leftMessage(context, data),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          /// Typing Indicator (Floating at bottom of list)
          _buildBodyTypingIndicator(),

          /// Input Bar
          _chatInput(context),
        ],
      ),
    );
  }

  Widget _buildBodyTypingIndicator() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chat_groups')
          .doc(widget.groupId)
          .collection('members')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        var typingMembers = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return data['is_typing'] == true && doc.id != currentUserId;
        }).toList();

        if (typingMembers.isEmpty) return const SizedBox.shrink();

        String typingText = typingMembers.length == 1
            ? '${typingMembers[0]['name']} is typing'
            : '${typingMembers.length} people are typing';

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      typingText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _TypingDots(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateBadge(String label) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xffA6FFF7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF2AA89A),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return 'Today';
    } else if (date.day == yesterday.day &&
        date.month == yesterday.month &&
        date.year == yesterday.year) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM dd, yyyy').format(date);
    }
  }

  Widget _buildMessageContent(Map<String, dynamic> data) {
    String type = data['type'] ?? 'text';
    String text = data['text'] ?? '';
    String? fileUrl = data['file_url'];

    switch (type) {
      case 'image':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                // Show full screen image
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  fileUrl!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.error),
                ),
              ),
            ),
            if (text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(text),
              ),
          ],
        );
      case 'video':
        return VideoPlayerWidget(url: fileUrl!);
      case 'audio':
        return AudioPlayerWidget(url: fileUrl!);
      case 'file':
        return InkWell(
          onTap: () async {
            if (await canLaunchUrl(Uri.parse(fileUrl!))) {
              await launchUrl(
                Uri.parse(fileUrl),
                mode: LaunchMode.externalApplication,
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.insert_drive_file, color: Colors.teal),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    text,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        );
      default:
        return Text(
          text,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        );
    }
  }

  Widget _leftMessage(BuildContext context, Map<String, dynamic> data) {
    String name = data['sender_name'] ?? 'User';
    Timestamp? ts = data['timestamp'];
    String time = ts != null ? DateFormat('hh:mm a').format(ts.toDate()) : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 60, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.zero,
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF00897B),
                  ),
                ),
                const SizedBox(height: 4),
                _buildMessageContent(data),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rightMessage(BuildContext context, Map<String, dynamic> data) {
    Timestamp? ts = data['timestamp'];
    String time = ts != null ? DateFormat('hh:mm a').format(ts.toDate()) : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(60, 4, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.zero,
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMessageContent(data),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.teal.shade700.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.done_all,
                      size: 14,
                      color: Color(0xFF26A69A),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatInput(BuildContext context) {
    if (_isUploading) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(child: LinearProgressIndicator(color: Color(0xFF2AA89A))),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file, color: Colors.grey),
                      onPressed: _showAttachmentOptions,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        onChanged: (text) {
                          bool isNotEmpty = text.trim().isNotEmpty;
                          if (isNotEmpty != _isComposing) {
                            setState(() {
                              _isComposing = isNotEmpty;
                            });
                          }

                          if (isNotEmpty) {
                            _updateTypingStatus(true);
                            _typingTimer?.cancel();
                            _typingTimer = Timer(
                              const Duration(seconds: 2),
                              () {
                                _updateTypingStatus(false);
                              },
                            );
                          } else {
                            _updateTypingStatus(false);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: _isRecording
                              ? 'Recording...'
                              : 'Type a message...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (!_isRecording)
                      _isComposing
                          ? IconButton(
                              icon: const Icon(
                                Icons.send,
                                color: Color(0xFF2AA89A),
                              ),
                              onPressed: () => _sendMessage(),
                            )
                          : GestureDetector(
                              onLongPress: _startRecording,
                              onLongPressUp: _stopRecording,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Long press to record audio message',
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                color: Colors.transparent,
                                child: Icon(
                                  _isRecording ? Icons.mic : Icons.mic_none,
                                  color: const Color(0xFF2AA89A),
                                ),
                              ),
                            ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  @override
  _TypingDotsState createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            double opacity = (0.3 + ((_animation.value * 3 - index) % 3) / 3)
                .clamp(0.2, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.teal.shade700.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
