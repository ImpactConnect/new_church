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
    this.isSynchronized = false,
    this.scheduledVideoStart,
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
      isSynchronized: data['isSynchronized'] ?? false,
      scheduledVideoStart: data['scheduledVideoStart'] != null
          ? (data['scheduledVideoStart'] as Timestamp).toDate()
          : null,
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

  /// Whether synchronized playback mode is enabled for this stream.
  final bool isSynchronized;

  /// The real-world clock time the video should start playing from position 0.
  /// Defaults to [startTime] if not explicitly set.
  final DateTime? scheduledVideoStart;

  /// Effective video-start reference time (falls back to startTime).
  DateTime get effectiveVideoStart => scheduledVideoStart ?? startTime;

  bool get hasEnded => endTime != null && endTime!.isBefore(DateTime.now());

  bool get hasStarted => !DateTime.now().isBefore(effectiveVideoStart);

  /// Seconds into the video the player should seek to so all viewers are in sync.
  /// Returns 0 if the stream has not started yet.
  int get syncSeekOffsetSeconds {
    if (!isSynchronized) return 0;
    final elapsed = DateTime.now().difference(effectiveVideoStart).inSeconds;
    return elapsed.clamp(0, 86400); // cap at 24 hrs
  }

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
      'isSynchronized': isSynchronized,
      'scheduledVideoStart': scheduledVideoStart != null
          ? Timestamp.fromDate(scheduledVideoStart!)
          : null,
    };
  }
}
