import 'package:json_annotation/json_annotation.dart';

part 'ai_models.g.dart';

enum AiMode { simple, study, deep }

enum VerseFeature { explain, context, keyWord, crossRefs, application }

// 1. Explain Analysis
@JsonSerializable()
class ExplainAnalysis {
  @JsonKey(defaultValue: '')
  final String verseReference;
  @JsonKey(defaultValue: '')
  final String connectedThoughtRange;
  @JsonKey(defaultValue: '')
  final String speaker;
  @JsonKey(defaultValue: '')
  final String audience;
  @JsonKey(defaultValue: '')
  final String historicalContext;
  @JsonKey(defaultValue: '')
  final String literaryContext;
  @JsonKey(defaultValue: '')
  final String explanation;
  @JsonKey(defaultValue: [])
  final List<AmbiguousTerm> ambiguousTerms;
  @JsonKey(defaultValue: '')
  final String supportingVerse;
  @JsonKey(defaultValue: [])
  final List<CovenantInfo> covenant;

  ExplainAnalysis({
    required this.verseReference,
    required this.connectedThoughtRange,
    required this.speaker,
    required this.audience,
    required this.historicalContext,
    required this.literaryContext,
    required this.explanation,
    required this.ambiguousTerms,
    required this.supportingVerse,
    required this.covenant,
  });

  factory ExplainAnalysis.fromJson(Map<String, dynamic> json) =>
      _$ExplainAnalysisFromJson(json);
  Map<String, dynamic> toJson() => _$ExplainAnalysisToJson(this);
}

@JsonSerializable()
class AmbiguousTerm {
  @JsonKey(defaultValue: '')
  final String term;
  @JsonKey(defaultValue: '')
  final String originalWord;
  @JsonKey(defaultValue: '')
  final String transliteration;
  @JsonKey(defaultValue: '')
  final String definition;
  @JsonKey(defaultValue: '')
  final String whyItMatters;

  AmbiguousTerm({
    required this.term,
    required this.originalWord,
    required this.transliteration,
    required this.definition,
    required this.whyItMatters,
  });

  factory AmbiguousTerm.fromJson(Map<String, dynamic> json) =>
      _$AmbiguousTermFromJson(json);
  Map<String, dynamic> toJson() => _$AmbiguousTermToJson(this);
}

@JsonSerializable()
class CovenantInfo {
  @JsonKey(defaultValue: '')
  final String covenant;
  @JsonKey(defaultValue: '')
  final String applicability; // Direct | Principle-Based | Historical | Fulfilled
  @JsonKey(defaultValue: '')
  final String explanation;

  CovenantInfo({
    required this.covenant,
    required this.applicability,
    required this.explanation,
  });

  factory CovenantInfo.fromJson(Map<String, dynamic> json) =>
      _$CovenantInfoFromJson(json);
  Map<String, dynamic> toJson() => _$CovenantInfoToJson(this);
}

// 2. Context Analysis
@JsonSerializable()
class ContextAnalysis {
  @JsonKey(defaultValue: '')
  final String immediateContextBefore;
  @JsonKey(defaultValue: '')
  final String immediateContextAfter;
  @JsonKey(defaultValue: '')
  final String chapterTheme;
  @JsonKey(defaultValue: '')
  final String speaker;
  @JsonKey(defaultValue: '')
  final String audience;
  @JsonKey(defaultValue: '')
  final String literaryType;
  @JsonKey(defaultValue: '')
  final String culturalBackgroundInsight;
  @JsonKey(defaultValue: '')
  final String culturalInterpretiveImpact;
  @JsonKey(defaultValue: '')
  final String commonMisunderstandings;
  @JsonKey(defaultValue: '')
  final String supportingVerse;

  ContextAnalysis({
    required this.immediateContextBefore,
    required this.immediateContextAfter,
    required this.chapterTheme,
    required this.speaker,
    required this.audience,
    required this.literaryType,
    required this.culturalBackgroundInsight,
    required this.culturalInterpretiveImpact,
    required this.commonMisunderstandings,
    required this.supportingVerse,
  });

