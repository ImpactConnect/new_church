import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gen_ai;
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/ai_config_service.dart';
import '../models/bible_study_models.dart';

// ─── Provider ───────────────────────────────────────────────────────────────
final bibleStudyAiServiceProvider = Provider<BibleStudyAiService>((ref) {
  return BibleStudyAiService();
});

typedef SessionPartialContentCallback =
    Future<void> Function(Map<String, dynamic> partialContent, String stage);

// ─── Service ────────────────────────────────────────────────────────────────
class BibleStudyAiService {
  static const int _maxRetries = 3;
  static const int _maxChunkValidationRetries = 2;

  // ── LOGOS System Prompt ─────────────────────────────────────────────────
  static const String _kSystemPrompt = '''
You are LOGOS — a biblical study companion embedded in illuminare.

Your purpose is to help believers understand God's Word deeply —
not as an academic subject to be analysed, but as a living reality
to be understood and lived. You speak as the most gifted Bible teacher
the user has ever sat with: warm, clear, story-rich, and deeply
grounded in scripture.

═══════════════════════════════════════════════════
CORE IDENTITY
═══════════════════════════════════════════════════
YOU ARE NOT AN ACADEMIC
   This is not a seminary course. This is not a commentary.
   This is a deep, personal, scripture-grounded study for a believer
   who wants to understand what God says and what it means for their
   life. Scholarship is your engine — never your product.
   The user should feel illuminated, not lectured.

YOU ARE A STORYTELLER
   The Bible is a story. Explain it through its own stories.
   When making any point, reach first for a biblical narrative,
   event, or teaching that shows what you mean — not an abstract
   theological principle. Use events from both Old and New Testaments.
   The story makes the truth unforgettable.

YOU MAKE WORDS CLEAR
   Whenever a word is ambiguous — same English word translating
   multiple different Hebrew or Greek words — you explain the
   distinction. You give the original word, its meaning, and why
   it matters. You do this in plain language. Never technical codes.
   Example: "The word translated 'love' here is not philia (friendship)
   but agapē (G26) — the kind of love that acts regardless of whether
   the person deserves it. This matters because..."

ZERO DENOMINATIONAL BIAS
   You represent no tradition. Where faithful readers have disagreed
   for centuries, you present the scriptural basis for each position
   fairly. Your only authority is scripture itself.

═══════════════════════════════════════════════════
NON-NEGOTIABLE SCRIPTURE DENSITY
═══════════════════════════════════════════════════
Every major point MUST be supported by scripture citations inline.
Every application claim MUST cite the scriptural basis.
Every story or event used MUST be cited by its passage reference.
Format: (Romans 8:1), (cf. Isaiah 53:5; 1 Peter 2:24), (John 3:16)
A section without scripture citations is INCOMPLETE.

═══════════════════════════════════════════════════
ORIGINAL LANGUAGE RULE
═══════════════════════════════════════════════════
For key words — especially where the English translation is
insufficient or where the same English word translates multiple
different originals — provide:
  - The original Hebrew or Greek word
  - Its transliteration
  - Its Strong's number (H#### or G####)
  - Its specific meaning in this context
  - Why knowing this changes how the reader understands the text
Written conversationally. Never use raw grammatical codes in output.

═══════════════════════════════════════════════════
OUTPUT RULES
═══════════════════════════════════════════════════
- Return ONLY valid JSON. No markdown. No preamble. No text outside.
- Never fabricate scripture references or Strong's numbers.
- Every session must stand alone as a complete study unit.
- All verse text: provide exact text or set verseText to null.
- Never be shallow. Each session must give the user a full, rich,
  complete understanding of their study subject.
- You MUST include ALL required fields in the schema. Missing fields
  are NOT acceptable. If content is minimal, write empty string "".
  DO NOT omit fields. DO NOT truncate your JSON response.
- Incomplete JSON will break the app. Complete every object fully.

═══════════════════════════════════════════════════
SERIES PROGRESSION RULES (MANDATORY FOR MULTI-SESSION STUDIES)
═══════════════════════════════════════════════════
RULE 1 — NO REPEAT INTRODUCTIONS
"Why This Book Exists", "Who the author is", "What the Hebrew/Greek 
word means" — these sections belong ONLY in Session 1. 
In Sessions 2+, these are referenced briefly, not repeated.
If sessionNumber > 1, do NOT include introductory context sections.

RULE 2 — NO REPEAT WORD DEFINITIONS
Words in wordsAlreadyDefined have been defined in previous sessions.
Do not re-define them. You may reference them: "As we saw in Session 1, 
this word means... Here we see it doing something new..."

RULE 3 — PREVIOUS SESSION BRIDGE IS REQUIRED
Every session from Session 2 onward must open with a 
previousSessionBridge (minimum 60 words) that:
- Names what was established in the previous session(s)
- Cites specific scriptures from previous sessions
- Connects organically to what this session explores
- Is warm and narrative, not a bullet summary

RULE 4 — PROGRESSIVE DEPTH
Each session must go deeper than the previous one.
Session 1 establishes foundations.
Middle sessions explore and develop.
The final session synthesizes and applies.
Content should feel like it BUILDS — not like it starts over.

RULE 5 — CROSS-SESSION REFERENCES
Sessions 3+ should actively reference insights from earlier sessions:
"In Session 2 we saw that Peter's denial was not the end of his story 
(John 18:15–27). Now we see the restoration that Session 2 was pointing 
toward (John 21:15–19)..."

═══════════════════════════════════════════════════
CONTENT DEPTH STANDARDS
═══════════════════════════════════════════════════
MINIMUM WORD COUNTS (NON-NEGOTIABLE):
- Opening hook/scene: 120 words, 2+ citations
- Historical/cultural context: 150 words, 3+ citations
- Key event/narrative: 200 words, every claim cited
- Word study insight: 80 words, 2+ other uses
- Theological explanation: 180 words, OT + NT references
- Application section: 120 words, 2+ supporting citations
- Previous session bridge: 60 words, specific citations

SCRIPTURE CITATION DENSITY:
Every 100 words must contain minimum 2 inline scripture citations.
Format: (Romans 8:1), (cf. Isaiah 53:5; 1 Peter 2:24)

TRUNCATION PREVENTION:
You MUST complete every section. If approaching output limit, 
mark incomplete sections as:
{"status": "requires_completion", "sectionKey": "[name]"}
The app will detect this and make a follow-up call.
''';

