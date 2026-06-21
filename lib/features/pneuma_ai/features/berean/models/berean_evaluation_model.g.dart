// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'berean_evaluation_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BereanEvaluationModelAdapter extends TypeAdapter<BereanEvaluationModel> {
  @override
  final int typeId = 30;

  @override
  BereanEvaluationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BereanEvaluationModel(
      id: fields[0] as String,
      inputText: fields[1] as String,
      statementType: fields[2] as String,
      statement: fields[3] as String,
      summary: fields[4] as String,
      confidenceLevel: fields[5] as String,
      confidenceReason: fields[6] as String,
      scriptures: (fields[7] as List).cast<BereanScriptureRef>(),
      broaderContext: fields[8] as String,
      statementAnalysis: fields[9] as String,
      alignmentVerdict: fields[10] as AlignmentVerdict,
      interpretiveTensions: fields[11] as InterpretiveTensions,
      rhetoricalFlags: (fields[12] as List).cast<RhetoricalFlag>(),
      historicalPerspective: fields[13] as String,
      contextWarnings: (fields[14] as List).cast<ContextWarning>(),
      doctrineClassification: fields[15] as DoctrineClassification,
      escalationFlag: fields[16] as bool,
      pastoralWarning: fields[17] as String?,
      exampleScenario: fields[18] as ExampleScenario,
      conclusion: fields[19] as String,
      userGuidance: fields[20] as UserGuidance,
      createdAt: fields[21] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, BereanEvaluationModel obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.inputText)
      ..writeByte(2)
      ..write(obj.statementType)
      ..writeByte(3)
      ..write(obj.statement)
      ..writeByte(4)
      ..write(obj.summary)
      ..writeByte(5)
      ..write(obj.confidenceLevel)
      ..writeByte(6)
      ..write(obj.confidenceReason)
      ..writeByte(7)
      ..write(obj.scriptures)
      ..writeByte(8)
      ..write(obj.broaderContext)
      ..writeByte(9)
      ..write(obj.statementAnalysis)
      ..writeByte(10)
      ..write(obj.alignmentVerdict)
      ..writeByte(11)
      ..write(obj.interpretiveTensions)
      ..writeByte(12)
      ..write(obj.rhetoricalFlags)
      ..writeByte(13)
      ..write(obj.historicalPerspective)
      ..writeByte(14)
      ..write(obj.contextWarnings)
      ..writeByte(15)
      ..write(obj.doctrineClassification)
      ..writeByte(16)
      ..write(obj.escalationFlag)
      ..writeByte(17)
      ..write(obj.pastoralWarning)
      ..writeByte(18)
      ..write(obj.exampleScenario)
      ..writeByte(19)
      ..write(obj.conclusion)
      ..writeByte(20)
      ..write(obj.userGuidance)
      ..writeByte(21)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BereanEvaluationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BereanScriptureRefAdapter extends TypeAdapter<BereanScriptureRef> {
  @override
  final int typeId = 31;

  @override
  BereanScriptureRef read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BereanScriptureRef(
      reference: fields[0] as String,
      text: fields[1] as String,
      explanation: fields[2] as String,
      context: fields[3] as String,
      supportsOrQualifies: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BereanScriptureRef obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.reference)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.explanation)
      ..writeByte(3)
      ..write(obj.context)
      ..writeByte(4)
      ..write(obj.supportsOrQualifies);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BereanScriptureRefAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AlignmentVerdictAdapter extends TypeAdapter<AlignmentVerdict> {
  @override
  final int typeId = 32;

  @override
  AlignmentVerdict read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlignmentVerdict(
      label: fields[0] as String,
      score: fields[1] as String,
      oneLineVerdict: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AlignmentVerdict obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.label)
      ..writeByte(1)
      ..write(obj.score)
      ..writeByte(2)
      ..write(obj.oneLineVerdict);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlignmentVerdictAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InterpretiveTensionsAdapter extends TypeAdapter<InterpretiveTensions> {
  @override
  final int typeId = 33;

  @override
  InterpretiveTensions read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InterpretiveTensions(
      viewA: fields[0] as InterpretiveView,
      viewB: fields[1] as InterpretiveView,
      whereDiffer: fields[2] as String,
      whereAgree: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, InterpretiveTensions obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.viewA)
      ..writeByte(1)
      ..write(obj.viewB)
      ..writeByte(2)
      ..write(obj.whereDiffer)
      ..writeByte(3)
      ..write(obj.whereAgree);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterpretiveTensionsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InterpretiveViewAdapter extends TypeAdapter<InterpretiveView> {
  @override
  final int typeId = 34;

  @override
  InterpretiveView read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InterpretiveView(
      tradition: fields[0] as String,
      argument: fields[1] as String,
      scriptures: (fields[2] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, InterpretiveView obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.tradition)
      ..writeByte(1)
      ..write(obj.argument)
      ..writeByte(2)
      ..write(obj.scriptures);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterpretiveViewAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RhetoricalFlagAdapter extends TypeAdapter<RhetoricalFlag> {
  @override
  final int typeId = 35;

  @override
  RhetoricalFlag read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RhetoricalFlag(
      flagType: fields[0] as String,
      explanation: fields[1] as String,
      corrective: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RhetoricalFlag obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.flagType)
      ..writeByte(1)
      ..write(obj.explanation)
      ..writeByte(2)
      ..write(obj.corrective);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RhetoricalFlagAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ContextWarningAdapter extends TypeAdapter<ContextWarning> {
  @override
  final int typeId = 36;

  @override
  ContextWarning read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ContextWarning(
      misusedVerse: fields[0] as String,
      howMisused: fields[1] as String,
      correctReading: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ContextWarning obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.misusedVerse)
      ..writeByte(1)
      ..write(obj.howMisused)
      ..writeByte(2)
      ..write(obj.correctReading);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContextWarningAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DoctrineClassificationAdapter
    extends TypeAdapter<DoctrineClassification> {
  @override
  final int typeId = 37;

  @override
  DoctrineClassification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DoctrineClassification(
      tier: fields[0] as String,
      label: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DoctrineClassification obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.tier)
      ..writeByte(1)
      ..write(obj.label);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoctrineClassificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExampleScenarioAdapter extends TypeAdapter<ExampleScenario> {
  @override
  final int typeId = 38;

  @override
  ExampleScenario read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExampleScenario(
      correctUse: fields[0] as String,
      incorrectUse: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ExampleScenario obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.correctUse)
      ..writeByte(1)
      ..write(obj.incorrectUse);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExampleScenarioAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserGuidanceAdapter extends TypeAdapter<UserGuidance> {
  @override
  final int typeId = 39;

  @override
  UserGuidance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserGuidance(
      action: fields[0] as String,
      practicalStep: fields[1] as String,
      prayerFocus: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UserGuidance obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.action)
      ..writeByte(1)
      ..write(obj.practicalStep)
      ..writeByte(2)
      ..write(obj.prayerFocus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserGuidanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
