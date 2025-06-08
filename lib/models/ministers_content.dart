import 'package:cloud_firestore/cloud_firestore.dart';

class MinistersContent {
  final String id;
  final String imageUrl;
  final String content;
  final DateTime createdAt;
  final String title;

  MinistersContent({
    required this.id,
    required this.imageUrl,
    required this.content,
    required this.createdAt,
    required this.title,
  });

  factory MinistersContent.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MinistersContent(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      content: data['content'] ?? '',
      title: data['title'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'imageUrl': imageUrl,
      'content': content,
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
