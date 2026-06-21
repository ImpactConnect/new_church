import 'package:json_annotation/json_annotation.dart';

part 'speak_with_models.g.dart';

enum ConversationMode { author, character, dual }
enum Testament { ot, nt }
enum FigureType { author, character, both }

enum SourceTier {
  @JsonValue("1")
  scripture,
  @JsonValue("2")
  historical,
  @JsonValue("3")
  cultural,
  @JsonValue("4")
  scholarly
}

enum EmotionalRegister {
  @JsonValue('Reflective') reflective,
  @JsonValue('Vulnerable') vulnerable,
  @JsonValue('Passionate') passionate,
  @JsonValue('Joyful') joyful,
  @JsonValue('Grieving') grieving,
  @JsonValue('Firm') firm,
  @JsonValue('Wondering') wondering,
  @JsonValue('Grateful') grateful,
  @JsonValue('Troubled') troubled,
  @JsonValue('Peaceful') peaceful,
}

@JsonSerializable(explicitToJson: true)
class BiblicalFigure {
  final String id;
  final String name;
  final String displayName;
  final Testament testament;
  final FigureType figureType;
  final String era;
  final String role;
  final String avatarEmoji;
  final List<String> books;
  final String characterIntroduction;
  final List<String> topicsTheyCanSpeak;
  final List<String> topicLimits;
  final List<String> suggestedOpeningQuestions;
  final List<SourceTier> availableSourceTiers;
  final FigureCorpus corpus;
  @JsonKey(defaultValue: false)
  final bool isCurated;

  BiblicalFigure({
    required this.id,
    required this.name,
    required this.displayName,
    required this.testament,
    required this.figureType,
    required this.era,
    required this.role,
    required this.avatarEmoji,
    required this.books,
    required this.characterIntroduction,
    required this.topicsTheyCanSpeak,
    required this.topicLimits,
    required this.suggestedOpeningQuestions,
    required this.availableSourceTiers,
    required this.corpus,
    this.isCurated = false,
  });

  factory BiblicalFigure.fromJson(Map<String, dynamic> json) => _$BiblicalFigureFromJson(json);
  Map<String, dynamic> toJson() => _$BiblicalFigureToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FigureCorpus {
  final String tier1Scripture;
  final String? tier2Historical;
  final String? tier3Cultural;
  final String? tier4Theological;
  final String personalityProfile;
  final List<FigureRelationship> knownRelationships;

  FigureCorpus({
    required this.tier1Scripture,
    this.tier2Historical,
    this.tier3Cultural,
    this.tier4Theological,
    required this.personalityProfile,
    required this.knownRelationships,
  });

  factory FigureCorpus.fromJson(Map<String, dynamic> json) => _$FigureCorpusFromJson(json);
  Map<String, dynamic> toJson() => _$FigureCorpusToJson(this);
}

@JsonSerializable()
class FigureRelationship {
  final String person;
  final String nature;
  final String keyMoments;

  FigureRelationship({
    required this.person,
    required this.nature,
    required this.keyMoments,
  });

  factory FigureRelationship.fromJson(Map<String, dynamic> json) => _$FigureRelationshipFromJson(json);
  Map<String, dynamic> toJson() => _$FigureRelationshipToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ChatMessage {
  final String id;
  final bool isUser;
  final String message;
  final DateTime sentAt;
  
  final String? speakerName;
  final List<ScriptureRef>? scriptureRefs;
  final List<ContextualSource>? contextualSources;
  final SourceTier? primarySourceTier;
  @JsonKey(defaultValue: false)
  final bool isAtLimit;
  final String? limitAcknowledgement;
  final EmotionalRegister? emotionalRegister;
  final List<String>? suggestedFollowUps;
  
  final ChatMessage? figureBMessage;
  final String? harmonySummary;
  final String? tensionNote;

  ChatMessage({
    required this.id,
    required this.isUser,
    required this.message,
    required this.sentAt,
    this.speakerName,
    this.scriptureRefs,
    this.contextualSources,
    this.primarySourceTier,
    this.isAtLimit = false,
    this.limitAcknowledgement,
    this.emotionalRegister,
    this.suggestedFollowUps,
    this.figureBMessage,
    this.harmonySummary,
    this.tensionNote,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
}

@JsonSerializable()
class ScriptureRef {
  final String reference;
  final String? verseText;
  final String whyCited;
  final String sourceTier;
  @JsonKey(defaultValue: true)
  final bool isVerified;

  ScriptureRef({
    required this.reference,
    this.verseText,
    required this.whyCited,
    required this.sourceTier,
    this.isVerified = true,
  });

  factory ScriptureRef.fromJson(Map<String, dynamic> json) => _$ScriptureRefFromJson(json);
  Map<String, dynamic> toJson() => _$ScriptureRefToJson(this);
}

@JsonSerializable()
class ContextualSource {
  final SourceTier tier;
  final String category;
  final String sourceLabel;
  final String contextNote;
  final String? edificationJustification;
  @JsonKey(defaultValue: true)
  final bool isAllowlisted;

  ContextualSource({
    required this.tier,
    required this.category,
    required this.sourceLabel,
    required this.contextNote,
    this.edificationJustification,
    this.isAllowlisted = true,
  });

  factory ContextualSource.fromJson(Map<String, dynamic> json) => _$ContextualSourceFromJson(json);
  Map<String, dynamic> toJson() => _$ContextualSourceToJson(this);
}

@JsonSerializable(explicitToJson: true)
class SpeakWithConversation {
  final String id;
  final ConversationMode mode;
  final BiblicalFigure figureA;
  final BiblicalFigure? figureB;
  final String? title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final String? passageContext;
  final String? studyContext;
  final String? askRabbiContext;

  SpeakWithConversation({
    required this.id,
    required this.mode,
    required this.figureA,
    this.figureB,
    this.title,
    required this.messages,
    required this.createdAt,
    required this.lastMessageAt,
    this.passageContext,
    this.studyContext,
    this.askRabbiContext,
  });

  factory SpeakWithConversation.fromJson(Map<String, dynamic> json) => _$SpeakWithConversationFromJson(json);
  Map<String, dynamic> toJson() => _$SpeakWithConversationToJson(this);
}