  // ── Prompts ─────────────────────────────────────────────────────────────
  // All prompts are now stored in Firestore for easy updates without deployment
  // No fallback prompts - except for bible_study_verse as requested.

  Future<String> _getPrompt(String promptKey) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('ai_prompts')
          .doc(promptKey)
          .get();

      if (doc.exists && doc.data()?['prompt'] is String) {
        return doc.data()!['prompt'] as String;
      }
      
      if (promptKey == 'bible_study_verse') {
        return '''
You are LOGOS — a biblical study companion embedded in illuminare.
Generate a deep, scripture-centered Bible study based strictly on the user's focus verses.

Context:
Verse(s): {{verseRefs}}
Translation: {{translation}}
User Question/Focus: {{verseQuestion}}

Your task is to provide a complete, dynamically structured study.

The study must include these essential parts (you choose the exact sectionTitle for each):
1. Introduction / The Heart of the Verse
2. Keyword Analysis (Identify key words from the verse, provide their original Hebrew/Greek meaning to remove ambiguity, and clarify their intent)
3. Context Explanation (Historical/Cultural context surrounding the verse)
4. Cross-References / Similar Verses (Provide similar verses that teach the same thing and explain their connection)
5. Related Biblical Stories & Events (Cite related biblical stories, events, and teachings where necessary)
6. Areas of Application (How to apply this practically to life)
7. Any other sections you find biblically relevant to fully expound the verses.

CHUNKED GENERATION INSTRUCTIONS:
Since you are generating dynamic sections for a Verse study, return the output in this strict JSON format:
{
  "sections": [
    {
      "sectionTitle": "Your Dynamic Heading (e.g., Introduction, Keyword Analysis)",
      "sectionType": "introduction",
      "content": "The main markdown-formatted teaching text for this section. Must be rich and detailed.",
      "scriptures": [
        {
          "reference": "John 3:16",
          "relevance": "Why this verse is relevant..."
        }
      ],
      "keyWordInsight": {
        "word": "love",
        "hebrewWord": null,
        "greekWord": {
          "script": "ἀγάπη",
          "transliteration": "agape",
          "strongsNumber": "G26",
          "definition": "affection or benevolence",
          "insight": "Unconditional love..."
        }
      }
    }
  ],
  "studyQuestions": [
    "A deep reflection question?"
  ],
  "prayerFocus": "A short, guided prayer based on these verses.",
  "sessionClosing": "A final concluding thought."
}

CRITICAL RULES:
1. "sectionTitle" will be rendered exactly as you provide it on the UI headers. Make them compelling but clear.
2. Return ONLY valid JSON matching the exact schema above.
3. Every section you generate must be appended to the "sections" array.
4. If "keyWordInsight" is not applicable for a section, provide null.
5. All references must be strictly biblical.
''';
      }

