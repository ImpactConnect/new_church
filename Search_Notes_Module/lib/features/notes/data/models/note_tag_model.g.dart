// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_tag_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteTagAdapter extends TypeAdapter<NoteTag> {
  @override
  final int typeId = 103;

  @override
  NoteTag read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteTag(
      name: fields[0] as String,
      usageCount: fields[1] as int,
      createdAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, NoteTag obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.usageCount)
      ..writeByte(2)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteTagAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NoteTag _$NoteTagFromJson(Map<String, dynamic> json) => NoteTag(
      name: json['name'] as String,
      usageCount: (json['usageCount'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$NoteTagToJson(NoteTag instance) => <String, dynamic>{
      'name': instance.name,
      'usageCount': instance.usageCount,
      'createdAt': instance.createdAt.toIso8601String(),
    };
