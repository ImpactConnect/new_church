import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'note_model.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class NoteModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String bookId;

  @HiveField(2)
  final String bookName;

  @HiveField(3)
  final int chapterNumber;

  @HiveField(4)
  final int verseNumber;

  @HiveField(5)
  final String content;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final String verseText;

  NoteModel({
    required this.id,
    required this.bookId,
    required this.bookName,
    required this.chapterNumber,
    required this.verseNumber,
    required this.content,
    required this.createdAt,
    required this.verseText,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) => _$NoteModelFromJson(json);
  Map<String, dynamic> toJson() => _$NoteModelToJson(this);

  String get reference => '$bookName $chapterNumber:$verseNumber';
}
