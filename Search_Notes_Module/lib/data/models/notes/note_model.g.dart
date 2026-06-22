// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteModelAdapter extends TypeAdapter<NoteModel> {
  @override
  final int typeId = 0;

  @override
  NoteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteModel(
      id: fields[0] as String,
      bookId: fields[1] as String,
      bookName: fields[2] as String,
      chapterNumber: fields[3] as int,
      verseNumber: fields[4] as int,
      content: fields[5] as String,
      createdAt: fields[6] as DateTime,
      verseText: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, NoteModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.bookId)
      ..writeByte(2)
      ..write(obj.bookName)
      ..writeByte(3)
      ..write(obj.chapterNumber)
      ..writeByte(4)
      ..write(obj.verseNumber)
      ..writeByte(5)
      ..write(obj.content)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.verseText);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NoteModel _$NoteModelFromJson(Map<String, dynamic> json) => NoteModel(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      bookName: json['bookName'] as String,
      chapterNumber: (json['chapterNumber'] as num).toInt(),
      verseNumber: (json['verseNumber'] as num).toInt(),
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      verseText: json['verseText'] as String,
    );

Map<String, dynamic> _$NoteModelToJson(NoteModel instance) => <String, dynamic>{
      'id': instance.id,
      'bookId': instance.bookId,
      'bookName': instance.bookName,
      'chapterNumber': instance.chapterNumber,
      'verseNumber': instance.verseNumber,
      'content': instance.content,
      'createdAt': instance.createdAt.toIso8601String(),
      'verseText': instance.verseText,
    };
