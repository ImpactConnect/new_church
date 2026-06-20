import 'package:uuid/uuid.dart';
import '../models/exegesis_result_model.dart';
import '../models/exegesis_result_v2_model.dart';

/// Service for migrating v1 exegesis results to v2 format
class ExegesisMigrationService {
  /// Migrate a v1 ExegesisResult to v2 ExegesisResultV2
  ExegesisResultV2 migrateV1ToV2({
    required ExegesisResult v1Result,
    required ExegesisMode targetMode,
  }) {
    return ExegesisResultV2(
      id: const Uuid().v4(),
      entryType: _mapEntryType(v1Result.entryType),
      subject: v1Result.subject,
      mode: targetMode,
      createdAt: v1Result.createdAt ?? DateTime.now(),
      bigPicture: v1Result.executiveSummary,
      historicalMoment: _buildHistoricalMoment(v1Result),
      keyWord: _extractKeyWord(v1Result),
      whatWasBeingSaid: _buildWhatWasBeingSaid(v1Result),
      inTheWholeStory: _buildInTheWholeStory(v1Result),
      echoes: _mapCrossReferences(v1Result.crossReferences),
      whatThisMeansForYou: _buildWhatThisMeansForYou(v1Result),
      somethingToSitWith: _generateMeditationPrompt(v1Result),
      // Go Deep fields (only if targetMode is goDeep)
      wordStudies: targetMode == ExegesisMode.goDeep
          ? _mapWordStudies(v1Result.languageStudy)
          : null,
      interpretiveTensions: targetMode == ExegesisMode.goDeep
          ? _mapInterpretiveTensions(v1Result.scholarlyDebates)
          : null,
      grammaticalHighlights: targetMode == ExegesisMode.goDeep
          ? v1Result.grammaticalNotes
          : null,
      covenantContext: targetMode == ExegesisMode.goDeep
          ? _buildCovenantContext(v1Result)
          : null,
    );
  }

  // ── Entry Type Mapping ──

  ExegesisEntryType _mapEntryType(String v1Type) {
    final normalized = v1Type.toLowerCase().replaceAll(' ', '');
    if (normalized.contains('passage')) return ExegesisEntryType.passage;
    if (normalized.contains('book')) return ExegesisEntryType.bibleBook;
    if (normalized.contains('character')) return ExegesisEntryType.bibleCharacter;
    if (normalized.contains('theme')) return ExegesisEntryType.theme;
    return ExegesisEntryType.singleVerse;
  }

  // ── Field Mappers ──

  String _buildHistoricalMoment(ExegesisResult v1) {
    final parts = <String>[];
    
    if (v1.historicalContext.author.isNotEmpty) {
      parts.add('Written by ${v1.historicalContext.author}');
    }
    
    if (v1.historicalContext.audience.isNotEmpty) {
      parts.add('to ${v1.historicalContext.audience}');
    }
    
    if (v1.historicalContext.date.isNotEmpty) {
      parts.add('around ${v1.historicalContext.date}');
    }
    
    if (v1.historicalContext.politicalSetting.isNotEmpty) {
      parts.add('during ${v1.historicalContext.politicalSetting}');
    }
    
    if (parts.isEmpty) {
      return 'Historical context not available';
    }
    
    return parts.join(' ');
  }

  KeyWordMoment? _extractKeyWord(ExegesisResult v1) {
    if (v1.languageStudy.isEmpty) return null;
    
    // Take the first word study as the key word
    final firstWord = v1.languageStudy.first;
    
    return KeyWordMoment(
      originalScript: firstWord.word,
      transliteration: firstWord.transliteration,
      strongsNumber: firstWord.strongsNumber.isNotEmpty 
          ? firstWord.strongsNumber 
          : null,
      meaning: firstWord.definition,
      whyItMatters: firstWord.usageNote.isNotEmpty 
          ? firstWord.usageNote 
          : 'This word is central to understanding the passage.',
    );
  }

  String _buildWhatWasBeingSaid(ExegesisResult v1) {
    final parts = <String>[];
    
    // Use theological meaning as primary source
    if (v1.theologicalMeaning.centralThesis != null && 
        v1.theologicalMeaning.centralThesis!.isNotEmpty) {
      parts.add(v1.theologicalMeaning.centralThesis!);
    }
    
    // Add literary structure insights
    if (v1.literaryStructure.structure.isNotEmpty) {
      parts.add(v1.literaryStructure.structure);
    }
    
    if (parts.isEmpty) {
      return 'The passage communicates important theological truths.';
    }
    
    return parts.join(' ');
  }

  String _buildInTheWholeStory(ExegesisResult v1) {
    final parts = <String>[];
    
    if (v1.theologicalMeaning.metaNarrativePlacement.isNotEmpty) {
      parts.add(v1.theologicalMeaning.metaNarrativePlacement);
    }
    
    if (v1.theologicalMeaning.christologicalConnection.isNotEmpty) {
      parts.add(v1.theologicalMeaning.christologicalConnection);
    }
    
    if (parts.isEmpty) {
      return 'This passage fits within God\'s redemptive plan.';
    }
    
    return parts.join(' ');
  }

