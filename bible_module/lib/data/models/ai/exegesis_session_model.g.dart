// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exegesis_session_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExegesisSessionModelAdapter extends TypeAdapter<ExegesisSessionModel> {
  @override
  final int typeId = 60;

  @override
  ExegesisSessionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExegesisSessionModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      type: fields[2] as String,
      query: fields[3] as String,
      chapter: fields[4] as String?,
      title: fields[5] as String,
      contentJson: fields[6] as String,
      depth: fields[7] as String,
      createdAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ExegesisSessionModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.query)
      ..writeByte(4)
      ..write(obj.chapter)
      ..writeByte(5)
      ..write(obj.title)
      ..writeByte(6)
      ..write(obj.contentJson)
      ..writeByte(7)
      ..write(obj.depth)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExegesisSessionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
