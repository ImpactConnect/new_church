import re

with open('lib/screens/community/group_chat_screen.dart', 'r') as f:
    content = f.read()

# 1. Class name replacements
content = content.replace('GroupChatScreen', 'PrivateChatScreen')
content = content.replace('_GroupChatScreenState', '_PrivateChatScreenState')

# 2. Field replacements
content = content.replace('final String groupId;', 'final String chatId;\n  final String otherUserId;\n  final String otherUserName;')
content = content.replace('required this.groupId,', 'required this.chatId,\n    required this.otherUserId,\n    required this.otherUserName,')
content = content.replace('required this.groupName,', '')
content = content.replace('final String groupName;', '')

# 3. Usage replacements
content = content.replace('widget.groupId', 'widget.chatId')
content = content.replace('widget.groupName', 'widget.otherUserName')

# 4. Storage and Firestore Paths
content = content.replace("'group_messages/${widget.chatId}/$fileName'", "'private_chats/${widget.chatId}/messages/$fileName'")

# Firestore Message query
content = content.replace(
    "_firestore.collection('group_messages').where('groupId', isEqualTo: widget.chatId)",
    "_firestore.collection('private_chats').doc(widget.chatId).collection('messages')"
)

# Firestore Message insert
content = content.replace(
    "_firestore.collection('group_messages').add({",
    "_firestore.collection('private_chats').doc(widget.chatId).collection('messages').add({"
)

# Remove the 'groupId' field from the inserted doc
content = content.replace("'groupId': widget.chatId,", "")

# 5. Metadata Update
old_metadata = """      await _firestore.collection('community_groups').doc(widget.chatId).update({
        'lastMessage': lastMsgStr,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderName': senderName,
      });"""

new_metadata = """      await _firestore.collection('private_chats').doc(widget.chatId).set({
        'lastMessage': lastMsgStr,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': {
           widget.otherUserId: FieldValue.increment(1),
        }
      }, SetOptions(merge: true));"""
content = content.replace(old_metadata, new_metadata)

# 6. Remove group info from appbar onTap
content = re.sub(r'void _showGroupInfo\(\) \{.*?(?=\n  Widget _buildMessageBubble)', '', content, flags=re.DOTALL)

# 7. Remove action from AppBar and update onTap
content = content.replace('onTap: _showGroupInfo,', '')
content = re.sub(r'actions: \[.*?\]\,', '', content, flags=re.DOTALL)

# 8. Reset unread count when opening screen
init_state = """  @override
  void initState() {
    super.initState();
    
    // Clear unread count for current user
    _firestore.collection('private_chats').doc(widget.chatId).set({
      'unreadCount': {
         widget.currentUser.id: 0,
      }
    }, SetOptions(merge: true));

    _focusNode.addListener(() {"""

content = content.replace("""  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {""", init_state)

with open('lib/screens/community/private_chat_screen.dart', 'w') as f:
    f.write(content)

