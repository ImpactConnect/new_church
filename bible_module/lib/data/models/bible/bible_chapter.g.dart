// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bible_chapter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BibleChapter _$BibleChapterFromJson(Map<String, dynamic> json) => BibleChapter(
      number: (json['number'] as num).toInt(),
      verses: (json['verses'] as List<dynamic>)
          .map((e) => BibleVerse.fromJson(e as Map<String, dynamic>))
          .toList(),
      id: json['id'] as String?,
    );

Map<String, dynamic> _$BibleChapterToJson(BibleChapter instance) =>
    <String, dynamic>{
      'number': instance.number,
      'verses': instance.verses,
      'id': instance.id,
    };
