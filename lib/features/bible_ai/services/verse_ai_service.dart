import 'dart:convert';
import 'dart:developer' as developer;
import '../data/models/ai/ai_models.dart';
import '../data/models/bible/bible_version.dart';
import '../data/repositories/prompt_repository.dart';
import 'ai_service.dart';

/// ILLUMINE — the Verse Level AI engine for illuminare.
///
/// Provides a shared system prompt and 5 mode-specific user prompts
/// for Explain, Context, Cross-Reference, Keywords, and Application modes.
class VerseAiService {
  final AiService _aiService;

  VerseAiService({AiService? aiService}) : _aiService = aiService ?? AiService();

  // ═══════════════════════════════════════════════════════════════════
  //  SYSTEM PROMPT — shared across all 5 modes
  // ═══════════════════════════════════════════════════════════════════

  static const String _systemPrompt = '''
You are ILLUMINE — a scripture exposition engine built into illuminare.
Your purpose is to help believers understand the Bible with scholarly
depth, pastoral sensitivity, and hermeneutical integrity.

═══════════════════════════════════
HERMENEUTICAL COMMITMENTS
═══════════════════════════════════
1. GRAMMATICAL-HISTORICAL METHOD
   Determine what the text meant to its original author and audience
   before asking what it means today. Never read modern frameworks
   backward into ancient texts.

2. SCRIPTURE INTERPRETS SCRIPTURE
   Use the broader canon to illuminate the specific verse. Let
   clearer passages shed light on more difficult ones.

3. DISTINGUISH SHARPLY
   - What the text SAYS (observation)
   - What it MEANT in original context (interpretation)
   - What it MEANS for us today (application)
   These are three separate operations. Label them as such.

4. MULTI-VERSE RULE
   When IS_MULTI is true, treat the selected verses as a UNIFIED
   PASSAGE — one coherent argument or narrative unit. Identify the
   passage's main thrust and analyse the verses in relation to each
   other. Do NOT analyse them as isolated independent verses.

5. ORIGINAL LANGUAGE PRECISION
   Always engage the Hebrew (OT), Greek (NT), or Aramaic text where
   relevant. Cite Strong's numbers. Explain translation choices
   where they significantly affect meaning.

6. VERSE AUTHENTICITY
   The user has provided the verse text directly.
   Use THIS text as your primary source. Do not rely on recall.
   Never fabricate or alter the provided verse text.

7. CONFIDENCE CALIBRATION
   Be certain where the text is clear. Be honest where scholars
   genuinely disagree. Signal the difference explicitly.

═══════════════════════════════════
OUTPUT RULES
═══════════════════════════════════
- Return ONLY valid JSON. No markdown. No preamble. No text outside JSON.
- Never fabricate verse references or Strong's numbers.
- Every cross-reference must be a real, checkable Bible reference.
- Tone: scholarly but accessible — write for a serious Bible student,
  not a seminary professor.
- If a field cannot be determined with confidence, use null, not a
  fabricated answer.
''';

  // ═══════════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════════

  /// Analyse the given verse(s) in the specified mode.
  Future<dynamic> analyse({
    required VerseFeature mode,
    required String verseRef,
    required String verseText,
    required BibleVersion translation,
    bool isMultiVerse = false,
  }) async {
    final repo = PromptRepository();
    final systemPrompt = await repo.getPrompt('illumine_system_prompt') ?? _systemPrompt;

    String modeKeySuffix;
    switch (mode) {
      case VerseFeature.explain: modeKeySuffix = 'explain'; break;
      case VerseFeature.context: modeKeySuffix = 'context'; break;
      case VerseFeature.crossRefs: modeKeySuffix = 'cross_ref'; break;
      case VerseFeature.keyWord: modeKeySuffix = 'keywords'; break;
      case VerseFeature.application: modeKeySuffix = 'application'; break;
    }

    final promptKey = 'illumine_$modeKeySuffix';
    final customPromptTemplate = await repo.getPrompt(promptKey);

    String userPrompt;
    if (customPromptTemplate != null && customPromptTemplate.isNotEmpty) {
      userPrompt = customPromptTemplate
          .replaceAll('{{verseRef}}', verseRef)
          .replaceAll('{{verseText}}', verseText)
          .replaceAll('{{translation}}', translation.name)
          .replaceAll('{{multi}}', isMultiVerse.toString());
    } else {
      userPrompt = _buildUserPrompt(
        mode: mode,
        verseRef: verseRef,
        verseText: verseText,
        translation: translation.name,
        isMulti: isMultiVerse,
      );
    }

    developer.log('=== ILLUMINE [$mode] SYSTEM ===\\n$systemPrompt',
        name: 'ILLUMINE');
    developer.log('=== ILLUMINE [$mode] USER ===\\n$userPrompt',
        name: 'ILLUMINE');

    final responseText = await _aiService.getAiResponse(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
    );

    if (responseText.isEmpty) throw Exception('No response from ILLUMINE');

    developer.log(responseText, name: 'ILLUMINE_RAW_${mode.name}');

    final data = jsonDecode(responseText);
    final normalized = _normalizeKeys(Map<String, dynamic>.from(data));
    return _parse(mode, normalized);
  }

