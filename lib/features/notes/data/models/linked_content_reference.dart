import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'linked_content_reference.g.dart';

/// Enum representing the type of linked content
@HiveType(typeId: 101)
enum LinkedContentType {
  @HiveField(0)
  verse,

  @HiveField(1)
  chat,

  @HiveField(2)
  study,

  @HiveField(3)
  exegesis,

  @HiveField(4)
  prayer,
}

/// Model representing a reference to external content linked to a note
@HiveType(typeId: 102)
@JsonSerializable()
class LinkedContentReference {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final LinkedContentType type;

  @HiveField(2)
  final String sourceId; // Reference to original content

  @HiveField(3)
  final String sourceReference; // Human-readable reference

  @HiveField(4)
  final DateTime linkedAt;

  @HiveField(5)
  final Map<String, dynamic> metadata; // Type-specific metadata

  LinkedContentReference({
    required this.id,
    required this.type,
    required this.sourceId,
    required this.sourceReference,
    required this.linkedAt,
    required this.metadata,
  });

  /// Creates a copy of this reference with the given fields replaced with new values
  LinkedContentReference copyWith({
    String? id,
    LinkedContentType? type,
    String? sourceId,
    String? sourceReference,
    DateTime? linkedAt,
    Map<String, dynamic>? metadata,
  }) {
    return LinkedContentReference(
      id: id ?? this.id,
      type: type ?? this.type,
      sourceId: sourceId ?? this.sourceId,
      sourceReference: sourceReference ?? this.sourceReference,
      linkedAt: linkedAt ?? this.linkedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Converts this reference to a JSON map
  Map<String, dynamic> toJson() => _$LinkedContentReferenceToJson(this);

  /// Creates a reference from a JSON map
  factory LinkedContentReference.fromJson(Map<String, dynamic> json) =>
      _$LinkedContentReferenceFromJson(json);
}
