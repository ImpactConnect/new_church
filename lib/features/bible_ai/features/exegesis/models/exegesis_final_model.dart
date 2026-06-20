// ignore_for_file: invalid_annotation_target
import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'exegesis_final_model.freezed.dart';
part 'exegesis_final_model.g.dart';

// ═══════════════════════════════════════════════════════════════════
//  ENUMS
// ═══════════════════════════════════════════════════════════════════

/// Two entry types as defined in the Final Edition guide.
@HiveType(typeId: 115)
enum ExegesisEntryType {
  @HiveField(0)
  verse,

  @HiveField(1)
  topic,
}

/// Where the exegesis request originated
@HiveType(typeId: 116)
enum ExegesisSource {
  @HiveField(0)
  newForm,

  @HiveField(1)
  bibleReader,
}

// ═══════════════════════════════════════════════════════════════════
//  VERSE REF INPUT MODEL
// ═══════════════════════════════════════════════════════════════════

/// A verse reference input unit (book, chapter, verse, optional end verse)
class VerseRef {
  final String book;
  final int chapter;
  final int verse;
  final int? endVerse;

  const VerseRef({
    required this.book,
    required this.chapter,
    required this.verse,
    this.endVerse,
  });

  /// Returns human-readable reference string e.g. "John 3:16" or "Romans 8:1–17"
  String get referenceString {
    if (endVerse != null && endVerse != verse) {
      return '$book $chapter:$verse–$endVerse';
    }
    return '$book $chapter:$verse';
  }

  Map<String, dynamic> toJson() => {
        'book': book,
        'chapter': chapter,
        'verse': verse,
        if (endVerse != null) 'endVerse': endVerse,
      };

  factory VerseRef.fromJson(Map<String, dynamic> json) => VerseRef(
        book: json['book'] as String,
        chapter: json['chapter'] as int,
        verse: json['verse'] as int,
        endVerse: json['endVerse'] as int?,
      );
}

// ═══════════════════════════════════════════════════════════════════
//  SHARED COMPONENT MODELS
// ═══════════════════════════════════════════════════════════════════

/// A single scripture occurrence for a word study
@freezed
class WordOccurrence with _$WordOccurrence {
  const factory WordOccurrence({
    required String reference,
    required String context,
  }) = _WordOccurrence;

  factory WordOccurrence.fromJson(Map<String, dynamic> json) =>
      _$WordOccurrenceFromJson(json);
}

/// Layer 4 — Original Language Word Study item
@freezed
class WordStudyItem with _$WordStudyItem {
  const factory WordStudyItem({
    required String englishWord,
    String? verseRef,
    required String originalWord,
    required String transliteration,
    required String strongsNumber,
    required String lexicalDefinition,
    required String meaningInThisContext,
    required String discoveryNote,
    @Default([]) List<WordOccurrence> otherOccurrences,
  }) = _WordStudyItem;

  factory WordStudyItem.fromJson(Map<String, dynamic> json) =>
      _$WordStudyItemFromJson(json);
}

/// Layer 5 — Morphological Analysis item
@freezed
class MorphItem with _$MorphItem {
  const factory MorphItem({
    required String word,
    required String originalWord,
    required String strongsNumber,
    required String partOfSpeech,
    String? tense,
    String? voice,
    String? mood,
    String? personNumber,
    required String plainEnglishExplanation,
  }) = _MorphItem;

  factory MorphItem.fromJson(Map<String, dynamic> json) =>
      _$MorphItemFromJson(json);
}

/// Word confused with another — used in Semantic Disambiguation
@freezed
class ConfusedWord with _$ConfusedWord {
  const factory ConfusedWord({
    required String word,
    required String strongsNumber,
    required String meaningDifference,
    required String exampleVerse,
  }) = _ConfusedWord;

  factory ConfusedWord.fromJson(Map<String, dynamic> json) =>
      _$ConfusedWordFromJson(json);
}

/// Layer 6 — Semantic Disambiguation item
@freezed
class SemanticItem with _$SemanticItem {
  const factory SemanticItem({
    required String englishWord,
    required String disambiguation,
    required String wordUsedHere,
    required String wordUsedHereStrongs,
    @Default([]) List<ConfusedWord> confusedWith,
  }) = _SemanticItem;

  factory SemanticItem.fromJson(Map<String, dynamic> json) =>
      _$SemanticItemFromJson(json);
}

/// A development mention in the Mention Analysis
@freezed
class DevelopmentMention with _$DevelopmentMention {
  const factory DevelopmentMention({
    required String reference,
    required String development,
  }) = _DevelopmentMention;

  factory DevelopmentMention.fromJson(Map<String, dynamic> json) =>
      _$DevelopmentMentionFromJson(json);
}

