// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bible_verse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BibleVerse _$BibleVerseFromJson(Map<String, dynamic> json) => BibleVerse(
      number: (json['number'] as num).toInt(),
      text: json['text'] as String,
      id: json['id'] as String?,
    );

Map<String, dynamic> _$BibleVerseToJson(BibleVerse instance) =>
    <String, dynamic>{
      'number': instance.number,
      'text': instance.text,
      'id': instance.id,
    };
