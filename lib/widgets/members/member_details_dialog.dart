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

    // Determine gender display
    final genderStr = member.gender?.toLowerCase();
    final genderLabel = genderStr == 'male'
        ? 'Male'
        : genderStr == 'female'
            ? 'Female'
            : member.gender ?? '';
    final genderIcon = genderStr == 'female' ? Icons.female : Icons.male;
    final genderColor = genderStr == 'female' ? Colors.pink : Colors.blue;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header with gradient ──────────────────────────────────────
            Container(
              height: 170,
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
                  // Close button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  // Avatar + Name + Profession
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 38,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
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
                        const SizedBox(height: 8),
                        Text(member.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        if (member.profession != null &&
                            member.profession!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              member.isStudent
                                  ? '🎓 Student${member.schoolName != null && member.schoolName!.isNotEmpty ? ' · ${member.schoolName}' : ''}'
                                  : member.profession!,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12),
                            ),
                          ),
                        // Member status badge
                        if (member.memberStatus != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: member.memberStatus?.toLowerCase() ==
                                      'active'
                                  ? Colors.green.withValues(alpha: 0.25)
                                  : Colors.orange.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color:
                                      Colors.white.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              (member.memberStatus ?? '').toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Status badges ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  if (member.gender != null && member.gender!.isNotEmpty)
                    _badge(genderIcon, genderLabel, genderColor),
                  if (member.maritalStatus != null)
                    _badge(
                      Icons.favorite_outline,
                      member.maritalStatus!.toDisplayString(),
                      Colors.purple,
                    ),
                  if (member.churchGroups.isNotEmpty)
                    for (final g in member.churchGroups)
                      _badge(Icons.group_outlined, g, Colors.teal),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── Details list ──────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Contact Info ───────────────────────────────────
                    _sectionHeader('Contact Information'),
                    _infoTile(Icons.phone_outlined, 'Phone',
                        member.phoneNumber ?? 'Not provided'),
                    _infoTile(Icons.email_outlined, 'Email',
                        member.email ?? 'Not provided'),
                    _infoTile(Icons.location_on_outlined, 'Resident Address',
                        member.residentAddress ?? member.address ?? 'Not provided'),
                    if (member.stateOfOrigin != null &&
                        member.stateOfOrigin!.isNotEmpty)
                      _infoTile(Icons.map_outlined, 'State of Origin',
                          member.stateOfOrigin!),

                    // ── Personal Info ──────────────────────────────────
                    _sectionHeader('Personal Information'),
                    _infoTile(
                      Icons.cake_outlined,
                      'Date of Birth',
                      member.birthDate != null
                          ? _formatDate(member.birthDate!)
                          : 'Not provided',
                    ),
                    if (member.weddingDate != null)
                      _infoTile(Icons.celebration_outlined,
                          'Wedding Anniversary', _formatDate(member.weddingDate!)),
                    if (member.spouseName != null &&
                        member.spouseName!.isNotEmpty)
                      _infoTile(
                          Icons.people_outlined, 'Spouse', member.spouseName!),

                    // ── Ministry Info ──────────────────────────────────
                    _sectionHeader('Ministry Information'),
                    if (member.churchGroups.isNotEmpty)
                      _infoTile(Icons.groups_outlined, 'Groups / Departments',
                          member.churchGroups.join(', ')),
                    if (member.joinDate != null)
                      _infoTile(Icons.calendar_today_outlined, 'Date Joined',
                          _formatDate(member.joinDate!)),
                    if (member.memberStatus != null)
                      _infoTile(
                        Icons.verified_outlined,
                        'Membership Status',
                        _capitalize(member.memberStatus!),
                      ),
                  ],
                ),
              ),
            ),

            // ── Action buttons ────────────────────────────────────────────
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

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: Colors.grey[600]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w500)),
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

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

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
