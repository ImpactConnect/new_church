import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:church_mobile/models/member.dart';
import 'package:flutter/material.dart';
import '../../services/community_auth_service.dart';
import '../../screens/community/private_chat_screen.dart';

class MemberDetailsDialog extends StatelessWidget {
  const MemberDetailsDialog({Key? key, required this.member}) : super(key: key);
  final Member member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = member.name
        .trim()
        .split(' ')
        .map((p) => p.isNotEmpty ? p[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header with gradient ────────────────────────────────────
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.primaryColor,
                    theme.primaryColorDark,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Pattern overlay
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.08,
                      child: Container(
                        decoration: const BoxDecoration(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                      ),
                    ),
                  ),
                  // Close button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  // Avatar + Name
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 38,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          backgroundImage: member.imageUrl != null
                              ? NetworkImage(member.imageUrl!)
                              : null,
                          child: member.imageUrl == null
                              ? Text(initials,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold))
                              : null,
                        ),
                        const SizedBox(height: 10),
                        Text(member.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        if (member.profession != null &&
                            member.profession!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(member.profession!,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Status badges ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (member.gender != null)
                    _badge(
                      member.gender == 'male' ? Icons.male : Icons.female,
                      member.gender == 'male' ? 'Male' : 'Female',
                      member.gender == 'male'
                          ? Colors.blue
                          : Colors.pink,
                    ),
                  if (member.maritalStatus != null) ...[
                    const SizedBox(width: 8),
                    _badge(
                      Icons.favorite_outline,
                      member.maritalStatus!.toDisplayString(),
                      Colors.purple,
                    ),
                  ],
                  if (member.churchGroups.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _badge(
                      Icons.group_outlined,
                      member.churchGroups.first,
                      Colors.teal,
                    ),
                  ],
                ],
              ),
            ),

            const Divider(height: 1),

            // ── Details list ────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoTile(Icons.phone_outlined, 'Phone',
                        member.phoneNumber ?? 'Not provided'),
                    _infoTile(Icons.email_outlined, 'Email',
                        member.email ?? 'Not provided'),
                    _infoTile(Icons.location_on_outlined, 'Address',
                        member.residentAddress ?? member.address ?? 'Not provided'),
                    _infoTile(
                        Icons.cake_outlined,
                        'Birthday',
                        member.birthDate != null
                            ? _formatDate(member.birthDate!)
                            : 'Not provided'),
                    if (member.weddingDate != null)
                      _infoTile(Icons.celebration_outlined, 'Wedding Anniversary',
                          _formatDate(member.weddingDate!)),
                    if (member.spouseName != null &&
                        member.spouseName!.isNotEmpty)
                      _infoTile(Icons.people_outlined, 'Spouse',
                          member.spouseName!),
                    if (member.churchGroups.isNotEmpty)
                      _infoTile(Icons.groups_outlined, 'Groups',
                          member.churchGroups.join(', ')),
                  ],
                ),
              ),
            ),

            // ── Action buttons ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('Message'),
                      onPressed: () => _startChat(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: Colors.grey[600]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month]}, ${date.year}';
  }

  Future<void> _startChat(BuildContext context) async {
    final authService = CommunityAuthService();
    final currentUser = await authService.getCurrentUser();

    if (currentUser == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to the community first.')),
      );
      return;
    }

    if (currentUser.memberId == member.id) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't message yourself.")),
      );
      return;
    }

    final otherUserId = member.id;
    final String chatId = currentUser.id.compareTo(otherUserId) < 0
        ? '${currentUser.id}_$otherUserId'
        : '${otherUserId}_${currentUser.id}';

    final chatRef =
        FirebaseFirestore.instance.collection('private_chats').doc(chatId);
    final chatDoc = await chatRef.get();
    if (!chatDoc.exists) {
      await chatRef.set({
        'participants': [currentUser.id, otherUserId],
        'participantNames': {
          currentUser.id: currentUser.displayName.isNotEmpty
              ? currentUser.displayName
              : currentUser.username,
          otherUserId: member.name,
        },
        'participantAvatars': {
          currentUser.id: '',
          otherUserId: member.imageUrl ?? '',
        },
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': {
          currentUser.id: 0,
          otherUserId: 0,
        }
      });
    }

    if (!context.mounted) return;
    Navigator.of(context).pop();
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PrivateChatScreen(
            chatId: chatId,
            otherUserId: otherUserId,
            otherUserName: member.name,
            currentUser: currentUser,
          ),
        ));
  }
}