  factory ContextAnalysis.fromJson(Map<String, dynamic> json) =>
      _$ContextAnalysisFromJson(json);
  Map<String, dynamic> toJson() => _$ContextAnalysisToJson(this);
}

// 3. Key Word Analysis
@JsonSerializable()
class KeyWordAnalysis {
  @JsonKey(defaultValue: [])
  final List<WordDetail> keywords;

  KeyWordAnalysis({required this.keywords});

  factory KeyWordAnalysis.fromJson(Map<String, dynamic> json) =>
      _$KeyWordAnalysisFromJson(json);
  Map<String, dynamic> toJson() => _$KeyWordAnalysisToJson(this);
}

@JsonSerializable()
class WordDetail {
  @JsonKey(defaultValue: '')
  final String word;
  @JsonKey(defaultValue: '')
  final String original;
  @JsonKey(defaultValue: '')
  final String transliteration;
  @JsonKey(defaultValue: '')
  final String definition;
  @JsonKey(defaultValue: '')
  final String usageInVerse;
  @JsonKey(defaultValue: '')
  final String usageElsewhere;
  @JsonKey(defaultValue: '')
  final String theologicalSignificance;
  @JsonKey(defaultValue: '')
  final String crossReference;

  WordDetail({
    required this.word,
    required this.original,
    required this.transliteration,
    required this.definition,
    required this.usageInVerse,
    required this.usageElsewhere,
    required this.theologicalSignificance,
    required this.crossReference,
  });

  factory WordDetail.fromJson(Map<String, dynamic> json) =>
      _$WordDetailFromJson(json);
  Map<String, dynamic> toJson() => _$WordDetailToJson(this);
}

// 4. Cross References Analysis
@JsonSerializable()
class CrossReferencesAnalysis {
  @JsonKey(defaultValue: '')
  final String theme;
  @JsonKey(defaultValue: [])
  final List<ReferenceItem> references;

  CrossReferencesAnalysis({required this.theme, required this.references});

  factory CrossReferencesAnalysis.fromJson(Map<String, dynamic> json) =>
      _$CrossReferencesAnalysisFromJson(json);
  Map<String, dynamic> toJson() => _$CrossReferencesAnalysisToJson(this);
}

@JsonSerializable()
class ReferenceItem {
  @JsonKey(defaultValue: '')
  final String reference;
  @JsonKey(defaultValue: '')
  final String connection;

  ReferenceItem({required this.reference, required this.connection});

  factory ReferenceItem.fromJson(Map<String, dynamic> json) =>
      _$ReferenceItemFromJson(json);
  Map<String, dynamic> toJson() => _$ReferenceItemToJson(this);
}

// 5. Application Analysis
@JsonSerializable()
class ApplicationAnalysis {
  @JsonKey(defaultValue: '')
  final String centralTruth;
  @JsonKey(defaultValue: '')
  final String commonMisuse;
  @JsonKey(defaultValue: '')
  final String applications;
  final ApplicationContexts applicationsAreas;
  @JsonKey(defaultValue: '')
  final String clarification;
  @JsonKey(defaultValue: '')
  final String supportingVerse;

  ApplicationAnalysis({
    required this.centralTruth,
    required this.commonMisuse,
    required this.applications,
    required this.applicationsAreas,
    required this.clarification,
    required this.supportingVerse,
  });

  factory ApplicationAnalysis.fromJson(Map<String, dynamic> json) =>
      _$ApplicationAnalysisFromJson(json);
  Map<String, dynamic> toJson() => _$ApplicationAnalysisToJson(this);
}

@JsonSerializable()
class ApplicationContexts {
  @JsonKey(defaultValue: '')
  final String personal;
  @JsonKey(defaultValue: '')
  final String family;
  @JsonKey(defaultValue: '')
  final String church;
  @JsonKey(defaultValue: '')
  final String workplace;
  @JsonKey(defaultValue: '')
  final String society;

  ApplicationContexts({
    required this.personal,
    required this.family,
    required this.church,
    required this.workplace,
    required this.society,
  });

