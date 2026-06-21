import 'package:hive/hive.dart';

part 'chat_session_model.g.dart';

@HiveType(typeId: 44)
class ChatSessionModel extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String title;

  @HiveField(2)
  DateTime? createdAt;

  @HiveField(3)
  DateTime? updatedAt;

  @HiveField(4)
  List<ChatMessageModel> messages;

  // Not persisted in Hive – only used at runtime
  String? preloadedContext;
  String? hiddenAutoPrompt;
  String? bookName;
  int? chapterNumber;
  int? verseNumber;
  String? verseText;

  ChatSessionModel({
    this.id,
    required this.title,
    this.createdAt,
    this.updatedAt,
    List<ChatMessageModel>? messages,
    this.preloadedContext,
    this.hiddenAutoPrompt,
    this.bookName,
    this.chapterNumber,
    this.verseNumber,
    this.verseText,
  }) : messages = messages ?? [];

  /// Convenience: create a Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'messages': messages.map((m) => m.toMap()).toList(),
    };
  }

  factory ChatSessionModel.fromFirestore(Map<String, dynamic> json) {
    return ChatSessionModel(
      id: json['id'] as String?,
      title: json['title'] as String? ?? 'Untitled',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((m) => ChatMessageModel.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

@HiveType(typeId: 45)
class ChatMessageModel extends HiveObject {
  @HiveField(0)
  String message;

  @HiveField(1)
  bool isUser;

  @HiveField(2)
  bool isHidden;

  @HiveField(3)
  DateTime? timestamp;

  ChatMessageModel({
    required this.message,
    required this.isUser,
    this.isHidden = false,
    this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'isUser': isUser,
      'isHidden': isHidden,
      'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
    };
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      message: map['message'] as String? ?? '',
      isUser: map['isUser'] as bool? ?? false,
      isHidden: map['isHidden'] as bool? ?? false,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'])
          : null,
    );
  }
}
