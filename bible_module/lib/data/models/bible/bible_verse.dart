import 'package:json_annotation/json_annotation.dart';

part 'bible_verse.g.dart';

@JsonSerializable()
class BibleVerse {
  /// The verse number (e.g., 1)
  final int number;

  /// The text of the verse
  final String text;

  /// Optional unique ID (e.g., "gen-1-1")
  final String? id;

  const BibleVerse({required this.number, required this.text, this.id});

  factory BibleVerse.fromJson(Map<String, dynamic> json) =>
      _$BibleVerseFromJson(json);
  Map<String, dynamic> toJson() => _$BibleVerseToJson(this);
}
