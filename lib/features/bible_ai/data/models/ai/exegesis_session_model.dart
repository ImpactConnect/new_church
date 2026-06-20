import 'package:hive/hive.dart';

part 'exegesis_session_model.g.dart';

@HiveType(typeId: 60)
class ExegesisSessionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String type; // 'character', 'book', 'chapter', 'passage'

  @HiveField(3)
  final String query;

  @HiveField(4)
  final String? chapter;

  @HiveField(5)
  final String title;

  @HiveField(6)
  final String contentJson;

  @HiveField(7)
  final String depth;

  @HiveField(8)
  final DateTime? createdAt;

  @HiveField(9)
  final DateTime? updatedAt;

  ExegesisSessionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.query,
    this.chapter,
    required this.title,
    required this.contentJson,
    required this.depth,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'query': query,
      'chapter': chapter,
      'title': title,
      'contentJson': contentJson,
      'depth': depth,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ExegesisSessionModel.fromMap(Map<String, dynamic> map) {
    return ExegesisSessionModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      type: map['type'] as String,
      query: map['query'] as String,
      chapter: map['chapter'] as String?,
      title: map['title'] as String,
      contentJson: map['contentJson'] as String,
      depth: map['depth'] as String,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
    );
  }
}

typedef ExegesisSession = ExegesisSessionModel;
