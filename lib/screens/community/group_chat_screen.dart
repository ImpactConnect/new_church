import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:swipe_to/swipe_to.dart';
import '../../models/community_user.dart';

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({
    Key? key,
    required this.groupId,
    required this.groupName,
    required this.currentUser,
  }) : super(key: key);

  final String groupId;
  final String groupName;
  final CommunityUser currentUser;

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FocusNode _focusNode = FocusNode();
  bool _isEmojiVisible = false;
  Map<String, dynamic>? _replyingToMessage;

  void _replyToMessage(Map<String, dynamic> msgData) {
    setState(() {
      _replyingToMessage = msgData;
      _focusNode.requestFocus();
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToMessage = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _isEmojiVisible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<bool> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.storage,
      Permission.photos,
    ].request();
    return true;
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 180,
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _attachmentIcon(Icons.insert_drive_file, Colors.indigo, 'Document', () async {
                Navigator.pop(context);
                await _requestPermissions();
                final result = await fp.FilePicker.pickFiles();
                if (result != null && result.files.single.path != null) {
                  _uploadFile(File(result.files.single.path!), 'document');
                }
              }),
              _attachmentIcon(Icons.camera_alt, Colors.pink, 'Camera', () async {
                Navigator.pop(context);
                await _requestPermissions();
                final picked = await ImagePicker().pickImage(source: ImageSource.camera);
                if (picked != null) _uploadFile(File(picked.path), 'image');
              }),
              _attachmentIcon(Icons.insert_photo, Colors.purple, 'Gallery', () async {
                Navigator.pop(context);
                await _requestPermissions();
                final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (picked != null) _uploadFile(File(picked.path), 'image');
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachmentIcon(IconData icon, Color color, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  Future<void> _uploadFile(File file, String fileType) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading attachment...')));
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = FirebaseStorage.instance.ref('group_messages/${widget.groupId}/$fileName');
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      await _sendMessageData(message: '', fileUrl: downloadUrl, fileType: fileType);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    await _sendMessageData(message: text);
  }

  Future<void> _sendMessageData({required String message, String? fileUrl, String? fileType}) async {
    try {
      final senderName = widget.currentUser.displayName.isNotEmpty
          ? widget.currentUser.displayName
          : widget.currentUser.username;

      final Map<String, dynamic>? replyTo = _replyingToMessage != null
          ? {
              'senderName': _replyingToMessage!['senderName'],
              'message': _replyingToMessage!['message'],
              'fileType': _replyingToMessage!['fileType'],
            }
          : null;
          
      if (_replyingToMessage != null) {
        setState(() {
          _replyingToMessage = null;
        });
      }

      await _firestore.collection('group_messages').add({
        'groupId': widget.groupId,
        'senderId': widget.currentUser.id,
        'senderName': senderName,
        'message': message,
        'fileUrl': fileUrl,
        'fileType': fileType,
        'replyTo': replyTo,
        'timestamp': FieldValue.serverTimestamp(),
      });

      String lastMsgStr = message;
      if (fileUrl != null) {
        lastMsgStr = fileType == 'image' ? '📷 Image' : '📎 Document';
      }

      await _firestore.collection('community_groups').doc(widget.groupId).update({
        'lastMessage': lastMsgStr,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderName': senderName,
      });

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  void _showGroupInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF0F2F5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: StreamBuilder<DocumentSnapshot>(
                stream: _firestore.collection('community_groups').doc(widget.groupId).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  final name = data['name'] ?? widget.groupName;
                  final desc = data['description'] ?? '';
                  final imageUrl = data['imageUrl'] ?? '';
                  final memberIds = List<String>.from(data['members'] ?? []);

                  return StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('members').snapshots(),
                    builder: (context, memberSnap) {
                      if (!memberSnap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final members = memberSnap.data!.docs.where((doc) {
                        final mData = doc.data() as Map<String, dynamic>;
                        final List<dynamic> mGroups = mData['churchGroups'] ?? (mData['churchGroup'] != null && mData['churchGroup'].toString().isNotEmpty ? [mData['churchGroup']] : []);
                        final isManuallyAdded = memberIds.contains(doc.id);
                        final isInChurchGroup = mGroups.contains(name);
                        return isManuallyAdded || isInChurchGroup;
                      }).toList();

                      return ListView(
                        controller: scrollController,
                        children: [
                      // Header Drag indicator
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      // Group Profile Card
                      Container(
                        color: Colors.white,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                              backgroundColor: const Color(0xFFDFE5E7),
                              child: imageUrl.isEmpty
                                  ? const Icon(Icons.group, size: 70, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              name,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111B21)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Group · ${members.length} members',
                              style: const TextStyle(fontSize: 14, color: Color(0xFF667781)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Group Description Card
                      if (desc.isNotEmpty) ...[
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Group Description',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF008069)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                desc,
                                style: const TextStyle(fontSize: 15, color: Color(0xFF111B21), height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Members list card
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${members.length} Members',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF667781)),
                            ),
                            const Divider(),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: members.length,
                              itemBuilder: (context, index) {
                                final mData = members[index].data() as Map<String, dynamic>;
                                final mName = mData['name'] ?? 'Unknown Member';
                                final List<dynamic> mGroups = mData['churchGroups'] ?? (mData['churchGroup'] != null && mData['churchGroup'].toString().isNotEmpty ? [mData['churchGroup']] : []);
                                final String mGroup = mGroups.isNotEmpty ? mGroups.join(', ') : '';
                                final isMe = members[index].id == widget.currentUser.id;

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFDFE5E7),
                                    child: Text(mName[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                                  ),
                                  title: Text(
                                    isMe ? '$mName (You)' : mName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111B21)),
                                  ),
                                  subtitle: mGroup.isNotEmpty ? Text(mGroup) : null,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
          },
        );
      },
    );
  }

  String _formatMessageTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return DateFormat('h:mm a').format(date);
  }

  bool _isDifferentDay(Timestamp? t1, Timestamp? t2) {
    if (t1 == null || t2 == null) return false;
    final d1 = t1.toDate();
    final d2 = t2.toDate();
    return d1.year != d2.year || d1.month != d2.month || d1.day != d2.day;
  }

  String _formatDividerDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'TODAY';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'YESTERDAY';
    } else {
      return DateFormat('MMMM d, yyyy').format(date).toUpperCase();
    }
  }

  Color _getSenderColor(String senderName) {
    // Generate deterministic color based on sender name
    final hash = senderName.hashCode;
    final colors = [
      const Color(0xFF1F618D),
      const Color(0xFFB9770E),
      const Color(0xFF117A65),
      const Color(0xFF9B59B6),
      const Color(0xFFA04000),
      const Color(0xFF17202A),
      const Color(0xFF7D6608),
      const Color(0xFF0E6251),
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('community_groups').doc(widget.groupId).snapshots(),
      builder: (context, groupSnap) {
        String groupName = widget.groupName;
        String imageUrl = '';
        List<String> memberIds = [];

        if (groupSnap.hasData && groupSnap.data!.exists) {
          final data = groupSnap.data!.data() as Map<String, dynamic>? ?? {};
          groupName = data['name'] ?? widget.groupName;
          imageUrl = data['imageUrl'] ?? '';
          memberIds = List<String>.from(data['members'] ?? []);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFE5DDD5), // WhatsApp beige wallpaper color
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 1,
            titleSpacing: 0,
            leadingWidth: 40,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF008069)),
              onPressed: () => Navigator.pop(context),
            ),
            title: InkWell(
              onTap: _showGroupInfo,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                    backgroundColor: const Color(0xFFDFE5E7),
                    child: imageUrl.isEmpty ? const Icon(Icons.group, size: 20, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groupName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111B21)),
                          overflow: TextOverflow.ellipsis,
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: _firestore.collection('members').snapshots(),
                          builder: (context, memberSnap) {
                            String subtitle = 'Tap for group info';
                            if (memberSnap.hasData) {
                              final names = memberSnap.data!.docs
                                  .where((doc) => memberIds.contains(doc.id))
                                  .map((doc) => (doc.data() as Map)['name'] as String? ?? '')
                                  .where((n) => n.isNotEmpty)
                                  .toList();
                              if (names.isNotEmpty) {
                                subtitle = names.join(', ');
                              }
                            }
                            return Text(
                              subtitle,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF667781)),
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline, color: Color(0xFF008069)),
                onPressed: _showGroupInfo,
              ),
            ],
          ),
          body: Column(
            children: [
              // Message List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('group_messages')
                      .where('groupId', isEqualTo: widget.groupId)
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Messages are end-to-end encrypted.\nNo one outside of this group can read them.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF667781), fontSize: 13, height: 1.4),
                          ),
                        ),
                      );
                    }

                    final messages = snapshot.data!.docs;

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msgDoc = messages[index];
                        final msgData = msgDoc.data() as Map<String, dynamic>;
                        final senderId = msgData['senderId'] ?? '';
                        final senderName = msgData['senderName'] ?? 'Unknown';
                        final messageText = msgData['message'] ?? '';
                        final fileUrl = msgData['fileUrl'] as String?;
                        final fileType = msgData['fileType'] as String?;
                        final timestamp = msgData['timestamp'] as Timestamp?;
                        final isMe = senderId == widget.currentUser.id;
                        final replyTo = msgData['replyTo'] as Map<String, dynamic>?;

                        final showDivider = index == messages.length - 1 ||
                            _isDifferentDay(timestamp, messages[index + 1]['timestamp'] as Timestamp?);

                        return Column(
                          children: [
                            if (showDivider) ...[
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 1,
                                      offset: const Offset(0, 1),
                                    )
                                  ],
                                ),
                                child: Text(
                                  _formatDividerDate(timestamp),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF54656F),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                            SwipeTo(
                              onRightSwipe: (details) {
                                _replyToMessage(msgData);
                              },
                              child: _buildMessageBubble(
                                senderName: senderName,
                                text: messageText,
                                timeStr: _formatMessageTime(timestamp),
                                isMe: isMe,
                                fileUrl: fileUrl,
                                fileType: fileType,
                                replyTo: replyTo,
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              // Message Input Field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                color: const Color(0xFFF0F2F5), // WhatsApp grey input tray
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Reply Preview
                      if (_replyingToMessage != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5DDD5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(width: 4, height: 40, color: const Color(0xFF008069)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _replyingToMessage!['senderName'] ?? 'Unknown',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF008069), fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      (_replyingToMessage!['fileType'] != null)
                                          ? (_replyingToMessage!['fileType'] == 'image' ? '📷 Image' : '📎 Document')
                                          : _replyingToMessage!['message'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20, color: Colors.black54),
                                onPressed: _cancelReply,
                              ),
                            ],
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(_isEmojiVisible ? Icons.keyboard : Icons.insert_emoticon, color: const Color(0xFF667781)),
                                    onPressed: () {
                                      if (_isEmojiVisible) {
                                        _focusNode.requestFocus();
                                      } else {
                                        _focusNode.unfocus();
                                        setState(() => _isEmojiVisible = true);
                                      }
                                    },
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _messageController,
                                      focusNode: _focusNode,
                                      maxLines: 4,
                                      minLines: 1,
                                      style: const TextStyle(fontSize: 15, color: Color(0xFF111B21)),
                                      decoration: const InputDecoration(
                                        hintText: 'Type a message',
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.attach_file, color: Color(0xFF667781)),
                                    onPressed: _showAttachmentOptions,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _sendTextMessage,
                            child: const Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: CircleAvatar(
                                radius: 22,
                                backgroundColor: Color(0xFF008069), // WhatsApp green send button
                                child: Icon(Icons.send, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Emoji Picker
                      if (_isEmojiVisible)
                        SizedBox(
                          height: 250,
                          child: EmojiPicker(
                            textEditingController: _messageController,
                            config: const Config(
                              emojiViewConfig: EmojiViewConfig(backgroundColor: Color(0xFFF0F2F5)),
                              bottomActionBarConfig: BottomActionBarConfig(showBackspaceButton: true),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble({
    required String senderName,
    required String text,
    required String timeStr,
    required bool isMe,
    String? fileUrl,
    String? fileType,
    Map<String, dynamic>? replyTo,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFD9FDD3) : Colors.white, // WhatsApp green vs white bubble
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMe ? 12 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 1,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(
                bottom: 12,
                top: isMe ? 0 : 4,
                right: 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMe) ...[
                    Text(
                      senderName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        color: _getSenderColor(senderName),
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  if (replyTo != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 4, height: 35, color: _getSenderColor(replyTo['senderName'] ?? '')),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  replyTo['senderName'] ?? 'Unknown',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _getSenderColor(replyTo['senderName'] ?? '')),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  (replyTo['fileType'] != null)
                                      ? (replyTo['fileType'] == 'image' ? '📷 Image' : '📎 Document')
                                      : replyTo['message'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (fileUrl != null && fileUrl.isNotEmpty) ...[
                    if (fileType == 'image')
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: fileUrl,
                          width: 220,
                          height: 220,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 220, height: 220,
                            color: Colors.black12,
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 220, height: 220,
                            color: Colors.black12,
                            child: const Icon(Icons.error, color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.insert_drive_file, color: Colors.black54),
                            const SizedBox(width: 8),
                            const Text('Document attached', style: TextStyle(fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    if (text.isNotEmpty) const SizedBox(height: 4),
                  ],
                  if (text.isNotEmpty)
                    Text(
                      text,
                      style: const TextStyle(
                        color: Color(0xFF111B21),
                        fontSize: 14.5,
                        height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: Color(0xFF667781),
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.done_all,
                      size: 15,
                      color: Color(0xFF53BDEB), // WhatsApp blue read ticks
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