/// First mention detail for a concept in Mention Analysis
@freezed
class FirstMentionDetail with _$FirstMentionDetail {
  const factory FirstMentionDetail({
    required String reference,
    String? verseText,
    required String whatItEstablishes,
  }) = _FirstMentionDetail;

  factory FirstMentionDetail.fromJson(Map<String, dynamic> json) =>
      _$FirstMentionDetailFromJson(json);
}

/// Layer 7 — First & Significant Mentions item
@freezed
class MentionItem with _$MentionItem {
  const factory MentionItem({
    required String concept,
    required FirstMentionDetail firstMention,
    @Default([]) List<DevelopmentMention> developmentMentions,
    String? emphasisPattern,
  }) = _MentionItem;

  factory MentionItem.fromJson(Map<String, dynamic> json) =>
      _$MentionItemFromJson(json);
}

/// A logical connector in Discourse Analysis
@freezed
class LogicalConnector with _$LogicalConnector {
  const factory LogicalConnector({
    required String word,
    required String originalWord,
    required String significance,
  }) = _LogicalConnector;

  factory LogicalConnector.fromJson(Map<String, dynamic> json) =>
      _$LogicalConnectorFromJson(json);
}

/// Layer 8 — Discourse Analysis
@freezed
class DiscourseAnalysis with _$DiscourseAnalysis {
  const factory DiscourseAnalysis({
    required String rhetoricalFunction,
    @Default([]) List<LogicalConnector> logicalConnectors,
    required String authorIntent,
  }) = _DiscourseAnalysis;

  factory DiscourseAnalysis.fromJson(Map<String, dynamic> json) =>
      _$DiscourseAnalysisFromJson(json);
}

/// Layer 9 — Cross-Reference item
@freezed
class CrossRef with _$CrossRef {
  const factory CrossRef({
    required String reference,
    String? verseText,
    required String connectionType,
    required String specificContribution,
  }) = _CrossRef;

  factory CrossRef.fromJson(Map<String, dynamic> json) =>
      _$CrossRefFromJson(json);
}

/// Layer 10 — Intertextual Allusion item
@freezed
class Allusion with _$Allusion {
  const factory Allusion({
    required String sourceText,
    String? sourceVerseText,
    required String allusionText,
    required String howToHearIt,
  }) = _Allusion;

  factory Allusion.fromJson(Map<String, dynamic> json) =>
      _$AllusionFromJson(json);
}

/// Layer 11 — Textual Apparatus Note
@freezed
class TextualNote with _$TextualNote {
  const factory TextualNote({
    @Default(false) bool include,
    String? notes,
  }) = _TextualNote;

  factory TextualNote.fromJson(Map<String, dynamic> json) =>
      _$TextualNoteFromJson(json);
}

/// Layer 13 — What This Cannot Mean item
@freezed
class Misreading with _$Misreading {
  const factory Misreading({
    required String commonMisreading,
    required String whyItIsWrong,
    required String whatItActuallyMeans,
  }) = _Misreading;

  factory Misreading.fromJson(Map<String, dynamic> json) =>
      _$MisreadingFromJson(json);
}

// ═══════════════════════════════════════════════════════════════════
//  VERSE EXEGESIS SPECIFIC MODELS
// ═══════════════════════════════════════════════════════════════════

/// A specific cultural key in the Historical/Cultural Setting
@freezed
class CulturalKey with _$CulturalKey {
  const factory CulturalKey({
    required String item,
    required String howItShapesReading,
  }) = _CulturalKey;

  factory CulturalKey.fromJson(Map<String, dynamic> json) =>
      _$CulturalKeyFromJson(json);
}

/// Layer 2 — Historical & Cultural Setting
@freezed
class HistoricalCulturalSetting with _$HistoricalCulturalSetting {
  const factory HistoricalCulturalSetting({
    required String world,
    @Default([]) List<CulturalKey> specificCulturalKeys,
  }) = _HistoricalCulturalSetting;

  factory HistoricalCulturalSetting.fromJson(Map<String, dynamic> json) =>
      _$HistoricalCulturalSettingFromJson(json);
}

/// Layer 3 — Literary & Structural Context
@freezed
class LiteraryContext with _$LiteraryContext {
  const factory LiteraryContext({
    required String genre,
    required String immediateBefore,
    required String immediateAfter,
    required String structuralRole,
    required String passageFlow,
  }) = _LiteraryContext;

  factory LiteraryContext.fromJson(Map<String, dynamic> json) =>
      _$LiteraryContextFromJson(json);
}

