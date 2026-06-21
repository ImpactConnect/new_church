import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:church_mobile/features/bible_ai/services/ai_service.dart';
import '../../../data/repositories/prompt_repository.dart';
import '../models/exegesis_result_v2_model.dart';

/// Service responsible for all Exegesis v2 AI interactions.
/// Handles ILLUMINE system prompt loading, mode-specific prompt generation,
/// and JSON parsing into ExegesisResultV2 models.
class ExegesisAiServiceV2 {
  final AiService _aiService;
  final PromptRepository _promptRepo;

  ExegesisAiServiceV2({
    required AiService aiService,
    required PromptRepository promptRepo,
  })  : _aiService = aiService,
        _promptRepo = promptRepo;

  /// Generates an exegesis for the given [subject] based on [entryType] and [mode].
  Future<ExegesisResultV2> generateExegesis({
    required String subject,
    required ExegesisEntryType entryType,
    required ExegesisMode mode,
    String? verseText,
    String translation = 'ESV',
    bool isMulti = false,
  }) async {
    final systemPrompt = await _getSystemPrompt();
    final userPrompt = _buildUserPrompt(
      subject: subject,
      entryType: entryType,
      mode: mode,
      verseText: verseText,
      translation: translation,
      isMulti: isMulti,
    );

    debugPrint('⟹ Exegesis v2: Generating ${mode.name} mode for "$subject" (${entryType.name})');

    final responseText = await _aiService.getAiResponse(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
    );

    debugPrint('⟹ Exegesis v2 raw response length: ${responseText.length}');

    final data = jsonDecode(responseText) as Map<String, dynamic>;
    
    // Validate JSON structure
    _validateResponse(data, mode);
    
    // Generate a unique ID for this result
    final id = '${DateTime.now().millisecondsSinceEpoch}_${subject.hashCode}';
    data['id'] = id;
    data['createdAt'] = DateTime.now().toIso8601String();
    
    return ExegesisResultV2.fromJson(data);
  }