  factory ApplicationContexts.fromJson(Map<String, dynamic> json) =>
      _$ApplicationContextsFromJson(json);
  Map<String, dynamic> toJson() => _$ApplicationContextsToJson(this);
}

// 6. Question Analysis
@JsonSerializable()
class QuestionAnalysis {
  @JsonKey(defaultValue: '')
  final String answer;
  @JsonKey(defaultValue: '')
  final String scripturalSupport;
  @JsonKey(defaultValue: '')
  final String interpretationNote;
  @JsonKey(defaultValue: '')
  final String confidenceLevel;

  QuestionAnalysis({
    required this.answer,
    required this.scripturalSupport,
    required this.interpretationNote,
    required this.confidenceLevel,
  });

  factory QuestionAnalysis.fromJson(Map<String, dynamic> json) =>
      _$QuestionAnalysisFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionAnalysisToJson(this);
}

@JsonSerializable()
class PassageAnalysis {
  @JsonKey(defaultValue: '')
  final String summary; // Short paragraph
  @JsonKey(defaultValue: '')
  final String mainTheme;
  @JsonKey(defaultValue: '')
  final String flowOfThought;
  @JsonKey(defaultValue: [])
  final List<String> keyTakeaways;

  PassageAnalysis({
    required this.summary,
    required this.mainTheme,
    required this.flowOfThought,
    required this.keyTakeaways,
  });

  factory PassageAnalysis.fromJson(Map<String, dynamic> json) =>
      _$PassageAnalysisFromJson(json);
  Map<String, dynamic> toJson() => _$PassageAnalysisToJson(this);
}

@JsonSerializable()
class ChapterAnalysis {
  @JsonKey(defaultValue: '')
  final String overview;
  @JsonKey(defaultValue: '')
  final String mainMessage; // One sentence
  @JsonKey(defaultValue: [])
  final List<String> keyVerses;
  @JsonKey(defaultValue: [])
  final List<String> reflectionQuestions;

  ChapterAnalysis({
    required this.overview,
    required this.mainMessage,
    required this.keyVerses,
    required this.reflectionQuestions,
  });

  factory ChapterAnalysis.fromJson(Map<String, dynamic> json) =>
      _$ChapterAnalysisFromJson(json);
  Map<String, dynamic> toJson() => _$ChapterAnalysisToJson(this);
}

@JsonSerializable()
class BookIntroduction {
  final String author;
  final String audience;
  final String purpose;
  final List<String> majorThemes;
  final String howToRead; // Genre/Style

  BookIntroduction({
    required this.author,
    required this.audience,
    required this.purpose,
    required this.majorThemes,
    required this.howToRead,
  });

  factory BookIntroduction.fromJson(Map<String, dynamic> json) =>
      _$BookIntroductionFromJson(json);
  Map<String, dynamic> toJson() => _$BookIntroductionToJson(this);
}

class ChatMessage {
  final String message;
  final bool isUser;
  final bool isHidden;

  ChatMessage({
    required this.message,
    required this.isUser,
    this.isHidden = false,
  });
}

// 7. Semantic Search
@JsonSerializable()
class SemanticSearchResponse {
  @JsonKey(defaultValue: [])
  final List<SemanticSearchResult> results;

  SemanticSearchResponse({required this.results});

  factory SemanticSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$SemanticSearchResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SemanticSearchResponseToJson(this);
}

@JsonSerializable()
class SemanticSearchResult {
  @JsonKey(defaultValue: '')
  final String bookName;
  @JsonKey(defaultValue: 1)
  final int chapterNumber;
  @JsonKey(defaultValue: 1)
  final int verseNumber;
  @JsonKey(defaultValue: '')
  final String reason;

  SemanticSearchResult({
    required this.bookName,
    required this.chapterNumber,
    required this.verseNumber,
    required this.reason,
  });

  factory SemanticSearchResult.fromJson(Map<String, dynamic> json) =>
      _$SemanticSearchResultFromJson(json);
  Map<String, dynamic> toJson() => _$SemanticSearchResultToJson(this);
}