// ═══════════════════════════════════════════════════════════════════
//  TOPIC EXEGESIS SPECIFIC MODELS
// ═══════════════════════════════════════════════════════════════════

/// Hebrew or Greek word definition in a topic
@freezed
class LanguageWord with _$LanguageWord {
  const factory LanguageWord({
    required String word,
    required String originalScript,
    required String transliteration,
    required String strongsNumber,
    required String fullSemanticRange,
  }) = _LanguageWord;

  factory LanguageWord.fromJson(Map<String, dynamic> json) =>
      _$LanguageWordFromJson(json);
}

/// Concept definition block for topic exegesis
@freezed
class ConceptDefinition with _$ConceptDefinition {
  const factory ConceptDefinition({
    required LanguageWord hebrewWord,
    required LanguageWord greekWord,
    required String semanticDisambiguation,
    required String modernVsAncient,
  }) = _ConceptDefinition;

  factory ConceptDefinition.fromJson(Map<String, dynamic> json) =>
      _$ConceptDefinitionFromJson(json);
}

/// First mention block for topic exegesis
@freezed
class TopicFirstMention with _$TopicFirstMention {
  const factory TopicFirstMention({
    required String reference,
    String? verseText,
    required String whatItEstablishes,
  }) = _TopicFirstMention;

  factory TopicFirstMention.fromJson(Map<String, dynamic> json) =>
      _$TopicFirstMentionFromJson(json);
}

/// A single defining passage for a topic (3–5 per topic)
@freezed
class DefiningPassage with _$DefiningPassage {
  const factory DefiningPassage({
    required String reference,
    String? verseText,
    required String whyDefinitive,
    required String historicalCulturalContext,
    @Default([]) List<WordStudyItem> wordStudy,
    String? morphologicalNote,
    required String whatThisPassageSays,
    String? connectionsToOtherDefiningPassages,
  }) = _DefiningPassage;

  factory DefiningPassage.fromJson(Map<String, dynamic> json) =>
      _$DefiningPassageFromJson(json);
}

/// A common distortion entry for topic exegesis
@freezed
class Distortion with _$Distortion {
  const factory Distortion({
    required String distortion,
    required String howItEnters,
    required String linguisticCorrection,
  }) = _Distortion;

  factory Distortion.fromJson(Map<String, dynamic> json) =>
      _$DistortionFromJson(json);
}

// ═══════════════════════════════════════════════════════════════════
//  VERSE EXEGESIS — Full Result Model (14 Analysis Layers)
// ═══════════════════════════════════════════════════════════════════

@freezed
class VerseExegesis with _$VerseExegesis {
  const VerseExegesis._();

  const factory VerseExegesis({
    required String id,
    required ExegesisSource source,
    required String subject,       // formatted ref string e.g. "John 3:16"
    required String translation,   // ESV / NIV / KJV / NASB / NLT
    @Default([]) List<Map<String, dynamic>> verseRefsJson, // serialized VerseRef list
    // ── Layer 1: The Orienting Insight ──
    required String bigPicture,
    // ── Layer 2: Historical & Cultural Setting ──
    required HistoricalCulturalSetting historicalCulturalSetting,
    // ── Layer 3: Literary & Structural Context ──
    required LiteraryContext literaryContext,
    // ── Layer 4: Original Language Word Study ──
    @Default([]) List<WordStudyItem> wordStudy,
    // ── Layer 5: Morphological Analysis ──
    @Default([]) List<MorphItem> morphologicalAnalysis,
    // ── Layer 6: Semantic Disambiguation (conditional) ──
    @Default([]) List<SemanticItem> semanticDisambiguation,
    // ── Layer 7: First & Significant Mentions ──
    @Default([]) List<MentionItem> mentionAnalysis,
    // ── Layer 8: Discourse Analysis ──
    required DiscourseAnalysis discourseAnalysis,
    // ── Layer 9: Cross-References ──
    @Default([]) List<CrossRef> crossReferences,
    // ── Layer 10: Intertextual Allusions (conditional) ──
    List<Allusion>? intertextualAllusions,
    // ── Layer 11: Textual Apparatus Notes (conditional) ──
    TextualNote? textualApparatusNotes,
    // ── Layer 12: The Implied Theological Claim ──
    required String impliedTheologicalClaim,
    // ── Layer 13: What This Text Cannot Mean ──
    @Default([]) List<Misreading> whatItCannotMean,
    // ── Layer 14: From Text to Life ──
    required String fromTextToLife,
    // ── Final: Something To Sit With ──
    required String somethingToSitWith,
    // ── Metadata ──
    String? contextSummary,
    required DateTime createdAt,
  }) = _VerseExegesis;

  factory VerseExegesis.fromJson(Map<String, dynamic> json) =>
      _$VerseExegesisFromJson(json);

