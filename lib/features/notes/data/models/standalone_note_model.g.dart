// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'standalone_note_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StandaloneNoteAdapter extends TypeAdapter<StandaloneNote> {
  @override
  final int typeId = 100;

  @override
  StandaloneNote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StandaloneNote(
      id: fields[0] as String,
      title: fields[1] as String,
      richTextContent: fields[2] as String,
      tags: (fields[3] as List).cast<String>(),
      isPinned: fields[4] as bool,
      createdAt: fields[5] as DateTime,
      lastModifiedAt: fields[6] as DateTime,
      linkedContent: (fields[7] as List).cast<LinkedContentReference>(),
      templateName: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, StandaloneNote obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.richTextContent)
      ..writeByte(3)
      ..write(obj.tags)
      ..writeByte(4)
      ..write(obj.isPinned)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.lastModifiedAt)
      ..writeByte(7)
      ..write(obj.linkedContent)
      ..writeByte(8)
      ..write(obj.templateName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StandaloneNoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StandaloneNote _$StandaloneNoteFromJson(Map<String, dynamic> json) =>
    StandaloneNote(
      id: json['id'] as String,
      title: json['title'] as String,
      richTextContent: json['richTextContent'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      isPinned: json['isPinned'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModifiedAt: DateTime.parse(json['lastModifiedAt'] as String),
      linkedContent: (json['linkedContent'] as List<dynamic>)
          .map(
              (e) => LinkedContentReference.fromJson(e as Map<String, dynamic>))
          .toList(),
      templateName: json['templateName'] as String?,
    );

Map<String, dynamic> _$StandaloneNoteToJson(StandaloneNote instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'richTextContent': instance.richTextContent,
      'tags': instance.tags,
      'isPinned': instance.isPinned,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastModifiedAt': instance.lastModifiedAt.toIso8601String(),
      'linkedContent': instance.linkedContent,
      'templateName': instance.templateName,
    };