// 8. Exegesis Engine Models
@JsonSerializable()
class CharacterExegesis {
  @JsonKey(defaultValue: '')
  final String character;
  @JsonKey(defaultValue: '')
  final String historicalContext;
  @JsonKey(defaultValue: '')
  final String narrativeRole;
  @JsonKey(defaultValue: '')
  final String covenantalContext;
  @JsonKey(defaultValue: [])
  final List<String> keyEvents;
  @JsonKey(defaultValue: '')
  final String theologicalContribution;
  @JsonKey(defaultValue: [])
  final List<String> strengths;
  @JsonKey(defaultValue: [])
  final List<String> failuresOrFlaws;
  @JsonKey(defaultValue: '')
  final String progressionArc;
  @JsonKey(defaultValue: '')
  final String canonicalSignificance;
  @JsonKey(defaultValue: '')
  final String messianicOrTypologicalLinks;
  @JsonKey(defaultValue: '')
  final String scholarlyNotes;

  CharacterExegesis({
    required this.character,
    required this.historicalContext,
    required this.narrativeRole,
    required this.covenantalContext,
    required this.keyEvents,
    required this.theologicalContribution,
    required this.strengths,
    required this.failuresOrFlaws,
    required this.progressionArc,
    required this.canonicalSignificance,
    required this.messianicOrTypologicalLinks,
    required this.scholarlyNotes,
  });

  factory CharacterExegesis.fromJson(Map<String, dynamic> json) =>
      _$CharacterExegesisFromJson(json);
  Map<String, dynamic> toJson() => _$CharacterExegesisToJson(this);
}

@JsonSerializable()
class BookExegesis {
  @JsonKey(defaultValue: '')
  final String book;
  @JsonKey(defaultValue: '')
  final String authorship;
  @JsonKey(defaultValue: '')
  final String dateAndSetting;
  @JsonKey(defaultValue: '')
  final String originalAudience;
  @JsonKey(defaultValue: '')
  final String historicalBackground;
  @JsonKey(defaultValue: '')
  final String literaryStructure;
  @JsonKey(defaultValue: [])
  final List<String> majorThemes;
  @JsonKey(defaultValue: '')
  final String theologicalEmphases;
  @JsonKey(defaultValue: '')
  final String covenantalContext;
  @JsonKey(defaultValue: '')
  final String christologicalOrRedemptiveTrajectory;
  @JsonKey(defaultValue: [])
  final List<String> keyPassages;
  @JsonKey(defaultValue: '')
  final String interpretiveChallenges;
  @JsonKey(defaultValue: '')
  final String canonicalRole;

  BookExegesis({
    required this.book,
    required this.authorship,
    required this.dateAndSetting,
    required this.originalAudience,
    required this.historicalBackground,
    required this.literaryStructure,
    required this.majorThemes,
    required this.theologicalEmphases,
    required this.covenantalContext,
    required this.christologicalOrRedemptiveTrajectory,
    required this.keyPassages,
    required this.interpretiveChallenges,
    required this.canonicalRole,
  });

  factory BookExegesis.fromJson(Map<String, dynamic> json) =>
      _$BookExegesisFromJson(json);
  Map<String, dynamic> toJson() => _$BookExegesisToJson(this);
}

@JsonSerializable()
class ChapterExegesis {
  @JsonKey(defaultValue: '')
  final String book;
  @JsonKey(defaultValue: '')
  final String chapter;
  @JsonKey(defaultValue: '')
  final String historicalContext;
  @JsonKey(defaultValue: '')
  final String literaryFlowSummary;
  @JsonKey(defaultValue: [])
  final List<String> sectionBreakdown;
  @JsonKey(defaultValue: [])
  final List<String> majorThemes;
  @JsonKey(defaultValue: [])
  final List<String> keyTerms;
  @JsonKey(defaultValue: '')
  final String interpretiveIssues;
  @JsonKey(defaultValue: '')
  final String canonicalConnection;
  @JsonKey(defaultValue: [])
  final List<String> applicationPrinciples;

