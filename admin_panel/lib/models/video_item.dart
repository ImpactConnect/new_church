import 'package:cloud_firestore/cloud_firestore.dart';

class VideoItem {
  const VideoItem({
    required this.id,
    required this.title,
    required this.videoUrl,
    required this.views,
    required this.likes,
    required this.postedDate,
    this.thumbnailUrl = '',
    this.category = '',
    this.description = '',
    this.videoType = 'youtube',
    this.isRecommended = false,
  });

  factory VideoItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoItem(
      id: doc.id,
      title: data['title'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      views: data['views'] ?? 0,
      likes: data['likes'] ?? 0,
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      videoType: data['videoType'] ?? 'youtube',
      isRecommended: data['isRecommended'] ?? false,
      postedDate: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  final String id;
  final String title;
  final String videoUrl;
  final String thumbnailUrl;
  final int views;
  final int likes;
  final DateTime postedDate;
  final String category;
  final String description;
  final String videoType;
  final bool isRecommended;
}