      throw Exception('Prompt not found in Firestore: $promptKey');
    } catch (e) {
      if (promptKey == 'bible_study_verse') {
        return '''
You are LOGOS — a biblical study companion embedded in illuminare.
Generate a deep, scripture-centered Bible study based strictly on the user's focus verses.

Context:
Verse(s): {{verseRefs}}
Translation: {{translation}}
User Question/Focus: {{verseQuestion}}

Your task is to provide a complete, dynamically structured study.

The study must include these essential parts (you choose the exact sectionTitle for each):
1. Introduction / The Heart of the Verse
2. Keyword Analysis (Identify key words from the verse, provide their original Hebrew/Greek meaning to remove ambiguity, and clarify their intent)
3. Context Explanation (Historical/Cultural context surrounding the verse)
4. Cross-References / Similar Verses (Provide similar verses that teach the same thing and explain their connection)
5. Related Biblical Stories & Events (Cite related biblical stories, events, and teachings where necessary)
6. Areas of Application (How to apply this practically to life)
7. Any other sections you find biblically relevant to fully expound the verses.

CHUNKED GENERATION INSTRUCTIONS:
Since you are generating dynamic sections for a Verse study, return the output in this strict JSON format:
{
  "sections": [
    {
      "sectionTitle": "Your Dynamic Heading (e.g., Introduction, Keyword Analysis)",
      "sectionType": "introduction",
      "content": "The main markdown-formatted teaching text for this section. Must be rich and detailed.",
      "scriptures": [
        {
          "reference": "John 3:16",
          "relevance": "Why this verse is relevant..."
        }
      ],
      "keyWordInsight": {
        "word": "love",
        "hebrewWord": null,
        "greekWord": {
          "script": "ἀγάπη",
          "transliteration": "agape",
          "strongsNumber": "G26",
          "definition": "affection or benevolence",
          "insight": "Unconditional love..."
        }
      }
    }
  ],
  "studyQuestions": [
    "A deep reflection question?"
  ],
  "prayerFocus": "A short, guided prayer based on these verses.",
  "sessionClosing": "A final concluding thought."
}

CRITICAL RULES:
1. "sectionTitle" will be rendered exactly as you provide it on the UI headers. Make them compelling but clear.
2. Return ONLY valid JSON matching the exact schema above.
3. Every section you generate must be appended to the "sections" array.
4. If "keyWordInsight" is not applicable for a section, provide null.
5. All references must be strictly biblical.
''';
      }
      throw Exception('Failed to load prompt $promptKey: $e');
    }
  }

  Future<String> _seriesMapPrompt(BibleStudyInput input) async {
    final template = await _getPrompt('bible_study_series_map');
    // Replace placeholders with actual values
    return template
        .replaceAll('{{studyType}}', input.studyType.name)
        .replaceAll('{{subject}}', input.subject)
        .replaceAll('{{sessionCount}}', input.sessionCount.toString());
  }

  Future<String> _characterPrompt(
    BibleStudyInput input,
    int sessionNumber,
    String sessionTitle,
    String? seriesContext,
    String? sessionRole,
  ) async {
    final template = await _getPrompt('bible_study_character');
    return template
        .replaceAll('{{characterName}}', input.characterName ?? '')
        .replaceAll('{{sessionNumber}}', sessionNumber.toString())
        .replaceAll('{{sessionCount}}', input.sessionCount.toString())
        .replaceAll('{{sessionTitle}}', sessionTitle)
        .replaceAll('{{sessionRole}}', sessionRole ?? 'development')
        .replaceAll('{{seriesContext}}', seriesContext ?? '')
        .replaceAll('{{focusChips}}', input.focusChips?.join(', ') ?? '');
  }

  Future<String> _bookPrompt(
    BibleStudyInput input,
    int sessionNumber,
    String sessionTitle,
    String? seriesContext,
    String? sessionRole,
  ) async {
    final template = await _getPrompt('bible_study_book');
    return template
        .replaceAll('{{bookName}}', input.bookName ?? '')
        .replaceAll('{{translation}}', input.translation ?? 'ESV')
        .replaceAll('{{sessionNumber}}', sessionNumber.toString())
        .replaceAll('{{sessionCount}}', input.sessionCount.toString())
        .replaceAll('{{sessionTitle}}', sessionTitle)
        .replaceAll('{{sessionRole}}', sessionRole ?? 'development')
        .replaceAll('{{seriesContext}}', seriesContext ?? '')
        .replaceAll('{{format}}', input.format.name);
  }

  Future<String> _versePrompt(BibleStudyInput input) async {
    final template = await _getPrompt('bible_study_verse');
    return template
        .replaceAll('{{verseRefs}}', input.verseRefs?.join(', ') ?? '')
        .replaceAll('{{translation}}', input.translation ?? 'ESV')
        .replaceAll('{{verseQuestion}}', input.verseQuestion ?? '');
  }

  Future<String> _themePrompt(
    BibleStudyInput input,
    int sessionNumber,
    String sessionTitle,
    String? eraFocus,
    String? seriesContext,
    String? sessionRole,
  ) async {
    final template = await _getPrompt('bible_study_theme');
    return template
        .replaceAll('{{themeName}}', input.themeName ?? '')
        .replaceAll('{{sessionNumber}}', sessionNumber.toString())
        .replaceAll('{{sessionCount}}', input.sessionCount.toString())
        .replaceAll('{{sessionTitle}}', sessionTitle)
        .replaceAll('{{sessionRole}}', sessionRole ?? 'development')
        .replaceAll('{{eraFocus}}', eraFocus ?? '')
        .replaceAll('{{seriesContext}}', seriesContext ?? '');
  }

  Future<String> _topicalPrompt(
    BibleStudyInput input,
    int sessionNumber,
    String sessionTitle,
    String sessionFocus,
    String? sessionRole,
  ) async {
    final template = await _getPrompt('bible_study_topical');
    return template
        .replaceAll('{{lifeQuestion}}', input.lifeQuestion ?? '')
        .replaceAll('{{userContext}}', input.userContext ?? '')
        .replaceAll('{{sessionNumber}}', sessionNumber.toString())
        .replaceAll('{{sessionCount}}', input.sessionCount.toString())
        .replaceAll('{{sessionTitle}}', sessionTitle)
        .replaceAll('{{sessionRole}}', sessionRole ?? 'development')
        .replaceAll('{{sessionFocus}}', sessionFocus);
  }

  Future<String> _devotionalPrompt(
    BibleStudyInput input,
    int dayNumber,
    String dayTitle,
    String arcPhase,
    String? seriesContext,
    List<String>? usedAnchorScriptures,
  ) async {
    final sessionDate = input.startDate != null
        ? input.startDate!.add(Duration(days: dayNumber - 1))
        : DateTime.now().add(Duration(days: dayNumber - 1));
    final dateStr =
        '${sessionDate.year}-${sessionDate.month.toString().padLeft(2, '0')}-${sessionDate.day.toString().padLeft(2, '0')}';

    final template = await _getPrompt('bible_study_devotional');
    return template
        .replaceAll('{{dayNumber}}', dayNumber.toString())
        .replaceAll('{{sessionCount}}', input.sessionCount.toString())
        .replaceAll('{{devotionalTheme}}', input.devotionalTheme ?? '')
        .replaceAll('{{dateStr}}', dateStr)
        .replaceAll('{{dayTitle}}', dayTitle)
        .replaceAll('{{arcPhase}}', arcPhase)
        .replaceAll('{{personalContext}}', input.personalContext ?? '')
        .replaceAll('{{seriesContext}}', seriesContext ?? '')
        .replaceAll(
          '{{usedAnchorScriptures}}',
          usedAnchorScriptures?.join(', ') ?? '',
        );
  }

  // ── Remote Prompt Fetching ───────────────────────────────────────────────
  String? _cachedSystemPrompt;

  Future<String> _getSystemPrompt() async {
    if (_cachedSystemPrompt != null) return _cachedSystemPrompt!;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('ai_prompts')
          .doc('bible_study_system')
          .get();
      if (doc.exists && doc.data()?['prompt'] is String) {
        _cachedSystemPrompt = doc.data()!['prompt'] as String;
        return _cachedSystemPrompt!;
      }
    } catch (_) {}
    return _kSystemPrompt;
  }

  // ── Generation ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _generate(
    String userPrompt, {
    Map<String, dynamic>? partialContent,
  }) async {
    final systemPrompt = await _getSystemPrompt();
    final provider = await AiConfigService.getProvider();
    final apiKey = await AiConfigService.getApiKey();
    final modelName = await AiConfigService.getModel();

    // If we have partial content, inject it into the prompt for continuation
    String effectivePrompt = userPrompt;
    if (partialContent != null) {
      effectivePrompt =
          '''
$userPrompt

CONTINUATION REQUEST:
The previous generation was incomplete. Here is the partial content generated so far:
${jsonEncode(partialContent)}

Please complete the missing sections. Return the COMPLETE JSON with all sections filled.
''';
    }

    Exception? lastError;
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      if (attempt > 0) {
        await Future.delayed(Duration(seconds: attempt * 2));
      }
      try {
        String responseText;

        if (provider == 'openai') {
          OpenAI.apiKey = apiKey;
          OpenAI.requestsTimeOut = const Duration(minutes: 5);
          final completion = await OpenAI.instance.chat.create(
            model: modelName,
            messages: [
              OpenAIChatCompletionChoiceMessageModel(
                content: [
                  OpenAIChatCompletionChoiceMessageContentItemModel.text(
                    systemPrompt,
                  ),
                ],
                role: OpenAIChatMessageRole.system,
              ),
              OpenAIChatCompletionChoiceMessageModel(
                content: [
                  OpenAIChatCompletionChoiceMessageContentItemModel.text(
                    effectivePrompt,
                  ),
                ],
                role: OpenAIChatMessageRole.user,
              ),
            ],
            responseFormat: const {"type": "json_object"},
          );
          final contentList = completion.choices.first.message.content;
          if (contentList == null || contentList.isEmpty) {
            throw Exception('Empty response from OpenAI');
          }
          responseText = contentList.first.text ?? '';
        } else if (provider == 'gemini') {
          final model = gen_ai.GenerativeModel(
            model: modelName,
            apiKey: apiKey,
            systemInstruction: gen_ai.Content.system(systemPrompt),
            generationConfig: gen_ai.GenerationConfig(
              responseMimeType: 'application/json',
              temperature: 0.7,
            ),
          );
          final response = await model
              .generateContent([gen_ai.Content.text(effectivePrompt)])
              .timeout(
                const Duration(minutes: 5),
                onTimeout: () =>
                    throw Exception('Generation timed out after 5 minutes'),
              );
          responseText = response.text ?? '';
        } else {
          throw Exception('Unsupported AI provider: $provider');
        }

        if (responseText.isEmpty) throw Exception('Empty response from model');
        final trimmed = _cleanJson(responseText);
        final result = jsonDecode(trimmed) as Map<String, dynamic>;

        // Check for truncation indicator
        if (result['status'] == 'requires_completion' &&
            result['sectionKey'] != null) {
          // Response indicates it was truncated - retry with partial content
          if (partialContent == null) {
            // First truncation - retry with the partial content
            return await _generate(userPrompt, partialContent: result);
          } else {
            // Already retried once - return what we have
            return result;
          }
        }

        return result;
      } catch (e) {
        lastError = Exception('Attempt ${attempt + 1} failed: $e');
      }
    }
    throw lastError ??
        Exception('Generation failed after $_maxRetries attempts');
  }

  String _cleanJson(String raw) {
    // Strip markdown code fences
    var s = raw.trim();
    if (s.startsWith('```')) {
      final start = s.indexOf('\n') + 1;
      final end = s.lastIndexOf('```');
      if (end > start) s = s.substring(start, end).trim();
    }
    return s;
  }

  /// Builds session context string for prompt injection
  String _buildSessionContext({
    required int sessionNumber,
    required int totalSessions,
    required String sessionRole,
    List<Map<String, dynamic>>? wordsAlreadyDefined,
    List<Map<String, dynamic>>? previousSessionSummaries,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('SESSION CONTEXT:');
    buffer.writeln('Session number: $sessionNumber of $totalSessions');
    buffer.writeln('Session role: $sessionRole');

    if (wordsAlreadyDefined != null && wordsAlreadyDefined.isNotEmpty) {
      buffer.writeln('\nWORDS ALREADY DEFINED IN PREVIOUS SESSIONS:');
      for (final word in wordsAlreadyDefined) {
        buffer.writeln(
          '- ${word['strongsNumber']} (defined in Session ${word['definedInSession']})',
        );
      }
      buffer.writeln('DO NOT re-define these words. Reference them if needed.');
    }

    if (previousSessionSummaries != null &&
        previousSessionSummaries.isNotEmpty) {
      buffer.writeln('\nPREVIOUS SESSION SUMMARIES:');
      for (final summary in previousSessionSummaries) {
        buffer.writeln(
          'Session ${summary['sessionNumber']}: ${summary['sessionTitle']}',
        );
        final findings = summary['keyFindings'] as List<dynamic>?;
        if (findings != null && findings.isNotEmpty) {
          for (final finding in findings) {
            buffer.writeln('  - $finding');
          }
        }
      }
    }

    if (sessionNumber > 1) {
      buffer.writeln(
        '\nREQUIRED: Include previousSessionBridge (min 60 words) that:',
      );
      buffer.writeln('- References specific content from previous session(s)');
      buffer.writeln('- Cites scriptures from previous sessions');
      buffer.writeln('- Connects warmly to what this session explores');
    }

    return buffer.toString();
  }

  // ── Public API ───────────────────────────────────────────────────────────

  /// Generate the series map for series studies
  Future<Map<String, dynamic>> generateSeriesMap(BibleStudyInput input) async {
    final prompt = await _seriesMapPrompt(input);
    return await _generate(prompt);
  }

  /// Regenerate the series map with a fresh attempt
  Future<Map<String, dynamic>> regenerateSeriesMap(
    BibleStudyInput input,
  ) async {
    // Same as generateSeriesMap but explicitly for regeneration
    final prompt = await _seriesMapPrompt(input);
    return await _generate(prompt);
  }

  /// Generate a single session for any study type
  Future<Map<String, dynamic>> generateSession({
    required BibleStudyInput input,
    required int sessionNumber,
    required String sessionTitle,
    String? seriesContext,
    String? eraFocus,
    String? arcPhase,
    String? sessionRole,
    int? totalSessions,
    List<Map<String, dynamic>>? wordsAlreadyDefined,
    List<Map<String, dynamic>>? previousSessionSummaries,
    bool useChunkedGeneration = true,
    SessionPartialContentCallback? onPartialContent,
  }) async {
    // Use chunked generation for studies with dynamic sections to prevent truncation
    final shouldUseChunked =
        useChunkedGeneration &&
        (input.studyType == StudyType.character ||
            input.studyType == StudyType.book ||
            input.studyType == StudyType.theme ||
            input.studyType == StudyType.topical ||
            input.studyType == StudyType.verse ||
            input.studyType == StudyType.devotional);

    if (shouldUseChunked) {
      return await _generateSessionChunked(
        input: input,
        sessionNumber: sessionNumber,
        sessionTitle: sessionTitle,
        seriesContext: seriesContext,
        eraFocus: eraFocus,
        arcPhase: arcPhase,
        sessionRole: sessionRole,
        totalSessions: totalSessions,
        wordsAlreadyDefined: wordsAlreadyDefined,
        previousSessionSummaries: previousSessionSummaries,
        onPartialContent: onPartialContent,
      );
    }

    // Fall back to single-call generation for verse studies or when disabled
    return await _generateSessionSingleCall(
      input: input,
      sessionNumber: sessionNumber,
      sessionTitle: sessionTitle,
      seriesContext: seriesContext,
      eraFocus: eraFocus,
      arcPhase: arcPhase,
      sessionRole: sessionRole,
      totalSessions: totalSessions,
      wordsAlreadyDefined: wordsAlreadyDefined,
      previousSessionSummaries: previousSessionSummaries,
    );
  }

  /// Generate session in a single API call (legacy method)
  Future<Map<String, dynamic>> _generateSessionSingleCall({
    required BibleStudyInput input,
    required int sessionNumber,
    required String sessionTitle,
    String? seriesContext,
    String? eraFocus,
    String? arcPhase,
    String? sessionRole,
    int? totalSessions,
    List<Map<String, dynamic>>? wordsAlreadyDefined,
    List<Map<String, dynamic>>? previousSessionSummaries,
  }) async {
    // Build session context if we have role information
    String? contextAddition;
    if (sessionRole != null && totalSessions != null) {
      contextAddition = _buildSessionContext(
        sessionNumber: sessionNumber,
        totalSessions: totalSessions,
        sessionRole: sessionRole,
        wordsAlreadyDefined: wordsAlreadyDefined,
        previousSessionSummaries: previousSessionSummaries,
      );
    }

    String prompt;
    switch (input.studyType) {
      case StudyType.character:
        prompt = await _characterPrompt(
          input,
          sessionNumber,
          sessionTitle,
          seriesContext,
          sessionRole,
        );
        break;
      case StudyType.book:
        prompt = await _bookPrompt(
          input,
          sessionNumber,
          sessionTitle,
          seriesContext,
          sessionRole,
        );
        break;
      case StudyType.verse:
        prompt = await _versePrompt(input);
        break;
      case StudyType.theme:
        prompt = await _themePrompt(
          input,
          sessionNumber,
          sessionTitle,
          eraFocus,
          seriesContext,
          sessionRole,
        );
        break;
      case StudyType.topical:
        prompt = await _topicalPrompt(
          input,
          sessionNumber,
          sessionTitle,
          'Session $sessionNumber',
          sessionRole,
        );
        break;
      case StudyType.devotional:
        prompt = await _devotionalPrompt(
          input,
          sessionNumber,
          sessionTitle,
          arcPhase ?? 'Grounding',
          seriesContext,
          null,
        );
        break;
    }

    // Append session context if available
    if (contextAddition != null) {
      prompt = '$prompt\n\n$contextAddition';
    }

    return await _generate(prompt);
  }

  /// Generate session in chunks to prevent truncation
  Future<Map<String, dynamic>> _generateSessionChunked({
    required BibleStudyInput input,
    required int sessionNumber,
    required String sessionTitle,
    String? seriesContext,
    String? eraFocus,
    String? arcPhase,
    String? sessionRole,
    int? totalSessions,
    List<Map<String, dynamic>>? wordsAlreadyDefined,
    List<Map<String, dynamic>>? previousSessionSummaries,
    SessionPartialContentCallback? onPartialContent,
  }) async {
    // Determine expected section count based on study type
    final expectedSectionCount = _getExpectedSectionCount(input.studyType);

    // Generate sections in chunks of 3
    final allSections = <Map<String, dynamic>>[];
    final chunksNeeded = (expectedSectionCount / 3).ceil();

    for (int chunkIndex = 0; chunkIndex < chunksNeeded; chunkIndex++) {
      final sectionStart = chunkIndex * 3 + 1;
      final sectionEnd = ((chunkIndex + 1) * 3).clamp(0, expectedSectionCount);

      final chunkSections = await _generateSectionChunk(
        input: input,
        sessionNumber: sessionNumber,
        sessionTitle: sessionTitle,
        seriesContext: seriesContext,
        eraFocus: eraFocus,
        arcPhase: arcPhase,
        sessionRole: sessionRole,
        totalSessions: totalSessions,
        wordsAlreadyDefined: wordsAlreadyDefined,
        previousSessionSummaries: previousSessionSummaries,
        sectionStart: sectionStart,
        sectionEnd: sectionEnd,
        previousSections: allSections,
      );

      allSections.addAll(chunkSections);
      if (onPartialContent != null) {
        await onPartialContent(
          _buildPartialSessionContent(
            input: input,
            sessionNumber: sessionNumber,
            sessionTitle: sessionTitle,
            arcPhase: arcPhase,
            sessionRole: sessionRole,
            sections: allSections,
          ),
          'sections_$sectionStart-$sectionEnd',
        );
      }
    }

    // Generate metadata (questions, prayer, closing) separately
    final metadata = await _generateSessionMetadata(
      input: input,
      sessionNumber: sessionNumber,
      sessionTitle: sessionTitle,
      sessionRole: sessionRole,
      sections: allSections,
    );

    final combined = {
      'studyType': input.studyType.name,
      'sessionNumber': sessionNumber,
      'sessionTitle': sessionTitle,
      'dayNumber':
          sessionNumber, // Fallback to session number if not in metadata
      'dayTitle': sessionTitle,
      'arcPhase': arcPhase,
      'sessionRole': sessionRole,
      'sections': allSections,
      ...metadata,
    };

    _validateFinalChunkedSession(
      session: combined,
      expectedSectionCount: expectedSectionCount,
    );
    if (onPartialContent != null) {
      await onPartialContent(combined, 'metadata_complete');
    }
    return combined;
  }

  /// Generate a chunk of sections (3 sections at a time)
  Future<List<Map<String, dynamic>>> _generateSectionChunk({
    required BibleStudyInput input,
    required int sessionNumber,
    required String sessionTitle,
    String? seriesContext,
    String? eraFocus,
    String? arcPhase,
    String? sessionRole,
    int? totalSessions,
    List<Map<String, dynamic>>? wordsAlreadyDefined,
    List<Map<String, dynamic>>? previousSessionSummaries,
    required int sectionStart,
    required int sectionEnd,
    required List<Map<String, dynamic>> previousSections,
  }) async {
    // Build base prompt
    String basePrompt;
    switch (input.studyType) {
      case StudyType.character:
        basePrompt = await _characterPrompt(
          input,
          sessionNumber,
          sessionTitle,
          seriesContext,
          sessionRole,
        );
        break;
      case StudyType.book:
        basePrompt = await _bookPrompt(
          input,
          sessionNumber,
          sessionTitle,
          seriesContext,
          sessionRole,
        );
        break;
      case StudyType.theme:
        basePrompt = await _themePrompt(
          input,
          sessionNumber,
          sessionTitle,
          eraFocus,
          seriesContext,
          sessionRole,
        );
        break;
      case StudyType.topical:
        basePrompt = await _topicalPrompt(
          input,
          sessionNumber,
          sessionTitle,
          'Session $sessionNumber',
          sessionRole,
        );
        break;
      case StudyType.devotional:
        basePrompt = await _devotionalPrompt(
          input,
          sessionNumber,
          sessionTitle,
          arcPhase ?? 'Grounding',
          seriesContext,
          null,
        );
        break;
      case StudyType.verse:
        basePrompt = await _versePrompt(input);
        break;
    }

    // Add chunking instructions
    final chunkPrompt =
        '''
$basePrompt

CHUNKED GENERATION INSTRUCTIONS:
Generate ONLY sections $sectionStart through $sectionEnd of the total sections.
${previousSections.isNotEmpty ? 'Previous sections already generated:\n${_formatPreviousSections(previousSections)}\n' : ''}
Return ONLY these sections in this format:
{
  "sections": [
    // Section $sectionStart
    {
      "sectionTitle": "...",
      "sectionType": "...",
      "content": "...",
      "scriptures": [...],
      "keyWordInsight": {...}
    },
    // Sections ${sectionStart + 1} through $sectionEnd
  ]
}

Do NOT include studyQuestions, prayerFocus, or sessionClosing - those will be generated separately.
Focus ONLY on generating high-quality content for sections $sectionStart-$sectionEnd.
''';

    Exception? lastValidationError;
    for (int attempt = 0; attempt < _maxChunkValidationRetries; attempt++) {
      try {
        final result = await _generate(chunkPrompt);
        final rawSections = (result['sections'] as List<dynamic>?) ?? [];
        final sections = rawSections.whereType<Map<String, dynamic>>().toList();
        _validateChunkSections(
          sections: sections,
          expectedCount: sectionEnd - sectionStart + 1,
          sectionStart: sectionStart,
          sectionEnd: sectionEnd,
        );
        return sections;
      } catch (e) {
        lastValidationError = Exception(
          'Chunk $sectionStart-$sectionEnd validation failed: $e',
        );
      }
    }
    throw lastValidationError ??
        Exception('Chunk $sectionStart-$sectionEnd validation failed');
  }

  /// Generate session metadata (questions, prayer, closing)
  Future<Map<String, dynamic>> _generateSessionMetadata({
    required BibleStudyInput input,
    required int sessionNumber,
    required String sessionTitle,
    String? sessionRole,
    required List<Map<String, dynamic>> sections,
  }) async {
    final metadataPrompt =
        '''
Generate the closing metadata for this ${input.studyType.name} study session.

Session: $sessionTitle (Session $sessionNumber)
${sessionRole != null ? 'Session Role: $sessionRole' : ''}

Sections covered:
${sections.map((s) => '- ${s['sectionTitle']}').join('\n')}

Generate:
{
  "studyQuestions": [
    "Question 1 based on the sections above",
    "Question 2 based on the sections above",
    "Question 3 based on the sections above",
    "Question 4 based on the sections above"
  ],
  "prayerFocus": "40-70 word prayer specific to this session's content",
  "sessionClosing": "2-3 landing sentences that seal this session"
}

Make the questions and prayer specific to what was covered in the sections above.
''';

    Exception? lastValidationError;
    for (int attempt = 0; attempt < _maxChunkValidationRetries; attempt++) {
      try {
        final metadata = await _generate(metadataPrompt);
        _validateMetadata(metadata);
        return metadata;
      } catch (e) {
        lastValidationError = Exception('Metadata validation failed: $e');
      }
    }

    throw lastValidationError ?? Exception('Metadata validation failed');
  }

  Map<String, dynamic> _buildPartialSessionContent({
    required BibleStudyInput input,
    required int sessionNumber,
    required String sessionTitle,
    String? arcPhase,
    String? sessionRole,
    required List<Map<String, dynamic>> sections,
  }) {
    return {
      'studyType': input.studyType.name,
      'sessionNumber': sessionNumber,
      'sessionTitle': sessionTitle,
      'dayNumber': sessionNumber,
      'dayTitle': sessionTitle,
      'arcPhase': arcPhase,
      'sessionRole': sessionRole,
      'sections': sections,
    };
  }

  void _validateChunkSections({
    required List<Map<String, dynamic>> sections,
    required int expectedCount,
    required int sectionStart,
    required int sectionEnd,
  }) {
    if (sections.length != expectedCount) {
      throw Exception(
        'Expected $expectedCount sections for chunk $sectionStart-$sectionEnd, got ${sections.length}',
      );
    }

    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      final title = (section['sectionTitle'] as String?)?.trim() ?? '';
      final type = (section['sectionType'] as String?)?.trim() ?? '';
      final content = (section['content'] as String?)?.trim() ?? '';

      if (title.isEmpty) {
        throw Exception('Section ${sectionStart + i} is missing a title');
      }
      if (type.isEmpty) {
        throw Exception(
          'Section ${sectionStart + i} is missing a section type',
        );
      }
      if (content.length < 80) {
        throw Exception('Section ${sectionStart + i} content is too short');
      }
      if (section['scriptures'] != null && section['scriptures'] is! List) {
        throw Exception(
          'Section ${sectionStart + i} scriptures must be a list',
        );
      }
      if (section['keyWordInsight'] != null &&
          section['keyWordInsight'] is! Map<String, dynamic>) {
        throw Exception(
          'Section ${sectionStart + i} keyword insight must be an object',
        );
      }
    }
  }

  void _validateMetadata(Map<String, dynamic> metadata) {
    final questions = metadata['studyQuestions'] as List<dynamic>?;
    final prayerFocus = (metadata['prayerFocus'] as String?)?.trim() ?? '';
    final sessionClosing =
        (metadata['sessionClosing'] as String?)?.trim() ?? '';

    if (questions == null || questions.length < 3) {
      throw Exception('Expected at least 3 study questions');
    }
    if (questions.any((q) => q.toString().trim().isEmpty)) {
      throw Exception('Study questions cannot be empty');
    }
    if (prayerFocus.length < 20) {
      throw Exception('Prayer focus is too short');
    }
    if (sessionClosing.length < 20) {
      throw Exception('Session closing is too short');
    }
  }

  void _validateFinalChunkedSession({
    required Map<String, dynamic> session,
    required int expectedSectionCount,
  }) {
    final sections =
        (session['sections'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        const <Map<String, dynamic>>[];
    _validateChunkSections(
      sections: sections,
      expectedCount: expectedSectionCount,
      sectionStart: 1,
      sectionEnd: expectedSectionCount,
    );
    _validateMetadata(session);
  }

  /// Format previous sections for context
  String _formatPreviousSections(List<Map<String, dynamic>> sections) {
    return sections
        .map((s) => '- ${s['sectionTitle']} (${s['sectionType']})')
        .join('\n');
  }

  /// Get expected section count by study type
  int _getExpectedSectionCount(StudyType type) {
    switch (type) {
      case StudyType.character:
        return 7;
      case StudyType.book:
        return 7;
      case StudyType.theme:
        return 7;
      case StudyType.topical:
        return 6;
      case StudyType.devotional:
        return 5;
      case StudyType.verse:
        return 5;
    }
  }
}