  ChapterExegesis({
    required this.book,
    required this.chapter,
    required this.historicalContext,
    required this.literaryFlowSummary,
    required this.sectionBreakdown,
    required this.majorThemes,
    required this.keyTerms,
    required this.interpretiveIssues,
    required this.canonicalConnection,
    required this.applicationPrinciples,
  });

  factory ChapterExegesis.fromJson(Map<String, dynamic> json) =>
      _$ChapterExegesisFromJson(json);
  Map<String, dynamic> toJson() => _$ChapterExegesisToJson(this);
}

@JsonSerializable()
class PassageExegesis {
  @JsonKey(defaultValue: '')
  final String reference;
  @JsonKey(defaultValue: '')
  final String literaryContext;
  @JsonKey(defaultValue: '')
  final String historicalContext;
  @JsonKey(defaultValue: '')
  final String genreAnalysis;
  @JsonKey(defaultValue: '')
  final String structureAnalysis;
  @JsonKey(defaultValue: [])
  final List<String> keyTerms;
  @JsonKey(defaultValue: '')
  final String verseByVerseSummary;
  @JsonKey(defaultValue: [])
  final List<String> theologicalThemes;
  @JsonKey(defaultValue: '')
  final String covenantalSignificance;
  @JsonKey(defaultValue: '')
  final String christologicalFulfillment;
  @JsonKey(defaultValue: '')
  final String interpretiveDebates;
  @JsonKey(defaultValue: '')
  final String canonicalConnections;
  @JsonKey(defaultValue: '')
  final String doctrinalImplications;

  PassageExegesis({
    required this.reference,
    required this.literaryContext,
    required this.historicalContext,
    required this.genreAnalysis,
    required this.structureAnalysis,
    required this.keyTerms,
    required this.verseByVerseSummary,
    required this.theologicalThemes,
    required this.covenantalSignificance,
    required this.christologicalFulfillment,
    required this.interpretiveDebates,
    required this.canonicalConnections,
    required this.doctrinalImplications,
  });

  factory PassageExegesis.fromJson(Map<String, dynamic> json) =>
      _$PassageExegesisFromJson(json);
  Map<String, dynamic> toJson() => _$PassageExegesisToJson(this);
}

// ═══════════════════════════════════════════════════════════════════
//  ILLUMINE v2 — Verse Level AI Models
// ═══════════════════════════════════════════════════════════════════

// ── Shared sub-models ──

@JsonSerializable()
class KeyTermV2 {
  @JsonKey(defaultValue: '')
  final String term;
  @JsonKey(defaultValue: '')
  final String originalWord;
  @JsonKey(defaultValue: '')
  final String transliteration;
  @JsonKey(defaultValue: '')
  final String strongsNumber;
  @JsonKey(defaultValue: '')
  final String definition;
  @JsonKey(defaultValue: '')
  final String whyItMatters;

  KeyTermV2({
    required this.term,
    required this.originalWord,
    required this.transliteration,
    required this.strongsNumber,
    required this.definition,
    required this.whyItMatters,
  });

  factory KeyTermV2.fromJson(Map<String, dynamic> json) =>
      _$KeyTermV2FromJson(json);
  Map<String, dynamic> toJson() => _$KeyTermV2ToJson(this);
}

@JsonSerializable()
class SupportingScriptureV2 {
  @JsonKey(defaultValue: '')
  final String reference;
  final String? text;
  @JsonKey(defaultValue: '')
  final String connection;

  SupportingScriptureV2({
    required this.reference,
    this.text,
    required this.connection,
  });

  factory SupportingScriptureV2.fromJson(Map<String, dynamic> json) =>
      _$SupportingScriptureV2FromJson(json);
  Map<String, dynamic> toJson() => _$SupportingScriptureV2ToJson(this);
}

@JsonSerializable()
class CovenantLinkV2 {
  @JsonKey(defaultValue: '')
  final String covenantName;
  @JsonKey(defaultValue: '')
  final String applicability;
  @JsonKey(defaultValue: '')
  final String explanation;

