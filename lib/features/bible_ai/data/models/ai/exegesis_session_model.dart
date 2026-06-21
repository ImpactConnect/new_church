

class ExegesisSessionModel {
  final String id;
  final String userId;
  final String type; // 'character', 'book', 'chapter', 'passage'
  final String query;
  final String? chapter;
  final String title;
  final String contentJson;
  final String depth;
  final DateTime? createdAt;
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
