import 'package:cloud_firestore/cloud_firestore.dart';

/// Supported live stream platforms
enum StreamPlatform { youtube, facebook, vimeo, hls }

extension StreamPlatformExtension on StreamPlatform {
  String get value {
    switch (this) {
      case StreamPlatform.youtube:
        return 'youtube';
      case StreamPlatform.facebook:
        return 'facebook';
      case StreamPlatform.vimeo:
        return 'vimeo';
      case StreamPlatform.hls:
        return 'hls';
    }
  }

  static StreamPlatform fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'facebook':
        return StreamPlatform.facebook;
      case 'vimeo':
        return StreamPlatform.vimeo;
      case 'hls':
        return StreamPlatform.hls;
      case 'youtube':
      default:
        return StreamPlatform.youtube;
    }
  }
}

class LiveStream {
  LiveStream({
    required this.id,
    required this.title,
    required this.url,
    required this.platform,
    required this.isLive,
    required this.startTime,
    this.endTime,
    this.thumbnailUrl,
    this.description,
  });

  factory LiveStream.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LiveStream(
      id: doc.id,
      title: data['title'] ?? '',
      url: data['url'] ?? '',
      platform: StreamPlatformExtension.fromString(data['platform']),
      isLive: data['isLive'] ?? false,
      startTime: data['startTime'] != null
          ? (data['startTime'] as Timestamp).toDate()
          : DateTime.now(),
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
      thumbnailUrl: data['thumbnailUrl'],
      description: data['description'],
    );
  }

  final String id;
  final String title;
  final String url;
  final StreamPlatform platform;
  final bool isLive;
  final DateTime startTime;
  final DateTime? endTime;
  final String? thumbnailUrl;
  final String? description;

  bool get hasEnded =>
      endTime != null && endTime!.isBefore(DateTime.now());

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'url': url,
      'platform': platform.value,
      'isLive': isLive,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'thumbnailUrl': thumbnailUrl,
      'description': description,
    };
  }
}