  List<EchoItem> _mapCrossReferences(List<ExegesisCrossReference> v1Refs) {
    return v1Refs.map((ref) {
      return EchoItem(
        reference: ref.reference,
        connectionType: _mapConnectionType(ref.connectionType),
        explanation: ref.explanation,
      );
    }).toList();
  }

  EchoConnectionType _mapConnectionType(String v1Type) {
    final normalized = v1Type.toLowerCase();
    if (normalized.contains('allusion')) return EchoConnectionType.allusion;
    if (normalized.contains('fulfillment')) return EchoConnectionType.fulfillment;
    if (normalized.contains('contrast')) return EchoConnectionType.contrast;
    if (normalized.contains('development')) return EchoConnectionType.development;
    return EchoConnectionType.parallel;
  }

  String _buildWhatThisMeansForYou(ExegesisResult v1) {
    if (v1.applicationBridge.modernApplication.isNotEmpty) {
      return v1.applicationBridge.modernApplication;
    }
    
    if (v1.applicationBridge.timelessPrinciple.isNotEmpty) {
      return v1.applicationBridge.timelessPrinciple;
    }
    
    return 'This passage has profound implications for your life today.';
  }

  String _generateMeditationPrompt(ExegesisResult v1) {
    // Generate a reflective question based on the content
    if (v1.applicationBridge.timelessPrinciple.isNotEmpty) {
      return 'How does ${v1.applicationBridge.timelessPrinciple.toLowerCase()} shape your understanding of God?';
    }
    
    return 'How is God inviting you to respond to this truth?';
  }

  // ── Go Deep Field Mappers ──

  List<WordStudyItem>? _mapWordStudies(List<ExegesisWordStudy> v1Studies) {
    if (v1Studies.isEmpty) return null;
    
    return v1Studies.map((study) {
      return WordStudyItem(
        word: study.word,
        transliteration: study.transliteration,
        strongsNumber: study.strongsNumber.isNotEmpty ? study.strongsNumber : null,
        definition: study.definition,
        semanticRange: study.semanticRange,
        usageExamples: study.verseRef != null ? [study.verseRef!] : [],
        whyItMatters: study.usageNote.isNotEmpty 
            ? study.usageNote 
            : 'Understanding this word enriches our interpretation.',
        translationVariance: study.translationComparison,
      );
    }).toList();
  }

  List<InterpretiveTension>? _mapInterpretiveTensions(
    List<ExegesisScholarlyDebate> v1Debates,
  ) {
    if (v1Debates.isEmpty) return null;
    
    return v1Debates.map((debate) {
      return InterpretiveTension(
        question: debate.topic,
        positionA: TensionPosition(
          label: 'View A',
          explanation: debate.positionA,
          supportingVerses: [],
        ),
        positionB: TensionPosition(
          label: 'View B',
          explanation: debate.positionB,
          supportingVerses: [],
        ),
        commonGround: debate.commonGround,
      );
    }).toList();
  }

  CovenantContext? _buildCovenantContext(ExegesisResult v1) {
    if (v1.theologicalMeaning.metaNarrativePlacement.isEmpty &&
        v1.theologicalMeaning.christologicalConnection.isEmpty) {
      return null;
    }
    
    return CovenantContext(
      covenantFramework: _determineCovenantFramework(v1),
      redemptiveHistoricalPlacement: v1.theologicalMeaning.metaNarrativePlacement,
      christologicalConnection: v1.theologicalMeaning.christologicalConnection,
    );
  }

  String _determineCovenantFramework(ExegesisResult v1) {
    // Simple heuristic based on subject
    final subject = v1.subject.toLowerCase();
    
    if (subject.contains('genesis') || 
        subject.contains('exodus') || 
        subject.contains('leviticus')) {
      return 'Mosaic Covenant';
    }
    
    if (subject.contains('matthew') || 
        subject.contains('mark') || 
        subject.contains('luke') || 
        subject.contains('john') ||
        subject.contains('acts') ||
        subject.contains('romans') ||
        subject.contains('corinthians') ||
        subject.contains('galatians') ||
        subject.contains('ephesians') ||
        subject.contains('philippians') ||
        subject.contains('colossians') ||
        subject.contains('thessalonians') ||
        subject.contains('timothy') ||
        subject.contains('titus') ||
        subject.contains('philemon') ||
        subject.contains('hebrews') ||
        subject.contains('james') ||
        subject.contains('peter') ||
        subject.contains('jude') ||
        subject.contains('revelation')) {
      return 'New Covenant';
    }
    
    return 'Old Testament Context';
  }
}