  /// Reconstruct VerseRef list from stored JSON maps
  List<VerseRef> get verseRefs =>
      verseRefsJson.map((m) => VerseRef.fromJson(m)).toList();
}

// ═══════════════════════════════════════════════════════════════════
//  TOPIC EXEGESIS — Full Result Model
// ═══════════════════════════════════════════════════════════════════

@freezed
class TopicExegesis with _$TopicExegesis {
  const TopicExegesis._();

  const factory TopicExegesis({
    required String id,
    required ExegesisSource source,
    required String subject, // the topic name e.g. "Grace"
    // ── Layer 1: The Orienting Insight ──
    required String bigPicture,
    // ── Concept Definition (Hebrew + Greek) ──
    required ConceptDefinition conceptDefinition,
    // ── First Mention ──
    required TopicFirstMention firstMention,
    // ── 3–5 Defining Passage Studies ──
    @Default([]) List<DefiningPassage> definingPassages,
    // ── Canonical Progression ──
    required String canonicalProgression,
    // ── Common Distortions ──
    @Default([]) List<Distortion> commonDistortions,
    // ── Layer 12: Implied Theological Claim ──
    required String impliedTheologicalClaim,
    // ── Layer 13: What This Cannot Mean ──
    @Default([]) List<Misreading> whatItCannotMean,
    // ── Layer 14: From Text to Life ──
    required String fromTextToLife,
    // ── Final: Something To Sit With ──
    required String somethingToSitWith,
    // ── Metadata ──
    String? contextSummary,
    required DateTime createdAt,
  }) = _TopicExegesis;

  factory TopicExegesis.fromJson(Map<String, dynamic> json) =>
      _$TopicExegesisFromJson(json);
}

// ═══════════════════════════════════════════════════════════════════
//  LIBRARY ITEM — Persisted to Hive + Firestore
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 117)
class ExegesisLibraryItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int typeIndex; // ExegesisEntryType.index

  @HiveField(2)
  final int sourceIndex; // ExegesisSource.index

  @HiveField(3)
  final String subject;

  @HiveField(4)
  final String bigPicture;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final String resultJson; // full result as JSON string

  ExegesisLibraryItem({
    required this.id,
    required this.typeIndex,
    required this.sourceIndex,
    required this.subject,
    required this.bigPicture,
    required this.createdAt,
    required this.resultJson,
  });

  ExegesisEntryType get type => ExegesisEntryType.values[typeIndex];
  ExegesisSource get source => ExegesisSource.values[sourceIndex];

  /// Reconstructs the full result from stored JSON
  dynamic get result {
    try {
      final rawJson = jsonDecode(resultJson) as Map<String, dynamic>;
      return type == ExegesisEntryType.verse
          ? VerseExegesis.fromJson(rawJson)
          : TopicExegesis.fromJson(rawJson);
    } catch (_) {
      return null;
    }
  }

  factory ExegesisLibraryItem.fromVerse(VerseExegesis e) => ExegesisLibraryItem(
        id: e.id,
        typeIndex: ExegesisEntryType.verse.index,
        sourceIndex: e.source.index,
        subject: e.subject,
        bigPicture: e.bigPicture,
        createdAt: e.createdAt,
        resultJson: jsonEncode(e.toJson()),
      );

  factory ExegesisLibraryItem.fromTopic(TopicExegesis e) => ExegesisLibraryItem(
        id: e.id,
        typeIndex: ExegesisEntryType.topic.index,
        sourceIndex: e.source.index,
        subject: e.subject,
        bigPicture: e.bigPicture,
        createdAt: e.createdAt,
        resultJson: jsonEncode(e.toJson()),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'typeIndex': typeIndex,
        'sourceIndex': sourceIndex,
        'subject': subject,
        'bigPicture': bigPicture,
        'createdAt': createdAt.toIso8601String(),
        'resultJson': resultJson,
      };

  factory ExegesisLibraryItem.fromMap(Map<String, dynamic> map) =>
      ExegesisLibraryItem(
        id: map['id'] as String,
        typeIndex: map['typeIndex'] as int? ??
            ExegesisEntryType.values
                .firstWhere(
                  (e) => e.name == map['type'],
                  orElse: () => ExegesisEntryType.verse,
                )
                .index,
        sourceIndex: map['sourceIndex'] as int? ??
            ExegesisSource.values
                .firstWhere(
                  (e) => e.name == map['source'],
                  orElse: () => ExegesisSource.newForm,
                )
                .index,
        subject: map['subject'] as String,
        bigPicture: map['bigPicture'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        resultJson: map['resultJson'] as String,
      );
}