  CovenantLinkV2({
    required this.covenantName,
    required this.applicability,
    required this.explanation,
  });

  factory CovenantLinkV2.fromJson(Map<String, dynamic> json) =>
      _$CovenantLinkV2FromJson(json);
  Map<String, dynamic> toJson() => _$CovenantLinkV2ToJson(this);
}

@JsonSerializable()
class MisunderstandingV2 {
  @JsonKey(defaultValue: '')
  final String misunderstanding;
  @JsonKey(defaultValue: '')
  final String whyItHappens;
  @JsonKey(defaultValue: '')
  final String correction;
  final String? correctiveVerse;

  MisunderstandingV2({
    required this.misunderstanding,
    required this.whyItHappens,
    required this.correction,
    this.correctiveVerse,
  });

  factory MisunderstandingV2.fromJson(Map<String, dynamic> json) =>
      _$MisunderstandingV2FromJson(json);
  Map<String, dynamic> toJson() => _$MisunderstandingV2ToJson(this);
}

@JsonSerializable()
class NearbyVerseV2 {
  @JsonKey(defaultValue: '')
  final String reference;
  final String? text;
  @JsonKey(defaultValue: '')
  final String relevance;

  NearbyVerseV2({
    required this.reference,
    this.text,
    required this.relevance,
  });

  factory NearbyVerseV2.fromJson(Map<String, dynamic> json) =>
      _$NearbyVerseV2FromJson(json);
  Map<String, dynamic> toJson() => _$NearbyVerseV2ToJson(this);
}

@JsonSerializable()
class CrossRefItemV2 {
  @JsonKey(defaultValue: '')
  final String reference;
  final String? verseText;
  @JsonKey(defaultValue: '')
  final String connectionType; // Parallel|Fulfillment|Allusion|Contrast|Development|Foundation
  @JsonKey(defaultValue: '')
  final String connectionStrength; // Strong|Moderate
  @JsonKey(defaultValue: '')
  final String connection;
  @JsonKey(defaultValue: '')
  final String testament; // OT|NT

  CrossRefItemV2({
    required this.reference,
    this.verseText,
    required this.connectionType,
    required this.connectionStrength,
    required this.connection,
    required this.testament,
  });

  factory CrossRefItemV2.fromJson(Map<String, dynamic> json) =>
      _$CrossRefItemV2FromJson(json);
  Map<String, dynamic> toJson() => _$CrossRefItemV2ToJson(this);
}

@JsonSerializable()
class KeywordV2 {
  @JsonKey(defaultValue: '')
  final String word;
  @JsonKey(defaultValue: '')
  final String originalWord;
  @JsonKey(defaultValue: '')
  final String transliteration;
  @JsonKey(defaultValue: '')
  final String strongsNumber;
  @JsonKey(defaultValue: '')
  final String partOfSpeech;
  @JsonKey(defaultValue: '')
  final String definition;
  @JsonKey(defaultValue: '')
  final String usageInVerse;
  @JsonKey(defaultValue: '')
  final String usageElsewhere;
  @JsonKey(defaultValue: '')
  final String theologicalSignificance;
  final String? translationVariance;
  @JsonKey(defaultValue: '')
  final String crossReference;

  KeywordV2({
    required this.word,
    required this.originalWord,
    required this.transliteration,
    required this.strongsNumber,
    required this.partOfSpeech,
    required this.definition,
    required this.usageInVerse,
    required this.usageElsewhere,
    required this.theologicalSignificance,
    this.translationVariance,
    required this.crossReference,
  });

  factory KeywordV2.fromJson(Map<String, dynamic> json) =>
      _$KeywordV2FromJson(json);
  Map<String, dynamic> toJson() => _$KeywordV2ToJson(this);
}

@JsonSerializable()
class ApplicabilityScopeV2 {
  @JsonKey(defaultValue: '')
  final String scope; // Universal|Historical-Specific|Principle-Based
  @JsonKey(defaultValue: '')
  final String explanation;

  ApplicabilityScopeV2({
    required this.scope,
    required this.explanation,
  });

