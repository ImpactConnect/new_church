// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExplainAnalysis _$ExplainAnalysisFromJson(Map<String, dynamic> json) =>
    ExplainAnalysis(
      verseReference: json['verseReference'] as String? ?? '',
      connectedThoughtRange: json['connectedThoughtRange'] as String? ?? '',
      speaker: json['speaker'] as String? ?? '',
      audience: json['audience'] as String? ?? '',
      historicalContext: json['historicalContext'] as String? ?? '',
      literaryContext: json['literaryContext'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      ambiguousTerms: (json['ambiguousTerms'] as List<dynamic>?)
              ?.map((e) => AmbiguousTerm.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      supportingVerse: json['supportingVerse'] as String? ?? '',
      covenant: (json['covenant'] as List<dynamic>?)
              ?.map((e) => CovenantInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$ExplainAnalysisToJson(ExplainAnalysis instance) =>
    <String, dynamic>{
      'verseReference': instance.verseReference,
      'connectedThoughtRange': instance.connectedThoughtRange,
      'speaker': instance.speaker,
      'audience': instance.audience,
      'historicalContext': instance.historicalContext,
      'literaryContext': instance.literaryContext,
      'explanation': instance.explanation,
      'ambiguousTerms': instance.ambiguousTerms,
      'supportingVerse': instance.supportingVerse,
      'covenant': instance.covenant,
    };

AmbiguousTerm _$AmbiguousTermFromJson(Map<String, dynamic> json) =>
    AmbiguousTerm(
      term: json['term'] as String? ?? '',
      originalWord: json['originalWord'] as String? ?? '',
      transliteration: json['transliteration'] as String? ?? '',
      definition: json['definition'] as String? ?? '',
      whyItMatters: json['whyItMatters'] as String? ?? '',
    );

Map<String, dynamic> _$AmbiguousTermToJson(AmbiguousTerm instance) =>
    <String, dynamic>{
      'term': instance.term,
      'originalWord': instance.originalWord,
      'transliteration': instance.transliteration,
      'definition': instance.definition,
      'whyItMatters': instance.whyItMatters,
    };

CovenantInfo _$CovenantInfoFromJson(Map<String, dynamic> json) => CovenantInfo(
      covenant: json['covenant'] as String? ?? '',
      applicability: json['applicability'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
    );

Map<String, dynamic> _$CovenantInfoToJson(CovenantInfo instance) =>
    <String, dynamic>{
      'covenant': instance.covenant,
      'applicability': instance.applicability,
      'explanation': instance.explanation,
    };

ContextAnalysis _$ContextAnalysisFromJson(Map<String, dynamic> json) =>
    ContextAnalysis(
      immediateContextBefore: json['immediateContextBefore'] as String? ?? '',
      immediateContextAfter: json['immediateContextAfter'] as String? ?? '',
      chapterTheme: json['chapterTheme'] as String? ?? '',
      speaker: json['speaker'] as String? ?? '',
      audience: json['audience'] as String? ?? '',
      literaryType: json['literaryType'] as String? ?? '',
      culturalBackgroundInsight:
          json['culturalBackgroundInsight'] as String? ?? '',
      culturalInterpretiveImpact:
          json['culturalInterpretiveImpact'] as String? ?? '',
      commonMisunderstandings: json['commonMisunderstandings'] as String? ?? '',
      supportingVerse: json['supportingVerse'] as String? ?? '',
    );

Map<String, dynamic> _$ContextAnalysisToJson(ContextAnalysis instance) =>
    <String, dynamic>{
      'immediateContextBefore': instance.immediateContextBefore,
      'immediateContextAfter': instance.immediateContextAfter,
      'chapterTheme': instance.chapterTheme,
      'speaker': instance.speaker,
      'audience': instance.audience,
      'literaryType': instance.literaryType,
      'culturalBackgroundInsight': instance.culturalBackgroundInsight,
      'culturalInterpretiveImpact': instance.culturalInterpretiveImpact,
      'commonMisunderstandings': instance.commonMisunderstandings,
      'supportingVerse': instance.supportingVerse,
    };

KeyWordAnalysis _$KeyWordAnalysisFromJson(Map<String, dynamic> json) =>
    KeyWordAnalysis(
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => WordDetail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$KeyWordAnalysisToJson(KeyWordAnalysis instance) =>
    <String, dynamic>{
      'keywords': instance.keywords,
    };

WordDetail _$WordDetailFromJson(Map<String, dynamic> json) => WordDetail(
      word: json['word'] as String? ?? '',
      original: json['original'] as String? ?? '',
      transliteration: json['transliteration'] as String? ?? '',
      definition: json['definition'] as String? ?? '',
      usageInVerse: json['usageInVerse'] as String? ?? '',
      usageElsewhere: json['usageElsewhere'] as String? ?? '',
      theologicalSignificance: json['theologicalSignificance'] as String? ?? '',
      crossReference: json['crossReference'] as String? ?? '',
    );

Map<String, dynamic> _$WordDetailToJson(WordDetail instance) =>
    <String, dynamic>{
      'word': instance.word,
      'original': instance.original,
      'transliteration': instance.transliteration,
      'definition': instance.definition,
      'usageInVerse': instance.usageInVerse,
      'usageElsewhere': instance.usageElsewhere,
      'theologicalSignificance': instance.theologicalSignificance,
      'crossReference': instance.crossReference,
    };

CrossReferencesAnalysis _$CrossReferencesAnalysisFromJson(
        Map<String, dynamic> json) =>
    CrossReferencesAnalysis(
      theme: json['theme'] as String? ?? '',
      references: (json['references'] as List<dynamic>?)
              ?.map((e) => ReferenceItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$CrossReferencesAnalysisToJson(
        CrossReferencesAnalysis instance) =>
    <String, dynamic>{
      'theme': instance.theme,
      'references': instance.references,
    };

ReferenceItem _$ReferenceItemFromJson(Map<String, dynamic> json) =>
    ReferenceItem(
      reference: json['reference'] as String? ?? '',
      connection: json['connection'] as String? ?? '',
    );

Map<String, dynamic> _$ReferenceItemToJson(ReferenceItem instance) =>
    <String, dynamic>{
      'reference': instance.reference,
      'connection': instance.connection,
    };

ApplicationAnalysis _$ApplicationAnalysisFromJson(Map<String, dynamic> json) =>
    ApplicationAnalysis(
      centralTruth: json['centralTruth'] as String? ?? '',
      commonMisuse: json['commonMisuse'] as String? ?? '',
      applications: json['applications'] as String? ?? '',
      applicationsAreas: ApplicationContexts.fromJson(
          json['applicationsAreas'] as Map<String, dynamic>),
      clarification: json['clarification'] as String? ?? '',
      supportingVerse: json['supportingVerse'] as String? ?? '',
    );

Map<String, dynamic> _$ApplicationAnalysisToJson(
        ApplicationAnalysis instance) =>
    <String, dynamic>{
      'centralTruth': instance.centralTruth,
      'commonMisuse': instance.commonMisuse,
      'applications': instance.applications,
      'applicationsAreas': instance.applicationsAreas,
      'clarification': instance.clarification,
      'supportingVerse': instance.supportingVerse,
    };

ApplicationContexts _$ApplicationContextsFromJson(Map<String, dynamic> json) =>
    ApplicationContexts(
      personal: json['personal'] as String? ?? '',
      family: json['family'] as String? ?? '',
      church: json['church'] as String? ?? '',
      workplace: json['workplace'] as String? ?? '',
      society: json['society'] as String? ?? '',
    );

Map<String, dynamic> _$ApplicationContextsToJson(
        ApplicationContexts instance) =>
    <String, dynamic>{
      'personal': instance.personal,
      'family': instance.family,
      'church': instance.church,
      'workplace': instance.workplace,
      'society': instance.society,
    };

QuestionAnalysis _$QuestionAnalysisFromJson(Map<String, dynamic> json) =>
    QuestionAnalysis(
      answer: json['answer'] as String? ?? '',
      scripturalSupport: json['scripturalSupport'] as String? ?? '',
      interpretationNote: json['interpretationNote'] as String? ?? '',
      confidenceLevel: json['confidenceLevel'] as String? ?? '',
    );

Map<String, dynamic> _$QuestionAnalysisToJson(QuestionAnalysis instance) =>
    <String, dynamic>{
      'answer': instance.answer,
      'scripturalSupport': instance.scripturalSupport,
      'interpretationNote': instance.interpretationNote,
      'confidenceLevel': instance.confidenceLevel,
    };

PassageAnalysis _$PassageAnalysisFromJson(Map<String, dynamic> json) =>
    PassageAnalysis(
      summary: json['summary'] as String? ?? '',
      mainTheme: json['mainTheme'] as String? ?? '',
      flowOfThought: json['flowOfThought'] as String? ?? '',
      keyTakeaways: (json['keyTakeaways'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$PassageAnalysisToJson(PassageAnalysis instance) =>
    <String, dynamic>{
      'summary': instance.summary,
      'mainTheme': instance.mainTheme,
      'flowOfThought': instance.flowOfThought,
      'keyTakeaways': instance.keyTakeaways,
    };

ChapterAnalysis _$ChapterAnalysisFromJson(Map<String, dynamic> json) =>
    ChapterAnalysis(
      overview: json['overview'] as String? ?? '',
      mainMessage: json['mainMessage'] as String? ?? '',
      keyVerses: (json['keyVerses'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      reflectionQuestions: (json['reflectionQuestions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$ChapterAnalysisToJson(ChapterAnalysis instance) =>
    <String, dynamic>{
      'overview': instance.overview,
      'mainMessage': instance.mainMessage,
      'keyVerses': instance.keyVerses,
      'reflectionQuestions': instance.reflectionQuestions,
    };

BookIntroduction _$BookIntroductionFromJson(Map<String, dynamic> json) =>
    BookIntroduction(
      author: json['author'] as String,
      audience: json['audience'] as String,
      purpose: json['purpose'] as String,
      majorThemes: (json['majorThemes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      howToRead: json['howToRead'] as String,
    );

Map<String, dynamic> _$BookIntroductionToJson(BookIntroduction instance) =>
    <String, dynamic>{
      'author': instance.author,
      'audience': instance.audience,
      'purpose': instance.purpose,
      'majorThemes': instance.majorThemes,
      'howToRead': instance.howToRead,
    };

SemanticSearchResponse _$SemanticSearchResponseFromJson(
        Map<String, dynamic> json) =>
    SemanticSearchResponse(
      results: (json['results'] as List<dynamic>?)
              ?.map((e) =>
                  SemanticSearchResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$SemanticSearchResponseToJson(
        SemanticSearchResponse instance) =>
    <String, dynamic>{
      'results': instance.results,
    };

SemanticSearchResult _$SemanticSearchResultFromJson(
        Map<String, dynamic> json) =>
    SemanticSearchResult(
      bookName: json['bookName'] as String? ?? '',
      chapterNumber: (json['chapterNumber'] as num?)?.toInt() ?? 1,
      verseNumber: (json['verseNumber'] as num?)?.toInt() ?? 1,
      reason: json['reason'] as String? ?? '',
    );

Map<String, dynamic> _$SemanticSearchResultToJson(
        SemanticSearchResult instance) =>
    <String, dynamic>{
      'bookName': instance.bookName,
      'chapterNumber': instance.chapterNumber,
      'verseNumber': instance.verseNumber,
      'reason': instance.reason,
    };

CharacterExegesis _$CharacterExegesisFromJson(Map<String, dynamic> json) =>
    CharacterExegesis(
      character: json['character'] as String? ?? '',
      historicalContext: json['historicalContext'] as String? ?? '',
      narrativeRole: json['narrativeRole'] as String? ?? '',
      covenantalContext: json['covenantalContext'] as String? ?? '',
      keyEvents: (json['keyEvents'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      theologicalContribution: json['theologicalContribution'] as String? ?? '',
      strengths: (json['strengths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      failuresOrFlaws: (json['failuresOrFlaws'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      progressionArc: json['progressionArc'] as String? ?? '',
      canonicalSignificance: json['canonicalSignificance'] as String? ?? '',
      messianicOrTypologicalLinks:
          json['messianicOrTypologicalLinks'] as String? ?? '',
      scholarlyNotes: json['scholarlyNotes'] as String? ?? '',
    );

Map<String, dynamic> _$CharacterExegesisToJson(CharacterExegesis instance) =>
    <String, dynamic>{
      'character': instance.character,
      'historicalContext': instance.historicalContext,
      'narrativeRole': instance.narrativeRole,
      'covenantalContext': instance.covenantalContext,
      'keyEvents': instance.keyEvents,
      'theologicalContribution': instance.theologicalContribution,
      'strengths': instance.strengths,
      'failuresOrFlaws': instance.failuresOrFlaws,
      'progressionArc': instance.progressionArc,
      'canonicalSignificance': instance.canonicalSignificance,
      'messianicOrTypologicalLinks': instance.messianicOrTypologicalLinks,
      'scholarlyNotes': instance.scholarlyNotes,
    };

BookExegesis _$BookExegesisFromJson(Map<String, dynamic> json) => BookExegesis(
      book: json['book'] as String? ?? '',
      authorship: json['authorship'] as String? ?? '',
      dateAndSetting: json['dateAndSetting'] as String? ?? '',
      originalAudience: json['originalAudience'] as String? ?? '',
      historicalBackground: json['historicalBackground'] as String? ?? '',
      literaryStructure: json['literaryStructure'] as String? ?? '',
      majorThemes: (json['majorThemes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      theologicalEmphases: json['theologicalEmphases'] as String? ?? '',
      covenantalContext: json['covenantalContext'] as String? ?? '',
      christologicalOrRedemptiveTrajectory:
          json['christologicalOrRedemptiveTrajectory'] as String? ?? '',
      keyPassages: (json['keyPassages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      interpretiveChallenges: json['interpretiveChallenges'] as String? ?? '',
      canonicalRole: json['canonicalRole'] as String? ?? '',
    );

Map<String, dynamic> _$BookExegesisToJson(BookExegesis instance) =>
    <String, dynamic>{
      'book': instance.book,
      'authorship': instance.authorship,
      'dateAndSetting': instance.dateAndSetting,
      'originalAudience': instance.originalAudience,
      'historicalBackground': instance.historicalBackground,
      'literaryStructure': instance.literaryStructure,
      'majorThemes': instance.majorThemes,
      'theologicalEmphases': instance.theologicalEmphases,
      'covenantalContext': instance.covenantalContext,
      'christologicalOrRedemptiveTrajectory':
          instance.christologicalOrRedemptiveTrajectory,
      'keyPassages': instance.keyPassages,
      'interpretiveChallenges': instance.interpretiveChallenges,
      'canonicalRole': instance.canonicalRole,
    };

ChapterExegesis _$ChapterExegesisFromJson(Map<String, dynamic> json) =>
    ChapterExegesis(
      book: json['book'] as String? ?? '',
      chapter: json['chapter'] as String? ?? '',
      historicalContext: json['historicalContext'] as String? ?? '',
      literaryFlowSummary: json['literaryFlowSummary'] as String? ?? '',
      sectionBreakdown: (json['sectionBreakdown'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      majorThemes: (json['majorThemes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      keyTerms: (json['keyTerms'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      interpretiveIssues: json['interpretiveIssues'] as String? ?? '',
      canonicalConnection: json['canonicalConnection'] as String? ?? '',
      applicationPrinciples: (json['applicationPrinciples'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$ChapterExegesisToJson(ChapterExegesis instance) =>
    <String, dynamic>{
      'book': instance.book,
      'chapter': instance.chapter,
      'historicalContext': instance.historicalContext,
      'literaryFlowSummary': instance.literaryFlowSummary,
      'sectionBreakdown': instance.sectionBreakdown,
      'majorThemes': instance.majorThemes,
      'keyTerms': instance.keyTerms,
      'interpretiveIssues': instance.interpretiveIssues,
      'canonicalConnection': instance.canonicalConnection,
      'applicationPrinciples': instance.applicationPrinciples,
    };

PassageExegesis _$PassageExegesisFromJson(Map<String, dynamic> json) =>
    PassageExegesis(
      reference: json['reference'] as String? ?? '',
      literaryContext: json['literaryContext'] as String? ?? '',
      historicalContext: json['historicalContext'] as String? ?? '',
      genreAnalysis: json['genreAnalysis'] as String? ?? '',
      structureAnalysis: json['structureAnalysis'] as String? ?? '',
      keyTerms: (json['keyTerms'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      verseByVerseSummary: json['verseByVerseSummary'] as String? ?? '',
      theologicalThemes: (json['theologicalThemes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      covenantalSignificance: json['covenantalSignificance'] as String? ?? '',
      christologicalFulfillment:
          json['christologicalFulfillment'] as String? ?? '',
      interpretiveDebates: json['interpretiveDebates'] as String? ?? '',
      canonicalConnections: json['canonicalConnections'] as String? ?? '',
      doctrinalImplications: json['doctrinalImplications'] as String? ?? '',
    );

Map<String, dynamic> _$PassageExegesisToJson(PassageExegesis instance) =>
    <String, dynamic>{
      'reference': instance.reference,
      'literaryContext': instance.literaryContext,
      'historicalContext': instance.historicalContext,
      'genreAnalysis': instance.genreAnalysis,
      'structureAnalysis': instance.structureAnalysis,
      'keyTerms': instance.keyTerms,
      'verseByVerseSummary': instance.verseByVerseSummary,
      'theologicalThemes': instance.theologicalThemes,
      'covenantalSignificance': instance.covenantalSignificance,
      'christologicalFulfillment': instance.christologicalFulfillment,
      'interpretiveDebates': instance.interpretiveDebates,
      'canonicalConnections': instance.canonicalConnections,
      'doctrinalImplications': instance.doctrinalImplications,
    };

KeyTermV2 _$KeyTermV2FromJson(Map<String, dynamic> json) => KeyTermV2(
      term: json['term'] as String? ?? '',
      originalWord: json['originalWord'] as String? ?? '',
      transliteration: json['transliteration'] as String? ?? '',
      strongsNumber: json['strongsNumber'] as String? ?? '',
      definition: json['definition'] as String? ?? '',
      whyItMatters: json['whyItMatters'] as String? ?? '',
    );

Map<String, dynamic> _$KeyTermV2ToJson(KeyTermV2 instance) => <String, dynamic>{
      'term': instance.term,
      'originalWord': instance.originalWord,
      'transliteration': instance.transliteration,
      'strongsNumber': instance.strongsNumber,
      'definition': instance.definition,
      'whyItMatters': instance.whyItMatters,
    };

SupportingScriptureV2 _$SupportingScriptureV2FromJson(
        Map<String, dynamic> json) =>
    SupportingScriptureV2(
      reference: json['reference'] as String? ?? '',
      text: json['text'] as String?,
      connection: json['connection'] as String? ?? '',
    );

Map<String, dynamic> _$SupportingScriptureV2ToJson(
        SupportingScriptureV2 instance) =>
    <String, dynamic>{
      'reference': instance.reference,
      'text': instance.text,
      'connection': instance.connection,
    };

CovenantLinkV2 _$CovenantLinkV2FromJson(Map<String, dynamic> json) =>
    CovenantLinkV2(
      covenantName: json['covenantName'] as String? ?? '',
      applicability: json['applicability'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
    );

Map<String, dynamic> _$CovenantLinkV2ToJson(CovenantLinkV2 instance) =>
    <String, dynamic>{
      'covenantName': instance.covenantName,
      'applicability': instance.applicability,
      'explanation': instance.explanation,
    };

MisunderstandingV2 _$MisunderstandingV2FromJson(Map<String, dynamic> json) =>
    MisunderstandingV2(
      misunderstanding: json['misunderstanding'] as String? ?? '',
      whyItHappens: json['whyItHappens'] as String? ?? '',
      correction: json['correction'] as String? ?? '',
      correctiveVerse: json['correctiveVerse'] as String?,
    );

Map<String, dynamic> _$MisunderstandingV2ToJson(MisunderstandingV2 instance) =>
    <String, dynamic>{
      'misunderstanding': instance.misunderstanding,
      'whyItHappens': instance.whyItHappens,
      'correction': instance.correction,
      'correctiveVerse': instance.correctiveVerse,
    };

NearbyVerseV2 _$NearbyVerseV2FromJson(Map<String, dynamic> json) =>
    NearbyVerseV2(
      reference: json['reference'] as String? ?? '',
      text: json['text'] as String?,
      relevance: json['relevance'] as String? ?? '',
    );

Map<String, dynamic> _$NearbyVerseV2ToJson(NearbyVerseV2 instance) =>
    <String, dynamic>{
      'reference': instance.reference,
      'text': instance.text,
      'relevance': instance.relevance,
    };

CrossRefItemV2 _$CrossRefItemV2FromJson(Map<String, dynamic> json) =>
    CrossRefItemV2(
      reference: json['reference'] as String? ?? '',
      verseText: json['verseText'] as String?,
      connectionType: json['connectionType'] as String? ?? '',
      connectionStrength: json['connectionStrength'] as String? ?? '',
      connection: json['connection'] as String? ?? '',
      testament: json['testament'] as String? ?? '',
    );

Map<String, dynamic> _$CrossRefItemV2ToJson(CrossRefItemV2 instance) =>
    <String, dynamic>{
      'reference': instance.reference,
      'verseText': instance.verseText,
      'connectionType': instance.connectionType,
      'connectionStrength': instance.connectionStrength,
      'connection': instance.connection,
      'testament': instance.testament,
    };

KeywordV2 _$KeywordV2FromJson(Map<String, dynamic> json) => KeywordV2(
      word: json['word'] as String? ?? '',
      originalWord: json['originalWord'] as String? ?? '',
      transliteration: json['transliteration'] as String? ?? '',
      strongsNumber: json['strongsNumber'] as String? ?? '',
      partOfSpeech: json['partOfSpeech'] as String? ?? '',
      definition: json['definition'] as String? ?? '',
      usageInVerse: json['usageInVerse'] as String? ?? '',
      usageElsewhere: json['usageElsewhere'] as String? ?? '',
      theologicalSignificance: json['theologicalSignificance'] as String? ?? '',
      translationVariance: json['translationVariance'] as String?,
      crossReference: json['crossReference'] as String? ?? '',
    );

Map<String, dynamic> _$KeywordV2ToJson(KeywordV2 instance) => <String, dynamic>{
      'word': instance.word,
      'originalWord': instance.originalWord,
      'transliteration': instance.transliteration,
      'strongsNumber': instance.strongsNumber,
      'partOfSpeech': instance.partOfSpeech,
      'definition': instance.definition,
      'usageInVerse': instance.usageInVerse,
      'usageElsewhere': instance.usageElsewhere,
      'theologicalSignificance': instance.theologicalSignificance,
      'translationVariance': instance.translationVariance,
      'crossReference': instance.crossReference,
    };

ApplicabilityScopeV2 _$ApplicabilityScopeV2FromJson(
        Map<String, dynamic> json) =>
    ApplicabilityScopeV2(
      scope: json['scope'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
    );

Map<String, dynamic> _$ApplicabilityScopeV2ToJson(
        ApplicabilityScopeV2 instance) =>
    <String, dynamic>{
      'scope': instance.scope,
      'explanation': instance.explanation,
    };

ApplicationAreasV2 _$ApplicationAreasV2FromJson(Map<String, dynamic> json) =>
    ApplicationAreasV2(
      personal: json['personal'] as String? ?? '',
      family: json['family'] as String? ?? '',
      church: json['church'] as String? ?? '',
      workplace: json['workplace'] as String? ?? '',
      society: json['society'] as String? ?? '',
    );

Map<String, dynamic> _$ApplicationAreasV2ToJson(ApplicationAreasV2 instance) =>
    <String, dynamic>{
      'personal': instance.personal,
      'family': instance.family,
      'church': instance.church,
      'workplace': instance.workplace,
      'society': instance.society,
    };

MisapplicationV2 _$MisapplicationV2FromJson(Map<String, dynamic> json) =>
    MisapplicationV2(
      misapplication: json['misapplication'] as String? ?? '',
      whoUsesIt: json['whoUsesIt'] as String? ?? '',
      whyItsWrong: json['whyItsWrong'] as String? ?? '',
      correctApplication: json['correctApplication'] as String? ?? '',
      correctiveVerse: json['correctiveVerse'] as String?,
    );

Map<String, dynamic> _$MisapplicationV2ToJson(MisapplicationV2 instance) =>
    <String, dynamic>{
      'misapplication': instance.misapplication,
      'whoUsesIt': instance.whoUsesIt,
      'whyItsWrong': instance.whyItsWrong,
      'correctApplication': instance.correctApplication,
      'correctiveVerse': instance.correctiveVerse,
    };

ExplainResultV2 _$ExplainResultV2FromJson(Map<String, dynamic> json) =>
    ExplainResultV2(
      verseReference: json['verseReference'] as String? ?? '',
      oneLineSummary: json['oneLineSummary'] as String? ?? '',
      connectedThoughtRange: json['connectedThoughtRange'] as String? ?? '',
      speaker: json['speaker'] as String? ?? '',
      audience: json['audience'] as String? ?? '',
      historicalContext: json['historicalContext'] as String? ?? '',
      literaryContext: json['literaryContext'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      keyTerms: (json['keyTerms'] as List<dynamic>?)
              ?.map((e) => KeyTermV2.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      supportingScriptures: (json['supportingScriptures'] as List<dynamic>?)
              ?.map((e) =>
                  SupportingScriptureV2.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      covenant: (json['covenant'] as List<dynamic>?)
              ?.map((e) => CovenantLinkV2.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      studyPrompt: json['studyPrompt'] as String? ?? '',
    );

Map<String, dynamic> _$ExplainResultV2ToJson(ExplainResultV2 instance) =>
    <String, dynamic>{
      'verseReference': instance.verseReference,
      'oneLineSummary': instance.oneLineSummary,
      'connectedThoughtRange': instance.connectedThoughtRange,
      'speaker': instance.speaker,
      'audience': instance.audience,
      'historicalContext': instance.historicalContext,
      'literaryContext': instance.literaryContext,
      'explanation': instance.explanation,
      'keyTerms': instance.keyTerms,
      'supportingScriptures': instance.supportingScriptures,
      'covenant': instance.covenant,
      'studyPrompt': instance.studyPrompt,
    };

ContextResultV2 _$ContextResultV2FromJson(Map<String, dynamic> json) =>
    ContextResultV2(
      verseReference: json['verseReference'] as String? ?? '',
      oneLineSummary: json['oneLineSummary'] as String? ?? '',
      immediateContextBefore: json['immediateContextBefore'] as String? ?? '',
      immediateContextAfter: json['immediateContextAfter'] as String? ?? '',
      chapterTheme: json['chapterTheme'] as String? ?? '',
      speaker: json['speaker'] as String? ?? '',
      audience: json['audience'] as String? ?? '',
      literaryType: json['literaryType'] as String? ?? '',
      culturalBackgroundInsight:
          json['culturalBackgroundInsight'] as String? ?? '',
      culturalInterpretiveImpact:
          json['culturalInterpretiveImpact'] as String? ?? '',
      commonMisunderstandings: (json['commonMisunderstandings']
                  as List<dynamic>?)
              ?.map(
                  (e) => MisunderstandingV2.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      nearbyVerseQuote: json['nearbyVerseQuote'] == null
          ? null
          : NearbyVerseV2.fromJson(
              json['nearbyVerseQuote'] as Map<String, dynamic>),
      studyPrompt: json['studyPrompt'] as String? ?? '',
    );

Map<String, dynamic> _$ContextResultV2ToJson(ContextResultV2 instance) =>
    <String, dynamic>{
      'verseReference': instance.verseReference,
      'oneLineSummary': instance.oneLineSummary,
      'immediateContextBefore': instance.immediateContextBefore,
      'immediateContextAfter': instance.immediateContextAfter,
      'chapterTheme': instance.chapterTheme,
      'speaker': instance.speaker,
      'audience': instance.audience,
      'literaryType': instance.literaryType,
      'culturalBackgroundInsight': instance.culturalBackgroundInsight,
      'culturalInterpretiveImpact': instance.culturalInterpretiveImpact,
      'commonMisunderstandings': instance.commonMisunderstandings,
      'nearbyVerseQuote': instance.nearbyVerseQuote,
      'studyPrompt': instance.studyPrompt,
    };

CrossRefResultV2 _$CrossRefResultV2FromJson(Map<String, dynamic> json) =>
    CrossRefResultV2(
      verseReference: json['verseReference'] as String? ?? '',
      oneLineSummary: json['oneLineSummary'] as String? ?? '',
      centralTheme: json['centralTheme'] as String? ?? '',
      references: (json['references'] as List<dynamic>?)
              ?.map((e) => CrossRefItemV2.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      canonicalThread: json['canonicalThread'] as String? ?? '',
      studyPrompt: json['studyPrompt'] as String? ?? '',
    );

Map<String, dynamic> _$CrossRefResultV2ToJson(CrossRefResultV2 instance) =>
    <String, dynamic>{
      'verseReference': instance.verseReference,
      'oneLineSummary': instance.oneLineSummary,
      'centralTheme': instance.centralTheme,
      'references': instance.references,
      'canonicalThread': instance.canonicalThread,
      'studyPrompt': instance.studyPrompt,
    };

KeywordsResultV2 _$KeywordsResultV2FromJson(Map<String, dynamic> json) =>
    KeywordsResultV2(
      verseReference: json['verseReference'] as String? ?? '',
      oneLineSummary: json['oneLineSummary'] as String? ?? '',
      language: json['language'] as String? ?? '',
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => KeywordV2.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      studyPrompt: json['studyPrompt'] as String? ?? '',
    );

Map<String, dynamic> _$KeywordsResultV2ToJson(KeywordsResultV2 instance) =>
    <String, dynamic>{
      'verseReference': instance.verseReference,
      'oneLineSummary': instance.oneLineSummary,
      'language': instance.language,
      'keywords': instance.keywords,
      'studyPrompt': instance.studyPrompt,
    };

ApplicationResultV2 _$ApplicationResultV2FromJson(Map<String, dynamic> json) =>
    ApplicationResultV2(
      verseReference: json['verseReference'] as String? ?? '',
      oneLineSummary: json['oneLineSummary'] as String? ?? '',
      centralTruth: json['centralTruth'] as String? ?? '',
      applicabilityScope: json['applicabilityScope'] == null
          ? null
          : ApplicabilityScopeV2.fromJson(
              json['applicabilityScope'] as Map<String, dynamic>),
      generalApplication: json['generalApplication'] as String? ?? '',
      applicationAreas: json['applicationAreas'] == null
          ? null
          : ApplicationAreasV2.fromJson(
              json['applicationAreas'] as Map<String, dynamic>),
      commonMisapplications: (json['commonMisapplications'] as List<dynamic>?)
              ?.map((e) => MisapplicationV2.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      supportingVerse: json['supportingVerse'] == null
          ? null
          : SupportingScriptureV2.fromJson(
              json['supportingVerse'] as Map<String, dynamic>),
      studyPrompt: json['studyPrompt'] as String? ?? '',
    );

Map<String, dynamic> _$ApplicationResultV2ToJson(
        ApplicationResultV2 instance) =>
    <String, dynamic>{
      'verseReference': instance.verseReference,
      'oneLineSummary': instance.oneLineSummary,
      'centralTruth': instance.centralTruth,
      'applicabilityScope': instance.applicabilityScope,
      'generalApplication': instance.generalApplication,
      'applicationAreas': instance.applicationAreas,
      'commonMisapplications': instance.commonMisapplications,
      'supportingVerse': instance.supportingVerse,
      'studyPrompt': instance.studyPrompt,
    };
