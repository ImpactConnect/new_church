import 'package:cloud_firestore/cloud_firestore.dart';

class Sermon {
  Sermon({
    required this.id,
    required this.title,
    required this.preacherName,
    required this.category,
    required this.tags,
    required this.thumbnailUrl,
    required this.audioUrl,
    required this.dateCreated,
    this.duration,
    this.description,
    this.scriptureReference,
    this.likes = 0,
    this.streams = 0,
    this.isBookmarked = false,
    this.isDownloaded = false,
    this.localAudioPath,
  });

  factory Sermon.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Sermon.fromMap(data, doc.id);
  }

  factory Sermon.fromMap(Map<String, dynamic> data, String id) {
    DateTime dateCreated;
    try {
      final timestamp = data['dateCreated'];
      if (timestamp is Timestamp) {
        dateCreated = timestamp.toDate();
      } else {
        dateCreated = DateTime.now();
      }
    } catch (e) {
      dateCreated = DateTime.now();
    }

    Duration? duration;
    try {
      final secs = data['durationSeconds'];
      if (secs is int && secs > 0) {
        duration = Duration(seconds: secs);
      }
    } catch (_) {}

    return Sermon(
      id: id,
      title: data['title'] as String? ?? '',
      preacherName: data['preacherName'] as String? ?? '',
      category: data['category'] as String? ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
      audioUrl: data['audioUrl'] as String? ?? '',
      dateCreated: dateCreated,
      duration: duration,
      description: data['description'] as String?,
      scriptureReference: data['scriptureReference'] as String?,
      likes: data['likes'] as int? ?? 0,
      streams: data['streams'] as int? ?? 0,
      isBookmarked: data['isBookmarked'] as bool? ?? false,
      isDownloaded: data['isDownloaded'] as bool? ?? false,
      localAudioPath: data['localAudioPath'] as String?,
    );
  }

  factory Sermon.fromJson(Map<String, dynamic> json) {
    Duration? duration;
    final secs = json['durationSeconds'];
    if (secs is int && secs > 0) duration = Duration(seconds: secs);

    return Sermon(
      id: json['id'] as String,
      title: json['title'] as String,
      preacherName: json['preacherName'] as String,
      category: json['category'] as String,
      tags: List<String>.from(json['tags'] as List),
      thumbnailUrl: json['thumbnailUrl'] as String,
      audioUrl: json['audioUrl'] as String,
      dateCreated: DateTime.parse(json['dateCreated'] as String),
      duration: duration,
      description: json['description'] as String?,
      scriptureReference: json['scriptureReference'] as String?,
      likes: json['likes'] as int? ?? 0,
      streams: json['streams'] as int? ?? 0,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
      localAudioPath: json['localAudioPath'] as String?,
    );
  }

  final String id;
  final String title;
  final String preacherName;
  final String category;
  final List<String> tags;
  final String thumbnailUrl;
  final String audioUrl;
  final DateTime dateCreated;
  final Duration? duration;
  final String? description;
  final String? scriptureReference;
  final int likes;
  final int streams;
  bool isBookmarked;
  bool isDownloaded;
  String? localAudioPath;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'preacherName': preacherName,
      'category': category,
      'tags': tags,
      'thumbnailUrl': thumbnailUrl,
      'audioUrl': audioUrl,
      'dateCreated': dateCreated.toIso8601String(),
      if (duration != null) 'durationSeconds': duration!.inSeconds,
      if (description != null) 'description': description,
      if (scriptureReference != null) 'scriptureReference': scriptureReference,
      'likes': likes,
      'streams': streams,
      'isBookmarked': isBookmarked,
      'isDownloaded': isDownloaded,
      'localAudioPath': localAudioPath,
    };
  }

  Sermon copyWith({
    String? id,
    String? title,
    String? preacherName,
    String? category,
    List<String>? tags,
    String? thumbnailUrl,
    String? audioUrl,
    DateTime? dateCreated,
    Duration? duration,
    String? description,
    String? scriptureReference,
    int? likes,
    int? streams,
    bool? isBookmarked,
    bool? isDownloaded,
    String? localAudioPath,
  }) {
    return Sermon(
      id: id ?? this.id,
      title: title ?? this.title,
      preacherName: preacherName ?? this.preacherName,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      dateCreated: dateCreated ?? this.dateCreated,
      duration: duration ?? this.duration,
      description: description ?? this.description,
      scriptureReference: scriptureReference ?? this.scriptureReference,
      likes: likes ?? this.likes,
      streams: streams ?? this.streams,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      localAudioPath: localAudioPath ?? this.localAudioPath,
    );
  }
}
