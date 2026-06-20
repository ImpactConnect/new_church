import 'package:json_annotation/json_annotation.dart';

import 'bible_verse.dart';

part 'bible_chapter.g.dart';

@JsonSerializable()
class BibleChapter {
  /// The chapter number (e.g., 1)
  final int number;

  /// Lists of verses in this chapter
  final List<BibleVerse> verses;

  /// Optional unique ID (e.g., "gen-1")
  final String? id;

  const BibleChapter({required this.number, required this.verses, this.id});

  factory BibleChapter.fromJson(Map<String, dynamic> json) =>
      _$BibleChapterFromJson(json);
  Map<String, dynamic> toJson() => _$BibleChapterToJson(this);
}
