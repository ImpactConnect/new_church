import 'dart:convert';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ENUMS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum StudyType {
  character,
  book,
  verse,
  theme,
  topical,
  devotional;

  String get label {
    switch (this) {
      case StudyType.character:
        return 'Character';
      case StudyType.book:
        return 'Book';
      case StudyType.verse:
        return 'Verse';
      case StudyType.theme:
        return 'Theme';
      case StudyType.topical:
        return 'Topical';
      case StudyType.devotional:
        return 'Devotional';
    }
  }

  String get emoji {
    switch (this) {
      case StudyType.character:
        return '👤';
      case StudyType.book:
        return '📚';
      case StudyType.verse:
        return '📌';
      case StudyType.theme:
        return '🧵';
      case StudyType.topical:
        return '💡';
      case StudyType.devotional:
        return '🌅';
    }
  }

  // Blue-purple accent colors for each study type
  int get accentValue {
    switch (this) {
      case StudyType.character:
        return 0xFF5B8DF6; // Bright blue
      case StudyType.book:
        return 0xFF7B61FF; // Purple-blue
      case StudyType.verse:
        return 0xFF5BB8F6; // Sky blue
      case StudyType.theme:
        return 0xFF8B5CF6; // Violet/purple
      case StudyType.topical:
        return 0xFF6B9AF6; // Periwinkle
      case StudyType.devotional:
        return 0xFF9B7DF6; // Lavender blue
    }
  }

  // Background tint (very subtle, good for both light/dark)
  int get tintValue {
    switch (this) {
      case StudyType.character:
        return 0x1A5B8DF6;
      case StudyType.book:
        return 0x1A7B61FF;
      case StudyType.verse:
        return 0x1A5BB8F6;
      case StudyType.theme:
        return 0x1A8B5CF6;
      case StudyType.topical:
        return 0x1A6B9AF6;
      case StudyType.devotional:
        return 0x1A9B7DF6;
    }
  }
}

enum StudyFormat { single, series }

enum StudyStatus { generating, active, completed, archived }

enum SessionRole {
  foundation,
  development,
  depth,
  turningPoint,
  integration,
  application;

  String get label {
    switch (this) {
      case SessionRole.foundation:
        return 'Foundation';
      case SessionRole.development:
        return 'Development';
      case SessionRole.depth:
        return 'Depth';
      case SessionRole.turningPoint:
        return 'Turning Point';
      case SessionRole.integration:
        return 'Integration';
      case SessionRole.application:
        return 'Application';
    }
  }

