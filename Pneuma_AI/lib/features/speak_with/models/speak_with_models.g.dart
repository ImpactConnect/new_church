// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'speak_with_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BiblicalFigure _$BiblicalFigureFromJson(Map<String, dynamic> json) =>
    BiblicalFigure(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['displayName'] as String,
      testament: $enumDecode(_$TestamentEnumMap, json['testament']),
      figureType: $enumDecode(_$FigureTypeEnumMap, json['figureType']),
      era: json['era'] as String,
      role: json['role'] as String,
      avatarEmoji: json['avatarEmoji'] as String,
      books: (json['books'] as List<dynamic>).map((e) => e as String).toList(),
      characterIntroduction: json['characterIntroduction'] as String,
      topicsTheyCanSpeak: (json['topicsTheyCanSpeak'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      topicLimits: (json['topicLimits'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      suggestedOpeningQuestions:
          (json['suggestedOpeningQuestions'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      availableSourceTiers: (json['availableSourceTiers'] as List<dynamic>)
          .map((e) => $enumDecode(_$SourceTierEnumMap, e))
          .toList(),
      corpus: FigureCorpus.fromJson(json['corpus'] as Map<String, dynamic>),
      isCurated: json['isCurated'] as bool? ?? false,
    );

Map<String, dynamic> _$BiblicalFigureToJson(BiblicalFigure instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'displayName': instance.displayName,
      'testament': _$TestamentEnumMap[instance.testament]!,
      'figureType': _$FigureTypeEnumMap[instance.figureType]!,
      'era': instance.era,
      'role': instance.role,
      'avatarEmoji': instance.avatarEmoji,
      'books': instance.books,
      'characterIntroduction': instance.characterIntroduction,
      'topicsTheyCanSpeak': instance.topicsTheyCanSpeak,
      'topicLimits': instance.topicLimits,
      'suggestedOpeningQuestions': instance.suggestedOpeningQuestions,
      'availableSourceTiers': instance.availableSourceTiers
          .map((e) => _$SourceTierEnumMap[e]!)
          .toList(),
      'corpus': instance.corpus.toJson(),
      'isCurated': instance.isCurated,
    };

const _$TestamentEnumMap = {
  Testament.ot: 'ot',
  Testament.nt: 'nt',
};

const _$FigureTypeEnumMap = {
  FigureType.author: 'author',
  FigureType.character: 'character',
  FigureType.both: 'both',
};

const _$SourceTierEnumMap = {
  SourceTier.scripture: '1',
  SourceTier.historical: '2',
  SourceTier.cultural: '3',
  SourceTier.scholarly: '4',
};

FigureCorpus _$FigureCorpusFromJson(Map<String, dynamic> json) => FigureCorpus(
      tier1Scripture: json['tier1Scripture'] as String,
      tier2Historical: json['tier2Historical'] as String?,
      tier3Cultural: json['tier3Cultural'] as String?,
      tier4Theological: json['tier4Theological'] as String?,
      personalityProfile: json['personalityProfile'] as String,
      knownRelationships: (json['knownRelationships'] as List<dynamic>)
          .map((e) => FigureRelationship.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FigureCorpusToJson(FigureCorpus instance) =>
    <String, dynamic>{
      'tier1Scripture': instance.tier1Scripture,
      'tier2Historical': instance.tier2Historical,
      'tier3Cultural': instance.tier3Cultural,
      'tier4Theological': instance.tier4Theological,
      'personalityProfile': instance.personalityProfile,
      'knownRelationships':
          instance.knownRelationships.map((e) => e.toJson()).toList(),
    };

FigureRelationship _$FigureRelationshipFromJson(Map<String, dynamic> json) =>
    FigureRelationship(
      person: json['person'] as String,
      nature: json['nature'] as String,
      keyMoments: json['keyMoments'] as String,
    );

Map<String, dynamic> _$FigureRelationshipToJson(FigureRelationship instance) =>
    <String, dynamic>{
      'person': instance.person,
      'nature': instance.nature,
      'keyMoments': instance.keyMoments,
    };

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
      id: json['id'] as String,
      isUser: json['isUser'] as bool,
      message: json['message'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      speakerName: json['speakerName'] as String?,
      scriptureRefs: (json['scriptureRefs'] as List<dynamic>?)
          ?.map((e) => ScriptureRef.fromJson(e as Map<String, dynamic>))
          .toList(),
      contextualSources: (json['contextualSources'] as List<dynamic>?)
          ?.map((e) => ContextualSource.fromJson(e as Map<String, dynamic>))
          .toList(),
      primarySourceTier:
          $enumDecodeNullable(_$SourceTierEnumMap, json['primarySourceTier']),
      isAtLimit: json['isAtLimit'] as bool? ?? false,
      limitAcknowledgement: json['limitAcknowledgement'] as String?,
      emotionalRegister: $enumDecodeNullable(
          _$EmotionalRegisterEnumMap, json['emotionalRegister']),
      suggestedFollowUps: (json['suggestedFollowUps'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      figureBMessage: json['figureBMessage'] == null
          ? null
          : ChatMessage.fromJson(
              json['figureBMessage'] as Map<String, dynamic>),
      harmonySummary: json['harmonySummary'] as String?,
      tensionNote: json['tensionNote'] as String?,
    );

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'isUser': instance.isUser,
      'message': instance.message,
      'sentAt': instance.sentAt.toIso8601String(),
      'speakerName': instance.speakerName,
      'scriptureRefs': instance.scriptureRefs?.map((e) => e.toJson()).toList(),
      'contextualSources':
          instance.contextualSources?.map((e) => e.toJson()).toList(),
      'primarySourceTier': _$SourceTierEnumMap[instance.primarySourceTier],
      'isAtLimit': instance.isAtLimit,
      'limitAcknowledgement': instance.limitAcknowledgement,
      'emotionalRegister':
          _$EmotionalRegisterEnumMap[instance.emotionalRegister],
      'suggestedFollowUps': instance.suggestedFollowUps,
      'figureBMessage': instance.figureBMessage?.toJson(),
      'harmonySummary': instance.harmonySummary,
      'tensionNote': instance.tensionNote,
    };

const _$EmotionalRegisterEnumMap = {
  EmotionalRegister.reflective: 'Reflective',
  EmotionalRegister.vulnerable: 'Vulnerable',
  EmotionalRegister.passionate: 'Passionate',
  EmotionalRegister.joyful: 'Joyful',
  EmotionalRegister.grieving: 'Grieving',
  EmotionalRegister.firm: 'Firm',
  EmotionalRegister.wondering: 'Wondering',
  EmotionalRegister.grateful: 'Grateful',
  EmotionalRegister.troubled: 'Troubled',
  EmotionalRegister.peaceful: 'Peaceful',
};

ScriptureRef _$ScriptureRefFromJson(Map<String, dynamic> json) => ScriptureRef(
      reference: json['reference'] as String,
      verseText: json['verseText'] as String?,
      whyCited: json['whyCited'] as String,
      sourceTier: json['sourceTier'] as String,
      isVerified: json['isVerified'] as bool? ?? true,
    );

Map<String, dynamic> _$ScriptureRefToJson(ScriptureRef instance) =>
    <String, dynamic>{
      'reference': instance.reference,
      'verseText': instance.verseText,
      'whyCited': instance.whyCited,
      'sourceTier': instance.sourceTier,
      'isVerified': instance.isVerified,
    };

ContextualSource _$ContextualSourceFromJson(Map<String, dynamic> json) =>
    ContextualSource(
      tier: $enumDecode(_$SourceTierEnumMap, json['tier']),
      category: json['category'] as String,
      sourceLabel: json['sourceLabel'] as String,
      contextNote: json['contextNote'] as String,
      edificationJustification: json['edificationJustification'] as String?,
      isAllowlisted: json['isAllowlisted'] as bool? ?? true,
    );

Map<String, dynamic> _$ContextualSourceToJson(ContextualSource instance) =>
    <String, dynamic>{
      'tier': _$SourceTierEnumMap[instance.tier]!,
      'category': instance.category,
      'sourceLabel': instance.sourceLabel,
      'contextNote': instance.contextNote,
      'edificationJustification': instance.edificationJustification,
      'isAllowlisted': instance.isAllowlisted,
    };

SpeakWithConversation _$SpeakWithConversationFromJson(
        Map<String, dynamic> json) =>
    SpeakWithConversation(
      id: json['id'] as String,
      mode: $enumDecode(_$ConversationModeEnumMap, json['mode']),
      figureA: BiblicalFigure.fromJson(json['figureA'] as Map<String, dynamic>),
      figureB: json['figureB'] == null
          ? null
          : BiblicalFigure.fromJson(json['figureB'] as Map<String, dynamic>),
      title: json['title'] as String?,
      messages: (json['messages'] as List<dynamic>)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
      passageContext: json['passageContext'] as String?,
      studyContext: json['studyContext'] as String?,
      askRabbiContext: json['askRabbiContext'] as String?,
    );

Map<String, dynamic> _$SpeakWithConversationToJson(
        SpeakWithConversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mode': _$ConversationModeEnumMap[instance.mode]!,
      'figureA': instance.figureA.toJson(),
      'figureB': instance.figureB?.toJson(),
      'title': instance.title,
      'messages': instance.messages.map((e) => e.toJson()).toList(),
      'createdAt': instance.createdAt.toIso8601String(),
      'lastMessageAt': instance.lastMessageAt.toIso8601String(),
      'passageContext': instance.passageContext,
      'studyContext': instance.studyContext,
      'askRabbiContext': instance.askRabbiContext,
    };

const _$ConversationModeEnumMap = {
  ConversationMode.author: 'author',
  ConversationMode.character: 'character',
  ConversationMode.dual: 'dual',
};
