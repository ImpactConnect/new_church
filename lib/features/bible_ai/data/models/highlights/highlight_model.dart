import 'package:equatable/equatable.dart';

/// Represents a highlighted verse in the Bible reader.
class HighlightModel extends Equatable {
  final String id;
  final String bookId;
  final int chapterNumber;
  final int verseNumber;
  final int colorValue; // Color stored as int (e.g. Colors.yellow.value)
  final DateTime createdAt;

  const HighlightModel({
    required this.id,
    required this.bookId,
    required this.chapterNumber,
    required this.verseNumber,
    required this.colorValue,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, bookId, chapterNumber, verseNumber];
}