  // Color values for UI badges
  int get colorValue {
    switch (this) {
      case SessionRole.foundation:
        return 0xFF5B8DF6; // Blue
      case SessionRole.development:
        return 0xFF26C6DA; // Teal
      case SessionRole.depth:
        return 0xFF8B5CF6; // Purple
      case SessionRole.turningPoint:
        return 0xFFFFA726; // Amber
      case SessionRole.integration:
        return 0xFF5C6BC0; // Indigo
      case SessionRole.application:
        return 0xFF66BB6A; // Green
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SESSION CONTINUITY MODELS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class PreviousSessionBridge {
  final List<int> sessionsReferenced;
  final String bridgeText;

  const PreviousSessionBridge({
    required this.sessionsReferenced,
    required this.bridgeText,
  });

  factory PreviousSessionBridge.fromJson(Map<String, dynamic> json) =>
      PreviousSessionBridge(
        sessionsReferenced:
            (json['sessionsReferenced'] as List<dynamic>?)?.cast<int>() ??
            (json['sessionReferenced'] != null
                ? [json['sessionReferenced'] as int]
                : []),
        bridgeText: json['bridgeText'] ?? '',
      );

  Map<String, dynamic> toJson() => {
    'sessionsReferenced': sessionsReferenced,
    'bridgeText': bridgeText,
  };

  bool get isValid => bridgeText.split(' ').length >= 60;
}

class WordDefinitionRegistry {
  final String studyId;
  final Map<String, int> strongsToSessionMap;

  WordDefinitionRegistry({
    required this.studyId,
    Map<String, int>? strongsToSessionMap,
  }) : strongsToSessionMap = strongsToSessionMap ?? {};

  bool isDefined(String strongsNumber) =>
      strongsToSessionMap.containsKey(strongsNumber);

  void registerWord(String strongsNumber, int sessionNumber) {
    strongsToSessionMap[strongsNumber] = sessionNumber;
  }

  int? getDefinedInSession(String strongsNumber) =>
      strongsToSessionMap[strongsNumber];

  List<Map<String, dynamic>> toPromptArray() {
    return strongsToSessionMap.entries
        .map((e) => {'strongsNumber': e.key, 'definedInSession': e.value})
        .toList();
  }

  factory WordDefinitionRegistry.fromJson(Map<String, dynamic> json) =>
      WordDefinitionRegistry(
        studyId: json['studyId'] ?? '',
        strongsToSessionMap:
            (json['strongsToSessionMap'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, v as int),
            ) ??
            {},
      );

  Map<String, dynamic> toJson() => {
    'studyId': studyId,
    'strongsToSessionMap': strongsToSessionMap,
  };
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CORE DATA MODELS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class WordInsight {
  final String englishWord;
  final String original;
  final String transliteration;
  final String strongsNumber;
  final String insight;
  final String? disambiguationNote;

  const WordInsight({
    required this.englishWord,
    required this.original,
    required this.transliteration,
    required this.strongsNumber,
    required this.insight,
    this.disambiguationNote,
  });

  factory WordInsight.fromJson(Map<String, dynamic> json) => WordInsight(
    englishWord: json['englishWord'] ?? '',
    original: json['original'] ?? '',
    transliteration: json['transliteration'] ?? '',
    strongsNumber: json['strongsNumber'] ?? '',
    insight: json['insight'] ?? json['discovery'] ?? '',
    disambiguationNote: json['disambiguationNote'],
  );

  Map<String, dynamic> toJson() => {
    'englishWord': englishWord,
    'original': original,
    'transliteration': transliteration,
    'strongsNumber': strongsNumber,
    'insight': insight,
    if (disambiguationNote != null) 'disambiguationNote': disambiguationNote,
  };

  bool get isHebrew => strongsNumber.startsWith('H');
}

class NarrativeEvent {
  final String eventTitle;
  final String primaryReference;
  final String narrative;
  final String whatGodReveals;
  final WordInsight? keyWordInsight;

  const NarrativeEvent({
    required this.eventTitle,
    required this.primaryReference,
    required this.narrative,
    required this.whatGodReveals,
    this.keyWordInsight,
  });

  factory NarrativeEvent.fromJson(Map<String, dynamic> json) => NarrativeEvent(
    eventTitle: json['eventTitle'] ?? json['title'] ?? '',
    primaryReference: json['primaryReference'] ?? json['reference'] ?? '',
    narrative: json['narrative'] ?? '',
    whatGodReveals:
        json['whatGodReveals'] ??
        json['themeConnection'] ??
        json['significance'] ??
        '',
    keyWordInsight: json['keyWordInsight'] != null
        ? WordInsight.fromJson(json['keyWordInsight'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'eventTitle': eventTitle,
    'primaryReference': primaryReference,
    'narrative': narrative,
    'whatGodReveals': whatGodReveals,
    if (keyWordInsight != null) 'keyWordInsight': keyWordInsight!.toJson(),
  };
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DYNAMIC SECTION MODELS (Character Studies V2)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class ScriptureReference {
  final String reference;
  final String? verseText;
  final String relevance;

  const ScriptureReference({
    required this.reference,
    this.verseText,
    required this.relevance,
  });

  factory ScriptureReference.fromJson(Map<String, dynamic> json) =>
      ScriptureReference(
        reference: json['reference'] ?? '',
        verseText: json['verseText'],
        relevance: json['relevance'] ?? '',
      );

  Map<String, dynamic> toJson() => {
    'reference': reference,
    if (verseText != null) 'verseText': verseText,
    'relevance': relevance,
  };
}

class OtherWordUse {
  final String reference;
  final String significance;

  const OtherWordUse({required this.reference, required this.significance});

  factory OtherWordUse.fromJson(Map<String, dynamic> json) => OtherWordUse(
    reference: json['reference'] ?? '',
    significance: json['significance'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'reference': reference,
    'significance': significance,
  };
}

class DynamicKeyWordInsight {
  final String englishWord;
  final String original;
  final String transliteration;
  final String strongsNumber;
  final String insight;
  final List<OtherWordUse> otherUses;

  const DynamicKeyWordInsight({
    required this.englishWord,
    required this.original,
    required this.transliteration,
    required this.strongsNumber,
    required this.insight,
    this.otherUses = const [],
  });

  factory DynamicKeyWordInsight.fromJson(Map<String, dynamic> json) {
    final otherUsesList = json['otherUses'] as List<dynamic>?;
    return DynamicKeyWordInsight(
      englishWord: json['englishWord'] ?? '',
      original: json['original'] ?? '',
      transliteration: json['transliteration'] ?? '',
      strongsNumber: json['strongsNumber'] ?? '',
      insight: json['insight'] ?? '',
      otherUses:
          otherUsesList
              ?.map((e) => OtherWordUse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'englishWord': englishWord,
    'original': original,
    'transliteration': transliteration,
    'strongsNumber': strongsNumber,
    'insight': insight,
    'otherUses': otherUses.map((e) => e.toJson()).toList(),
  };
}

enum SectionType {
  introduction,
  narrative,
  teaching,
  wordStudy,
  application,
  bridge,
  reflection,
  legacy;

  String get label {
    switch (this) {
      case SectionType.introduction:
        return 'Introduction';
      case SectionType.narrative:
        return 'Narrative';
      case SectionType.teaching:
        return 'Teaching';
      case SectionType.wordStudy:
        return 'Word Study';
      case SectionType.application:
        return 'Application';
      case SectionType.bridge:
        return 'Bridge';
      case SectionType.reflection:
        return 'Reflection';
      case SectionType.legacy:
        return 'Legacy';
    }
  }

  static SectionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'introduction':
        return SectionType.introduction;
      case 'narrative':
        return SectionType.narrative;
      case 'teaching':
        return SectionType.teaching;
      case 'word_study':
        return SectionType.wordStudy;
      case 'application':
        return SectionType.application;
      case 'bridge':
        return SectionType.bridge;
      case 'reflection':
        return SectionType.reflection;
      case 'legacy':
        return SectionType.legacy;
      default:
        return SectionType.narrative;
    }
  }
}

class DynamicStudySection {
  final String sectionTitle;
  final SectionType sectionType;
  final String content;
  final List<ScriptureReference> scriptures;
  final DynamicKeyWordInsight? keyWordInsight;

  const DynamicStudySection({
    required this.sectionTitle,
    required this.sectionType,
    required this.content,
    this.scriptures = const [],
    this.keyWordInsight,
  });

  factory DynamicStudySection.fromJson(Map<String, dynamic> json) {
    final scripturesList = json['scriptures'] as List<dynamic>?;
    return DynamicStudySection(
      sectionTitle: json['sectionTitle'] ?? '',
      sectionType: SectionType.fromString(json['sectionType'] ?? 'narrative'),
      content: json['content'] ?? '',
      scriptures:
          scripturesList
              ?.map(
                (e) => ScriptureReference.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      keyWordInsight: json['keyWordInsight'] != null
          ? DynamicKeyWordInsight.fromJson(json['keyWordInsight'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'sectionTitle': sectionTitle,
    'sectionType': sectionType.name,
    'content': content,
    'scriptures': scriptures.map((e) => e.toJson()).toList(),
    if (keyWordInsight != null) 'keyWordInsight': keyWordInsight!.toJson(),
  };
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// V2.1 MODELS - ANCHOR PASSAGES, KEYWORD ANALYSIS, BIBLE STORIES
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class AnchorPassage {
  final String reference;
  final String verseText;
  final String whyThisPassage;

  const AnchorPassage({
    required this.reference,
    required this.verseText,
    required this.whyThisPassage,
  });

  factory AnchorPassage.fromJson(Map<String, dynamic> json) => AnchorPassage(
    reference: json['reference'] ?? '',
    verseText: json['verseText'] ?? '',
    whyThisPassage: json['whyThisPassage'] ?? json['whyToday'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'reference': reference,
    'verseText': verseText,
    'whyThisPassage': whyThisPassage,
  };
}

class HebrewWord {
  final String script;
  final String transliteration;
  final String strongsNumber;
  final String definition;
  final String insight;

  const HebrewWord({
    required this.script,
    required this.transliteration,
    required this.strongsNumber,
    required this.definition,
    required this.insight,
  });

  factory HebrewWord.fromJson(Map<String, dynamic> json) => HebrewWord(
    script: json['script'] ?? '',
    transliteration: json['transliteration'] ?? '',
    strongsNumber: json['strongsNumber'] ?? '',
    definition: json['definition'] ?? '',
    insight: json['insight'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'script': script,
    'transliteration': transliteration,
    'strongsNumber': strongsNumber,
    'definition': definition,
    'insight': insight,
  };
}

class GreekWord {
  final String script;
  final String transliteration;
  final String strongsNumber;
  final String definition;
  final String insight;

  const GreekWord({
    required this.script,
    required this.transliteration,
    required this.strongsNumber,
    required this.definition,
    required this.insight,
  });

  factory GreekWord.fromJson(Map<String, dynamic> json) => GreekWord(
    script: json['script'] ?? '',
    transliteration: json['transliteration'] ?? '',
    strongsNumber: json['strongsNumber'] ?? '',
    definition: json['definition'] ?? '',
    insight: json['insight'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'script': script,
    'transliteration': transliteration,
    'strongsNumber': strongsNumber,
    'definition': definition,
    'insight': insight,
  };
}

class KeywordAnalysisItem {
  final String word;
  final HebrewWord? hebrewWord;
  final GreekWord? greekWord;

  const KeywordAnalysisItem({
    required this.word,
    this.hebrewWord,
    this.greekWord,
  });

  factory KeywordAnalysisItem.fromJson(Map<String, dynamic> json) =>
      KeywordAnalysisItem(
        word: json['word'] ?? '',
        hebrewWord: json['hebrewWord'] != null
            ? HebrewWord.fromJson(json['hebrewWord'])
            : null,
        greekWord: json['greekWord'] != null
            ? GreekWord.fromJson(json['greekWord'])
            : null,
      );

  Map<String, dynamic> toJson() => {
    'word': word,
    if (hebrewWord != null) 'hebrewWord': hebrewWord!.toJson(),
    if (greekWord != null) 'greekWord': greekWord!.toJson(),
  };
}

class KeywordAnalysis {
  final List<KeywordAnalysisItem> keywords;

  const KeywordAnalysis({required this.keywords});

  factory KeywordAnalysis.fromJson(Map<String, dynamic> json) {
    final keywordsList = json['keywords'] as List<dynamic>?;
    return KeywordAnalysis(
      keywords:
          keywordsList
              ?.map(
                (k) => KeywordAnalysisItem.fromJson(k as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'keywords': keywords.map((k) => k.toJson()).toList(),
  };
}

class BibleStory {
  final String title;
  final String reference;
  final String summary;
  final String connection;

  const BibleStory({
    required this.title,
    required this.reference,
    required this.summary,
    required this.connection,
  });

  factory BibleStory.fromJson(Map<String, dynamic> json) => BibleStory(
    title: json['title'] ?? '',
    reference: json['reference'] ?? '',
    summary: json['summary'] ?? '',
    connection: json['connection'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'reference': reference,
    'summary': summary,
    'connection': connection,
  };
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ENHANCED BOOK STUDY MODELS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class NotableEvent {
  final String eventTitle;
  final String reference;
  final String narrative;
  final String participants;
  final String context;
  final String significance;
  final List<String> lessons;

  const NotableEvent({
    required this.eventTitle,
    required this.reference,
    required this.narrative,
    required this.participants,
    required this.context,
    required this.significance,
    required this.lessons,
  });

  factory NotableEvent.fromJson(Map<String, dynamic> json) => NotableEvent(
    eventTitle: json['eventTitle'] ?? '',
    reference: json['reference'] ?? '',
    narrative: json['narrative'] ?? '',
    participants: json['participants'] ?? '',
    context: json['context'] ?? '',
    significance: json['significance'] ?? '',
    lessons: (json['lessons'] as List<dynamic>?)?.cast<String>() ?? [],
  );

  Map<String, dynamic> toJson() => {
    'eventTitle': eventTitle,
    'reference': reference,
    'narrative': narrative,
    'participants': participants,
    'context': context,
    'significance': significance,
    'lessons': lessons,
  };
}

class NotableStatement {
  final String statement;
  final String reference;
  final String speaker;
  final String audience;
  final String context;
  final String significance;
  final List<String> lessons;

  const NotableStatement({
    required this.statement,
    required this.reference,
    required this.speaker,
    required this.audience,
    required this.context,
    required this.significance,
    required this.lessons,
  });

  factory NotableStatement.fromJson(Map<String, dynamic> json) =>
      NotableStatement(
        statement: json['statement'] ?? '',
        reference: json['reference'] ?? '',
        speaker: json['speaker'] ?? '',
        audience: json['audience'] ?? '',
        context: json['context'] ?? '',
        significance: json['significance'] ?? '',
        lessons: (json['lessons'] as List<dynamic>?)?.cast<String>() ?? [],
      );

  Map<String, dynamic> toJson() => {
    'statement': statement,
    'reference': reference,
    'speaker': speaker,
    'audience': audience,
    'context': context,
    'significance': significance,
    'lessons': lessons,
  };
}

class CharacterMoment {
  final String reference;
  final String event;
  final String significance;

  const CharacterMoment({
    required this.reference,
    required this.event,
    required this.significance,
  });

  factory CharacterMoment.fromJson(Map<String, dynamic> json) =>
      CharacterMoment(
        reference: json['reference'] ?? '',
        event: json['event'] ?? '',
        significance: json['significance'] ?? '',
      );

  Map<String, dynamic> toJson() => {
    'reference': reference,
    'event': event,
    'significance': significance,
  };
}

class NotableCharacter {
  final String name;
  final String role;
  final List<CharacterMoment> keyMoments;
  final String characterArc;
  final List<String> lessons;

  const NotableCharacter({
    required this.name,
    required this.role,
    required this.keyMoments,
    required this.characterArc,
    required this.lessons,
  });

  factory NotableCharacter.fromJson(Map<String, dynamic> json) =>
      NotableCharacter(
        name: json['name'] ?? '',
        role: json['role'] ?? '',
        keyMoments:
            (json['keyMoments'] as List<dynamic>?)
                ?.map((m) => CharacterMoment.fromJson(m))
                .toList() ??
            [],
        characterArc: json['characterArc'] ?? '',
        lessons: (json['lessons'] as List<dynamic>?)?.cast<String>() ?? [],
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'role': role,
    'keyMoments': keyMoments.map((m) => m.toJson()).toList(),
    'characterArc': characterArc,
    'lessons': lessons,
  };
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// VERSE STUDY ENHANCED MODELS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class FirstUseInBible {
  final String reference;
  final String? verseText;
  final String whatItEstablishes;

  const FirstUseInBible({
    required this.reference,
    this.verseText,
    required this.whatItEstablishes,
  });

  factory FirstUseInBible.fromJson(Map<String, dynamic> json) =>
      FirstUseInBible(
        reference: json['reference'] ?? '',
        verseText: json['verseText'],
        whatItEstablishes: json['whatItEstablishes'] ?? '',
      );

  Map<String, dynamic> toJson() => {
    'reference': reference,
    if (verseText != null) 'verseText': verseText,
    'whatItEstablishes': whatItEstablishes,
  };
}

class SignificantUse {
  final String reference;
  final String? verseText;
  final String howItIlluminatesThisVerse;

  const SignificantUse({
    required this.reference,
    this.verseText,
    required this.howItIlluminatesThisVerse,
  });

  factory SignificantUse.fromJson(Map<String, dynamic> json) => SignificantUse(
    reference: json['reference'] ?? '',
    verseText: json['verseText'],
    howItIlluminatesThisVerse: json['howItIlluminatesThisVerse'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'reference': reference,
    if (verseText != null) 'verseText': verseText,
    'howItIlluminatesThisVerse': howItIlluminatesThisVerse,
  };
}

class CanonicalUsageMap {
  final FirstUseInBible firstUseInEntireBible;
  final List<SignificantUse> significantUses;

  const CanonicalUsageMap({
    required this.firstUseInEntireBible,
    required this.significantUses,
  });

  factory CanonicalUsageMap.fromJson(Map<String, dynamic> json) =>
      CanonicalUsageMap(
        firstUseInEntireBible: FirstUseInBible.fromJson(
          json['firstUseInEntireBible'] ?? {},
        ),
        significantUses:
            (json['significantUses'] as List<dynamic>?)
                ?.map((u) => SignificantUse.fromJson(u))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
    'firstUseInEntireBible': firstUseInEntireBible.toJson(),
    'significantUses': significantUses.map((u) => u.toJson()).toList(),
  };
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CHARACTER STUDY ENHANCED MODELS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class CharacterLifePhase {
  final String lifePhase;
  final String chronologicalPosition;
  final String? whereWeAreInTheStory;

  const CharacterLifePhase({
    required this.lifePhase,
    required this.chronologicalPosition,
    this.whereWeAreInTheStory,
  });

  factory CharacterLifePhase.fromJson(Map<String, dynamic> json) =>
      CharacterLifePhase(
        lifePhase: json['lifePhase'] ?? '',
        chronologicalPosition: json['chronologicalPosition'] ?? '',
        whereWeAreInTheStory: json['whereWeAreInTheStory'],
      );

  Map<String, dynamic> toJson() => {
    'lifePhase': lifePhase,
    'chronologicalPosition': chronologicalPosition,
    if (whereWeAreInTheStory != null)
      'whereWeAreInTheStory': whereWeAreInTheStory,
  };
}

class BiblicalFigureConnection {
  final String figure;
  final String connection;

  const BiblicalFigureConnection({
    required this.figure,
    required this.connection,
  });

  factory BiblicalFigureConnection.fromJson(Map<String, dynamic> json) =>
      BiblicalFigureConnection(
        figure: json['figure'] ?? '',
        connection: json['connection'] ?? '',
      );

  Map<String, dynamic> toJson() => {'figure': figure, 'connection': connection};
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// STUDY NOTES AND HIGHLIGHTS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class StudyNote {
  final String id;
  final String questionIndex;
  final String content;
  final DateTime createdAt;

  const StudyNote({
    required this.id,
    required this.questionIndex,
    required this.content,
    required this.createdAt,
  });

  factory StudyNote.fromJson(Map<String, dynamic> json) => StudyNote(
    id: json['id'] ?? '',
    questionIndex: json['questionIndex'] ?? 'general',
    content: json['content'] ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'questionIndex': questionIndex,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };
}

class StudyHighlight {
  final String id;
  final String sectionKey;
  final int startOffset;
  final int endOffset;
  final String colour;
  final String? annotation;

  const StudyHighlight({
    required this.id,
    required this.sectionKey,
    required this.startOffset,
    required this.endOffset,
    required this.colour,
    this.annotation,
  });

  factory StudyHighlight.fromJson(Map<String, dynamic> json) => StudyHighlight(
    id: json['id'] ?? '',
    sectionKey: json['sectionKey'] ?? '',
    startOffset: json['startOffset'] ?? 0,
    endOffset: json['endOffset'] ?? 0,
    colour: json['colour'] ?? 'yellow',
    annotation: json['annotation'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sectionKey': sectionKey,
    'startOffset': startOffset,
    'endOffset': endOffset,
    'colour': colour,
    if (annotation != null) 'annotation': annotation,
  };
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// STUDY SESSION
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class StudySession {
  final int sessionNumber;
  final SessionRole? sessionRole;
  final String sessionTitle;
  final String? sessionSubtitle;
  final String? primaryScripture;
  final String? lifePhase; // Character Study
  final String? chapterRange; // Book Study
  final String? eraFocus; // Theme Study
  bool isGenerated;
  bool isGenerating;
  String? contentJson;
  String? partialContentJson;
  String? generationStage;
  String? lastGenerationError;
  final List<String> wordsAlreadyDefined; // Strong's numbers
  List<StudyHighlight> highlights;
  List<StudyNote> notes;
  List<int> answeredQuestions;
  DateTime? generatedAt;
  DateTime? unlocksAt; // For devotionals

  StudySession({
    required this.sessionNumber,
    this.sessionRole,
    required this.sessionTitle,
    this.sessionSubtitle,
    this.primaryScripture,
    this.lifePhase,
    this.chapterRange,
    this.eraFocus,
    this.isGenerated = false,
    this.isGenerating = false,
    this.contentJson,
    this.partialContentJson,
    this.generationStage,
    this.lastGenerationError,
    List<String>? wordsAlreadyDefined,
    List<StudyHighlight>? highlights,
    List<StudyNote>? notes,
    List<int>? answeredQuestions,
    this.generatedAt,
    this.unlocksAt,
  }) : wordsAlreadyDefined = wordsAlreadyDefined ?? [],
       highlights = highlights ?? [],
       notes = notes ?? [],
       answeredQuestions = answeredQuestions ?? [];

  Map<String, dynamic>? get parsedContent {
    if (contentJson == null) return null;
    try {
      return jsonDecode(contentJson!) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? get parsedPartialContent {
    if (partialContentJson == null) return null;
    try {
      return jsonDecode(partialContentJson!) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  bool get isAvailableToRead {
    if (unlocksAt == null) return isGenerated;
    return DateTime.now().isAfter(unlocksAt!) && isGenerated;
  }

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
    sessionNumber: json['sessionNumber'] ?? 1,
    sessionRole: json['sessionRole'] != null
        ? SessionRole.values.firstWhere(
            (r) => r.name == json['sessionRole'],
            orElse: () => SessionRole.foundation,
          )
        : null,
    sessionTitle: json['sessionTitle'] ?? '',
    sessionSubtitle: json['sessionSubtitle'],
    primaryScripture: json['primaryScripture'],
    lifePhase: json['lifePhase'],
    chapterRange: json['chapterRange'],
    eraFocus: json['eraFocus'],
    isGenerated: json['isGenerated'] ?? false,
    isGenerating: json['isGenerating'] ?? false,
    contentJson: json['contentJson'],
    partialContentJson: json['partialContentJson'],
    generationStage: json['generationStage'],
    lastGenerationError: json['lastGenerationError'],
    wordsAlreadyDefined:
        (json['wordsAlreadyDefined'] as List<dynamic>?)?.cast<String>() ?? [],
    highlights:
        (json['highlights'] as List<dynamic>?)
            ?.map((h) => StudyHighlight.fromJson(h))
            .toList() ??
        [],
    notes:
        (json['notes'] as List<dynamic>?)
            ?.map((n) => StudyNote.fromJson(n))
            .toList() ??
        [],
    answeredQuestions:
        (json['answeredQuestions'] as List<dynamic>?)?.cast<int>() ?? [],
    generatedAt: json['generatedAt'] != null
        ? DateTime.tryParse(json['generatedAt'])
        : null,
    unlocksAt: json['unlocksAt'] != null
        ? DateTime.tryParse(json['unlocksAt'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'sessionNumber': sessionNumber,
    if (sessionRole != null) 'sessionRole': sessionRole!.name,
    'sessionTitle': sessionTitle,
    if (sessionSubtitle != null) 'sessionSubtitle': sessionSubtitle,
    if (primaryScripture != null) 'primaryScripture': primaryScripture,
    if (lifePhase != null) 'lifePhase': lifePhase,
    if (chapterRange != null) 'chapterRange': chapterRange,
    if (eraFocus != null) 'eraFocus': eraFocus,
    'isGenerated': isGenerated,
    'isGenerating': isGenerating,
    if (contentJson != null) 'contentJson': contentJson,
    if (partialContentJson != null) 'partialContentJson': partialContentJson,
    if (generationStage != null) 'generationStage': generationStage,
    if (lastGenerationError != null) 'lastGenerationError': lastGenerationError,
    'wordsAlreadyDefined': wordsAlreadyDefined,
    'highlights': highlights.map((h) => h.toJson()).toList(),
    'notes': notes.map((n) => n.toJson()).toList(),
    'answeredQuestions': answeredQuestions,
    if (generatedAt != null) 'generatedAt': generatedAt!.toIso8601String(),
    if (unlocksAt != null) 'unlocksAt': unlocksAt!.toIso8601String(),
  };
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BIBLE STUDY (MAIN MODEL)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class BibleStudy {
  final String id;
  final StudyType studyType;
  final StudyFormat format;
  StudyStatus status;
  final String subject; // character name / book / verse ref / theme / question
  final String studyTitle;
  final String? seriesOverview;
  final int totalSessions;
  List<StudySession> sessions;
  List<int> completedSessions;
  final DateTime createdAt;
  DateTime? lastAccessedAt;
  // Devotional-specific
  final DateTime? startDate;
  final String? personalContext;
  final BibleStudyInput? originalInput;

  BibleStudy({
    required this.id,
    required this.studyType,
    required this.format,
    required this.status,
    required this.subject,
    required this.studyTitle,
    this.seriesOverview,
    required this.totalSessions,
    required this.sessions,
    List<int>? completedSessions,
    required this.createdAt,
    this.lastAccessedAt,
    this.startDate,
    this.personalContext,
    this.originalInput,
  }) : completedSessions = completedSessions ?? [];

  bool get isCompleted => completedSessions.length >= totalSessions;

  double get progress =>
      totalSessions > 0 ? completedSessions.length / totalSessions : 0.0;

  int get nextSessionNumber {
    for (int i = 1; i <= totalSessions; i++) {
      if (!completedSessions.contains(i)) return i;
    }
    return totalSessions;
  }

  StudySession? get nextSession {
    if (sessions.isEmpty) return null;
    final n = nextSessionNumber;
    return sessions.firstWhere(
      (s) => s.sessionNumber == n,
      orElse: () => sessions.last,
    );
  }

  factory BibleStudy.fromJson(Map<String, dynamic> json) => BibleStudy(
    id: json['id'] ?? '',
    studyType: StudyType.values.firstWhere(
      (t) => t.name == json['studyType'],
      orElse: () => StudyType.character,
    ),
    format: StudyFormat.values.firstWhere(
      (f) => f.name == json['format'],
      orElse: () => StudyFormat.single,
    ),
    status: StudyStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => StudyStatus.active,
    ),
    subject: json['subject'] ?? '',
    studyTitle: json['studyTitle'] ?? '',
    seriesOverview: json['seriesOverview'],
    totalSessions: json['totalSessions'] ?? 1,
    sessions:
        (json['sessions'] as List<dynamic>?)
            ?.map((s) => StudySession.fromJson(s))
            .toList() ??
        [],
    completedSessions:
        (json['completedSessions'] as List<dynamic>?)?.cast<int>() ?? [],
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    lastAccessedAt: json['lastAccessedAt'] != null
        ? DateTime.tryParse(json['lastAccessedAt'])
        : null,
    startDate: json['startDate'] != null
        ? DateTime.tryParse(json['startDate'])
        : null,
    personalContext: json['personalContext'],
    originalInput: json['originalInput'] is Map<String, dynamic>
        ? BibleStudyInput.fromJson(
            json['originalInput'] as Map<String, dynamic>,
          )
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'studyType': studyType.name,
    'format': format.name,
    'status': status.name,
    'subject': subject,
    'studyTitle': studyTitle,
    if (seriesOverview != null) 'seriesOverview': seriesOverview,
    'totalSessions': totalSessions,
    'sessions': sessions.map((s) => s.toJson()).toList(),
    'completedSessions': completedSessions,
    'createdAt': createdAt.toIso8601String(),
    if (lastAccessedAt != null)
      'lastAccessedAt': lastAccessedAt!.toIso8601String(),
    if (startDate != null) 'startDate': startDate!.toIso8601String(),
    if (personalContext != null) 'personalContext': personalContext,
    if (originalInput != null) 'originalInput': originalInput!.toJson(),
  };
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// FORM INPUT MODELS (for constructing prompts)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class BibleStudyInput {
  final StudyType studyType;
  final StudyFormat format;
  final int sessionCount;
  // Character
  final String? characterName;
  final List<String>? focusChips;
  // Book
  final String? bookName;
  final String? translation;
  // Verse
  final List<String>? verseRefs; // e.g. ["Romans 8:1", "John 3:16"]
  final String? verseQuestion;
  // Theme
  final String? themeName;
  // Topical
  final String? lifeQuestion;
  final String? userContext;
  // Devotional
  final String? devotionalTheme;
  final DateTime? startDate;
  final String? personalContext;

  const BibleStudyInput({
    required this.studyType,
    this.format = StudyFormat.series,
    this.sessionCount = 4,
    this.characterName,
    this.focusChips,
    this.bookName,
    this.translation,
    this.verseRefs,
    this.verseQuestion,
    this.themeName,
    this.lifeQuestion,
    this.userContext,
    this.devotionalTheme,
    this.startDate,
    this.personalContext,
  });

  factory BibleStudyInput.fromJson(Map<String, dynamic> json) =>
      BibleStudyInput(
        studyType: StudyType.values.firstWhere(
          (t) => t.name == json['studyType'],
          orElse: () => StudyType.character,
        ),
        format: StudyFormat.values.firstWhere(
          (f) => f.name == json['format'],
          orElse: () => StudyFormat.series,
        ),
        sessionCount: json['sessionCount'] ?? 4,
        characterName: json['characterName'],
        focusChips: (json['focusChips'] as List<dynamic>?)?.cast<String>(),
        bookName: json['bookName'],
        translation: json['translation'],
        verseRefs: (json['verseRefs'] as List<dynamic>?)?.cast<String>(),
        verseQuestion: json['verseQuestion'],
        themeName: json['themeName'],
        lifeQuestion: json['lifeQuestion'],
        userContext: json['userContext'],
        devotionalTheme: json['devotionalTheme'],
        startDate: json['startDate'] != null
            ? DateTime.tryParse(json['startDate'])
            : null,
        personalContext: json['personalContext'],
      );

  Map<String, dynamic> toJson() => {
    'studyType': studyType.name,
    'format': format.name,
    'sessionCount': sessionCount,
    if (characterName != null) 'characterName': characterName,
    if (focusChips != null) 'focusChips': focusChips,
    if (bookName != null) 'bookName': bookName,
    if (translation != null) 'translation': translation,
    if (verseRefs != null) 'verseRefs': verseRefs,
    if (verseQuestion != null) 'verseQuestion': verseQuestion,
    if (themeName != null) 'themeName': themeName,
    if (lifeQuestion != null) 'lifeQuestion': lifeQuestion,
    if (userContext != null) 'userContext': userContext,
    if (devotionalTheme != null) 'devotionalTheme': devotionalTheme,
    if (startDate != null) 'startDate': startDate!.toIso8601String(),
    if (personalContext != null) 'personalContext': personalContext,
  };

  String get subject {
    switch (studyType) {
      case StudyType.character:
        return characterName ?? '';
      case StudyType.book:
        return bookName ?? '';
      case StudyType.verse:
        return verseRefs?.join(', ') ?? '';
      case StudyType.theme:
        return themeName ?? '';
      case StudyType.topical:
        return lifeQuestion ?? '';
      case StudyType.devotional:
        return devotionalTheme ?? '';
    }
  }
}
