import 'package:json_annotation/json_annotation.dart';

import 'bible_chapter.dart';

part 'bible_book.g.dart';

@JsonSerializable()
class BibleBook {
  /// The name of the book (e.g., "Genesis")
  final String name;

  /// Unique ID for the book (e.g., "gen")
  final String id;

  /// List of chapters in this book
  final List<BibleChapter> chapters;

  const BibleBook({
    required this.name,
    required this.id,
    required this.chapters,
  });

  factory BibleBook.fromJson(Map<String, dynamic> json) =>
      _$BibleBookFromJson(json);
  Map<String, dynamic> toJson() => _$BibleBookToJson(this);
}
