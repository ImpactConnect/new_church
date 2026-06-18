import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum representing the source type of a video.
/// - [youtube]  : A YouTube link (played via youtube_player_iframe)
/// - [facebook] : A Facebook video link (played in an in-app WebView)
/// - [network]  : A direct MP4/hosted URL (played via Chewie + video_player)
enum VideoType { youtube, facebook, network }

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
    this.preacher,
    this.videoType = VideoType.youtube,
    this.isRecommended = false,
  });

  factory VideoItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse videoType string to enum
    VideoType type;
    switch ((data['videoType'] as String? ?? 'youtube').toLowerCase()) {
      case 'facebook':
        type = VideoType.facebook;
        break;
      case 'network':
        type = VideoType.network;
        break;
      default:
        type = VideoType.youtube;
    }

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
      preacher: data['preacher'] as String?,
      videoType: type,
      isRecommended: data['isRecommended'] as bool? ?? false,
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
  final String? preacher;
  final VideoType videoType;
  final bool isRecommended;

  /// Returns true if this is a YouTube video.
  bool get isYouTube => videoType == VideoType.youtube;

  /// Returns true if this is a Facebook video.
  bool get isFacebook => videoType == VideoType.facebook;

  /// Returns true if this is a direct network/hosted video.
  bool get isNetworkVideo => videoType == VideoType.network;

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
    String? preacher,
    VideoType? videoType,
    bool? isRecommended,
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
      preacher: preacher ?? this.preacher,
      videoType: videoType ?? this.videoType,
      isRecommended: isRecommended ?? this.isRecommended,
    );
  }
}
