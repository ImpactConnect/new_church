import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'note_tag_model.g.dart';

/// Model representing a tag used for organizing notes
@HiveType(typeId: 103)
@JsonSerializable()
class NoteTag {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int usageCount;

  @HiveField(2)
  final DateTime createdAt;

  NoteTag({
    required this.name,
    required this.usageCount,
    required this.createdAt,
  });

  /// Creates a copy of this tag with the given fields replaced with new values
  NoteTag copyWith({
    String? name,
    int? usageCount,
    DateTime? createdAt,
  }) {
    return NoteTag(
      name: name ?? this.name,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converts this tag to a JSON map
  Map<String, dynamic> toJson() => _$NoteTagToJson(this);

  /// Creates a tag from a JSON map
  factory NoteTag.fromJson(Map<String, dynamic> json) =>
      _$NoteTagFromJson(json);
}
