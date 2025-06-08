import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/blog_post.dart';

class BlogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'blog_posts';

  Stream<List<BlogPost>> getBlogPosts() {
    return _firestore
        .collection(_collection)
        .orderBy('datePosted', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BlogPost.fromFirestore(doc)).toList();
    });
  }

  Future<BlogPost> getBlogPost(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    return BlogPost.fromFirestore(doc);
  }

  Future<void> incrementLikes(String postId) async {
    await _firestore.collection(_collection).doc(postId).update({
      'likes': FieldValue.increment(1),
    });
  }

  Future<void> decrementLikes(String postId) async {
    await _firestore.collection(_collection).doc(postId).update({
      'likes': FieldValue.increment(-1),
    });
  }
}
