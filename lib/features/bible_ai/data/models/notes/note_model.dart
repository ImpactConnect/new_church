import 'package:equatable/equatable.dart';

/// A user annotation/note linked to a specific verse.
class NoteModel extends Equatable {
  final String id;
  final String bookId;
  final String bookName;
  final int chapterNumber;
  final int verseNumber;
  final String content;
  final String verseText;
  final DateTime createdAt;

  const NoteModel({
    required this.id,
    required this.bookId,
    required this.bookName,
    required this.chapterNumber,
    required this.verseNumber,
    required this.content,
    this.verseText = '',
    required this.createdAt,
  });

  String get reference => '$bookName $chapterNumber:$verseNumber';

  @override
  List<Object?> get props => [id, bookId, chapterNumber, verseNumber];
}
