import 'package:equatable/equatable.dart';

/// A simple verse bookmark saved by the user.
class BookmarkModel extends Equatable {
  final String id;
  final String bookId;
  final String bookName;
  final int chapterNumber;
  final int verseNumber;
  final String verseText;
  final DateTime createdAt;
  final String? category;

  const BookmarkModel({
    required this.id,
    required this.bookId,
    required this.bookName,
    required this.chapterNumber,
    required this.verseNumber,
    required this.verseText,
    required this.createdAt,
    this.category,
  });

  String get reference => '$bookName $chapterNumber:$verseNumber';

  @override
  List<Object?> get props => [id, bookId, chapterNumber, verseNumber];
}