  factory ApplicabilityScopeV2.fromJson(Map<String, dynamic> json) =>
      _$ApplicabilityScopeV2FromJson(json);
  Map<String, dynamic> toJson() => _$ApplicabilityScopeV2ToJson(this);
}

@JsonSerializable()
class ApplicationAreasV2 {
  @JsonKey(defaultValue: '')
  final String personal;
  @JsonKey(defaultValue: '')
  final String family;
  @JsonKey(defaultValue: '')
  final String church;
  @JsonKey(defaultValue: '')
  final String workplace;
  @JsonKey(defaultValue: '')
  final String society;

  ApplicationAreasV2({
    required this.personal,
    required this.family,
    required this.church,
    required this.workplace,
    required this.society,
  });

  factory ApplicationAreasV2.fromJson(Map<String, dynamic> json) =>
      _$ApplicationAreasV2FromJson(json);
  Map<String, dynamic> toJson() => _$ApplicationAreasV2ToJson(this);
}

@JsonSerializable()
class MisapplicationV2 {
  @JsonKey(defaultValue: '')
  final String misapplication;
  @JsonKey(defaultValue: '')
  final String whoUsesIt;
  @JsonKey(defaultValue: '')
  final String whyItsWrong;
  @JsonKey(defaultValue: '')
  final String correctApplication;
  final String? correctiveVerse;

  MisapplicationV2({
    required this.misapplication,
    required this.whoUsesIt,
    required this.whyItsWrong,
    required this.correctApplication,
    this.correctiveVerse,
  });

  factory MisapplicationV2.fromJson(Map<String, dynamic> json) =>
      _$MisapplicationV2FromJson(json);
  Map<String, dynamic> toJson() => _$MisapplicationV2ToJson(this);
}

// ── Mode 1: Explain ──

@JsonSerializable()
class ExplainResultV2 {
  @JsonKey(defaultValue: '')
  final String verseReference;
  @JsonKey(defaultValue: '')
  final String oneLineSummary;
  @JsonKey(defaultValue: '')
  final String connectedThoughtRange;
  @JsonKey(defaultValue: '')
  final String speaker;
  @JsonKey(defaultValue: '')
  final String audience;
  @JsonKey(defaultValue: '')
  final String historicalContext;
  @JsonKey(defaultValue: '')
  final String literaryContext;
  @JsonKey(defaultValue: '')
  final String explanation;
  @JsonKey(defaultValue: [])
  final List<KeyTermV2> keyTerms;
  @JsonKey(defaultValue: [])
  final List<SupportingScriptureV2> supportingScriptures;
  @JsonKey(defaultValue: [])
  final List<CovenantLinkV2> covenant;
  @JsonKey(defaultValue: '')
  final String studyPrompt;

  ExplainResultV2({
    required this.verseReference,
    required this.oneLineSummary,
    required this.connectedThoughtRange,
    required this.speaker,
    required this.audience,
    required this.historicalContext,
    required this.literaryContext,
    required this.explanation,
    required this.keyTerms,
    required this.supportingScriptures,
    required this.covenant,
    required this.studyPrompt,
  });

  factory ExplainResultV2.fromJson(Map<String, dynamic> json) =>
      _$ExplainResultV2FromJson(json);
  Map<String, dynamic> toJson() => _$ExplainResultV2ToJson(this);
}

// ── Mode 2: Context ──

@JsonSerializable()
class ContextResultV2 {
  @JsonKey(defaultValue: '')
  final String verseReference;
  @JsonKey(defaultValue: '')
  final String oneLineSummary;
  @JsonKey(defaultValue: '')
  final String immediateContextBefore;
  @JsonKey(defaultValue: '')
  final String immediateContextAfter;
  @JsonKey(defaultValue: '')
  final String chapterTheme;
  @JsonKey(defaultValue: '')
  final String speaker;
  @JsonKey(defaultValue: '')
  final String audience;
  @JsonKey(defaultValue: '')
  final String literaryType;
  @JsonKey(defaultValue: '')
  final String culturalBackgroundInsight;
  @JsonKey(defaultValue: '')
  final String culturalInterpretiveImpact;
  @JsonKey(defaultValue: [])
  final List<MisunderstandingV2> commonMisunderstandings;
  final NearbyVerseV2? nearbyVerseQuote;
  @JsonKey(defaultValue: '')
  final String studyPrompt;

