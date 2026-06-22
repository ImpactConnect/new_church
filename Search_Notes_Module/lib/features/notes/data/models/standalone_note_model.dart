import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'linked_content_reference.dart';

part 'standalone_note_model.g.dart';

@HiveType(typeId: 100)
@JsonSerializable()
class StandaloneNote extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String richTextContent; // Serialized Delta format from flutter_quill

  @HiveField(3)
  final List<String> tags;

  @HiveField(4)
  final bool isPinned;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime lastModifiedAt;

  @HiveField(7)
  final List<LinkedContentReference> linkedContent;

  @HiveField(8)
  final String? templateName; // For template tracking

  StandaloneNote({
    required this.id,
    required this.title,
    required this.richTextContent,
    required this.tags,
    required this.isPinned,
    required this.createdAt,
    required this.lastModifiedAt,
    required this.linkedContent,
    this.templateName,
  });

  /// Creates a copy of this note with the given fields replaced with new values
  StandaloneNote copyWith({
    String? id,
    String? title,
    String? richTextContent,
    List<String>? tags,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? lastModifiedAt,
    List<LinkedContentReference>? linkedContent,
    String? templateName,
  }) {
    return StandaloneNote(
      id: id ?? this.id,
      title: title ?? this.title,
      richTextContent: richTextContent ?? this.richTextContent,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      linkedContent: linkedContent ?? this.linkedContent,
      templateName: templateName ?? this.templateName,
    );
  }

  /// Converts this note to a JSON map
  Map<String, dynamic> toJson() => _$StandaloneNoteToJson(this);

  /// Creates a note from a JSON map
  factory StandaloneNote.fromJson(Map<String, dynamic> json) =>
      _$StandaloneNoteFromJson(json);
}
