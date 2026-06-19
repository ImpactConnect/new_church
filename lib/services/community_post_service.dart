import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community_post.dart';
import '../models/community_user.dart';

class CommunityPostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new post
  Future<CommunityPost?> createPost({
    required CommunityUser author,
    required String title,
    required String content,
    PostType type = PostType.post,
    List<String>? imageUrls,
    String? bannerUrl,
  }) async {
    try {
      // Create post document
      final DocumentReference postRef =
          _firestore.collection('community_posts').doc();

      final CommunityPost newPost = CommunityPost(
        id: postRef.id,
        title: title,
        content: content,
        authorId: author.id,
        authorName: author.displayName,
        createdAt: Timestamp.now(),
        type: type,
        imageUrls: imageUrls,
        bannerUrl: bannerUrl,
      );

      // Save to Firestore
      await postRef.set(newPost.toFirestore());

      return newPost;
    } catch (e) {
      print('Error creating post: $e');
      return null;
    }
  }

  // Get all posts (paginated)
  Stream<List<CommunityPost>> getPosts({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) {
    Query query = _firestore
        .collection('community_posts')
        .orderBy('created_at', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CommunityPost.fromFirestore(doc))
          .toList();
    });
  }

  // Like / Unlike a post
  Future<bool> likePost(String postId, String userId) async {
    try {
      final DocumentReference postRef =
          _firestore.collection('community_posts').doc(postId);

      await _firestore.runTransaction((transaction) async {
        final DocumentSnapshot postSnapshot = await transaction.get(postRef);

        if (!postSnapshot.exists) {
          throw Exception('Post does not exist');
        }

        final List<dynamic> likedByDynamic = postSnapshot.data() is Map 
            ? (postSnapshot.data() as Map<String, dynamic>)['liked_by'] ?? []
            : [];
            
        final List<String> likedBy = List<String>.from(likedByDynamic);
        final int currentLikes = postSnapshot['likes_count'] ?? 0;

        if (likedBy.contains(userId)) {
          // Unlike
          transaction.update(postRef, {
            'liked_by': FieldValue.arrayRemove([userId]),
            'likes_count': currentLikes > 0 ? currentLikes - 1 : 0,
          });
        } else {
          // Like
          transaction.update(postRef, {
            'liked_by': FieldValue.arrayUnion([userId]),
            'likes_count': currentLikes + 1,
          });
        }
      });

      return true;
    } catch (e) {
      print('Error liking/unliking post: $e');
      return false;
    }
  }

  // Like / Unlike a comment
  Future<bool> likeComment(String commentId, String userId) async {
    try {
      final DocumentReference commentRef =
          _firestore.collection('community_comments').doc(commentId);

      await _firestore.runTransaction((transaction) async {
        final DocumentSnapshot commentSnapshot = await transaction.get(commentRef);

        if (!commentSnapshot.exists) {
          throw Exception('Comment does not exist');
        }

        final List<dynamic> likedByDynamic = commentSnapshot.data() is Map 
            ? (commentSnapshot.data() as Map<String, dynamic>)['liked_by'] ?? []
            : [];
            
        final List<String> likedBy = List<String>.from(likedByDynamic);
        final int currentLikes = commentSnapshot['likes_count'] ?? 0;

        if (likedBy.contains(userId)) {
          // Unlike
          transaction.update(commentRef, {
            'liked_by': FieldValue.arrayRemove([userId]),
            'likes_count': currentLikes > 0 ? currentLikes - 1 : 0,
          });
        } else {
          // Like
          transaction.update(commentRef, {
            'liked_by': FieldValue.arrayUnion([userId]),
            'likes_count': currentLikes + 1,
          });
        }
      });

      return true;
    } catch (e) {
      print('Error liking/unliking comment: $e');
      return false;
    }
  }

  // Get post details
  Future<CommunityPost?> getPostById(String postId) async {
    try {
      final DocumentSnapshot postDoc =
          await _firestore.collection('community_posts').doc(postId).get();

      return CommunityPost.fromFirestore(postDoc);
    } catch (e) {
      print('Error fetching post: $e');
      return null;
    }
  }
}
