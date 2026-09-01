import 'package:cloud_firestore/cloud_firestore.dart';

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
    this.isSynchronized = false,
    this.scheduledVideoStart,
  });

  factory LiveStream.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LiveStream(
      id: doc.id,
      title: data['title'] ?? '',
      url: data['url'] ?? '',
      platform: data['platform'] ?? 'youtube',
      isLive: data['isLive'] ?? false,
      // Guard against null startTime (created before field existed)
      startTime: data['startTime'] != null
          ? (data['startTime'] as Timestamp).toDate()
          : DateTime.now(),
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
      thumbnailUrl: data['thumbnailUrl'],
      description: data['description'],
      isSynchronized: data['isSynchronized'] ?? false,
      scheduledVideoStart: data['scheduledVideoStart'] != null
          ? (data['scheduledVideoStart'] as Timestamp).toDate()
          : null,
    );
  }

  final String id;
  final String title;
  final String url;
  final String platform; // 'youtube' | 'facebook' | 'vimeo' | 'hls' | 'firebase'
  final bool isLive;
  final DateTime startTime;
  final DateTime? endTime;
  final String? thumbnailUrl;
  final String? description;
  final bool isSynchronized;
  final DateTime? scheduledVideoStart;

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'url': url,
      'platform': platform,
      'isLive': isLive,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'thumbnailUrl': thumbnailUrl,
      'description': description,
      'isSynchronized': isSynchronized,
      'scheduledVideoStart': scheduledVideoStart != null
          ? Timestamp.fromDate(scheduledVideoStart!)
          : null,
    };
  }
}
