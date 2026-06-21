import 'package:hive/hive.dart';

part 'exegesis_result_v2_model.g.dart';

// ═══════════════════════════════════════════════════════════════════
//  ENUMS
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 81)
enum ExegesisMode {
  @HiveField(0)
  understand,
  
  @HiveField(1)
  goDeep,
}

@HiveType(typeId: 82)
enum ExegesisEntryType {
  @HiveField(0)
  singleVerse,
  
  @HiveField(1)
  passage,
  
  @HiveField(2)
  bibleBook,
  
  @HiveField(3)
  bibleCharacter,
  
  @HiveField(4)
  theme,
}

@HiveType(typeId: 83)
enum EchoConnectionType {
  @HiveField(0)
  parallel,
  
  @HiveField(1)
  allusion,
  
  @HiveField(2)
  fulfillment,
  
  @HiveField(3)
  contrast,
  
  @HiveField(4)
  development,
}

// ═══════════════════════════════════════════════════════════════════
//  MAIN MODEL — ExegesisResultV2 (typeId: 80)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 80)
class ExegesisResultV2 extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final ExegesisEntryType entryType;

  @HiveField(2)
  final String subject;

  @HiveField(3)
  final ExegesisMode mode;

  @HiveField(4)
  final DateTime createdAt;

  // ── Core Narrative Sections (both modes) ──
  
  @HiveField(5)
  final String bigPicture;

  @HiveField(6)
  final String historicalMoment;

  @HiveField(7)
  final KeyWordMoment? keyWord;

  @HiveField(8)
  final String whatWasBeingSaid;

  @HiveField(9)
  final String inTheWholeStory;

  @HiveField(10)
  final List<EchoItem> echoes;

  @HiveField(11)
  final String whatThisMeansForYou;

  @HiveField(12)
  final String somethingToSitWith;

  // ── Go Deep Only Fields ──
  
  @HiveField(13)
  final List<WordStudyItem>? wordStudies;

  @HiveField(14)
  final List<InterpretiveTension>? interpretiveTensions;

  @HiveField(15)
  final String? grammaticalHighlights;

  @HiveField(16)
  final CovenantContext? covenantContext;

  // ── Metadata ──
  
  @HiveField(17)
  final String? cachedAlternateModeId;

  ExegesisResultV2({
    required this.id,
    required this.entryType,
    required this.subject,
    required this.mode,
    required this.createdAt,
    required this.bigPicture,
    required this.historicalMoment,
    this.keyWord,
    required this.whatWasBeingSaid,
    required this.inTheWholeStory,
    required this.echoes,
    required this.whatThisMeansForYou,
    required this.somethingToSitWith,
    this.wordStudies,
    this.interpretiveTensions,
    this.grammaticalHighlights,
    this.covenantContext,
    this.cachedAlternateModeId,
  });

  factory ExegesisResultV2.fromJson(Map<String, dynamic> json) {
    return ExegesisResultV2(
      id: json['id'] as String? ?? '',
      entryType: _parseEntryType(json['entryType']),
      subject: json['subject'] as String? ?? '',
      mode: _parseMode(json['mode']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      bigPicture: json['bigPicture'] as String? ?? '',
      historicalMoment: json['historicalMoment'] as String? ?? '',
      keyWord: json['keyWord'] != null
          ? KeyWordMoment.fromJson(json['keyWord'] as Map<String, dynamic>)
          : null,
      whatWasBeingSaid: json['whatWasBeingSaid'] as String? ?? '',
      inTheWholeStory: json['inTheWholeStory'] as String? ?? '',
      echoes: (json['echoes'] as List<dynamic>? ?? [])
          .where((e) => e is Map)
          .map((e) => EchoItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      whatThisMeansForYou: json['whatThisMeansForYou'] as String? ?? '',
      somethingToSitWith: json['somethingToSitWith'] as String? ?? '',
      wordStudies: json['wordStudies'] != null && json['wordStudies'] is List
          ? (json['wordStudies'] as List<dynamic>)
              .where((e) => e is Map)
              .map((e) => WordStudyItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      interpretiveTensions: json['interpretiveTensions'] != null && json['interpretiveTensions'] is List
          ? (json['interpretiveTensions'] as List<dynamic>)
              .where((e) => e is Map)
              .map((e) => InterpretiveTension.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      grammaticalHighlights: json['grammaticalHighlights'] as String?,
      covenantContext: json['covenantContext'] != null && json['covenantContext'] is Map
          ? CovenantContext.fromJson(json['covenantContext'] as Map<String, dynamic>)
          : null,
      cachedAlternateModeId: json['cachedAlternateModeId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entryType': _entryTypeToString(entryType),
      'subject': subject,
      'mode': _modeToString(mode),
      'createdAt': createdAt.toIso8601String(),
      'bigPicture': bigPicture,
      'historicalMoment': historicalMoment,
      if (keyWord != null) 'keyWord': keyWord!.toJson(),
      'whatWasBeingSaid': whatWasBeingSaid,
      'inTheWholeStory': inTheWholeStory,
      'echoes': echoes.map((e) => e.toJson()).toList(),
      'whatThisMeansForYou': whatThisMeansForYou,
      'somethingToSitWith': somethingToSitWith,
      if (wordStudies != null) 'wordStudies': wordStudies!.map((e) => e.toJson()).toList(),
      if (interpretiveTensions != null) 'interpretiveTensions': interpretiveTensions!.map((e) => e.toJson()).toList(),
      if (grammaticalHighlights != null) 'grammaticalHighlights': grammaticalHighlights,
      if (covenantContext != null) 'covenantContext': covenantContext!.toJson(),
      if (cachedAlternateModeId != null) 'cachedAlternateModeId': cachedAlternateModeId,
    };
  }

  ExegesisResultV2 copyWith({
    String? id,
    ExegesisEntryType? entryType,
    String? subject,
    ExegesisMode? mode,
    DateTime? createdAt,
    String? bigPicture,
    String? historicalMoment,
    KeyWordMoment? keyWord,
    String? whatWasBeingSaid,
    String? inTheWholeStory,
    List<EchoItem>? echoes,
    String? whatThisMeansForYou,
    String? somethingToSitWith,
    List<WordStudyItem>? wordStudies,
    List<InterpretiveTension>? interpretiveTensions,
    String? grammaticalHighlights,
    CovenantContext? covenantContext,
    String? cachedAlternateModeId,
  }) {
    return ExegesisResultV2(
      id: id ?? this.id,
      entryType: entryType ?? this.entryType,
      subject: subject ?? this.subject,
      mode: mode ?? this.mode,
      createdAt: createdAt ?? this.createdAt,
      bigPicture: bigPicture ?? this.bigPicture,
      historicalMoment: historicalMoment ?? this.historicalMoment,
      keyWord: keyWord ?? this.keyWord,
      whatWasBeingSaid: whatWasBeingSaid ?? this.whatWasBeingSaid,
      inTheWholeStory: inTheWholeStory ?? this.inTheWholeStory,
      echoes: echoes ?? this.echoes,
      whatThisMeansForYou: whatThisMeansForYou ?? this.whatThisMeansForYou,
      somethingToSitWith: somethingToSitWith ?? this.somethingToSitWith,
      wordStudies: wordStudies ?? this.wordStudies,
      interpretiveTensions: interpretiveTensions ?? this.interpretiveTensions,
      grammaticalHighlights: grammaticalHighlights ?? this.grammaticalHighlights,
      covenantContext: covenantContext ?? this.covenantContext,
      cachedAlternateModeId: cachedAlternateModeId ?? this.cachedAlternateModeId,
    );
  }

  // Helper methods for enum conversion
  static ExegesisMode _parseMode(dynamic value) {
    if (value is ExegesisMode) return value;
    final str = value.toString().toLowerCase();
    if (str.contains('deep')) return ExegesisMode.goDeep;
    return ExegesisMode.understand;
  }

  static String _modeToString(ExegesisMode mode) {
    return mode == ExegesisMode.goDeep ? 'goDeep' : 'understand';
  }

  static ExegesisEntryType _parseEntryType(dynamic value) {
    if (value is ExegesisEntryType) return value;
    final str = value.toString().toLowerCase().replaceAll(' ', '');
    if (str.contains('passage')) return ExegesisEntryType.passage;
    if (str.contains('book')) return ExegesisEntryType.bibleBook;
    if (str.contains('character')) return ExegesisEntryType.bibleCharacter;
    if (str.contains('theme')) return ExegesisEntryType.theme;
    return ExegesisEntryType.singleVerse;
  }

  static String _entryTypeToString(ExegesisEntryType type) {
    switch (type) {
      case ExegesisEntryType.singleVerse:
        return 'Single Verse';
      case ExegesisEntryType.passage:
        return 'Passage';
      case ExegesisEntryType.bibleBook:
        return 'Bible Book';
      case ExegesisEntryType.bibleCharacter:
        return 'Bible Character';
      case ExegesisEntryType.theme:
        return 'Theme';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SUB-MODEL: KeyWordMoment (typeId: 84)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 84)
class KeyWordMoment {
  @HiveField(0)
  final String originalScript;

  @HiveField(1)
  final String transliteration;

  @HiveField(2)
  final String? strongsNumber;

  @HiveField(3)
  final String meaning;

  @HiveField(4)
  final String whyItMatters;

  KeyWordMoment({
    required this.originalScript,
    required this.transliteration,
    this.strongsNumber,
    required this.meaning,
    required this.whyItMatters,
  });

  factory KeyWordMoment.fromJson(Map<String, dynamic> json) {
    return KeyWordMoment(
      originalScript: json['originalScript'] as String? ?? '',
      transliteration: json['transliteration'] as String? ?? '',
      strongsNumber: json['strongsNumber'] as String?,
      meaning: json['meaning'] as String? ?? '',
      whyItMatters: json['whyItMatters'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalScript': originalScript,
      'transliteration': transliteration,
      if (strongsNumber != null) 'strongsNumber': strongsNumber,
      'meaning': meaning,
      'whyItMatters': whyItMatters,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SUB-MODEL: EchoItem (typeId: 85)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 85)
class EchoItem {
  @HiveField(0)
  final String reference;

  @HiveField(1)
  final EchoConnectionType connectionType;

  @HiveField(2)
  final String explanation;

  @HiveField(3)
  final String? verseText;

  EchoItem({
    required this.reference,
    required this.connectionType,
    required this.explanation,
    this.verseText,
  });

  factory EchoItem.fromJson(Map<String, dynamic> json) {
    return EchoItem(
      reference: json['reference'] as String? ?? '',
      connectionType: _parseConnectionType(json['connectionType']),
      explanation: json['explanation'] as String? ?? '',
      verseText: json['verseText'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reference': reference,
      'connectionType': _connectionTypeToString(connectionType),
      'explanation': explanation,
      if (verseText != null) 'verseText': verseText,
    };
  }

  static EchoConnectionType _parseConnectionType(dynamic value) {
    if (value is EchoConnectionType) return value;
    final str = value.toString().toLowerCase();
    if (str.contains('allusion')) return EchoConnectionType.allusion;
    if (str.contains('fulfillment')) return EchoConnectionType.fulfillment;
    if (str.contains('contrast')) return EchoConnectionType.contrast;
    if (str.contains('development')) return EchoConnectionType.development;
    return EchoConnectionType.parallel;
  }

  static String _connectionTypeToString(EchoConnectionType type) {
    switch (type) {
      case EchoConnectionType.parallel:
        return 'Parallel';
      case EchoConnectionType.allusion:
        return 'Allusion';
      case EchoConnectionType.fulfillment:
        return 'Fulfillment';
      case EchoConnectionType.contrast:
        return 'Contrast';
      case EchoConnectionType.development:
        return 'Development';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SUB-MODEL: CommonMisreading (typeId: 86)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 86)
class CommonMisreading {
  @HiveField(0)
  final String misreading;

  @HiveField(1)
  final String correction;

  CommonMisreading({
    required this.misreading,
    required this.correction,
  });

  factory CommonMisreading.fromJson(Map<String, dynamic> json) {
    return CommonMisreading(
      misreading: json['misreading'] as String? ?? '',
      correction: json['correction'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'misreading': misreading,
      'correction': correction,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SUB-MODEL: WordStudyItem (typeId: 87)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 87)
class WordStudyItem {
  @HiveField(0)
  final String word;

  @HiveField(1)
  final String transliteration;

  @HiveField(2)
  final String? strongsNumber;

  @HiveField(3)
  final String definition;

  @HiveField(4)
  final String semanticRange;

  @HiveField(5)
  final List<String> usageExamples;

  @HiveField(6)
  final String whyItMatters;

  @HiveField(7)
  final String? translationVariance;

  WordStudyItem({
    required this.word,
    required this.transliteration,
    this.strongsNumber,
    required this.definition,
    required this.semanticRange,
    required this.usageExamples,
    required this.whyItMatters,
    this.translationVariance,
  });

  factory WordStudyItem.fromJson(Map<String, dynamic> json) {
    return WordStudyItem(
      word: json['word'] as String? ?? '',
      transliteration: json['transliteration'] as String? ?? '',
      strongsNumber: json['strongsNumber'] as String?,
      definition: json['definition'] as String? ?? '',
      semanticRange: json['semanticRange'] as String? ?? '',
      usageExamples: (json['usageExamples'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      whyItMatters: json['whyItMatters'] as String? ?? '',
      translationVariance: json['translationVariance'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'transliteration': transliteration,
      if (strongsNumber != null) 'strongsNumber': strongsNumber,
      'definition': definition,
      'semanticRange': semanticRange,
      'usageExamples': usageExamples,
      'whyItMatters': whyItMatters,
      if (translationVariance != null) 'translationVariance': translationVariance,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SUB-MODEL: InterpretiveTension (typeId: 88)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 88)
class InterpretiveTension {
  @HiveField(0)
  final String question;

  @HiveField(1)
  final TensionPosition positionA;

  @HiveField(2)
  final TensionPosition positionB;

  @HiveField(3)
  final String commonGround;

  InterpretiveTension({
    required this.question,
    required this.positionA,
    required this.positionB,
    required this.commonGround,
  });

  factory InterpretiveTension.fromJson(Map<String, dynamic> json) {
    return InterpretiveTension(
      question: json['question'] as String? ?? '',
      positionA: TensionPosition.fromJson(
        json['positionA'] as Map<String, dynamic>? ?? {},
      ),
      positionB: TensionPosition.fromJson(
        json['positionB'] as Map<String, dynamic>? ?? {},
      ),
      commonGround: json['commonGround'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'positionA': positionA.toJson(),
      'positionB': positionB.toJson(),
      'commonGround': commonGround,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SUB-MODEL: TensionPosition (typeId: 89)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 89)
class TensionPosition {
  @HiveField(0)
  final String label;

  @HiveField(1)
  final String explanation;

  @HiveField(2)
  final List<String> supportingVerses;

  TensionPosition({
    required this.label,
    required this.explanation,
    required this.supportingVerses,
  });

  factory TensionPosition.fromJson(Map<String, dynamic> json) {
    return TensionPosition(
      label: json['label'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      supportingVerses: (json['supportingVerses'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'explanation': explanation,
      'supportingVerses': supportingVerses,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SUB-MODEL: CovenantContext (typeId: 90)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 90)
class CovenantContext {
  @HiveField(0)
  final String covenantFramework;

  @HiveField(1)
  final String redemptiveHistoricalPlacement;

  @HiveField(2)
  final String christologicalConnection;

  CovenantContext({
    required this.covenantFramework,
    required this.redemptiveHistoricalPlacement,
    required this.christologicalConnection,
  });

  factory CovenantContext.fromJson(Map<String, dynamic> json) {
    return CovenantContext(
      covenantFramework: json['covenantFramework'] as String? ?? '',
      redemptiveHistoricalPlacement: json['redemptiveHistoricalPlacement'] as String? ?? '',
      christologicalConnection: json['christologicalConnection'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'covenantFramework': covenantFramework,
      'redemptiveHistoricalPlacement': redemptiveHistoricalPlacement,
      'christologicalConnection': christologicalConnection,
    };
  }
}