  ContextResultV2({
    required this.verseReference,
    required this.oneLineSummary,
    required this.immediateContextBefore,
    required this.immediateContextAfter,
    required this.chapterTheme,
    required this.speaker,
    required this.audience,
    required this.literaryType,
    required this.culturalBackgroundInsight,
    required this.culturalInterpretiveImpact,
    required this.commonMisunderstandings,
    this.nearbyVerseQuote,
    required this.studyPrompt,
  });

  factory ContextResultV2.fromJson(Map<String, dynamic> json) =>
      _$ContextResultV2FromJson(json);
  Map<String, dynamic> toJson() => _$ContextResultV2ToJson(this);
}

// ── Mode 3: Cross-Reference ──

@JsonSerializable()
class CrossRefResultV2 {
  @JsonKey(defaultValue: '')
  final String verseReference;
  @JsonKey(defaultValue: '')
  final String oneLineSummary;
  @JsonKey(defaultValue: '')
  final String centralTheme;
  @JsonKey(defaultValue: [])
  final List<CrossRefItemV2> references;
  @JsonKey(defaultValue: '')
  final String canonicalThread;
  @JsonKey(defaultValue: '')
  final String studyPrompt;

  CrossRefResultV2({
    required this.verseReference,
    required this.oneLineSummary,
    required this.centralTheme,
    required this.references,
    required this.canonicalThread,
    required this.studyPrompt,
  });

  factory CrossRefResultV2.fromJson(Map<String, dynamic> json) =>
      _$CrossRefResultV2FromJson(json);
  Map<String, dynamic> toJson() => _$CrossRefResultV2ToJson(this);
}

// ── Mode 4: Keywords ──

@JsonSerializable()
class KeywordsResultV2 {
  @JsonKey(defaultValue: '')
  final String verseReference;
  @JsonKey(defaultValue: '')
  final String oneLineSummary;
  @JsonKey(defaultValue: '')
  final String language;
  @JsonKey(defaultValue: [])
  final List<KeywordV2> keywords;
  @JsonKey(defaultValue: '')
  final String studyPrompt;

  KeywordsResultV2({
    required this.verseReference,
    required this.oneLineSummary,
    required this.language,
    required this.keywords,
    required this.studyPrompt,
  });

  factory KeywordsResultV2.fromJson(Map<String, dynamic> json) =>
      _$KeywordsResultV2FromJson(json);
  Map<String, dynamic> toJson() => _$KeywordsResultV2ToJson(this);
}

// ── Mode 5: Application ──

@JsonSerializable()
class ApplicationResultV2 {
  @JsonKey(defaultValue: '')
  final String verseReference;
  @JsonKey(defaultValue: '')
  final String oneLineSummary;
  @JsonKey(defaultValue: '')
  final String centralTruth;
  final ApplicabilityScopeV2? applicabilityScope;
  @JsonKey(defaultValue: '')
  final String generalApplication;
  final ApplicationAreasV2? applicationAreas;
  @JsonKey(defaultValue: [])
  final List<MisapplicationV2> commonMisapplications;
  final SupportingScriptureV2? supportingVerse;
  @JsonKey(defaultValue: '')
  final String studyPrompt;

  ApplicationResultV2({
    required this.verseReference,
    required this.oneLineSummary,
    required this.centralTruth,
    this.applicabilityScope,
    required this.generalApplication,
    this.applicationAreas,
    required this.commonMisapplications,
    this.supportingVerse,
    required this.studyPrompt,
  });

  factory ApplicationResultV2.fromJson(Map<String, dynamic> json) =>
      _$ApplicationResultV2FromJson(json);
  Map<String, dynamic> toJson() => _$ApplicationResultV2ToJson(this);
}