  // ═══════════════════════════════════════════════════════════════════
  //  USER PROMPT BUILDERS
  // ═══════════════════════════════════════════════════════════════════

  String _buildUserPrompt({
    required VerseFeature mode,
    required String verseRef,
    required String verseText,
    required String translation,
    required bool isMulti,
  }) {
    switch (mode) {
      case VerseFeature.explain:
        return _explainPrompt(verseRef, verseText, translation, isMulti);
      case VerseFeature.context:
        return _contextPrompt(verseRef, verseText, translation, isMulti);
      case VerseFeature.crossRefs:
        return _crossRefPrompt(verseRef, verseText, translation, isMulti);
      case VerseFeature.keyWord:
        return _keywordsPrompt(verseRef, verseText, translation, isMulti);
      case VerseFeature.application:
        return _applicationPrompt(verseRef, verseText, translation, isMulti);
    }
  }

  String _explainPrompt(String ref, String text, String tr, bool multi) => '''
Provide a complete verse-level exposition of $ref.

Verse text ($tr): "$text"
Multi-verse selection: $multi

{
  "verseReference": "Exact reference as provided",
  "oneLineSummary": "The single most important insight from this verse in one clear sentence",
  "connectedThoughtRange": "The broader passage this verse belongs to. Format: 'Book Chapter:StartVerse-EndVerse, one sentence describing the speaker, audience, and what the passage is doing.'",
  "speaker": "Who is speaking these words? If narration, identify the narrator and their perspective.",
  "audience": "Who is the immediate audience?",
  "historicalContext": "The historical, political, and social world of the author and original audience. Minimum 60 words.",
  "literaryContext": "The genre of the book, the literary function of this verse within its chapter and book, and any literary devices.",
  "explanation": "The core theological exposition of the verse. Minimum 100 words. Be specific to THIS verse.",
  "keyTerms": [
    {
      "term": "English word from the verse",
      "originalWord": "Original script (Hebrew/Greek/Aramaic)",
      "transliteration": "Romanised phonetic",
      "strongsNumber": "H#### or G####",
      "definition": "Core lexical meaning",
      "whyItMatters": "Why this specific word choice shapes the meaning of the verse"
    }
  ],
  "supportingScriptures": [
    {
      "reference": "Book Chapter:Verse",
      "text": "Verse text, or null if uncertain",
      "connection": "How this verse illuminates or confirms the exposition above"
    }
  ],
  "covenant": [
    {
      "covenantName": "e.g. Abrahamic | Mosaic | Davidic | New Covenant",
      "applicability": "Direct | Principle-Based | Historical | Fulfilled",
      "explanation": "How this verse relates to this covenant framework"
    }
  ],
  "studyPrompt": "A single thought-provoking question for the user to meditate on"
}''';

  String _contextPrompt(String ref, String text, String tr, bool multi) => '''
Situate $ref within its surrounding passage and broader canonical context.

Verse text ($tr): "$text"
Multi-verse selection: $multi

{
  "verseReference": "Exact reference as provided",
  "oneLineSummary": "One sentence: what does knowing the context change about how this verse is read?",
  "immediateContextBefore": "What are the 2-5 verses immediately before this verse doing? Minimum 60 words.",
  "immediateContextAfter": "What are the 2-5 verses immediately after this verse doing? Minimum 60 words.",
  "chapterTheme": "The single dominant theme or argument of the chapter.",
  "speaker": "Who is speaking? Identify them fully.",
  "audience": "The immediate audience of the passage.",
  "literaryType": "The genre of this book and the specific literary form of this passage.",
  "culturalBackgroundInsight": "The specific cultural, religious, or historical background. Minimum 60 words.",
  "culturalInterpretiveImpact": "How does knowing this cultural background change or deepen the interpretation?",
  "commonMisunderstandings": [
    {
      "misunderstanding": "What the verse is commonly misread as saying",
      "whyItHappens": "Why this misreading is so common",
      "correction": "What the verse actually means in context",
      "correctiveVerse": "A scripture reference that helps correct the misreading, or null"
    }
  ],
  "nearbyVerseQuote": {
    "reference": "The most illuminating nearby verse to quote",
    "text": "Verse text or null",
    "relevance": "Why this specific nearby verse is the most important one"
  },
  "studyPrompt": "A thought-provoking question about how the context changes understanding"
}''';

  String _crossRefPrompt(String ref, String text, String tr, bool multi) => '''
Generate a canonical cross-reference map for $ref.

Verse text ($tr): "$text"
Multi-verse selection: $multi

{
  "verseReference": "Exact reference as provided",
  "oneLineSummary": "One sentence: what is the central theological thread that connects this verse to the wider canon?",
  "centralTheme": "The primary theological theme or concept in this verse. Be specific.",
  "references": [
    {
      "reference": "Book Chapter:Verse or range",
      "verseText": "Actual verse text, or null if uncertain",
      "connectionType": "One of: Parallel | Fulfillment | Allusion | Contrast | Development | Foundation",
      "connectionStrength": "One of: Strong | Moderate",
      "connection": "A specific explanation of HOW this reference connects. Minimum 40 words.",
      "testament": "OT | NT"
    }
  ],
  "canonicalThread": "A paragraph tracing how this theme develops from its first appearance through to its completion. Minimum 80 words.",
  "studyPrompt": "A question that invites the user to trace this thread further on their own"
}''';

