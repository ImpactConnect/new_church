// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'linked_content_reference.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LinkedContentReferenceAdapter
    extends TypeAdapter<LinkedContentReference> {
  @override
  final int typeId = 102;

  @override
  LinkedContentReference read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LinkedContentReference(
      id: fields[0] as String,
      type: fields[1] as LinkedContentType,
      sourceId: fields[2] as String,
      sourceReference: fields[3] as String,
      linkedAt: fields[4] as DateTime,
      metadata: (fields[5] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, LinkedContentReference obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.sourceId)
      ..writeByte(3)
      ..write(obj.sourceReference)
      ..writeByte(4)
      ..write(obj.linkedAt)
      ..writeByte(5)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkedContentReferenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LinkedContentTypeAdapter extends TypeAdapter<LinkedContentType> {
  @override
  final int typeId = 101;

  @override
  LinkedContentType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LinkedContentType.verse;
      case 1:
        return LinkedContentType.chat;
      case 2:
        return LinkedContentType.study;
      case 3:
        return LinkedContentType.exegesis;
      case 4:
        return LinkedContentType.prayer;
      default:
        return LinkedContentType.verse;
    }
  }

  @override
  void write(BinaryWriter writer, LinkedContentType obj) {
    switch (obj) {
      case LinkedContentType.verse:
        writer.writeByte(0);
        break;
      case LinkedContentType.chat:
        writer.writeByte(1);
        break;
      case LinkedContentType.study:
        writer.writeByte(2);
        break;
      case LinkedContentType.exegesis:
        writer.writeByte(3);
        break;
      case LinkedContentType.prayer:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkedContentTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LinkedContentReference _$LinkedContentReferenceFromJson(
        Map<String, dynamic> json) =>
    LinkedContentReference(
      id: json['id'] as String,
      type: $enumDecode(_$LinkedContentTypeEnumMap, json['type']),
      sourceId: json['sourceId'] as String,
      sourceReference: json['sourceReference'] as String,
      linkedAt: DateTime.parse(json['linkedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$LinkedContentReferenceToJson(
        LinkedContentReference instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$LinkedContentTypeEnumMap[instance.type]!,
      'sourceId': instance.sourceId,
      'sourceReference': instance.sourceReference,
      'linkedAt': instance.linkedAt.toIso8601String(),
      'metadata': instance.metadata,
    };

const _$LinkedContentTypeEnumMap = {
  LinkedContentType.verse: 'verse',
  LinkedContentType.chat: 'chat',
  LinkedContentType.study: 'study',
  LinkedContentType.exegesis: 'exegesis',
  LinkedContentType.prayer: 'prayer',
};
