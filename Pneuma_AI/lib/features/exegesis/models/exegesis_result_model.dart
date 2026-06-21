import 'package:hive/hive.dart';

part 'exegesis_result_model.g.dart';

// ═══════════════════════════════════════════════════════════════════
//  MAIN MODEL — ExegesisResult (typeId: 40)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 40)
class ExegesisResult extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String entryType; // 'Single Verse' | 'Passage' | 'Bible Book' | 'Bible Character' | 'Theme'

  @HiveField(2)
  final String subject;

  @HiveField(3)
  final String depthLevel; // 'Overview' | 'Deep' | 'Scholarly'

  @HiveField(4)
  final String originalLanguage;

  @HiveField(5)
  final String executiveSummary;

  @HiveField(6)
  final ExegesisHistoricalContext historicalContext;

  @HiveField(7)
  final ExegesisLiteraryStructure literaryStructure;

  @HiveField(8)
  final List<ExegesisWordStudy> languageStudy;

  @HiveField(9)
  final String grammaticalNotes;

  @HiveField(10)
  final ExegesisTheologicalMeaning theologicalMeaning;

  @HiveField(11)
  final List<ExegesisInterpretiveTradition> interpretiveTraditions;

  @HiveField(12)
  final ExegesisApplicationBridge applicationBridge;

  @HiveField(13)
  final List<ExegesisCrossReference> crossReferences;

  @HiveField(14)
  final List<ExegesisScholarlyDebate> scholarlyDebates;

  @HiveField(15)
  final List<ExegesisComprehensionQuestion> comprehensionQuiz;

  @HiveField(16)
  final List<String> studyNextSteps;

  // ── Type-specific nullable fields ──

  @HiveField(17)
  final List<ExegesisBiographyEvent>? biographyTimeline; // Character only

  @HiveField(18)
  final ExegesisCharacterPsychology? characterPsychology; // Character only

  @HiveField(19)
  final String? transformationArc; // Character only

  @HiveField(20)
  final ExegesisCanonicalDevelopment? canonicalDevelopment; // Theme only

  @HiveField(21)
  final DateTime? createdAt;

  ExegesisResult({
    required this.id,
    required this.entryType,
    required this.subject,
    required this.depthLevel,
    required this.originalLanguage,
    required this.executiveSummary,
    required this.historicalContext,
    required this.literaryStructure,
    required this.languageStudy,
    required this.grammaticalNotes,
    required this.theologicalMeaning,
    required this.interpretiveTraditions,
    required this.applicationBridge,
    required this.crossReferences,
    required this.scholarlyDebates,
    required this.comprehensionQuiz,
    required this.studyNextSteps,
    this.biographyTimeline,
    this.characterPsychology,
    this.transformationArc,
    this.canonicalDevelopment,
    this.createdAt,
  });

  factory ExegesisResult.fromJson(Map<String, dynamic> json) {
    return ExegesisResult(
      id: json['id'] as String? ?? '',
      entryType: json['entryType'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      depthLevel: json['depthLevel'] as String? ?? 'Deep',
      originalLanguage: json['originalLanguage'] as String? ?? 'N/A',
      executiveSummary: json['executiveSummary'] as String? ?? '',
      historicalContext: ExegesisHistoricalContext.fromJson(
        json['historicalContext'] as Map<String, dynamic>? ?? {},
      ),
      literaryStructure: ExegesisLiteraryStructure.fromJson(
        json['literaryStructure'] as Map<String, dynamic>? ?? {},
      ),
      languageStudy: (json['languageStudy'] as List<dynamic>? ?? [])
          .map((e) => ExegesisWordStudy.fromJson(e as Map<String, dynamic>))
          .toList(),
      grammaticalNotes: json['grammaticalNotes'] as String? ?? '',
      theologicalMeaning: ExegesisTheologicalMeaning.fromJson(
        json['theologicalMeaning'] as Map<String, dynamic>? ?? {},
      ),
      interpretiveTraditions: (json['interpretiveTraditions'] as List<dynamic>? ?? [])
          .map((e) => ExegesisInterpretiveTradition.fromJson(e as Map<String, dynamic>))
          .toList(),
      applicationBridge: ExegesisApplicationBridge.fromJson(
        json['applicationBridge'] as Map<String, dynamic>? ?? {},
      ),
      crossReferences: (json['crossReferences'] as List<dynamic>? ?? [])
          .map((e) => ExegesisCrossReference.fromJson(e as Map<String, dynamic>))
          .toList(),
      scholarlyDebates: (json['scholarlyDebates'] as List<dynamic>? ?? [])
          .map((e) => ExegesisScholarlyDebate.fromJson(e as Map<String, dynamic>))
          .toList(),
      comprehensionQuiz: (json['comprehensionQuiz'] as List<dynamic>? ?? [])
          .map((e) => ExegesisComprehensionQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      studyNextSteps: (json['studyNextSteps'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      // Character-specific
      biographyTimeline: json['biographyTimeline'] != null
          ? (json['biographyTimeline'] as List<dynamic>)
              .map((e) => ExegesisBiographyEvent.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      characterPsychology: json['characterPsychology'] != null
          ? ExegesisCharacterPsychology.fromJson(
              json['characterPsychology'] as Map<String, dynamic>)
          : null,
      transformationArc: json['transformationArc'] as String?,
      // Theme-specific
      canonicalDevelopment: json['canonicalDevelopment'] != null
          ? ExegesisCanonicalDevelopment.fromJson(
              json['canonicalDevelopment'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'entryType': entryType,
      'subject': subject,
      'depthLevel': depthLevel,
      'originalLanguage': originalLanguage,
      'executiveSummary': executiveSummary,
      'historicalContext': historicalContext.toJson(),
      'literaryStructure': literaryStructure.toJson(),
      'languageStudy': languageStudy.map((e) => e.toJson()).toList(),
      'grammaticalNotes': grammaticalNotes,
      'theologicalMeaning': theologicalMeaning.toJson(),
      'interpretiveTraditions': interpretiveTraditions.map((e) => e.toJson()).toList(),
      'applicationBridge': applicationBridge.toJson(),
      'crossReferences': crossReferences.map((e) => e.toJson()).toList(),
      'scholarlyDebates': scholarlyDebates.map((e) => e.toJson()).toList(),
      'comprehensionQuiz': comprehensionQuiz.map((e) => e.toJson()).toList(),
      'studyNextSteps': studyNextSteps,
    };
    if (biographyTimeline != null) {
      map['biographyTimeline'] = biographyTimeline!.map((e) => e.toJson()).toList();
    }
    if (characterPsychology != null) {
      map['characterPsychology'] = characterPsychology!.toJson();
    }
    if (transformationArc != null) {
      map['transformationArc'] = transformationArc;
    }
    if (canonicalDevelopment != null) {
      map['canonicalDevelopment'] = canonicalDevelopment!.toJson();
    }
    return map;
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SUB-MODEL: HistoricalContext (typeId: 41)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 41)
class ExegesisHistoricalContext {
  @HiveField(0)
  final String author;

  @HiveField(1)
  final String audience;

  @HiveField(2)
  final String date;

  @HiveField(3)
  final String politicalSetting;

  @HiveField(4)
  final String geographicContext;

  @HiveField(5)
  final String culturalNotes;

  // Character-specific fields
  @HiveField(6)
  final String? era;

  @HiveField(7)
  final String? keyRelationships;

  // Theme-specific fields
  @HiveField(8)
  final String? conceptDefinition;

  @HiveField(9)
  final String? modernVsAncient;

  // Book-specific
  @HiveField(10)
  final String? occasion;

  ExegesisHistoricalContext({
    this.author = '',
    this.audience = '',
    this.date = '',
    this.politicalSetting = '',
    this.geographicContext = '',
    this.culturalNotes = '',
    this.era,
    this.keyRelationships,
    this.conceptDefinition,
    this.modernVsAncient,
    this.occasion,
  });

  factory ExegesisHistoricalContext.fromJson(Map<String, dynamic> json) {
    return ExegesisHistoricalContext(
      author: json['author'] as String? ?? '',
      audience: json['audience'] as String? ?? '',
      date: json['date'] as String? ?? '',
      politicalSetting: json['politicalSetting'] as String? ?? '',
      geographicContext: json['geographicContext'] as String? ?? json['geographicWorld'] as String? ?? '',
      culturalNotes: json['culturalNotes'] as String? ?? '',
      era: json['era'] as String?,
      keyRelationships: json['keyRelationships'] as String?,
      conceptDefinition: json['conceptDefinition'] as String?,
      modernVsAncient: json['modernVsAncient'] as String?,
      occasion: json['occasion'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'author': author,
    'audience': audience,
    'date': date,
    'politicalSetting': politicalSetting,
    'geographicContext': geographicContext,
    'culturalNotes': culturalNotes,
    if (era != null) 'era': era,
    if (keyRelationships != null) 'keyRelationships': keyRelationships,
    if (conceptDefinition != null) 'conceptDefinition': conceptDefinition,
    if (modernVsAncient != null) 'modernVsAncient': modernVsAncient,
    if (occasion != null) 'occasion': occasion,
  };
}

// ═══════════════════════════════════════════════════════════════════
//  SUB-MODEL: LiteraryStructure (typeId: 42)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 42)
class ExegesisLiteraryStructure {
  @HiveField(0)
  final String genre;

  @HiveField(1)
  final String structure; // or 'argumentFlow' for Passage, 'bookOutline' for Book

  @HiveField(2)
  final List<String> literaryDevices;

  @HiveField(3)
  final String positionInBook;

  // Passage-specific
  @HiveField(4)
  final String? argumentFlow;

  @HiveField(5)
  final String? passageOutline;

  // Book-specific
  @HiveField(6)
  final String? bookOutline;

  @HiveField(7)
  final String? unifyingTheme;

  @HiveField(8)
  final List<ExegesisKeyPassage>? keyPassages;

  ExegesisLiteraryStructure({
    this.genre = '',
    this.structure = '',
    this.literaryDevices = const [],
    this.positionInBook = '',
    this.argumentFlow,
    this.passageOutline,
    this.bookOutline,
    this.unifyingTheme,
    this.keyPassages,
  });

  factory ExegesisLiteraryStructure.fromJson(Map<String, dynamic> json) {
    return ExegesisLiteraryStructure(
      genre: json['genre'] as String? ?? '',
      structure: json['structure'] as String? ?? '',
      literaryDevices: (json['literaryDevices'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      positionInBook: json['positionInBook'] as String? ?? '',
      argumentFlow: json['argumentFlow'] as String?,
      passageOutline: json['passageOutline'] as String?,
      bookOutline: json['bookOutline'] as String?,
      unifyingTheme: json['unifyingTheme'] as String?,
      keyPassages: json['keyPassages'] != null
          ? (json['keyPassages'] as List<dynamic>)
              .map((e) => ExegesisKeyPassage.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'genre': genre,
    'structure': structure,
    'literaryDevices': literaryDevices,
    'positionInBook': positionInBook,
    if (argumentFlow != null) 'argumentFlow': argumentFlow,
    if (passageOutline != null) 'passageOutline': passageOutline,
    if (bookOutline != null) 'bookOutline': bookOutline,
    if (unifyingTheme != null) 'unifyingTheme': unifyingTheme,
    if (keyPassages != null) 'keyPassages': keyPassages!.map((e) => e.toJson()).toList(),
  };
}

// ═══════════════════════════════════════════════════════════════════
//  SUB-MODEL: KeyPassage (typeId: 43)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 43)
class ExegesisKeyPassage {
  @HiveField(0)
  final String reference;

  @HiveField(1)
  final String reason; // or 'contribution' for Theme

  ExegesisKeyPassage({this.reference = '', this.reason = ''});

  factory ExegesisKeyPassage.fromJson(Map<String, dynamic> json) {
    return ExegesisKeyPassage(
      reference: json['reference'] as String? ?? '',
      reason: json['reason'] as String? ?? json['contribution'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'reference': reference, 'reason': reason};
}

// ═══════════════════════════════════════════════════════════════════
//  SUB-MODEL: WordStudy (typeId: 46)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 46)
class ExegesisWordStudy {
  @HiveField(0)
  final String word;

  @HiveField(1)
  final String transliteration;

  @HiveField(2)
  final String strongsNumber;

  @HiveField(3)
  final String definition;

  @HiveField(4)
  final String semanticRange;

  @HiveField(5)
  final String usageNote;

  @HiveField(6)
  final String? verseRef; // Passage type

  @HiveField(7)
  final String? translationComparison;

  @HiveField(8)
  final String? partOfSpeech;

  // Character-specific
  @HiveField(9)
  final String? meaning; // Name meaning

  @HiveField(10)
  final String? additionalTerms;

  // Theme-specific
  @HiveField(11)
  final String? testament;

  @HiveField(12)
  final String? interTestamentalShift;

  // Book-specific
  @HiveField(13)
  final String? roleInBook;

  ExegesisWordStudy({
    this.word = '',
    this.transliteration = '',
    this.strongsNumber = '',
    this.definition = '',
    this.semanticRange = '',
    this.usageNote = '',
    this.verseRef,
    this.translationComparison,
    this.partOfSpeech,
    this.meaning,
    this.additionalTerms,
    this.testament,
    this.interTestamentalShift,
    this.roleInBook,
  });

  factory ExegesisWordStudy.fromJson(Map<String, dynamic> json) {
    return ExegesisWordStudy(
      word: json['word'] as String? ?? '',
      transliteration: json['transliteration'] as String? ?? '',
      strongsNumber: json['strongsNumber'] as String? ?? '',
      definition: json['definition'] as String? ?? '',
      semanticRange: json['semanticRange'] as String? ?? '',
      usageNote: json['usageNote'] as String? ?? '',
      verseRef: json['verseRef'] as String?,
      translationComparison: json['translationComparison'] as String?,
      partOfSpeech: json['partOfSpeech'] as String?,
      meaning: json['meaning'] as String?,
      additionalTerms: json['additionalTerms'] as String?,
      testament: json['testament'] as String?,
      interTestamentalShift: json['interTestamentalShift'] as String?,
      roleInBook: json['roleInBook'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'word': word,
    'transliteration': transliteration,
    'strongsNumber': strongsNumber,
    'definition': definition,
    'semanticRange': semanticRange,
    'usageNote': usageNote,
    if (verseRef != null) 'verseRef': verseRef,
    if (translationComparison != null) 'translationComparison': translationComparison,
    if (partOfSpeech != null) 'partOfSpeech': partOfSpeech,
    if (meaning != null) 'meaning': meaning,
    if (additionalTerms != null) 'additionalTerms': additionalTerms,
    if (testament != null) 'testament': testament,
    if (interTestamentalShift != null) 'interTestamentalShift': interTestamentalShift,
    if (roleInBook != null) 'roleInBook': roleInBook,
  };
}

// ═══════════════════════════════════════════════════════════════════
//  SUB-MODEL: TheologicalMeaning (typeId: 47)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 47)
class ExegesisTheologicalMeaning {
  @HiveField(0)
  final String? doctrineEstablished;

  @HiveField(1)
  final String metaNarrativePlacement;

  @HiveField(2)
  final String christologicalConnection;

  @HiveField(3)
  final String? otNtConnection;

  // Passage-specific
  @HiveField(4)
  final String? centralThesis;

  // Book-specific
  @HiveField(5)
  final String? centralPurpose;

  @HiveField(6)
  final String? canonicalPosition;

  @HiveField(7)
  final List<ExegesisBookTheme>? majorThemes;

  // Theme-specific
  @HiveField(8)
  final String? doctrinalSynthesis;

  // Character-specific
  @HiveField(9)
  final String? roleInRedemptiveHistory;

  @HiveField(10)
  final String? typologicalSignificance;

  ExegesisTheologicalMeaning({
    this.doctrineEstablished,
    this.metaNarrativePlacement = '',
    this.christologicalConnection = '',
    this.otNtConnection,
    this.centralThesis,
    this.centralPurpose,
    this.canonicalPosition,
    this.majorThemes,
    this.doctrinalSynthesis,
    this.roleInRedemptiveHistory,
    this.typologicalSignificance,
  });

  factory ExegesisTheologicalMeaning.fromJson(Map<String, dynamic> json) {
    return ExegesisTheologicalMeaning(
      doctrineEstablished: json['doctrineEstablished'] as String?,
      metaNarrativePlacement: json['metaNarrativePlacement'] as String? ?? '',
      christologicalConnection: json['christologicalConnection'] as String? ?? '',
      otNtConnection: json['otNtConnection'] as String?,
      centralThesis: json['centralThesis'] as String?,
      centralPurpose: json['centralPurpose'] as String?,
      canonicalPosition: json['canonicalPosition'] as String?,
      majorThemes: json['majorThemes'] != null
          ? (json['majorThemes'] as List<dynamic>)
              .map((e) => ExegesisBookTheme.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      doctrinalSynthesis: json['doctrinalSynthesis'] as String?,
      roleInRedemptiveHistory: json['roleInRedemptiveHistory'] as String?,
      typologicalSignificance: json['typologicalSignificance'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (doctrineEstablished != null) 'doctrineEstablished': doctrineEstablished,
    'metaNarrativePlacement': metaNarrativePlacement,
    'christologicalConnection': christologicalConnection,
    if (otNtConnection != null) 'otNtConnection': otNtConnection,
    if (centralThesis != null) 'centralThesis': centralThesis,
    if (centralPurpose != null) 'centralPurpose': centralPurpose,
    if (canonicalPosition != null) 'canonicalPosition': canonicalPosition,
    if (majorThemes != null) 'majorThemes': majorThemes!.map((e) => e.toJson()).toList(),
    if (doctrinalSynthesis != null) 'doctrinalSynthesis': doctrinalSynthesis,
    if (roleInRedemptiveHistory != null) 'roleInRedemptiveHistory': roleInRedemptiveHistory,
    if (typologicalSignificance != null) 'typologicalSignificance': typologicalSignificance,
  };
}

// ═══════════════════════════════════════════════════════════════════
//  SUB-MODEL: BookTheme (typeId: 48)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 48)
class ExegesisBookTheme {
  @HiveField(0)
  final String theme;

  @HiveField(1)
  final String development;

  @HiveField(2)
  final String keyVerse;

  ExegesisBookTheme({this.theme = '', this.development = '', this.keyVerse = ''});

  factory ExegesisBookTheme.fromJson(Map<String, dynamic> json) {
    return ExegesisBookTheme(
      theme: json['theme'] as String? ?? '',
      development: json['development'] as String? ?? '',
      keyVerse: json['keyVerse'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'theme': theme,
    'development': development,
    'keyVerse': keyVerse,
  };
}

// ═══════════════════════════════════════════════════════════════════
//  SUB-MODEL: InterpretiveTradition (typeId: 49)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 49)
class ExegesisInterpretiveTradition {
  @HiveField(0)
  final String traditionName;

  @HiveField(1)
  final String interpretation;

  @HiveField(2)
  final List<String> supportingVerses;

  @HiveField(3)
  final String agreementWithOthers;

  ExegesisInterpretiveTradition({
    this.traditionName = '',
    this.interpretation = '',
    this.supportingVerses = const [],
    this.agreementWithOthers = '',
  });

  factory ExegesisInterpretiveTradition.fromJson(Map<String, dynamic> json) {
    return ExegesisInterpretiveTradition(
      traditionName: json['traditionName'] as String? ?? '',
      interpretation: json['interpretation'] as String? ?? '',
      supportingVerses: (json['supportingVerses'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      agreementWithOthers: json['agreementWithOthers'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'traditionName': traditionName,
    'interpretation': interpretation,
    'supportingVerses': supportingVerses,
    'agreementWithOthers': agreementWithOthers,
  };
}

// ═══════════════════════════════════════════════════════════════════
//  SUB-MODEL: ApplicationBridge (typeId: 50)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 50)
class ExegesisApplicationBridge {
  @HiveField(0)
  final String originalIntent;

  @HiveField(1)
  final String timelessPrinciple;

  @HiveField(2)
  final String modernApplication;

  @HiveField(3)
  final List<String> misapplicationWarnings;

  // Character-specific
  @HiveField(4)
  final String? lessonsFromStrengths;

  @HiveField(5)
  final String? warningsFromFailures;

  ExegesisApplicationBridge({
    this.originalIntent = '',
    this.timelessPrinciple = '',
    this.modernApplication = '',
    this.misapplicationWarnings = const [],
    this.lessonsFromStrengths,
    this.warningsFromFailures,
  });

  factory ExegesisApplicationBridge.fromJson(Map<String, dynamic> json) {
    return ExegesisApplicationBridge(
      originalIntent: json['originalIntent'] as String? ?? '',
      timelessPrinciple: json['timelessPrinciple'] as String? ?? '',
      modernApplication: json['modernApplication'] as String? ?? '',
      misapplicationWarnings: (json['misapplicationWarnings'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      lessonsFromStrengths: json['lessonsFromStrengths'] as String?,
      warningsFromFailures: json['warningsFromFailures'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'originalIntent': originalIntent,
    'timelessPrinciple': timelessPrinciple,
    'modernApplication': modernApplication,
    'misapplicationWarnings': misapplicationWarnings,
    if (lessonsFromStrengths != null) 'lessonsFromStrengths': lessonsFromStrengths,
    if (warningsFromFailures != null) 'warningsFromFailures': warningsFromFailures,
  };
}

// ═══════════════════════════════════════════════════════════════════
//  SUB-MODEL: CrossReference (typeId: 51)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 51)
class ExegesisCrossReference {
  @HiveField(0)
  final String reference;

  @HiveField(1)
  final String connectionType; // Parallel | Allusion | Fulfillment | Contrast | Development

  @HiveField(2)
  final String explanation;

  ExegesisCrossReference({
    this.reference = '',
    this.connectionType = '',
    this.explanation = '',
  });

  factory ExegesisCrossReference.fromJson(Map<String, dynamic> json) {
    return ExegesisCrossReference(
      reference: json['reference'] as String? ?? '',
      connectionType: json['connectionType'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'reference': reference,
    'connectionType': connectionType,
    'explanation': explanation,
  };
}

// ═══════════════════════════════════════════════════════════════════
//  SUB-MODEL: ScholarlyDebate (typeId: 52)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 52)
class ExegesisScholarlyDebate {
  @HiveField(0)
  final String topic;

  @HiveField(1)
  final String positionA;

  @HiveField(2)
  final String positionB;

  @HiveField(3)
  final String commonGround;

  ExegesisScholarlyDebate({
    this.topic = '',
    this.positionA = '',
    this.positionB = '',
    this.commonGround = '',
  });

  factory ExegesisScholarlyDebate.fromJson(Map<String, dynamic> json) {
    return ExegesisScholarlyDebate(
      topic: json['topic'] as String? ?? '',
      positionA: json['positionA'] as String? ?? '',
      positionB: json['positionB'] as String? ?? '',
      commonGround: json['commonGround'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'topic': topic,
    'positionA': positionA,
    'positionB': positionB,
    'commonGround': commonGround,
  };
}

// ═══════════════════════════════════════════════════════════════════
//  SUB-MODEL: ComprehensionQuestion (typeId: 53)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 53)
class ExegesisComprehensionQuestion {
  @HiveField(0)
  final String question;

  @HiveField(1)
  final String answer;

  @HiveField(2)
  final String explanation;

  ExegesisComprehensionQuestion({
    this.question = '',
    this.answer = '',
    this.explanation = '',
  });

  factory ExegesisComprehensionQuestion.fromJson(Map<String, dynamic> json) {
    return ExegesisComprehensionQuestion(
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'question': question,
    'answer': answer,
    'explanation': explanation,
  };
}

// ═══════════════════════════════════════════════════════════════════
//  SUB-MODEL: BiographyEvent — Character only (typeId: 54)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 54)
class ExegesisBiographyEvent {
  @HiveField(0)
  final String event;

  @HiveField(1)
  final String reference;

  @HiveField(2)
  final String significance;

  ExegesisBiographyEvent({
    this.event = '',
    this.reference = '',
    this.significance = '',
  });

  factory ExegesisBiographyEvent.fromJson(Map<String, dynamic> json) {
    return ExegesisBiographyEvent(
      event: json['event'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      significance: json['significance'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'event': event,
    'reference': reference,
    'significance': significance,
  };
}

// ═══════════════════════════════════════════════════════════════════
//  SUB-MODEL: CharacterPsychology — Character only (typeId: 55)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 55)
class ExegesisCharacterPsychology {
  @HiveField(0)
  final String coreMotivations;

  @HiveField(1)
  final String strengths;

  @HiveField(2)
  final String weaknesses;

  @HiveField(3)
  final String definingMoment;

  ExegesisCharacterPsychology({
    this.coreMotivations = '',
    this.strengths = '',
    this.weaknesses = '',
    this.definingMoment = '',
  });

  factory ExegesisCharacterPsychology.fromJson(Map<String, dynamic> json) {
    return ExegesisCharacterPsychology(
      coreMotivations: json['coreMotivations'] as String? ?? '',
      strengths: json['strengths'] as String? ?? '',
      weaknesses: json['weaknesses'] as String? ?? '',
      definingMoment: json['definingMoment'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'coreMotivations': coreMotivations,
    'strengths': strengths,
    'weaknesses': weaknesses,
    'definingMoment': definingMoment,
  };
}

// ═══════════════════════════════════════════════════════════════════
//  SUB-MODEL: CanonicalDevelopment — Theme only (typeId: 56)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 56)
class ExegesisCanonicalDevelopment {
  @HiveField(0)
  final ExegesisFirstMention firstMention;

  @HiveField(1)
  final String otDevelopment;

  @HiveField(2)
  final String fulfillmentInChrist;

  @HiveField(3)
  final String ntDevelopment;

  @HiveField(4)
  final String eschatologicalCompletion;

  ExegesisCanonicalDevelopment({
    required this.firstMention,
    this.otDevelopment = '',
    this.fulfillmentInChrist = '',
    this.ntDevelopment = '',
    this.eschatologicalCompletion = '',
  });

  factory ExegesisCanonicalDevelopment.fromJson(Map<String, dynamic> json) {
    return ExegesisCanonicalDevelopment(
      firstMention: ExegesisFirstMention.fromJson(
        json['firstMention'] as Map<String, dynamic>? ?? {},
      ),
      otDevelopment: json['otDevelopment'] as String? ?? '',
      fulfillmentInChrist: json['fulfillmentInChrist'] as String? ?? '',
      ntDevelopment: json['ntDevelopment'] as String? ?? '',
      eschatologicalCompletion: json['eschatologicalCompletion'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'firstMention': firstMention.toJson(),
    'otDevelopment': otDevelopment,
    'fulfillmentInChrist': fulfillmentInChrist,
    'ntDevelopment': ntDevelopment,
    'eschatologicalCompletion': eschatologicalCompletion,
  };
}

// ═══════════════════════════════════════════════════════════════════
//  SUB-MODEL: FirstMention (typeId: 57)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 57)
class ExegesisFirstMention {
  @HiveField(0)
  final String reference;

  @HiveField(1)
  final String form;

  @HiveField(2)
  final String significance;

  ExegesisFirstMention({
    this.reference = '',
    this.form = '',
    this.significance = '',
  });

  factory ExegesisFirstMention.fromJson(Map<String, dynamic> json) {
    return ExegesisFirstMention(
      reference: json['reference'] as String? ?? '',
      form: json['form'] as String? ?? '',
      significance: json['significance'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'reference': reference,
    'form': form,
    'significance': significance,
  };
}
