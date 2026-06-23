import 'package:flutter/material.dart';

import '../../models/community_comment.dart';
import '../../models/community_post.dart';
import '../../models/community_user.dart';
import '../../services/community_comment_service.dart';
import '../../services/community_post_service.dart';

class CommunityPostDetailsScreen extends StatefulWidget {
  const CommunityPostDetailsScreen({
    Key? key,
    required this.post,
    required this.currentUser,
  }) : super(key: key);
  final CommunityPost post;
  final CommunityUser currentUser;

  @override
  _CommunityPostDetailsScreenState createState() =>
      _CommunityPostDetailsScreenState();
}

class _CommunityPostDetailsScreenState
    extends State<CommunityPostDetailsScreen> {
  final CommunityPostService _postService = CommunityPostService();
  final CommunityCommentService _commentService = CommunityCommentService();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  bool _isLiked = false;
  CommunityComment? _replyingTo;
  late Stream<List<CommunityComment>> _commentsStream;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.likedBy.contains(widget.currentUser.id);
    _commentsStream = _commentService.getComments(widget.post.id);
  }

  Future<void> _likePost() async {
    final bool success =
        await _postService.likePost(widget.post.id, widget.currentUser.id);

    if (success) {
      setState(() {
        _isLiked = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post liked!')),
      );
    }
  }

  Future<void> _submitComment() async {
    print('Submit Comment Called');
    print('Comment Text: ${_commentController.text}');
    print('Post ID: ${widget.post.id}');
    print('Current User: ${widget.currentUser.id}');
    print('Replying To: ${_replyingTo?.id}');

    if (_commentController.text.isEmpty) {
      print('Comment text is empty');
      return;
    }

    try {
      final comment = await _commentService.addComment(
        author: widget.currentUser,
        postId: widget.post.id,
        content: _commentController.text.trim(),
        parentCommentId: _replyingTo?.id,
      );

      print('Comment Added: ${comment?.id}');

      // Clear comment field and reset reply state
      _commentController.clear();
      setState(() {
        _replyingTo = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment added successfully')),
      );
    } catch (e) {
      print('Comment Submission Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment: $e')),
      );
    }
  }

  void _setReplyTo(CommunityComment comment) {
    setState(() {
      _replyingTo = comment;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Column(
            children: [
              // Custom Header for Bottom Sheet
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.keyboard_arrow_down, size: 28, color: isDark ? Colors.white : Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.post.type == PostType.post 
                          ? 'Post' 
                          : widget.post.type == PostType.question 
                              ? 'Question Details' 
                              : 'Article',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.share_outlined, color: isDark ? Colors.white : Colors.black),
                      onPressed: _sharePost,
                    ),
                  ],
                ),
              ),

            // Post Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Topic (Title)
                      if (widget.post.type != PostType.post || widget.post.title.isNotEmpty) ...[
                        Text(
                          widget.post.title,
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Author Information
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.2),
                            child: Text(
                              widget.post.authorName[0].toUpperCase(),
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.post.authorName,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                _formatPostDate(widget.post.createdAt.toDate()),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: isDark ? Colors.white60 : Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Post Content
                      Text(
                        widget.post.content,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.5,
                            ),
                      ),

                      // Interaction Bar
                      const SizedBox(height: 16),
                      _buildInteractionBar(),

                      Divider(height: 32, color: isDark ? Colors.white.withOpacity(0.08) : null),

                      // Comments Section
                      _buildCommentSection(),
                    ],
                  ),
                ),
              ),
            ),

            // Comment Input Bar
            _buildCommentInputBar(),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildCommentInputBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 150, // Limit max height
                  minHeight: 50, // Minimum height
                ),
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null, // Allow multiple lines
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _submitComment,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildInteractionButton(
          icon: Icons.favorite_border,
          count: widget.post.likesCount,
          onTap: _toggleLike,
          activeIcon: Icons.favorite,
          isActive: _isLiked,
        ),
        _buildInteractionButton(
          icon: Icons.comment_outlined,
          count: widget.post.commentsCount,
          onTap: () {
            // Focus on comment input when tapped
            _commentFocusNode.requestFocus();
          },
        ),
        _buildInteractionButton(
          icon: Icons.share_outlined,
          onTap: _sharePost,
        ),
      ],
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    int? count,
    VoidCallback? onTap,
    IconData? activeIcon,
    bool isActive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              isActive ? activeIcon ?? icon : icon,
              color: isActive ? Colors.red : (isDark ? Colors.white60 : Colors.grey[600]),
              size: 24,
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Text(
                count.toString(),
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<CommunityComment>>(
          stream: _commentsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  'No comments yet',
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.length,
              separatorBuilder: (context, index) => Divider(height: 16, color: isDark ? Colors.white.withOpacity(0.08) : null),
              itemBuilder: (context, index) {
                final comment = snapshot.data![index];
                return _buildCommentCard(comment);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommentCard(CommunityComment comment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.2),
                child: Text(
                  comment.authorName[0].toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.authorName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    _formatCommentDate(comment.createdAt.toDate()),
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.content,
            style: TextStyle(
              color: isDark ? Colors.white.withOpacity(0.87) : Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format post date (similar to previous implementation)
  String _formatPostDate(DateTime postDate) {
    final now = DateTime.now();
    final difference = now.difference(postDate);

    if (difference.inDays == 0) {
      if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else {
        return '${difference.inHours}h ago';
      }
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${postDate.day}/${postDate.month}/${postDate.year}';
    }
  }

  // New method to format comment date with more granularity
  String _formatCommentDate(DateTime commentDate) {
    final now = DateTime.now();
    final difference = now.difference(commentDate);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${commentDate.day}/${commentDate.month}/${commentDate.year}';
    }
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
    });
    _likePost();
  }

  void _sharePost() {
    // TODO: Implement post sharing
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }
}
