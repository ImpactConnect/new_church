import 'package:equatable/equatable.dart';

/// A bookmark for an AI-generated content result (verse explanation, chat, etc.)
class AiContentBookmarkModel extends Equatable {
  final String id;
  final String bookName;
  final int chapterNumber;
  final int verseNumber;
  final String verseText;
  final String feature; // VerseFeature name
  final String analysisJson;
  final DateTime createdAt;

  const AiContentBookmarkModel({
    required this.id,
    required this.bookName,
    required this.chapterNumber,
    required this.verseNumber,
    required this.verseText,
    required this.feature,
    required this.analysisJson,
    required this.createdAt,
  });

  String get displayTitle => '$bookName $chapterNumber:$verseNumber · ${feature.toUpperCase()}';

  @override
  List<Object?> get props => [id];
}
