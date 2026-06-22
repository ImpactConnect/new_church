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

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'],
      bookId: json['bookId'],
      bookName: json['bookName'],
      chapterNumber: json['chapterNumber'],
      verseNumber: json['verseNumber'],
      content: json['content'],
      verseText: json['verseText'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'bookName': bookName,
      'chapterNumber': chapterNumber,
      'verseNumber': verseNumber,
      'content': content,
      'verseText': verseText,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get reference => '$bookName $chapterNumber:$verseNumber';

  @override
  List<Object?> get props => [id, bookId, chapterNumber, verseNumber];
}
