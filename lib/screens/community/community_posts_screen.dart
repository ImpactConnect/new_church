import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../models/community_post.dart';
import '../../models/community_user.dart';
import '../../services/community_post_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'community_post_details_screen.dart';
import 'create_community_post_screen.dart';
import 'group_chat_screen.dart';

class CommunityPostsScreen extends StatefulWidget {
  const CommunityPostsScreen({Key? key, required this.currentUser})
      : super(key: key);
  final CommunityUser currentUser;

  @override
  _CommunityPostsScreenState createState() => _CommunityPostsScreenState();
}

class _CommunityPostsScreenState extends State<CommunityPostsScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final CommunityPostService _postService = CommunityPostService();
  late TabController _tabController;

  late Stream<List<CommunityPost>> _postsStream;

  @override
  void initState() {
    super.initState();
    _postsStream = _postService.getPosts();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  void _showCreatePostScreen(PostType initialType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateCommunityPostScreen(
        currentUser: widget.currentUser,
        initialType: initialType,
      ),
    );
  }

  void _showDetailsBottomSheet(CommunityPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommunityPostDetailsScreen(
        post: post,
        currentUser: widget.currentUser,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Community', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Modern TabBar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(bottom: 12),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Theme.of(context).primaryColor,
                  boxShadow: [
                    BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(text: 'Feeds'),
                  Tab(text: 'Questions'),
                  Tab(text: 'My Groups'),
                ],
              ),
            ),
          ),
          // Search Bar
          if (_tabController.index != 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search topics...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
          // Tab Content
          Expanded(
            child: StreamBuilder<List<CommunityPost>>(
              stream: _postsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No posts yet.', style: TextStyle(color: Colors.grey)));
                }

                // Filter by search query
                final filteredPosts = snapshot.data!.where((post) {
                  final titleMatches = post.title.toLowerCase().contains(_searchQuery);
                  final contentMatches = post.content.toLowerCase().contains(_searchQuery);
                  return titleMatches || contentMatches;
                }).toList();

                final feeds = filteredPosts.where((p) => p.type == PostType.post || p.type == PostType.article).toList();
                final questions = filteredPosts.where((p) => p.type == PostType.question).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFeedsTab(feeds),
                    _buildQuestionsTab(questions),
                    _buildGroupsTab(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 2
          ? null
          : FloatingActionButton(
              onPressed: () {
                if (_tabController.index == 0) _showCreatePostScreen(PostType.post);
                else if (_tabController.index == 1) _showCreatePostScreen(PostType.question);
              },
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3), // Set to Community index
    );
  }

  Widget _buildFeedsTab(List<CommunityPost> posts) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 80), // Padding for FAB
      children: [
        // Facebook Style "What's on your mind"
        Card(
          margin: const EdgeInsets.all(12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  child: Text(widget.currentUser.displayName.isNotEmpty ? widget.currentUser.displayName[0].toUpperCase() : 'U'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _showCreatePostScreen(PostType.post),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text("What's on your mind?", style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.green),
                  onPressed: () => _showCreatePostScreen(PostType.post),
                ),
              ],
            ),
          ),
        ),
        if (posts.isEmpty)
          const Padding(padding: EdgeInsets.all(32), child: Center(child: Text("No feeds to display", style: TextStyle(color: Colors.grey))))
        else
          ...posts.map((post) => _buildFeedCard(post)).toList(),
      ],
    );
  }

  Widget _buildFeedCard(CommunityPost post) {
    final DateTime postDate = post.createdAt.toDate();
    final String formattedDate = _formatPostDate(postDate);
    final theme = Theme.of(context);
    final hasLiked = post.likedBy.contains(widget.currentUser.id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          _showDetailsBottomSheet(post);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Avatar, Name, Time
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.primaryColor.withValues(alpha: 0.2),
                      child: Text(
                        post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                post.authorName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              if (post.type == PostType.article) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Article',
                                    style: TextStyle(
                                      color: Colors.indigo,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            formattedDate,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_horiz),
                      onPressed: () {},
                    )
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Article Title (if any)
              if (post.type == PostType.article && post.title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12).copyWith(bottom: 6),
                  child: Text(
                    post.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87),
                  ),
                ),

              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  post.content,
                  style: const TextStyle(fontSize: 15),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 10),

              // Image/Banner (if any)
              if (post.type == PostType.article && post.bannerUrl != null)
                Image.network(
                  post.bannerUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  height: 200,
                )
              else if (post.imageUrls != null && post.imageUrls!.isNotEmpty)
                Image.network(
                  post.imageUrls!.first,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  height: 250,
                ),

              const SizedBox(height: 10),
              
              // Interaction counts
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.thumb_up, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text('${post.likesCount}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                    const Spacer(),
                    Icon(Icons.comment_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${post.commentsCount}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                  ],
                ),
              ),
              
              const Divider(height: 20, thickness: 1),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFeedActionButton(
                      icon: hasLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                      label: 'Like',
                      color: hasLiked ? Colors.blue : Colors.grey[700]!,
                      onTap: () => _postService.likePost(post.id, widget.currentUser.id),
                    ),
                    _buildFeedActionButton(
                      icon: Icons.chat_bubble_outline,
                      label: 'Comment',
                      color: Colors.grey[700]!,
                      onTap: () {
                         _showDetailsBottomSheet(post);
                      },
                    ),
                    _buildFeedActionButton(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      color: Colors.grey[700]!,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsTab(List<CommunityPost> questions) {
    if (questions.isEmpty) {
      return const Center(child: Text("No questions asked yet. Be the first!", style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12).copyWith(bottom: 80),
      itemCount: questions.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final post = questions[index];
        return InkWell(
          onTap: () => _showDetailsBottomSheet(post),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Interaction Stats
                Column(
                  children: [
                    const Icon(Icons.keyboard_arrow_up, color: Colors.grey),
                    Text('${post.likesCount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.indigo[800])),
                      const SizedBox(height: 6),
                      Text(post.contentPreview, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[800])),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.comment_outlined, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text('${post.commentsCount} comments', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          const Spacer(),
                          Text('Asked by ${post.authorName} • ${_formatPostDate(post.createdAt.toDate())}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community_groups')
          .where('members', arrayContains: widget.currentUser.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'You do not belong to any groups yet.',
                  style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ask your administrator to assign you to a group.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          );
        }

        final groups = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final groupDoc = groups[index];
            final groupData = groupDoc.data() as Map<String, dynamic>;
            final name = groupData['name'] ?? 'Unnamed Group';
            final imageUrl = groupData['imageUrl'] ?? '';
            
            // Last message details
            final lastMessage = groupData['lastMessage'] ?? '';
            final lastMsgSender = groupData['lastMessageSenderName'] ?? '';
            final lastMsgTime = groupData['lastMessageTime'] as Timestamp?;
            
            String lastMsgText = 'No messages yet';
            if (lastMessage.isNotEmpty) {
              lastMsgText = lastMsgSender.isNotEmpty ? '$lastMsgSender: $lastMessage' : lastMessage;
            }

            String timeStr = '';
            if (lastMsgTime != null) {
              final date = lastMsgTime.toDate();
              final now = DateTime.now();
              if (date.day == now.day && date.month == now.month && date.year == now.year) {
                timeStr = DateFormat('h:mm a').format(date);
              } else if (date.day == now.day - 1 && date.month == now.month && date.year == now.year) {
                timeStr = 'Yesterday';
              } else {
                timeStr = DateFormat('d/M/yy').format(date);
              }
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 3,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupChatScreen(
                        groupId: groupDoc.id,
                        groupName: name,
                        currentUser: widget.currentUser,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: imageUrl.isEmpty
                              ? const Icon(Icons.group, color: Colors.white, size: 30)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF111B21)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (timeStr.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    timeStr,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: lastMessage.isNotEmpty ? Theme.of(context).primaryColor : const Color(0xFF8696A0),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              lastMsgText,
                              style: const TextStyle(
                                color: Color(0xFF667781),
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }
    );
  }

  Widget _buildPostCard(CommunityPost post, {bool isCompact = false}) {
    final DateTime postDate = post.createdAt.toDate();
    final String formattedDate = _formatPostDate(postDate);
    final theme = Theme.of(context);
    final hasLiked = post.likedBy.contains(widget.currentUser.id);

    // Dynamic UI styling based on type
    Color typeColor = Colors.blueGrey;
    String typeLabel = 'Post';
    IconData typeIcon = Icons.article_outlined;

    if (post.type == PostType.question) {
      typeColor = Colors.orange;
      typeLabel = 'Question';
      typeIcon = Icons.help_outline;
    } else if (post.type == PostType.article) {
      typeColor = Colors.indigo;
      typeLabel = 'Article';
      typeIcon = Icons.library_books;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          _showDetailsBottomSheet(post);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article Banner Image
            if (post.type == PostType.article && post.bannerUrl != null)
              Image.network(post.bannerUrl!, height: 160, width: double.infinity, fit: BoxFit.cover),
            
            // Standard Post Image
            if (post.type == PostType.post && post.imageUrls != null && post.imageUrls!.isNotEmpty)
              Image.network(post.imageUrls!.first, height: 200, width: double.infinity, fit: BoxFit.cover),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          children: [
                            Icon(typeIcon, size: 14, color: typeColor),
                            const SizedBox(width: 4),
                            Text(typeLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: typeColor)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(formattedDate, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title & Content
                  if (post.type != PostType.post || post.title.isNotEmpty) ...[
                    Text(post.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                  ],
                  Text(post.contentPreview, maxLines: 3, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
                  
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // Footer (Author & Interactions)
                  Row(
                    children: [
                      CircleAvatar(radius: 12, backgroundColor: theme.primaryColor.withValues(alpha: 0.2), child: Text(post.authorName[0].toUpperCase(), style: const TextStyle(fontSize: 12))),
                      const SizedBox(width: 8),
                      Text(post.authorName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[800])),
                      const Spacer(),
                      
                      // Interaction Buttons
                      InkWell(
                        onTap: () => _postService.likePost(post.id, widget.currentUser.id),
                        child: Row(
                          children: [
                            Icon(hasLiked ? Icons.favorite : Icons.favorite_border, size: 18, color: hasLiked ? Colors.red : Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text('${post.likesCount}', style: TextStyle(color: Colors.grey[700])),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          Icon(Icons.comment_outlined, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text('${post.commentsCount}', style: TextStyle(color: Colors.grey[700])),
                        ],
                      ),
                      if (post.type == PostType.article) ...[
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: 18, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text('${post.viewsCount}', style: TextStyle(color: Colors.grey[700])),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to format post date
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
}
