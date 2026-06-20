// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exegesis_final_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WordOccurrenceImpl _$$WordOccurrenceImplFromJson(Map<String, dynamic> json) =>
    _$WordOccurrenceImpl(
      reference: json['reference'] as String,
      context: json['context'] as String,
    );

Map<String, dynamic> _$$WordOccurrenceImplToJson(
        _$WordOccurrenceImpl instance) =>
    <String, dynamic>{
      'reference': instance.reference,
      'context': instance.context,
    };

_$WordStudyItemImpl _$$WordStudyItemImplFromJson(Map<String, dynamic> json) =>
    _$WordStudyItemImpl(
      englishWord: json['englishWord'] as String,
      verseRef: json['verseRef'] as String?,
      originalWord: json['originalWord'] as String,
      transliteration: json['transliteration'] as String,
      strongsNumber: json['strongsNumber'] as String,
      lexicalDefinition: json['lexicalDefinition'] as String,
      meaningInThisContext: json['meaningInThisContext'] as String,
      discoveryNote: json['discoveryNote'] as String,
      otherOccurrences: (json['otherOccurrences'] as List<dynamic>?)
              ?.map((e) => WordOccurrence.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$WordStudyItemImplToJson(_$WordStudyItemImpl instance) =>
    <String, dynamic>{
      'englishWord': instance.englishWord,
      'verseRef': instance.verseRef,
      'originalWord': instance.originalWord,
      'transliteration': instance.transliteration,
      'strongsNumber': instance.strongsNumber,
      'lexicalDefinition': instance.lexicalDefinition,
      'meaningInThisContext': instance.meaningInThisContext,
      'discoveryNote': instance.discoveryNote,
      'otherOccurrences': instance.otherOccurrences,
    };

_$MorphItemImpl _$$MorphItemImplFromJson(Map<String, dynamic> json) =>
    _$MorphItemImpl(
      word: json['word'] as String,
      originalWord: json['originalWord'] as String,
      strongsNumber: json['strongsNumber'] as String,
      partOfSpeech: json['partOfSpeech'] as String,
      tense: json['tense'] as String?,
      voice: json['voice'] as String?,
      mood: json['mood'] as String?,
      personNumber: json['personNumber'] as String?,
      plainEnglishExplanation: json['plainEnglishExplanation'] as String,
    );

Map<String, dynamic> _$$MorphItemImplToJson(_$MorphItemImpl instance) =>
    <String, dynamic>{
      'word': instance.word,
      'originalWord': instance.originalWord,
      'strongsNumber': instance.strongsNumber,
      'partOfSpeech': instance.partOfSpeech,
      'tense': instance.tense,
      'voice': instance.voice,
      'mood': instance.mood,
      'personNumber': instance.personNumber,
      'plainEnglishExplanation': instance.plainEnglishExplanation,
    };

_$ConfusedWordImpl _$$ConfusedWordImplFromJson(Map<String, dynamic> json) =>
    _$ConfusedWordImpl(
      word: json['word'] as String,
      strongsNumber: json['strongsNumber'] as String,
      meaningDifference: json['meaningDifference'] as String,
      exampleVerse: json['exampleVerse'] as String,
    );

Map<String, dynamic> _$$ConfusedWordImplToJson(_$ConfusedWordImpl instance) =>
    <String, dynamic>{
      'word': instance.word,
      'strongsNumber': instance.strongsNumber,
      'meaningDifference': instance.meaningDifference,
      'exampleVerse': instance.exampleVerse,
    };

_$SemanticItemImpl _$$SemanticItemImplFromJson(Map<String, dynamic> json) =>
    _$SemanticItemImpl(
      englishWord: json['englishWord'] as String,
      disambiguation: json['disambiguation'] as String,
      wordUsedHere: json['wordUsedHere'] as String,
      wordUsedHereStrongs: json['wordUsedHereStrongs'] as String,
      confusedWith: (json['confusedWith'] as List<dynamic>?)
              ?.map((e) => ConfusedWord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$SemanticItemImplToJson(_$SemanticItemImpl instance) =>
    <String, dynamic>{
      'englishWord': instance.englishWord,
      'disambiguation': instance.disambiguation,
      'wordUsedHere': instance.wordUsedHere,
      'wordUsedHereStrongs': instance.wordUsedHereStrongs,
      'confusedWith': instance.confusedWith,
    };

_$DevelopmentMentionImpl _$$DevelopmentMentionImplFromJson(
        Map<String, dynamic> json) =>
    _$DevelopmentMentionImpl(
      reference: json['reference'] as String,
      development: json['development'] as String,
    );

Map<String, dynamic> _$$DevelopmentMentionImplToJson(
        _$DevelopmentMentionImpl instance) =>
    <String, dynamic>{
      'reference': instance.reference,
      'development': instance.development,
    };

_$FirstMentionDetailImpl _$$FirstMentionDetailImplFromJson(
        Map<String, dynamic> json) =>
    _$FirstMentionDetailImpl(
      reference: json['reference'] as String,
      verseText: json['verseText'] as String?,
      whatItEstablishes: json['whatItEstablishes'] as String,
    );

Map<String, dynamic> _$$FirstMentionDetailImplToJson(
        _$FirstMentionDetailImpl instance) =>
    <String, dynamic>{
      'reference': instance.reference,
      'verseText': instance.verseText,
      'whatItEstablishes': instance.whatItEstablishes,
    };

_$MentionItemImpl _$$MentionItemImplFromJson(Map<String, dynamic> json) =>
    _$MentionItemImpl(
      concept: json['concept'] as String,
      firstMention: FirstMentionDetail.fromJson(
          json['firstMention'] as Map<String, dynamic>),
      developmentMentions: (json['developmentMentions'] as List<dynamic>?)
              ?.map(
                  (e) => DevelopmentMention.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      emphasisPattern: json['emphasisPattern'] as String?,
    );

Map<String, dynamic> _$$MentionItemImplToJson(_$MentionItemImpl instance) =>
    <String, dynamic>{
      'concept': instance.concept,
      'firstMention': instance.firstMention,
      'developmentMentions': instance.developmentMentions,
      'emphasisPattern': instance.emphasisPattern,
    };

_$LogicalConnectorImpl _$$LogicalConnectorImplFromJson(
        Map<String, dynamic> json) =>
    _$LogicalConnectorImpl(
      word: json['word'] as String,
      originalWord: json['originalWord'] as String,
      significance: json['significance'] as String,
    );

Map<String, dynamic> _$$LogicalConnectorImplToJson(
        _$LogicalConnectorImpl instance) =>
    <String, dynamic>{
      'word': instance.word,
      'originalWord': instance.originalWord,
      'significance': instance.significance,
    };

_$DiscourseAnalysisImpl _$$DiscourseAnalysisImplFromJson(
        Map<String, dynamic> json) =>
    _$DiscourseAnalysisImpl(
      rhetoricalFunction: json['rhetoricalFunction'] as String,
      logicalConnectors: (json['logicalConnectors'] as List<dynamic>?)
              ?.map((e) => LogicalConnector.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      authorIntent: json['authorIntent'] as String,
    );

Map<String, dynamic> _$$DiscourseAnalysisImplToJson(
        _$DiscourseAnalysisImpl instance) =>
    <String, dynamic>{
      'rhetoricalFunction': instance.rhetoricalFunction,
      'logicalConnectors': instance.logicalConnectors,
      'authorIntent': instance.authorIntent,
    };

_$CrossRefImpl _$$CrossRefImplFromJson(Map<String, dynamic> json) =>
    _$CrossRefImpl(
      reference: json['reference'] as String,
      verseText: json['verseText'] as String?,
      connectionType: json['connectionType'] as String,
      specificContribution: json['specificContribution'] as String,
    );

Map<String, dynamic> _$$CrossRefImplToJson(_$CrossRefImpl instance) =>
    <String, dynamic>{
      'reference': instance.reference,
      'verseText': instance.verseText,
      'connectionType': instance.connectionType,
      'specificContribution': instance.specificContribution,
    };

_$AllusionImpl _$$AllusionImplFromJson(Map<String, dynamic> json) =>
    _$AllusionImpl(
      sourceText: json['sourceText'] as String,
      sourceVerseText: json['sourceVerseText'] as String?,
      allusionText: json['allusionText'] as String,
      howToHearIt: json['howToHearIt'] as String,
    );

Map<String, dynamic> _$$AllusionImplToJson(_$AllusionImpl instance) =>
    <String, dynamic>{
      'sourceText': instance.sourceText,
      'sourceVerseText': instance.sourceVerseText,
      'allusionText': instance.allusionText,
      'howToHearIt': instance.howToHearIt,
    };

_$TextualNoteImpl _$$TextualNoteImplFromJson(Map<String, dynamic> json) =>
    _$TextualNoteImpl(
      include: json['include'] as bool? ?? false,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$$TextualNoteImplToJson(_$TextualNoteImpl instance) =>
    <String, dynamic>{
      'include': instance.include,
      'notes': instance.notes,
    };

_$MisreadingImpl _$$MisreadingImplFromJson(Map<String, dynamic> json) =>
    _$MisreadingImpl(
      commonMisreading: json['commonMisreading'] as String,
      whyItIsWrong: json['whyItIsWrong'] as String,
      whatItActuallyMeans: json['whatItActuallyMeans'] as String,
    );

Map<String, dynamic> _$$MisreadingImplToJson(_$MisreadingImpl instance) =>
    <String, dynamic>{
      'commonMisreading': instance.commonMisreading,
      'whyItIsWrong': instance.whyItIsWrong,
      'whatItActuallyMeans': instance.whatItActuallyMeans,
    };

_$CulturalKeyImpl _$$CulturalKeyImplFromJson(Map<String, dynamic> json) =>
    _$CulturalKeyImpl(
      item: json['item'] as String,
      howItShapesReading: json['howItShapesReading'] as String,
    );

Map<String, dynamic> _$$CulturalKeyImplToJson(_$CulturalKeyImpl instance) =>
    <String, dynamic>{
      'item': instance.item,
      'howItShapesReading': instance.howItShapesReading,
    };

_$HistoricalCulturalSettingImpl _$$HistoricalCulturalSettingImplFromJson(
        Map<String, dynamic> json) =>
    _$HistoricalCulturalSettingImpl(
      world: json['world'] as String,
      specificCulturalKeys: (json['specificCulturalKeys'] as List<dynamic>?)
              ?.map((e) => CulturalKey.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$HistoricalCulturalSettingImplToJson(
        _$HistoricalCulturalSettingImpl instance) =>
    <String, dynamic>{
      'world': instance.world,
      'specificCulturalKeys': instance.specificCulturalKeys,
    };

_$LiteraryContextImpl _$$LiteraryContextImplFromJson(
        Map<String, dynamic> json) =>
    _$LiteraryContextImpl(
      genre: json['genre'] as String,
      immediateBefore: json['immediateBefore'] as String,
      immediateAfter: json['immediateAfter'] as String,
      structuralRole: json['structuralRole'] as String,
      passageFlow: json['passageFlow'] as String,
    );

Map<String, dynamic> _$$LiteraryContextImplToJson(
        _$LiteraryContextImpl instance) =>
    <String, dynamic>{
      'genre': instance.genre,
      'immediateBefore': instance.immediateBefore,
      'immediateAfter': instance.immediateAfter,
      'structuralRole': instance.structuralRole,
      'passageFlow': instance.passageFlow,
    };

_$LanguageWordImpl _$$LanguageWordImplFromJson(Map<String, dynamic> json) =>
    _$LanguageWordImpl(
      word: json['word'] as String,
      originalScript: json['originalScript'] as String,
      transliteration: json['transliteration'] as String,
      strongsNumber: json['strongsNumber'] as String,
      fullSemanticRange: json['fullSemanticRange'] as String,
    );

Map<String, dynamic> _$$LanguageWordImplToJson(_$LanguageWordImpl instance) =>
    <String, dynamic>{
      'word': instance.word,
      'originalScript': instance.originalScript,
      'transliteration': instance.transliteration,
      'strongsNumber': instance.strongsNumber,
      'fullSemanticRange': instance.fullSemanticRange,
    };

_$ConceptDefinitionImpl _$$ConceptDefinitionImplFromJson(
        Map<String, dynamic> json) =>
    _$ConceptDefinitionImpl(
      hebrewWord:
          LanguageWord.fromJson(json['hebrewWord'] as Map<String, dynamic>),
      greekWord:
          LanguageWord.fromJson(json['greekWord'] as Map<String, dynamic>),
      semanticDisambiguation: json['semanticDisambiguation'] as String,
      modernVsAncient: json['modernVsAncient'] as String,
    );

Map<String, dynamic> _$$ConceptDefinitionImplToJson(
        _$ConceptDefinitionImpl instance) =>
    <String, dynamic>{
      'hebrewWord': instance.hebrewWord,
      'greekWord': instance.greekWord,
      'semanticDisambiguation': instance.semanticDisambiguation,
      'modernVsAncient': instance.modernVsAncient,
    };

_$TopicFirstMentionImpl _$$TopicFirstMentionImplFromJson(
        Map<String, dynamic> json) =>
    _$TopicFirstMentionImpl(
      reference: json['reference'] as String,
      verseText: json['verseText'] as String?,
      whatItEstablishes: json['whatItEstablishes'] as String,
    );

Map<String, dynamic> _$$TopicFirstMentionImplToJson(
        _$TopicFirstMentionImpl instance) =>
    <String, dynamic>{
      'reference': instance.reference,
      'verseText': instance.verseText,
      'whatItEstablishes': instance.whatItEstablishes,
    };

_$DefiningPassageImpl _$$DefiningPassageImplFromJson(
        Map<String, dynamic> json) =>
    _$DefiningPassageImpl(
      reference: json['reference'] as String,
      verseText: json['verseText'] as String?,
      whyDefinitive: json['whyDefinitive'] as String,
      historicalCulturalContext: json['historicalCulturalContext'] as String,
      wordStudy: (json['wordStudy'] as List<dynamic>?)
              ?.map((e) => WordStudyItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      morphologicalNote: json['morphologicalNote'] as String?,
      whatThisPassageSays: json['whatThisPassageSays'] as String,
      connectionsToOtherDefiningPassages:
          json['connectionsToOtherDefiningPassages'] as String?,
    );

Map<String, dynamic> _$$DefiningPassageImplToJson(
        _$DefiningPassageImpl instance) =>
    <String, dynamic>{
      'reference': instance.reference,
      'verseText': instance.verseText,
      'whyDefinitive': instance.whyDefinitive,
      'historicalCulturalContext': instance.historicalCulturalContext,
      'wordStudy': instance.wordStudy,
      'morphologicalNote': instance.morphologicalNote,
      'whatThisPassageSays': instance.whatThisPassageSays,
      'connectionsToOtherDefiningPassages':
          instance.connectionsToOtherDefiningPassages,
    };

_$DistortionImpl _$$DistortionImplFromJson(Map<String, dynamic> json) =>
    _$DistortionImpl(
      distortion: json['distortion'] as String,
      howItEnters: json['howItEnters'] as String,
      linguisticCorrection: json['linguisticCorrection'] as String,
    );

Map<String, dynamic> _$$DistortionImplToJson(_$DistortionImpl instance) =>
    <String, dynamic>{
      'distortion': instance.distortion,
      'howItEnters': instance.howItEnters,
      'linguisticCorrection': instance.linguisticCorrection,
    };

_$VerseExegesisImpl _$$VerseExegesisImplFromJson(Map<String, dynamic> json) =>
    _$VerseExegesisImpl(
      id: json['id'] as String,
      source: $enumDecode(_$ExegesisSourceEnumMap, json['source']),
      subject: json['subject'] as String,
      translation: json['translation'] as String,
      verseRefsJson: (json['verseRefsJson'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      bigPicture: json['bigPicture'] as String,
      historicalCulturalSetting: HistoricalCulturalSetting.fromJson(
          json['historicalCulturalSetting'] as Map<String, dynamic>),
      literaryContext: LiteraryContext.fromJson(
          json['literaryContext'] as Map<String, dynamic>),
      wordStudy: (json['wordStudy'] as List<dynamic>?)
              ?.map((e) => WordStudyItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      morphologicalAnalysis: (json['morphologicalAnalysis'] as List<dynamic>?)
              ?.map((e) => MorphItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      semanticDisambiguation: (json['semanticDisambiguation'] as List<dynamic>?)
              ?.map((e) => SemanticItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      mentionAnalysis: (json['mentionAnalysis'] as List<dynamic>?)
              ?.map((e) => MentionItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      discourseAnalysis: DiscourseAnalysis.fromJson(
          json['discourseAnalysis'] as Map<String, dynamic>),
      crossReferences: (json['crossReferences'] as List<dynamic>?)
              ?.map((e) => CrossRef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      intertextualAllusions: (json['intertextualAllusions'] as List<dynamic>?)
          ?.map((e) => Allusion.fromJson(e as Map<String, dynamic>))
          .toList(),
      textualApparatusNotes: json['textualApparatusNotes'] == null
          ? null
          : TextualNote.fromJson(
              json['textualApparatusNotes'] as Map<String, dynamic>),
      impliedTheologicalClaim: json['impliedTheologicalClaim'] as String,
      whatItCannotMean: (json['whatItCannotMean'] as List<dynamic>?)
              ?.map((e) => Misreading.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      fromTextToLife: json['fromTextToLife'] as String,
      somethingToSitWith: json['somethingToSitWith'] as String,
      contextSummary: json['contextSummary'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$VerseExegesisImplToJson(_$VerseExegesisImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'source': _$ExegesisSourceEnumMap[instance.source]!,
      'subject': instance.subject,
      'translation': instance.translation,
      'verseRefsJson': instance.verseRefsJson,
      'bigPicture': instance.bigPicture,
      'historicalCulturalSetting': instance.historicalCulturalSetting,
      'literaryContext': instance.literaryContext,
      'wordStudy': instance.wordStudy,
      'morphologicalAnalysis': instance.morphologicalAnalysis,
      'semanticDisambiguation': instance.semanticDisambiguation,
      'mentionAnalysis': instance.mentionAnalysis,
      'discourseAnalysis': instance.discourseAnalysis,
      'crossReferences': instance.crossReferences,
      'intertextualAllusions': instance.intertextualAllusions,
      'textualApparatusNotes': instance.textualApparatusNotes,
      'impliedTheologicalClaim': instance.impliedTheologicalClaim,
      'whatItCannotMean': instance.whatItCannotMean,
      'fromTextToLife': instance.fromTextToLife,
      'somethingToSitWith': instance.somethingToSitWith,
      'contextSummary': instance.contextSummary,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$ExegesisSourceEnumMap = {
  ExegesisSource.newForm: 'newForm',
  ExegesisSource.bibleReader: 'bibleReader',
};

_$TopicExegesisImpl _$$TopicExegesisImplFromJson(Map<String, dynamic> json) =>
    _$TopicExegesisImpl(
      id: json['id'] as String,
      source: $enumDecode(_$ExegesisSourceEnumMap, json['source']),
      subject: json['subject'] as String,
      bigPicture: json['bigPicture'] as String,
      conceptDefinition: ConceptDefinition.fromJson(
          json['conceptDefinition'] as Map<String, dynamic>),
      firstMention: TopicFirstMention.fromJson(
          json['firstMention'] as Map<String, dynamic>),
      definingPassages: (json['definingPassages'] as List<dynamic>?)
              ?.map((e) => DefiningPassage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      canonicalProgression: json['canonicalProgression'] as String,
      commonDistortions: (json['commonDistortions'] as List<dynamic>?)
              ?.map((e) => Distortion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      impliedTheologicalClaim: json['impliedTheologicalClaim'] as String,
      whatItCannotMean: (json['whatItCannotMean'] as List<dynamic>?)
              ?.map((e) => Misreading.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      fromTextToLife: json['fromTextToLife'] as String,
      somethingToSitWith: json['somethingToSitWith'] as String,
      contextSummary: json['contextSummary'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$TopicExegesisImplToJson(_$TopicExegesisImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'source': _$ExegesisSourceEnumMap[instance.source]!,
      'subject': instance.subject,
      'bigPicture': instance.bigPicture,
      'conceptDefinition': instance.conceptDefinition,
      'firstMention': instance.firstMention,
      'definingPassages': instance.definingPassages,
      'canonicalProgression': instance.canonicalProgression,
      'commonDistortions': instance.commonDistortions,
      'impliedTheologicalClaim': instance.impliedTheologicalClaim,
      'whatItCannotMean': instance.whatItCannotMean,
      'fromTextToLife': instance.fromTextToLife,
      'somethingToSitWith': instance.somethingToSitWith,
      'contextSummary': instance.contextSummary,
      'createdAt': instance.createdAt.toIso8601String(),
    };
