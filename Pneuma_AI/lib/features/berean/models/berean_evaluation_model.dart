import 'package:hive/hive.dart';

part 'berean_evaluation_model.g.dart';

// ═══════════════════════════════════════════════════════════════════
//  ROOT MODEL — BereanEvaluationModel (typeId: 30)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 30)
class BereanEvaluationModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String inputText;

  @HiveField(2)
  final String statementType;

  @HiveField(3)
  final String statement;

  @HiveField(4)
  final String summary;

  @HiveField(5)
  final String confidenceLevel;

  @HiveField(6)
  final String confidenceReason;

  @HiveField(7)
  final List<BereanScriptureRef> scriptures;

  @HiveField(8)
  final String broaderContext;

  @HiveField(9)
  final String statementAnalysis;

  @HiveField(10)
  final AlignmentVerdict alignmentVerdict;

  @HiveField(11)
  final InterpretiveTensions interpretiveTensions;

  @HiveField(12)
  final List<RhetoricalFlag> rhetoricalFlags;

  @HiveField(13)
  final String historicalPerspective;

  @HiveField(14)
  final List<ContextWarning> contextWarnings;

  @HiveField(15)
  final DoctrineClassification doctrineClassification;

  @HiveField(16)
  final bool escalationFlag;

  @HiveField(17)
  final String? pastoralWarning;

  @HiveField(18)
  final ExampleScenario exampleScenario;

  @HiveField(19)
  final String conclusion;

  @HiveField(20)
  final UserGuidance userGuidance;

  @HiveField(21)
  final DateTime createdAt;

  BereanEvaluationModel({
    required this.id,
    required this.inputText,
    required this.statementType,
    required this.statement,
    required this.summary,
    required this.confidenceLevel,
    required this.confidenceReason,
    required this.scriptures,
    required this.broaderContext,
    required this.statementAnalysis,
    required this.alignmentVerdict,
    required this.interpretiveTensions,
    required this.rhetoricalFlags,
    required this.historicalPerspective,
    required this.contextWarnings,
    required this.doctrineClassification,
    required this.escalationFlag,
    this.pastoralWarning,
    required this.exampleScenario,
    required this.conclusion,
    required this.userGuidance,
    required this.createdAt,
  });

  factory BereanEvaluationModel.fromJson(
    Map<String, dynamic> json, {
    required String id,
    required String inputText,
  }) {
    return BereanEvaluationModel(
      id: id,
      inputText: inputText,
      statementType: json['statementType'] ?? 'Doctrinal Claim',
      statement: json['statement'] ?? '',
      summary: json['summary'] ?? '',
      confidenceLevel: json['confidenceLevel'] ?? 'Moderate',
      confidenceReason: json['confidenceReason'] ?? '',
      scriptures: _parseScriptures(json['scriptures']),
      broaderContext: json['broaderContext'] ?? '',
      statementAnalysis: json['statementAnalysis'] ?? '',
      alignmentVerdict: AlignmentVerdict.fromJson(
        json['alignmentVerdict'] as Map<String, dynamic>? ?? {},
      ),
      interpretiveTensions: InterpretiveTensions.fromJson(
        json['interpretiveTensions'] as Map<String, dynamic>? ?? {},
      ),
      rhetoricalFlags: _parseRhetoricalFlags(json['rhetoricalFlags']),
      historicalPerspective: json['historicalPerspective'] ?? '',
      contextWarnings: _parseContextWarnings(json['contextWarnings']),
      doctrineClassification: DoctrineClassification.fromJson(
        json['doctrineClassification'] as Map<String, dynamic>? ?? {},
      ),
      escalationFlag: json['escalationFlag'] ?? false,
      pastoralWarning: json['pastoralWarning'],
      exampleScenario: ExampleScenario.fromJson(
        json['exampleScenario'] as Map<String, dynamic>? ?? {},
      ),
      conclusion: json['conclusion'] ?? '',
      userGuidance: UserGuidance.fromJson(
        json['userGuidance'] as Map<String, dynamic>? ?? {},
      ),
      createdAt: DateTime.now(),
    );
  }

  static List<BereanScriptureRef> _parseScriptures(dynamic list) {
    if (list is! List) return [];
    return list
        .map((e) => BereanScriptureRef.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static List<RhetoricalFlag> _parseRhetoricalFlags(dynamic list) {
    if (list is! List) return [];
    return list
        .map((e) => RhetoricalFlag.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static List<ContextWarning> _parseContextWarnings(dynamic list) {
    if (list is! List) return [];
    return list
        .map((e) => ContextWarning.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ═══════════════════════════════════════════════════════════════════
//  BereanScriptureRef (typeId: 31)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 31)
class BereanScriptureRef {
  @HiveField(0)
  final String reference;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final String explanation;

  @HiveField(3)
  final String context;

  @HiveField(4)
  final String supportsOrQualifies;

  BereanScriptureRef({
    required this.reference,
    required this.text,
    required this.explanation,
    required this.context,
    required this.supportsOrQualifies,
  });

  factory BereanScriptureRef.fromJson(Map<String, dynamic> json) {
    return BereanScriptureRef(
      reference: json['reference'] ?? '',
      text: json['text'] ?? '',
      explanation: json['explanation'] ?? '',
      context: json['context'] ?? '',
      supportsOrQualifies: json['supportsOrQualifies'] ?? 'Supports',
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  AlignmentVerdict (typeId: 32)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 32)
class AlignmentVerdict {
  @HiveField(0)
  final String label;

  @HiveField(1)
  final String score;

  @HiveField(2)
  final String oneLineVerdict;

  AlignmentVerdict({
    required this.label,
    required this.score,
    required this.oneLineVerdict,
  });

  factory AlignmentVerdict.fromJson(Map<String, dynamic> json) {
    return AlignmentVerdict(
      label: json['label'] ?? 'Context Dependent',
      score: json['score'] ?? 'Mixed',
      oneLineVerdict: json['oneLineVerdict'] ?? '',
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  InterpretiveTensions (typeId: 33)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 33)
class InterpretiveTensions {
  @HiveField(0)
  final InterpretiveView viewA;

  @HiveField(1)
  final InterpretiveView viewB;

  @HiveField(2)
  final String whereDiffer;

  @HiveField(3)
  final String whereAgree;

  InterpretiveTensions({
    required this.viewA,
    required this.viewB,
    required this.whereDiffer,
    required this.whereAgree,
  });

  factory InterpretiveTensions.fromJson(Map<String, dynamic> json) {
    return InterpretiveTensions(
      viewA: InterpretiveView.fromJson(
        json['viewA'] as Map<String, dynamic>? ?? {},
      ),
      viewB: InterpretiveView.fromJson(
        json['viewB'] as Map<String, dynamic>? ?? {},
      ),
      whereDiffer: json['whereTheyDiffer'] ?? json['whereDiffer'] ?? '',
      whereAgree: json['whereTheyAgree'] ?? json['whereAgree'] ?? '',
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  InterpretiveView (typeId: 34)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 34)
class InterpretiveView {
  @HiveField(0)
  final String tradition;

  @HiveField(1)
  final String argument;

  @HiveField(2)
  final List<String> scriptures;

  InterpretiveView({
    required this.tradition,
    required this.argument,
    required this.scriptures,
  });

  factory InterpretiveView.fromJson(Map<String, dynamic> json) {
    return InterpretiveView(
      tradition: json['label'] ?? json['tradition'] ?? '',
      argument: json['argument'] ?? '',
      scriptures: (json['scriptures'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  RhetoricalFlag (typeId: 35)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 35)
class RhetoricalFlag {
  @HiveField(0)
  final String flagType;

  @HiveField(1)
  final String explanation;

  @HiveField(2)
  final String corrective;

  RhetoricalFlag({
    required this.flagType,
    required this.explanation,
    required this.corrective,
  });

  factory RhetoricalFlag.fromJson(Map<String, dynamic> json) {
    return RhetoricalFlag(
      flagType: json['flagType'] ?? '',
      explanation: json['explanation'] ?? '',
      corrective: json['corrective'] ?? '',
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ContextWarning (typeId: 36)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 36)
class ContextWarning {
  @HiveField(0)
  final String misusedVerse;

  @HiveField(1)
  final String howMisused;

  @HiveField(2)
  final String correctReading;

  ContextWarning({
    required this.misusedVerse,
    required this.howMisused,
    required this.correctReading,
  });

  factory ContextWarning.fromJson(Map<String, dynamic> json) {
    return ContextWarning(
      misusedVerse: json['verse'] ?? json['misusedVerse'] ?? '',
      howMisused: json['misuse'] ?? json['howMisused'] ?? '',
      correctReading: json['correctReading'] ?? '',
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DoctrineClassification (typeId: 37)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 37)
class DoctrineClassification {
  @HiveField(0)
  final String tier;

  @HiveField(1)
  final String label;

  DoctrineClassification({
    required this.tier,
    required this.label,
  });

  factory DoctrineClassification.fromJson(Map<String, dynamic> json) {
    return DoctrineClassification(
      tier: json['tag'] ?? json['tier'] ?? 'Secondary Doctrine',
      label: json['explanation'] ?? json['label'] ?? '',
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ExampleScenario (typeId: 38)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 38)
class ExampleScenario {
  @HiveField(0)
  final String correctUse;

  @HiveField(1)
  final String incorrectUse;

  ExampleScenario({
    required this.correctUse,
    required this.incorrectUse,
  });

  factory ExampleScenario.fromJson(Map<String, dynamic> json) {
    return ExampleScenario(
      correctUse: json['correct'] ?? json['correctUse'] ?? '',
      incorrectUse: json['incorrect'] ?? json['incorrectUse'] ?? '',
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  UserGuidance (typeId: 39)
// ═══════════════════════════════════════════════════════════════════

@HiveType(typeId: 39)
class UserGuidance {
  @HiveField(0)
  final String action;

  @HiveField(1)
  final String practicalStep;

  @HiveField(2)
  final String prayerFocus;

  UserGuidance({
    required this.action,
    required this.practicalStep,
    required this.prayerFocus,
  });

  factory UserGuidance.fromJson(Map<String, dynamic> json) {
    return UserGuidance(
      action: json['action'] ?? '',
      practicalStep: json['practicalStep'] ?? '',
      prayerFocus: json['prayerFocus'] ?? '',
    );
  }
}
