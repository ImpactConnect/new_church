import 'package:cloud_firestore/cloud_firestore.dart';

enum PostType { post, question, article }

class CommunityPost {
  CommunityPost({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.type = PostType.post,
    this.likedBy = const [],
    this.imageUrls,
    this.bannerUrl,
    this.viewsCount = 0,
  });

  // Convert Firestore document to CommunityPost object
  factory CommunityPost.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Parse PostType safely
    PostType parsedType = PostType.post;
    if (data['post_type'] != null) {
      final typeStr = data['post_type'].toString();
      if (typeStr == 'question') parsedType = PostType.question;
      if (typeStr == 'article') parsedType = PostType.article;
    }

    return CommunityPost(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['author_id'] ?? '',
      authorName: data['author_name'] ?? '',
      createdAt: data['created_at'] ?? Timestamp.now(),
      likesCount: data['likes_count'] ?? 0,
      commentsCount: data['comments_count'] ?? 0,
      type: parsedType,
      likedBy: List<String>.from(data['liked_by'] ?? []),
      imageUrls: data['image_urls'] != null ? List<String>.from(data['image_urls']) : null,
      bannerUrl: data['banner_url'],
      viewsCount: data['views_count'] ?? 0,
    );
  }
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final Timestamp createdAt;
  final int likesCount;
  final int commentsCount;
  final PostType type;
  final List<String> likedBy;
  final List<String>? imageUrls;
  final String? bannerUrl;
  final int viewsCount;

  // Convert CommunityPost to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'author_id': authorId,
      'author_name': authorName,
      'created_at': createdAt,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'post_type': type.name,
      'liked_by': likedBy,
      if (imageUrls != null) 'image_urls': imageUrls,
      if (bannerUrl != null) 'banner_url': bannerUrl,
      'views_count': viewsCount,
    };
  }

  // Get a preview of the content (first 100 characters)
  String get contentPreview {
    return content.length > 100 ? '${content.substring(0, 100)}...' : content;
  }
}