  /// Generates the alternate mode for an existing result.
  /// Reuses the same subject and entry type but switches the mode.
  Future<ExegesisResultV2> generateAlternateMode({
    required ExegesisResultV2 existingResult,
    required ExegesisMode targetMode,
  }) async {
    return generateExegesis(
      subject: existingResult.subject,
      entryType: existingResult.entryType,
      mode: targetMode,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SYSTEM PROMPT
  // ═══════════════════════════════════════════════════════════════════

  Future<String> _getSystemPrompt() async {
    final prompt = await _promptRepo.getPrompt('exegesis_system_v2');
    return prompt ?? _fallbackSystemPrompt;
  }

  static const String _fallbackSystemPrompt = '''
You are ILLUMINE — a biblical guide embedded in illuminare.

You are NOT a lecturer. You are NOT a seminary professor.
You are the most trusted Bible teacher the user has ever had —
someone who has studied the scripture deeply but speaks about it
as a living, breathing reality, not an academic subject.

Your gift is making complex truth feel simple without being shallow.
You carry your scholarship invisibly. The user should feel enlightened,
not educated. Moved, not managed. Closer to the text — and to God.

═══════════════════════════════════════
YOUR VOICE
═══════════════════════════════════════
WARM AND DIRECT
   Speak to one person. Not a congregation, not a class — a person
   sitting with a question about the scripture. Write the way a trusted
   friend who knows the Bible deeply would explain it over coffee.

NARRATIVE FIRST
   Whenever you can make a point through a story, an image, or a
   scene — do that instead of making it abstractly. The scripture is
   a story. Your explanation should feel like a story too.

HONESTY OVER POLISH
   If a text is difficult, say so. If scholars genuinely disagree,
   say so. If the original language reveals something surprising,
   lead with the surprise. Never smooth over tension to seem tidy.

SCHOLARSHIP IS INVISIBLE
   Use the grammatical-historical method. Know the Hebrew and Greek.
   Know the cultural context. Know the interpretive history.
   But let none of that show on the surface unless the user has
   asked for the deep layer (Go Deep mode). Your scholarship is the
   engine — not the dashboard.

═══════════════════════════════════════
HERMENEUTICAL COMMITMENTS
═══════════════════════════════════════
1. TEXT FIRST
   What does the text actually say? This governs everything.
   Never import ideas from outside the text to fill gaps.

2. ORIGINAL AUDIENCE FIRST
   What did this text mean to the first people who heard it?
   Modern assumptions must be set aside before application is made.

3. SCRIPTURE INTERPRETS SCRIPTURE
   Let the canon speak to itself. Draw connections across the Bible
   that genuinely illuminate — not surface-level word associations.

4. ZERO DOCTRINAL BIAS
   You represent no denomination. Where faithful readers have
   disagreed for centuries, present the disagreement fairly.
   Your job is understanding, not advocacy.

5. VERSE AUTHENTICITY
   {VERSE_TEXT} is provided by the user. Use it. Do not alter it.
   If you are not certain of exact verse text, set it to null.
   Never fabricate scripture.

═══════════════════════════════════════
MULTI-VERSE RULE
═══════════════════════════════════════
When {IS_MULTI} is true: treat all selected verses/subjects as a
unified passage or concept. Find the thread that connects them
and speak to that thread — not to each verse in isolation.

═══════════════════════════════════════
OUTPUT RULES
═══════════════════════════════════════
- Return ONLY valid JSON. No markdown. No preamble. No text outside.
- Never use academic section labels in your content text.
  (The labels exist in the JSON keys — not in what you write.)
- If a section does not apply to this entry type, use null.
- Never use words like "exegesis", "hermeneutics", "pericope",
  "penal substitution", "soteriology" in the Understand mode output.
  These words are invisible scaffolding. They are never in the product.
''';

  // ═══════════════════════════════════════════════════════════════════
  //  USER PROMPT BUILDER
  // ═══════════════════════════════════════════════════════════════════

  String _buildUserPrompt({
    required String subject,
    required ExegesisEntryType entryType,
    required ExegesisMode mode,
    String? verseText,
    required String translation,
    required bool isMulti,
  }) {
    if (mode == ExegesisMode.understand) {
      return _buildUnderstandPrompt(
        subject: subject,
        entryType: entryType,
        verseText: verseText,
        translation: translation,
        isMulti: isMulti,
      );
    } else {
      return _buildGoDeepPrompt(
        subject: subject,
        entryType: entryType,
        verseText: verseText,
        translation: translation,
        isMulti: isMulti,
      );
    }
  }

  String _buildUnderstandPrompt({
    required String subject,
    required ExegesisEntryType entryType,
    String? verseText,
    required String translation,
    required bool isMulti,
  }) {
    final entryTypeStr = _entryTypeToString(entryType);
    
    return '''
Help me understand: "$subject"

Entry type: $entryTypeStr
Verse/Text: "${verseText ?? 'null'}" ($translation)
Multiple subjects: $isMulti

Write as a trusted Bible teacher speaking to one person.
The method is exegesis. The product is understanding.
No academic language. No technical labels. Just living truth.

{
  "entryType": "$entryTypeStr",
  "subject": "$subject",
  "mode": "understand",

  "bigPicture": "2–3 sentences. The single most important insight
    about this subject stated plainly and powerfully.
    Write it as a revelation — the thing someone would quote to
    a friend: 'I just learned that...' Not a summary.
    A discovery. Lead with the most surprising, clarifying, or
    moving truth the scripture contains about this subject.",

  "historicalMoment": "Put the reader inside the world of the text.
    Write it as a scene — not a list of facts. Who are the people?
    What is the world like? What does the air smell like, politically,
    culturally, spiritually? What is at stake? Make the reader feel
    how different that world was — so they understand why the text
    was written and what it meant to those who first received it.
    Minimum 80 words. Never start with 'This text was written...'
    Start with the world itself.",

  "keyWord": {
    "originalScript": "Original script (Hebrew/Greek)",
    "transliteration": "...",
    "strongsNumber": "H#### or G#### — stored but not displayed in Understand mode",
    "meaning": "The core meaning of this word",
    "whyItMatters": "Write the word insight as a discovery moment —
      not a dictionary entry. Start with what the English reader
      assumes. Then open the door: 'But the word used here is...'
      Show what the original language reveals that the English loses.
      Make the reader feel the discovery. 60–100 words.
      Never use the word 'Strong's', 'lexicon', or 'etymology'."
  },

  "whatWasBeingSaid": "The core explanation. What was the author
    actually saying to the original audience? What did this text mean
    before anyone applied it to themselves? Explain it as a gifted
    teacher would — with images, with connections, with the kind of
    clarity that makes someone say 'I never understood that before.'
    For VERSE/PASSAGE: focus on the specific words and their context.
    For BOOK: explain the book's central argument and purpose.
    For CHARACTER: explain who this person was and what their life means.
    For TOPIC: trace the idea from its roots to its fullest expression.
    Minimum 120 words. Never use academic terminology.",

  "inTheWholeStory": "Show the user how this subject fits into the
    larger story the Bible is telling — from creation to new creation.
    Write it as a connecting thread, not a position paper.
    Help the user feel that this verse, character, or theme is not
    floating alone — it is part of something vast and coherent.
    Minimum 70 words. Use language like 'This is where the story
    turns...' or 'This is the same promise that...' — narrative
    connectors, not theological positioning.",

  "echoes": [
    {
      "reference": "Book Chapter:Verse",
      "verseText": "Exact text or null",
      "connectionType": "Parallel | Fulfillment | Allusion | Contrast | Development",
      "explanation": "Describe this connection as an echo, not a cross-reference.
        'The Psalms were singing this same grief centuries earlier...'
        or 'This is the moment Jesus was reaching back to when he said...'
        Plain language. Minimum 30 words per echo."
    }
  ],

  "whatThisMeansForYou": "Bridge the text to the reader's life —
    but from the text, not from culture. Start with what the text
    establishes as true. Then show how that truth changes something
    specific: a question, a fear, a habit, a relationship, a prayer.
    Be specific — not 'trust God more' but a concrete shift in
    perspective or practice that flows directly from this text.
    Never moralize. Never guilt-trip. Write as someone who has
    sat with this text themselves and been changed by it.
    Minimum 80 words.",

  "somethingToSitWith": "One question or thought the user carries away.
    Not a comprehension question — a meditation. Something that works
    on them quietly after they close the app. It should feel personal,
    not academic. Example format: 'What would change about how you...'
    or 'The next time you encounter... notice whether...'
    Write it as a gift — the last thing a good teacher says before
    the conversation ends."
}

Include 3–5 echoes. Both OT and NT where possible.
Favour strong, theologically significant connections over quantity.
''';
  }

  String _buildGoDeepPrompt({
    required String subject,
    required ExegesisEntryType entryType,
    String? verseText,
    required String translation,
    required bool isMulti,
  }) {
    final entryTypeStr = _entryTypeToString(entryType);
    
    return '''
Help me understand: "$subject" (Go Deep mode)

Entry type: $entryTypeStr
Verse/Text: "${verseText ?? 'null'}" ($translation)
Multiple subjects: $isMulti

Write as a trusted Bible teacher speaking to a serious student.
Include all Understand mode content PLUS technical depth.

{
  "entryType": "$entryTypeStr",
  "subject": "$subject",
  "mode": "goDeep",

  // ALL UNDERSTAND MODE FIELDS (bigPicture, historicalMoment, keyWord, etc.)
  // Use the same instructions as Understand mode for these fields.

  "bigPicture": "...",
  "historicalMoment": "...",
  "keyWord": {...},
  "whatWasBeingSaid": "...",
  "inTheWholeStory": "...",
  "echoes": [...],
  "whatThisMeansForYou": "...",
  "somethingToSitWith": "...",

  // GO DEEP ADDITIONS:

  "wordStudies": [
    {
      "word": "Original script",
      "transliteration": "...",
      "strongsNumber": "H#### or G#### — displayed in Go Deep mode",
      "definition": "Full lexical definition — semantic range, not just synonym",
      "semanticRange": "The full range of meanings this word can carry",
      "usageExamples": ["Example 1", "Example 2", "Example 3"],
      "whyItMatters": "Connects the technical insight back to meaning:
        why does knowing this specific word change how we read the text?",
      "translationVariance": "How major translations differ and what that reveals,
        or null if translations are consistent"
    }
  ],

  "interpretiveTensions": [
    {
      "question": "Written as a genuine intellectual question — not an academic category.
        'There's a question here that careful readers have wrestled with:
        Is Paul describing...' Make it feel like a real puzzle, not a debate label.",
      "positionA": {
        "label": "The first scholarly position",
        "explanation": "The scriptural evidence that supports this view",
        "supportingVerses": ["Verse 1", "Verse 2"]
      },
      "positionB": {
        "label": "The second scholarly position",
        "explanation": "The scriptural evidence that supports this view",
        "supportingVerses": ["Verse 1", "Verse 2"]
      },
      "commonGround": "What both positions agree on — always end here,
        because agreement is usually where the core truth lives"
    }
  ],

  "grammaticalHighlights": "The most important grammatical observation from
    the original text — written for an intelligent reader, not a grammarian.
    Focus on ONE thing: a verb tense that changes everything, a pronoun
    reference that is routinely confused, a connecting particle that
    carries the logical weight of the argument.
    Write it conversationally: 'The verb Paul uses here is in the aorist —
    which means he isn't describing an ongoing process. He's describing
    a completed act.' Maximum 100 words.",

  "covenantContext": {
    "covenantFramework": "Abrahamic | Mosaic | Davidic | New Covenant | Multiple",
    "redemptiveHistoricalPlacement": "Where this fits in redemptive history",
    "christologicalConnection": "How understanding the covenant framework this text belongs
      to changes how we read it — written conversationally, not academically"
  }
}

Include 3–5 word studies. Prioritise theologically significant and translation-sensitive terms.
Max 2 interpretive tensions. Only genuine, textually significant scholarly debates.
''';
  }

  String _entryTypeToString(ExegesisEntryType type) {
    switch (type) {
      case ExegesisEntryType.singleVerse:
        return 'Verse';
      case ExegesisEntryType.passage:
        return 'Passage';
      case ExegesisEntryType.bibleBook:
        return 'Book';
      case ExegesisEntryType.bibleCharacter:
        return 'Character';
      case ExegesisEntryType.theme:
        return 'Topic';
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  JSON VALIDATION
  // ═══════════════════════════════════════════════════════════════════

  void _validateResponse(Map<String, dynamic> json, ExegesisMode mode) {
    final requiredUnderstandFields = [
      'bigPicture',
      'historicalMoment',
      'keyWord',
      'whatWasBeingSaid',
      'inTheWholeStory',
      'echoes',
      'whatThisMeansForYou',
      'somethingToSitWith',
    ];

    for (final field in requiredUnderstandFields) {
      if (!json.containsKey(field) || json[field] == null) {
        throw FormatException('Missing required field: $field');
      }
    }

    if (mode == ExegesisMode.goDeep) {
      // Only wordStudies is truly required for Go Deep mode
      // grammaticalHighlights, interpretiveTensions, and covenantContext are optional
      if (!json.containsKey('wordStudies') || json['wordStudies'] == null) {
        throw FormatException('Missing required Go Deep field: wordStudies');
      }
    }
  }
}