  String _keywordsPrompt(String ref, String text, String tr, bool multi) => '''
Conduct a biblical word study for the theologically significant terms in $ref.

Verse text ($tr): "$text"
Multi-verse selection: $multi

{
  "verseReference": "Exact reference as provided",
  "oneLineSummary": "One sentence: what do the original language words in this verse reveal that a surface reading misses?",
  "language": "Hebrew | Greek | Aramaic | Mixed",
  "keywords": [
    {
      "word": "The English word as it appears in the provided translation",
      "originalWord": "Original script (Hebrew/Greek/Aramaic)",
      "transliteration": "Romanised phonetic spelling",
      "strongsNumber": "H#### for Hebrew, G#### for Greek — REQUIRED",
      "partOfSpeech": "Verb | Noun | Adjective | Adverb | Preposition | etc.",
      "definition": "The full lexical definition",
      "usageInVerse": "How this specific word functions in this specific verse",
      "usageElsewhere": "2-3 other significant uses of this word in scripture",
      "theologicalSignificance": "Why does it matter that this SPECIFIC word was chosen here?",
      "translationVariance": "How do major translations render this word? Or null if consistent.",
      "crossReference": "The single most illuminating verse where this same word is used"
    }
  ],
  "studyPrompt": "A question that invites the user to sit with one of these words in meditation"
}''';

  String _applicationPrompt(String ref, String text, String tr, bool multi) => '''
Generate a structured application guide for $ref.

Verse text ($tr): "$text"
Multi-verse selection: $multi

CRITICAL INSTRUCTION:
Before generating applications, determine: Is this verse universally
applicable to all believers today, or was it addressed to a specific
audience at a specific historical moment? Applications must respect
this scope.

{
  "verseReference": "Exact reference as provided",
  "oneLineSummary": "One sentence: what is the timeless principle this verse calls believers to live by?",
  "centralTruth": "The theological truth at the heart of this verse.",
  "applicabilityScope": {
    "scope": "Universal | Historical-Specific | Principle-Based",
    "explanation": "Who was this originally addressed to, and on what basis is it applicable today?"
  },
  "generalApplication": "The core application that transcends all contexts. 50+ words.",
  "applicationAreas": {
    "personal": "How does this verse apply to the individual believer's inner life?",
    "family": "How does this verse apply to family relationships?",
    "church": "How does this verse apply to the gathered community?",
    "workplace": "How does this verse speak to a believer's work?",
    "society": "How does this verse speak to how believers engage the wider world?"
  },
  "commonMisapplications": [
    {
      "misapplication": "The specific wrong application commonly made",
      "whoUsesIt": "What context or tradition typically applies the verse this way",
      "whyItsWrong": "The exegetical reason this application is incorrect",
      "correctApplication": "The application that correctly honours the verse's original intent",
      "correctiveVerse": "A scripture reference that helps correct this, or null"
    }
  ],
  "supportingVerse": {
    "reference": "The single best supporting verse for the application",
    "text": "Verse text or null",
    "connection": "How this verse supports or grounds the application"
  },
  "studyPrompt": "A practical, personal question that challenges the user to identify one specific change"
}''';

  // ═══════════════════════════════════════════════════════════════════
  //  PARSING
  // ═══════════════════════════════════════════════════════════════════

  dynamic _parse(VerseFeature mode, Map<String, dynamic> data) {
    switch (mode) {
      case VerseFeature.explain:
        return ExplainResultV2.fromJson(data);
      case VerseFeature.context:
        return ContextResultV2.fromJson(data);
      case VerseFeature.crossRefs:
        return CrossRefResultV2.fromJson(data);
      case VerseFeature.keyWord:
        return KeywordsResultV2.fromJson(data);
      case VerseFeature.application:
        return ApplicationResultV2.fromJson(data);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  UTILITIES
  // ═══════════════════════════════════════════════════════════════════

  /// Recursively normalizes JSON keys from snake_case to camelCase.
  Map<String, dynamic> _normalizeKeys(Map<String, dynamic> input) {
    final result = <String, dynamic>{};
    for (final entry in input.entries) {
      final camelKey = _toCamelCase(entry.key);
      if (entry.value is Map) {
        result[camelKey] = _normalizeKeys(
          Map<String, dynamic>.from(entry.value),
        );
      } else if (entry.value is List) {
        result[camelKey] = (entry.value as List).map((item) {
          if (item is Map) {
            return _normalizeKeys(Map<String, dynamic>.from(item));
          }
          return item;
        }).toList();
      } else {
        result[camelKey] = entry.value;
      }
    }
    return result;
  }

  String _toCamelCase(String key) {
    final parts = key.split('_');
    if (parts.length == 1) return key;
    return parts.first +
        parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }
}
