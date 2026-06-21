// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exegesis_result_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExegesisResultAdapter extends TypeAdapter<ExegesisResult> {
  @override
  final int typeId = 40;

  @override
  ExegesisResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExegesisResult(
      id: fields[0] as String,
      entryType: fields[1] as String,
      subject: fields[2] as String,
      depthLevel: fields[3] as String,
      originalLanguage: fields[4] as String,
      executiveSummary: fields[5] as String,
      historicalContext: fields[6] as ExegesisHistoricalContext,
      literaryStructure: fields[7] as ExegesisLiteraryStructure,
      languageStudy: (fields[8] as List).cast<ExegesisWordStudy>(),
      grammaticalNotes: fields[9] as String,
      theologicalMeaning: fields[10] as ExegesisTheologicalMeaning,
      interpretiveTraditions:
          (fields[11] as List).cast<ExegesisInterpretiveTradition>(),
      applicationBridge: fields[12] as ExegesisApplicationBridge,
      crossReferences: (fields[13] as List).cast<ExegesisCrossReference>(),
      scholarlyDebates: (fields[14] as List).cast<ExegesisScholarlyDebate>(),
      comprehensionQuiz:
          (fields[15] as List).cast<ExegesisComprehensionQuestion>(),
      studyNextSteps: (fields[16] as List).cast<String>(),
      biographyTimeline: (fields[17] as List?)?.cast<ExegesisBiographyEvent>(),
      characterPsychology: fields[18] as ExegesisCharacterPsychology?,
      transformationArc: fields[19] as String?,
      canonicalDevelopment: fields[20] as ExegesisCanonicalDevelopment?,
      createdAt: fields[21] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ExegesisResult obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.entryType)
      ..writeByte(2)
      ..write(obj.subject)
      ..writeByte(3)
      ..write(obj.depthLevel)
      ..writeByte(4)
      ..write(obj.originalLanguage)
      ..writeByte(5)
      ..write(obj.executiveSummary)
      ..writeByte(6)
      ..write(obj.historicalContext)
      ..writeByte(7)
      ..write(obj.literaryStructure)
      ..writeByte(8)
      ..write(obj.languageStudy)
      ..writeByte(9)
      ..write(obj.grammaticalNotes)
      ..writeByte(10)
      ..write(obj.theologicalMeaning)
      ..writeByte(11)
      ..write(obj.interpretiveTraditions)
      ..writeByte(12)
      ..write(obj.applicationBridge)
      ..writeByte(13)
      ..write(obj.crossReferences)
      ..writeByte(14)
      ..write(obj.scholarlyDebates)
      ..writeByte(15)
      ..write(obj.comprehensionQuiz)
      ..writeByte(16)
      ..write(obj.studyNextSteps)
      ..writeByte(17)
      ..write(obj.biographyTimeline)
      ..writeByte(18)
      ..write(obj.characterPsychology)
      ..writeByte(19)
      ..write(obj.transformationArc)
      ..writeByte(20)
      ..write(obj.canonicalDevelopment)
      ..writeByte(21)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExegesisResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExegesisHistoricalContextAdapter
    extends TypeAdapter<ExegesisHistoricalContext> {
  @override
  final int typeId = 41;

  @override
  ExegesisHistoricalContext read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExegesisHistoricalContext(
      author: fields[0] as String,
      audience: fields[1] as String,
      date: fields[2] as String,
      politicalSetting: fields[3] as String,
      geographicContext: fields[4] as String,
      culturalNotes: fields[5] as String,
      era: fields[6] as String?,
      keyRelationships: fields[7] as String?,
      conceptDefinition: fields[8] as String?,
      modernVsAncient: fields[9] as String?,
      occasion: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ExegesisHistoricalContext obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.author)
      ..writeByte(1)
      ..write(obj.audience)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.politicalSetting)
      ..writeByte(4)
      ..write(obj.geographicContext)
      ..writeByte(5)
      ..write(obj.culturalNotes)
      ..writeByte(6)
      ..write(obj.era)
      ..writeByte(7)
      ..write(obj.keyRelationships)
      ..writeByte(8)
      ..write(obj.conceptDefinition)
      ..writeByte(9)
      ..write(obj.modernVsAncient)
      ..writeByte(10)
      ..write(obj.occasion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExegesisHistoricalContextAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExegesisLiteraryStructureAdapter
    extends TypeAdapter<ExegesisLiteraryStructure> {
  @override
  final int typeId = 42;

  @override
  ExegesisLiteraryStructure read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExegesisLiteraryStructure(
      genre: fields[0] as String,
      structure: fields[1] as String,
      literaryDevices: (fields[2] as List).cast<String>(),
      positionInBook: fields[3] as String,
      argumentFlow: fields[4] as String?,
      passageOutline: fields[5] as String?,
      bookOutline: fields[6] as String?,
      unifyingTheme: fields[7] as String?,
      keyPassages: (fields[8] as List?)?.cast<ExegesisKeyPassage>(),
    );
  }

  @override
  void write(BinaryWriter writer, ExegesisLiteraryStructure obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.genre)
      ..writeByte(1)
      ..write(obj.structure)
      ..writeByte(2)
      ..write(obj.literaryDevices)
      ..writeByte(3)
      ..write(obj.positionInBook)
      ..writeByte(4)
      ..write(obj.argumentFlow)
      ..writeByte(5)
      ..write(obj.passageOutline)
      ..writeByte(6)
      ..write(obj.bookOutline)
      ..writeByte(7)
      ..write(obj.unifyingTheme)
      ..writeByte(8)
      ..write(obj.keyPassages);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExegesisLiteraryStructureAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExegesisKeyPassageAdapter extends TypeAdapter<ExegesisKeyPassage> {
  @override
  final int typeId = 43;

  @override
  ExegesisKeyPassage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExegesisKeyPassage(
      reference: fields[0] as String,
      reason: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ExegesisKeyPassage obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.reference)
      ..writeByte(1)
      ..write(obj.reason);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExegesisKeyPassageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExegesisWordStudyAdapter extends TypeAdapter<ExegesisWordStudy> {
  @override
  final int typeId = 46;

  @override
  ExegesisWordStudy read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExegesisWordStudy(
      word: fields[0] as String,
      transliteration: fields[1] as String,
      strongsNumber: fields[2] as String,
      definition: fields[3] as String,
      semanticRange: fields[4] as String,
      usageNote: fields[5] as String,
      verseRef: fields[6] as String?,
      translationComparison: fields[7] as String?,
      partOfSpeech: fields[8] as String?,
      meaning: fields[9] as String?,
      additionalTerms: fields[10] as String?,
      testament: fields[11] as String?,
      interTestamentalShift: fields[12] as String?,
      roleInBook: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ExegesisWordStudy obj) {
    writer
      ..writeByte(14)
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
      ..write(obj.usageNote)
      ..writeByte(6)
      ..write(obj.verseRef)
      ..writeByte(7)
      ..write(obj.translationComparison)
      ..writeByte(8)
      ..write(obj.partOfSpeech)
      ..writeByte(9)
      ..write(obj.meaning)
      ..writeByte(10)
      ..write(obj.additionalTerms)
      ..writeByte(11)
      ..write(obj.testament)
      ..writeByte(12)
      ..write(obj.interTestamentalShift)
      ..writeByte(13)
      ..write(obj.roleInBook);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExegesisWordStudyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExegesisTheologicalMeaningAdapter
    extends TypeAdapter<ExegesisTheologicalMeaning> {
  @override
  final int typeId = 47;

  @override
  ExegesisTheologicalMeaning read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExegesisTheologicalMeaning(
      doctrineEstablished: fields[0] as String?,
      metaNarrativePlacement: fields[1] as String,
      christologicalConnection: fields[2] as String,
      otNtConnection: fields[3] as String?,
      centralThesis: fields[4] as String?,
      centralPurpose: fields[5] as String?,
      canonicalPosition: fields[6] as String?,
      majorThemes: (fields[7] as List?)?.cast<ExegesisBookTheme>(),
      doctrinalSynthesis: fields[8] as String?,
      roleInRedemptiveHistory: fields[9] as String?,
      typologicalSignificance: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ExegesisTheologicalMeaning obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.doctrineEstablished)
      ..writeByte(1)
      ..write(obj.metaNarrativePlacement)
      ..writeByte(2)
      ..write(obj.christologicalConnection)
      ..writeByte(3)
      ..write(obj.otNtConnection)
      ..writeByte(4)
      ..write(obj.centralThesis)
      ..writeByte(5)
      ..write(obj.centralPurpose)
      ..writeByte(6)
      ..write(obj.canonicalPosition)
      ..writeByte(7)
      ..write(obj.majorThemes)
      ..writeByte(8)
      ..write(obj.doctrinalSynthesis)
      ..writeByte(9)
      ..write(obj.roleInRedemptiveHistory)
      ..writeByte(10)
      ..write(obj.typologicalSignificance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExegesisTheologicalMeaningAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExegesisBookThemeAdapter extends TypeAdapter<ExegesisBookTheme> {
  @override
  final int typeId = 48;

  @override
  ExegesisBookTheme read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExegesisBookTheme(
      theme: fields[0] as String,
      development: fields[1] as String,
      keyVerse: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ExegesisBookTheme obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.theme)
      ..writeByte(1)
      ..write(obj.development)
      ..writeByte(2)
      ..write(obj.keyVerse);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExegesisBookThemeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExegesisInterpretiveTraditionAdapter
    extends TypeAdapter<ExegesisInterpretiveTradition> {
  @override
  final int typeId = 49;

  @override
  ExegesisInterpretiveTradition read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExegesisInterpretiveTradition(
      traditionName: fields[0] as String,
      interpretation: fields[1] as String,
      supportingVerses: (fields[2] as List).cast<String>(),
      agreementWithOthers: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ExegesisInterpretiveTradition obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.traditionName)
      ..writeByte(1)
      ..write(obj.interpretation)
      ..writeByte(2)
      ..write(obj.supportingVerses)
      ..writeByte(3)
      ..write(obj.agreementWithOthers);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExegesisInterpretiveTraditionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExegesisApplicationBridgeAdapter
    extends TypeAdapter<ExegesisApplicationBridge> {
  @override
  final int typeId = 50;

  @override
  ExegesisApplicationBridge read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExegesisApplicationBridge(
      originalIntent: fields[0] as String,
      timelessPrinciple: fields[1] as String,
      modernApplication: fields[2] as String,
      misapplicationWarnings: (fields[3] as List).cast<String>(),
      lessonsFromStrengths: fields[4] as String?,
      warningsFromFailures: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ExegesisApplicationBridge obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.originalIntent)
      ..writeByte(1)
      ..write(obj.timelessPrinciple)
      ..writeByte(2)
      ..write(obj.modernApplication)
      ..writeByte(3)
      ..write(obj.misapplicationWarnings)
      ..writeByte(4)
      ..write(obj.lessonsFromStrengths)
      ..writeByte(5)
      ..write(obj.warningsFromFailures);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExegesisApplicationBridgeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExegesisCrossReferenceAdapter
    extends TypeAdapter<ExegesisCrossReference> {
  @override
  final int typeId = 51;

  @override
  ExegesisCrossReference read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExegesisCrossReference(
      reference: fields[0] as String,
      connectionType: fields[1] as String,
      explanation: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ExegesisCrossReference obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.reference)
      ..writeByte(1)
      ..write(obj.connectionType)
      ..writeByte(2)
      ..write(obj.explanation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExegesisCrossReferenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExegesisScholarlyDebateAdapter
    extends TypeAdapter<ExegesisScholarlyDebate> {
  @override
  final int typeId = 52;

  @override
  ExegesisScholarlyDebate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExegesisScholarlyDebate(
      topic: fields[0] as String,
      positionA: fields[1] as String,
      positionB: fields[2] as String,
      commonGround: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ExegesisScholarlyDebate obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.topic)
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
      other is ExegesisScholarlyDebateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExegesisComprehensionQuestionAdapter
    extends TypeAdapter<ExegesisComprehensionQuestion> {
  @override
  final int typeId = 53;

  @override
  ExegesisComprehensionQuestion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExegesisComprehensionQuestion(
      question: fields[0] as String,
      answer: fields[1] as String,
      explanation: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ExegesisComprehensionQuestion obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.question)
      ..writeByte(1)
      ..write(obj.answer)
      ..writeByte(2)
      ..write(obj.explanation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExegesisComprehensionQuestionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExegesisBiographyEventAdapter
    extends TypeAdapter<ExegesisBiographyEvent> {
  @override
  final int typeId = 54;

  @override
  ExegesisBiographyEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExegesisBiographyEvent(
      event: fields[0] as String,
      reference: fields[1] as String,
      significance: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ExegesisBiographyEvent obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.event)
      ..writeByte(1)
      ..write(obj.reference)
      ..writeByte(2)
      ..write(obj.significance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExegesisBiographyEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExegesisCharacterPsychologyAdapter
    extends TypeAdapter<ExegesisCharacterPsychology> {
  @override
  final int typeId = 55;

  @override
  ExegesisCharacterPsychology read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExegesisCharacterPsychology(
      coreMotivations: fields[0] as String,
      strengths: fields[1] as String,
      weaknesses: fields[2] as String,
      definingMoment: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ExegesisCharacterPsychology obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.coreMotivations)
      ..writeByte(1)
      ..write(obj.strengths)
      ..writeByte(2)
      ..write(obj.weaknesses)
      ..writeByte(3)
      ..write(obj.definingMoment);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExegesisCharacterPsychologyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExegesisCanonicalDevelopmentAdapter
    extends TypeAdapter<ExegesisCanonicalDevelopment> {
  @override
  final int typeId = 56;

  @override
  ExegesisCanonicalDevelopment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExegesisCanonicalDevelopment(
      firstMention: fields[0] as ExegesisFirstMention,
      otDevelopment: fields[1] as String,
      fulfillmentInChrist: fields[2] as String,
      ntDevelopment: fields[3] as String,
      eschatologicalCompletion: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ExegesisCanonicalDevelopment obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.firstMention)
      ..writeByte(1)
      ..write(obj.otDevelopment)
      ..writeByte(2)
      ..write(obj.fulfillmentInChrist)
      ..writeByte(3)
      ..write(obj.ntDevelopment)
      ..writeByte(4)
      ..write(obj.eschatologicalCompletion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExegesisCanonicalDevelopmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExegesisFirstMentionAdapter extends TypeAdapter<ExegesisFirstMention> {
  @override
  final int typeId = 57;

  @override
  ExegesisFirstMention read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExegesisFirstMention(
      reference: fields[0] as String,
      form: fields[1] as String,
      significance: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ExegesisFirstMention obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.reference)
      ..writeByte(1)
      ..write(obj.form)
      ..writeByte(2)
      ..write(obj.significance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExegesisFirstMentionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
