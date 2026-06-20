// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exegesis_result_v2_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExegesisResultV2Adapter extends TypeAdapter<ExegesisResultV2> {
  @override
  final int typeId = 80;

  @override
  ExegesisResultV2 read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExegesisResultV2(
      id: fields[0] as String,
      entryType: fields[1] as ExegesisEntryType,
      subject: fields[2] as String,
      mode: fields[3] as ExegesisMode,
      createdAt: fields[4] as DateTime,
      bigPicture: fields[5] as String,
      historicalMoment: fields[6] as String,
      keyWord: fields[7] as KeyWordMoment?,
      whatWasBeingSaid: fields[8] as String,
      inTheWholeStory: fields[9] as String,
      echoes: (fields[10] as List).cast<EchoItem>(),
      whatThisMeansForYou: fields[11] as String,
      somethingToSitWith: fields[12] as String,
      wordStudies: (fields[13] as List?)?.cast<WordStudyItem>(),
      interpretiveTensions: (fields[14] as List?)?.cast<InterpretiveTension>(),
      grammaticalHighlights: fields[15] as String?,
      covenantContext: fields[16] as CovenantContext?,
      cachedAlternateModeId: fields[17] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ExegesisResultV2 obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.entryType)
      ..writeByte(2)
      ..write(obj.subject)
      ..writeByte(3)
      ..write(obj.mode)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.bigPicture)
      ..writeByte(6)
      ..write(obj.historicalMoment)
      ..writeByte(7)
      ..write(obj.keyWord)
      ..writeByte(8)
      ..write(obj.whatWasBeingSaid)
      ..writeByte(9)
      ..write(obj.inTheWholeStory)
      ..writeByte(10)
      ..write(obj.echoes)
      ..writeByte(11)
      ..write(obj.whatThisMeansForYou)
      ..writeByte(12)
      ..write(obj.somethingToSitWith)
      ..writeByte(13)
      ..write(obj.wordStudies)
      ..writeByte(14)
      ..write(obj.interpretiveTensions)
      ..writeByte(15)
      ..write(obj.grammaticalHighlights)
      ..writeByte(16)
      ..write(obj.covenantContext)
      ..writeByte(17)
      ..write(obj.cachedAlternateModeId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExegesisResultV2Adapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class KeyWordMomentAdapter extends TypeAdapter<KeyWordMoment> {
  @override
  final int typeId = 84;

  @override
  KeyWordMoment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KeyWordMoment(
      originalScript: fields[0] as String,
      transliteration: fields[1] as String,
      strongsNumber: fields[2] as String?,
      meaning: fields[3] as String,
      whyItMatters: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, KeyWordMoment obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.originalScript)
      ..writeByte(1)
      ..write(obj.transliteration)
      ..writeByte(2)
      ..write(obj.strongsNumber)
      ..writeByte(3)
      ..write(obj.meaning)
      ..writeByte(4)
      ..write(obj.whyItMatters);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeyWordMomentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EchoItemAdapter extends TypeAdapter<EchoItem> {
  @override
  final int typeId = 85;

  @override
  EchoItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EchoItem(
      reference: fields[0] as String,
      connectionType: fields[1] as EchoConnectionType,
      explanation: fields[2] as String,
      verseText: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EchoItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.reference)
      ..writeByte(1)
      ..write(obj.connectionType)
      ..writeByte(2)
      ..write(obj.explanation)
      ..writeByte(3)
      ..write(obj.verseText);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EchoItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CommonMisreadingAdapter extends TypeAdapter<CommonMisreading> {
  @override
  final int typeId = 86;

  @override
  CommonMisreading read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CommonMisreading(
      misreading: fields[0] as String,
      correction: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CommonMisreading obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.misreading)
      ..writeByte(1)
      ..write(obj.correction);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommonMisreadingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WordStudyItemAdapter extends TypeAdapter<WordStudyItem> {
  @override
  final int typeId = 87;

  @override
  WordStudyItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WordStudyItem(
      word: fields[0] as String,
      transliteration: fields[1] as String,
      strongsNumber: fields[2] as String?,
      definition: fields[3] as String,
      semanticRange: fields[4] as String,
      usageExamples: (fields[5] as List).cast<String>(),
      whyItMatters: fields[6] as String,
      translationVariance: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WordStudyItem obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.word)
      ..writeByte(1)
      ..write(obj.transliteration)
      ..writeByte(2)
      ..write(obj.strongsNumber)
      ..writeByte(3)
      ..write(obj.definition)
      ..writeByte(4)
      ..write(obj.semanticRange)
      ..writeByte(5)
      ..write(obj.usageExamples)
      ..writeByte(6)
      ..write(obj.whyItMatters)
      ..writeByte(7)
      ..write(obj.translationVariance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordStudyItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InterpretiveTensionAdapter extends TypeAdapter<InterpretiveTension> {
  @override
  final int typeId = 88;

  @override
  InterpretiveTension read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InterpretiveTension(
      question: fields[0] as String,
      positionA: fields[1] as TensionPosition,
      positionB: fields[2] as TensionPosition,
      commonGround: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, InterpretiveTension obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.question)
      ..writeByte(1)
      ..write(obj.positionA)
      ..writeByte(2)
      ..write(obj.positionB)
      ..writeByte(3)
      ..write(obj.commonGround);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterpretiveTensionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TensionPositionAdapter extends TypeAdapter<TensionPosition> {
  @override
  final int typeId = 89;

  @override
  TensionPosition read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TensionPosition(
      label: fields[0] as String,
      explanation: fields[1] as String,
      supportingVerses: (fields[2] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, TensionPosition obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.label)
      ..writeByte(1)
      ..write(obj.explanation)
      ..writeByte(2)
      ..write(obj.supportingVerses);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TensionPositionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CovenantContextAdapter extends TypeAdapter<CovenantContext> {
  @override
  final int typeId = 90;

  @override
  CovenantContext read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CovenantContext(
      covenantFramework: fields[0] as String,
      redemptiveHistoricalPlacement: fields[1] as String,
      christologicalConnection: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CovenantContext obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.covenantFramework)
      ..writeByte(1)
      ..write(obj.redemptiveHistoricalPlacement)
      ..writeByte(2)
      ..write(obj.christologicalConnection);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CovenantContextAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExegesisModeAdapter extends TypeAdapter<ExegesisMode> {
  @override
  final int typeId = 81;

  @override
  ExegesisMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExegesisMode.understand;
      case 1:
        return ExegesisMode.goDeep;
      default:
        return ExegesisMode.understand;
    }
  }

  @override
  void write(BinaryWriter writer, ExegesisMode obj) {
    switch (obj) {
      case ExegesisMode.understand:
        writer.writeByte(0);
        break;
      case ExegesisMode.goDeep:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExegesisModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExegesisEntryTypeAdapter extends TypeAdapter<ExegesisEntryType> {
  @override
  final int typeId = 82;

  @override
  ExegesisEntryType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExegesisEntryType.singleVerse;
      case 1:
        return ExegesisEntryType.passage;
      case 2:
        return ExegesisEntryType.bibleBook;
      case 3:
        return ExegesisEntryType.bibleCharacter;
      case 4:
        return ExegesisEntryType.theme;
      default:
        return ExegesisEntryType.singleVerse;
    }
  }

  @override
  void write(BinaryWriter writer, ExegesisEntryType obj) {
    switch (obj) {
      case ExegesisEntryType.singleVerse:
        writer.writeByte(0);
        break;
      case ExegesisEntryType.passage:
        writer.writeByte(1);
        break;
      case ExegesisEntryType.bibleBook:
        writer.writeByte(2);
        break;
      case ExegesisEntryType.bibleCharacter:
        writer.writeByte(3);
        break;
      case ExegesisEntryType.theme:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExegesisEntryTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EchoConnectionTypeAdapter extends TypeAdapter<EchoConnectionType> {
  @override
  final int typeId = 83;

  @override
  EchoConnectionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EchoConnectionType.parallel;
      case 1:
        return EchoConnectionType.allusion;
      case 2:
        return EchoConnectionType.fulfillment;
      case 3:
        return EchoConnectionType.contrast;
      case 4:
        return EchoConnectionType.development;
      default:
        return EchoConnectionType.parallel;
    }
  }

  @override
  void write(BinaryWriter writer, EchoConnectionType obj) {
    switch (obj) {
      case EchoConnectionType.parallel:
        writer.writeByte(0);
        break;
      case EchoConnectionType.allusion:
        writer.writeByte(1);
        break;
      case EchoConnectionType.fulfillment:
        writer.writeByte(2);
        break;
      case EchoConnectionType.contrast:
        writer.writeByte(3);
        break;
      case EchoConnectionType.development:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EchoConnectionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
