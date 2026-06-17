import 'package:cloud_firestore/cloud_firestore.dart';

class VideoItem {
  const VideoItem({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.views,
    required this.likes,
    required this.postedDate,
    this.description,
    this.category,
  });

  factory VideoItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoItem(
      id: doc.id,
      title: data['title'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      views: data['views'] ?? 0,
      likes: data['likes'] ?? 0,
      postedDate: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      description: data['description'] as String?,
      category: data['category'] as String?,
    );
  }

  final String id;
  final String title;
  final String thumbnailUrl;
  final String videoUrl;
  final int views;
  final int likes;
  final DateTime postedDate;
  final String? description;
  final String? category;

  VideoItem copyWith({
    String? id,
    String? title,
    String? thumbnailUrl,
    String? videoUrl,
    int? views,
    int? likes,
    DateTime? postedDate,
    String? description,
    String? category,
  }) {
    return VideoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      postedDate: postedDate ?? this.postedDate,
      description: description ?? this.description,
      category: category ?? this.category,
    );
  }
}
