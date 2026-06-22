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

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    return BookmarkModel(
      id: json['id'],
      bookId: json['bookId'],
      bookName: json['bookName'],
      chapterNumber: json['chapterNumber'],
      verseNumber: json['verseNumber'],
      verseText: json['verseText'],
      createdAt: DateTime.parse(json['createdAt']),
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'bookName': bookName,
      'chapterNumber': chapterNumber,
      'verseNumber': verseNumber,
      'verseText': verseText,
      'createdAt': createdAt.toIso8601String(),
      'category': category,
    };
  }

  String get reference => '$bookName $chapterNumber:$verseNumber';

  @override
  List<Object?> get props => [id, bookId, chapterNumber, verseNumber];
}
