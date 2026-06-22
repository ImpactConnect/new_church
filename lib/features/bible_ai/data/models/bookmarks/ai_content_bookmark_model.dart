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

  factory AiContentBookmarkModel.fromJson(Map<String, dynamic> json) {
    return AiContentBookmarkModel(
      id: json['id'],
      bookName: json['bookName'],
      chapterNumber: json['chapterNumber'],
      verseNumber: json['verseNumber'],
      verseText: json['verseText'],
      feature: json['feature'],
      analysisJson: json['analysisJson'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookName': bookName,
      'chapterNumber': chapterNumber,
      'verseNumber': verseNumber,
      'verseText': verseText,
      'feature': feature,
      'analysisJson': analysisJson,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get displayTitle => '$bookName $chapterNumber:$verseNumber · ${feature.toUpperCase()}';

  @override
  List<Object?> get props => [id];
}
