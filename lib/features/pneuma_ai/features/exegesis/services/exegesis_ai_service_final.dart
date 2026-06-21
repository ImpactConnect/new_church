import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:church_mobile/features/bible_ai/services/ai_service.dart';
import '../../../data/repositories/prompt_repository.dart';
import '../models/exegesis_final_model.dart';

/// ILLUMINE Final — The Exegesis AI service for illuminare Final Edition.
///
/// Supports exactly two entry types as per the Final Edition guide:
///   - Verse / Verse Range  (Section 04 of guide)
///   - Topic / Subject      (Section 05 of guide)
class ExegesisAiServiceFinal {
  final AiService _aiService;
  final PromptRepository _promptRepo;

  // Cached prompts to reduce Firestore reads
  String? _cachedSystemPrompt;
  String? _cachedVersePrompt;
  String? _cachedTopicPrompt;

  ExegesisAiServiceFinal({
    required AiService aiService,
    required PromptRepository promptRepo,
  })  : _aiService = aiService,
        _promptRepo = promptRepo;

  // ═══════════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════════

  /// Generate a Verse exegesis (single verse, multiple verses, or a range).
  ///
  /// [verseRefs]    — list of VerseRef objects (up to 7)
  /// [verseTexts]   — map of "Book Ch:V" → verse text
  /// [translation]  — ESV / NIV / KJV / NASB / NLT
  /// [isRange]      — true when a verse range is selected
  /// [userQuestion] — optional question from the user
  /// [source]       — whether coming from the new form or bible reader
  Future<VerseExegesis> generateVerseExegesis({
    required List<VerseRef> verseRefs,
    required Map<String, String> verseTexts,
    String translation = 'ESV',
    bool isRange = false,
    String? userQuestion,
    ExegesisSource source = ExegesisSource.newForm,
  }) async {
    assert(verseRefs.isNotEmpty, 'verseRefs must not be empty');

    final systemPrompt = await _getSystemPrompt();
    final typePrompt = await _getVersePrompt();

    // Build the formatted inputs
    final verseRefsStr = verseRefs.map((r) => r.referenceString).join(', ');
    final verseTextsStr = verseTexts.entries
        .map((e) => '"${e.key}": ${e.value}')
        .join('\n');

    final userPrompt = typePrompt
        .replaceAll('{VERSE_REFS}', verseRefsStr)
        .replaceAll('{VERSE_TEXTS}', verseTextsStr)
        .replaceAll('{TRANSLATION}', translation)
        .replaceAll('{IS_RANGE}', isRange.toString())
        .replaceAll('{USER_QUESTION}', userQuestion ?? 'none');

    debugPrint('⟹ ILLUMINE Final: Verse exegesis for "$verseRefsStr"');

    // Retry up to 3 times with exponential back-off
    String responseText = '';
    Exception? lastError;
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        responseText = await _aiService.getAiResponse(
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
        );
        break; // success
      } catch (e) {
        lastError = Exception(e.toString());
        debugPrint('⚠️ ILLUMINE Final: Verse attempt $attempt failed: $e');
        if (attempt < 3) await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    if (responseText.isEmpty && lastError != null) throw lastError;

    debugPrint('⟹ ILLUMINE Final: raw response \${responseText.length} chars');

    return _parseVerseResponse(
      response: responseText,
      verseRefs: verseRefs,
      subject: verseRefsStr,
      translation: translation,
      source: source,
    );
  }

  /// Generate a Topic exegesis.
  ///
  /// [topicName]     — e.g. "Grace", "The Kingdom of God"
  /// [specificAngle] — optional refinement angle
  Future<TopicExegesis> generateTopicExegesis({
    required String topicName,
    String? specificAngle,
    ExegesisSource source = ExegesisSource.newForm,
  }) async {
    assert(topicName.trim().isNotEmpty, 'topicName must not be empty');

    final systemPrompt = await _getSystemPrompt();
    final typePrompt = await _getTopicPrompt();

    final userPrompt = typePrompt
        .replaceAll('{TOPIC_NAME}', topicName.trim())
        .replaceAll('{SPECIFIC_ANGLE}', specificAngle ?? 'none');

    debugPrint('⟹ ILLUMINE Final: Topic exegesis for "$topicName"');

    // Retry up to 3 times with exponential back-off
    String responseText = '';
    Exception? lastError;
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        responseText = await _aiService.getAiResponse(
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
        );
        break; // success
      } catch (e) {
        lastError = Exception(e.toString());
        debugPrint('⚠️ ILLUMINE Final: Topic attempt $attempt failed: $e');
        if (attempt < 3) await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    if (responseText.isEmpty && lastError != null) throw lastError;

    debugPrint('⟹ ILLUMINE Final: raw response \${responseText.length} chars');

    return _parseTopicResponse(
      response: responseText,
      subject: topicName.trim(),
      source: source,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PROMPT FETCHING WITH CACHING
  // ═══════════════════════════════════════════════════════════════════

  Future<String> _getSystemPrompt() async {
    if (_cachedSystemPrompt != null) return _cachedSystemPrompt!;
    final remote = await _promptRepo.getPrompt('exegesis_system_final');
    _cachedSystemPrompt = remote ?? _kSystemPrompt;
    return _cachedSystemPrompt!;
  }

  Future<String> _getVersePrompt() async {
    if (_cachedVersePrompt != null) return _cachedVersePrompt!;
    final remote = await _promptRepo.getPrompt('exegesis_verse_final');
    _cachedVersePrompt = remote ?? _kVersePrompt;
    return _cachedVersePrompt!;
  }

  Future<String> _getTopicPrompt() async {
    if (_cachedTopicPrompt != null) return _cachedTopicPrompt!;
    final remote = await _promptRepo.getPrompt('exegesis_topic_final');
    _cachedTopicPrompt = remote ?? _kTopicPrompt;
    return _cachedTopicPrompt!;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PARSING
  // ═══════════════════════════════════════════════════════════════════

  void _normalizeLists(Map data) {
    const listFields = {
      'wordStudy',
      'morphologicalAnalysis',
      'semanticDisambiguation',
      'mentionAnalysis',
      'crossReferences',
      'intertextualAllusions',
      'whatItCannotMean',
      'definingPassages',
      'commonDistortions',
      'otherOccurrences',
      'specificCulturalKeys',
      'confusedWith',
      'developmentMentions',
      'logicalConnectors',
    };

    // Use .toList() to avoid concurrent modification during iteration
    for (final entry in data.entries.toList()) {
      if (entry.value == null) continue;
      
      if (listFields.contains(entry.key.toString()) && entry.value is Map) {
        data[entry.key] = [entry.value];
      }
      
      final dynamic newVal = data[entry.key];
      if (newVal is Map) {
        _normalizeLists(newVal);
      } else if (newVal is List) {
        for (final item in newVal) {
          if (item is Map) {
            _normalizeLists(item);
          }
        }
      }
    }
  }

  void _applyDefaults(Map m, Map<String, dynamic> defaults) {
    for (final key in defaults.keys) {
      if (!m.containsKey(key) || m[key] == null) {
        if (defaults[key] is Map) {
          m[key] = <String, dynamic>{};
          _applyDefaults(m[key] as Map, defaults[key] as Map<String, dynamic>);
        } else if (defaults[key] is List) {
          m[key] = defaults[key]; // empty list
        } else {
          m[key] = defaults[key]; // empty string etc
        }
      } else if (m[key] is Map && defaults[key] is Map) {
        _applyDefaults(m[key] as Map, defaults[key] as Map<String, dynamic>);
      } else if (m[key] is List && defaults[key] is List) {
        if ((defaults[key] as List).isNotEmpty && (defaults[key] as List)[0] is Map) {
          final itemDefaults = (defaults[key] as List)[0] as Map<String, dynamic>;
          for (var i = 0; i < (m[key] as List).length; i++) {
            if (m[key][i] is Map) {
              _applyDefaults(m[key][i] as Map, itemDefaults);
            }
          }
        }
      }
    }
  }

  VerseExegesis _parseVerseResponse({
    required String response,
    required List<VerseRef> verseRefs,
    required String subject,
    required String translation,
    required ExegesisSource source,
  }) {
    try {
      // Strip any markdown fences the model may have added
      final clean = _stripMarkdownFences(response);
      final data = jsonDecode(clean) as Map<String, dynamic>;
      _normalizeLists(data);
      
      final verseDefaults = {
        'bigPicture': '',
        'historicalCulturalSetting': {
          'world': '',
          'specificCulturalKeys': [
            {'item': '', 'howItShapesReading': ''}
          ]
        },
        'literaryContext': {
          'genre': '', 'immediateBefore': '', 'immediateAfter': '', 'structuralRole': '', 'passageFlow': ''
        },
        'wordStudy': [
          {'englishWord': '', 'verseRef': '', 'originalWord': '', 'transliteration': '', 'strongsNumber': '', 'lexicalDefinition': '', 'meaningInThisContext': '', 'discoveryNote': '', 'otherOccurrences': []}
        ],
        'morphologicalAnalysis': [
          {'word': '', 'originalWord': '', 'strongsNumber': '', 'partOfSpeech': '', 'plainEnglishExplanation': ''}
        ],
        'semanticDisambiguation': [
          {'englishWord': '', 'disambiguation': '', 'wordUsedHere': '', 'wordUsedHereStrongs': '', 'confusedWith': []}
        ],
        'mentionAnalysis': [
          {'concept': '', 'firstMention': {'reference': '', 'whatItEstablishes': ''}, 'developmentMentions': []}
        ],
        'discourseAnalysis': {
          'rhetoricalFunction': '', 'logicalConnectors': [], 'authorIntent': ''
        },
        'crossReferences': [
          {'reference': '', 'connectionType': '', 'specificContribution': ''}
        ],
        'impliedTheologicalClaim': '',
        'whatItCannotMean': [
          {'commonMisreading': '', 'whyItIsWrong': '', 'whatItActuallyMeans': ''}
        ],
        'fromTextToLife': '',
        'somethingToSitWith': '',
      };
      
      _applyDefaults(data, verseDefaults);

      // Inject server-generated metadata
      final id = '${DateTime.now().millisecondsSinceEpoch}_${subject.hashCode.abs()}';
      data['id'] = id;
      data['subject'] = subject;
      data['translation'] = translation;
      data['source'] = source.name;
      data['createdAt'] = DateTime.now().toIso8601String();
      data['entryType'] = 'verse';
      // Store verseRefs as JSON maps
      data['verseRefsJson'] = verseRefs.map((r) => r.toJson()).toList();

      return VerseExegesis.fromJson(data);
    } on FormatException catch (e, st) {
      debugPrint('⚠️ ILLUMINE Final: JSON parse error: $e');
      debugPrint('⚠️ First 600 chars: ${response.substring(0, response.length.clamp(0, 600))}');
      debugPrint(st.toString());
      throw FormatException('Invalid JSON from ILLUMINE Final (verse): ${e.message}');
    } catch (e, st) {
      debugPrint('⚠️ ILLUMINE Final: Unexpected parse error: $e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  TopicExegesis _parseTopicResponse({
    required String response,
    required String subject,
    required ExegesisSource source,
  }) {
    try {
      final clean = _stripMarkdownFences(response);
      final data = jsonDecode(clean) as Map<String, dynamic>;
      _normalizeLists(data);
      
      final topicDefaults = {
        'bigPicture': '',
        'conceptDefinition': {
          'hebrewWord': {'word': '', 'originalScript': '', 'transliteration': '', 'strongsNumber': '', 'fullSemanticRange': ''},
          'greekWord': {'word': '', 'originalScript': '', 'transliteration': '', 'strongsNumber': '', 'fullSemanticRange': ''},
          'semanticDisambiguation': '',
          'modernVsAncient': '',
        },
        'firstMention': {
          'reference': '',
          'verseText': '',
          'whatItEstablishes': '',
        },
        'definingPassages': [
          {
            'reference': '',
            'verseText': '',
            'whyDefinitive': '',
            'historicalCulturalContext': '',
            'wordStudy': [],
            'morphologicalNote': '',
            'whatThisPassageSays': '',
            'connectionsToOtherDefiningPassages': '',
          }
        ],
        'canonicalProgression': '',
        'commonDistortions': [
          {'distortion': '', 'howItEnters': '', 'linguisticCorrection': ''}
        ],
        'impliedTheologicalClaim': '',
        'whatItCannotMean': [
          {'commonMisreading': '', 'whyItIsWrong': '', 'whatItActuallyMeans': ''}
        ],
        'fromTextToLife': '',
        'somethingToSitWith': '',
      };
      
      _applyDefaults(data, topicDefaults);

      final id = '${DateTime.now().millisecondsSinceEpoch}_${subject.hashCode.abs()}';
      data['id'] = id;
      data['subject'] = subject;
      data['source'] = source.name;
      data['createdAt'] = DateTime.now().toIso8601String();
      data['entryType'] = 'topic';

      return TopicExegesis.fromJson(data);
    } on FormatException catch (e, st) {
      debugPrint('⚠️ ILLUMINE Final: JSON parse error: $e');
      debugPrint('⚠️ First 600 chars: ${response.substring(0, response.length.clamp(0, 600))}');
      debugPrint(st.toString());
      throw FormatException('Invalid JSON from ILLUMINE Final (topic): ${e.message}');
    } catch (e, st) {
      debugPrint('⚠️ ILLUMINE Final: Unexpected parse error: $e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  /// Strips ```json ... ``` markdown fences if present
  String _stripMarkdownFences(String text) {
    final trimmed = text.trim();
    if (trimmed.startsWith('```')) {
      final start = trimmed.indexOf('\n') + 1;
      final end = trimmed.lastIndexOf('```');
      if (end > start) return trimmed.substring(start, end).trim();
    }
    return trimmed;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  FALLBACK PROMPTS — Exact from Guide Sections 03, 04, 05
  // ═══════════════════════════════════════════════════════════════════

  // ── SECTION 03 — SYSTEM PROMPT ──────────────────────────────────────
  static const String _kSystemPrompt = r'''
You are ILLUMINE — a biblical exegete embedded in illuminare.

Your purpose is singular: to lead the meaning out of the text.
Not to impose meaning onto it. Not to decorate it with theology.
To investigate it with rigour and explain it with warmth.

Your user is a believer who wants to truly understand what they are
reading. They are not a scholar — but they deserve scholarship.
Your job is to do the scholarly work invisibly and give the user
the understanding directly. They should finish reading your analysis
and need nothing else to understand this text.

═══════════════════════════════════════════════════
VOICE AND REGISTER
═══════════════════════════════════════════════════
SPEAK TO ONE PERSON
   Not a classroom. Not a congregation. A person sitting with a
   specific text and a genuine question about what it means.
   Write as the most trusted Bible teacher they have ever had.

NARRATIVE WHERE POSSIBLE
   Whenever you can make a point through a concrete image, scene,
   or story from scripture — do that instead of abstraction.
   The Bible is a story. Your explanation should feel like one.

SCHOLARSHIP IS INVISIBLE IN LANGUAGE, VISIBLE IN DEPTH
   Use technical knowledge fully. But write in plain, powerful
   English. The user feels the depth through what is revealed —
   not through the vocabulary used to reveal it.
   BANNED WORDS: "exegesis", "hermeneutics", "pericope",
   "soteriology", "epistemology", "prolegomena". Never appear
   in the output text.

ZERO DENOMINATIONAL BIAS
   You represent no tradition. Where genuine scholarly disagreement
   exists across centuries of faithful reading, present it fairly.
   Your only authority is the text itself and what it says.

═══════════════════════════════════════════════════
NON-NEGOTIABLE SCRIPTURE DENSITY RULE
═══════════════════════════════════════════════════
EVERY theological assertion must cite its scriptural basis inline.
EVERY claim about what a text means must reference the text itself.
EVERY section must contain multiple scripture references woven
throughout — not collected at the end of a section.
A paragraph with NO scripture reference is incomplete. Return to it.
The user must be able to open their Bible and verify every single
claim you make. This rule has NO exceptions.

Format all inline references consistently:
  Single verse:  (Romans 8:1)
  Verse range:   (Romans 8:1–4)
  Multiple refs: (cf. Psalm 22:1; Matthew 27:46)
  OT in NT:      (quoting Isaiah 53:5 — see also 1 Peter 2:24)

═══════════════════════════════════════════════════
ORIGINAL LANGUAGE RULES
═══════════════════════════════════════════════════
1. ALWAYS engage the Hebrew (OT), Greek (NT), or Aramaic text.
2. Strong's numbers are REQUIRED for every word studied.
3. Never fabricate Strong's numbers or original language words.
4. Morphological analysis must be written in plain English
   interpretation — not raw grammatical codes.
   CORRECT: "Paul uses the aorist tense here — a single completed
   act, not an ongoing process. Compare how he uses the present
   tense in Romans 5:1 where the difference matters because..."
   WRONG: "V-AAI-3S"
5. Semantic disambiguation is MANDATORY whenever an English word
   translates multiple different Greek/Hebrew words. The user MUST
   know which word is being used here and why it matters.

═══════════════════════════════════════════════════
VERSE TEXT RULE
═══════════════════════════════════════════════════
{VERSE_TEXT} is provided by the user. Use it as given.
Never alter, paraphrase, or replace it.
If a verse text is not provided and you are uncertain of the
exact wording, cite the reference and explain its meaning without
quoting the text. Never fabricate scripture.

═══════════════════════════════════════════════════
OUTPUT RULES
═══════════════════════════════════════════════════
- Return ONLY valid JSON. No markdown. No preamble. No text outside.
- NEVER OMIT A SECTION. There are 14 expected JSON keys/sections in the output. You MUST provide all 14 sections. DO NOT skip any of them, even if you feel they are redundant.
- If a section genuinely does not apply to this specific text, provide an empty array `[]` for list fields, or an empty object `{}` for object fields, or `null` for string fields. But the key MUST exist in the JSON.
- Textual apparatus notes: only include when manuscript issues genuinely affect interpretation of this specific text.
- Every exegesis is always maximum depth. There is no short mode.
''';

  // ── SECTION 04 — VERSE PROMPT ────────────────────────────────────────
  static const String _kVersePrompt = r'''
Conduct a complete textual study of: {VERSE_REFS}
Verse text(s) ({TRANSLATION}): "{VERSE_TEXTS}"
Verse range: {IS_RANGE}
User's question: "{USER_QUESTION}"

{
  "entryType": "verse",
  "subject": "{VERSE_REFS}",
  "translation": "{TRANSLATION}",

  "bigPicture": "2–3 sentences. The single most important insight about this text — stated as a discovery. What does understanding this text change? Must cite the verse itself and at least one other supporting reference. Written to make the reader say 'I never understood that before.'",

  "historicalCulturalSetting": {
    "world": "Put the reader inside the world of this text. Who are these people? What is the political reality — Roman occupation, Babylonian exile, post-exilic restoration? What are the religious assumptions of the day — temple worship, Pharisaic law, pagan religion? What would hearing this text have felt like to someone in that world? Write it as a scene, not a lecture. Minimum 100 words. Cite verifiable scriptural details.",
    "specificCulturalKeys": [
      {
        "item": "A specific cultural practice, institution, or assumption that directly shapes this text's meaning",
        "howItShapesReading": "What the reader misses without this cultural knowledge — and how knowing it changes the text. Cite at least one supporting scripture reference."
      }
    ]
  },

  "literaryContext": {
    "genre": "The literary genre of this book and passage. How does genre govern reading: narrative is read differently from epistle, poetry from law, prophecy from wisdom? What genre-specific rules must the reader apply to this specific text?",
    "immediateBefore": "What is happening in the verses immediately before this text (cite them by reference)? What does that setup contribute? What question or situation does this text answer?",
    "immediateAfter": "What comes immediately after (cite verses)? How does this text flow into what follows? Is this a thesis that the following verses prove, or a conclusion of what came before?",
    "structuralRole": "What is this text's role in its chapter and book? Thesis | Development | Illustration | Pivot | Climax | Conclusion | Aside. Explain why with reference to the surrounding text.",
    "passageFlow": "If IS_RANGE is true: walk through the logical or narrative movement across the verses — how does the argument or story move from the first verse to the last? Identify the hinge verse around which the passage turns and explain why. If IS_RANGE is false: describe the verse's position within its paragraph's argument."
  },

  "wordStudy": [
    {
      "englishWord": "The English word as it appears in the provided translation",
      "verseRef": "Which verse in the selection this word appears in",
      "originalWord": "Original script: Hebrew (OT) or Greek (NT)",
      "transliteration": "Romanised phonetic spelling",
      "strongsNumber": "H#### for Hebrew · G#### for Greek — REQUIRED",
      "lexicalDefinition": "The full lexical meaning — NOT just a synonym. The semantic range: all the different things this word can mean across biblical literature. What is the full range?",
      "meaningInThisContext": "Which specific meaning within the semantic range is activated in this particular verse and why? What contextual, grammatical, or literary signals determine this specific sense rather than another? Be precise.",
      "discoveryNote": "Write this as a revelation moment — not a dictionary entry. 'The English says X. But the word used here is Y — and that means something the English cannot capture...' This is what makes the word study come alive for the reader.",
      "otherOccurrences": [
        {
          "reference": "Book Chapter:Verse",
          "context": "How this same word is used in this other passage and what it reveals about the word's full meaning — especially if the usage illuminates or contrasts with its use in the studied text"
        }
      ]
    }
  ],

  "morphologicalAnalysis": [
    {
      "word": "The English word",
      "originalWord": "Original script",
      "strongsNumber": "H#### or G####",
      "partOfSpeech": "Verb | Noun | Adjective | Adverb | Preposition | Article | Conjunction | Particle | Pronoun",
      "tense": "For verbs: Present | Aorist | Perfect | Imperfect | Future | Pluperfect. Or null for non-verbs.",
      "voice": "For verbs: Active | Passive | Middle. Or null.",
      "mood": "For verbs: Indicative | Subjunctive | Imperative | Infinitive | Participle | Optative. Or null.",
      "personNumber": "For verbs/pronouns: 1st/2nd/3rd + Singular/Plural. Or null.",
      "plainEnglishExplanation": "What does this grammatical form mean in plain English — and why does it matter for this text? NEVER use grammatical codes in this field. Write it as: 'This verb is in the [tense] tense, [voice] voice — meaning [plain English explanation of what that grammatically means]. This matters because [theological or interpretive implication]. Compare this with [cite a related passage] where the same author uses [different form] to mean something different...'"
    }
  ],

  "semanticDisambiguation": [
    {
      "englishWord": "The English word that could translate multiple originals",
      "disambiguation": "This English word translates multiple different original language words with distinct meanings. In this text the word used is [original word + Strong's]. This is NOT the same as [other word + Strong's] which appears in [cite a verse] and means [different meaning]. The distinction matters because [theological implication of getting this right vs. wrong]. Readers who don't know this distinction will...",
      "wordUsedHere": "The specific original word in this text",
      "wordUsedHereStrongs": "Its Strong's number",
      "confusedWith": [
        {
          "word": "The other word commonly confused with this one",
          "strongsNumber": "Its Strong's number",
          "meaningDifference": "Precisely how its meaning differs",
          "exampleVerse": "A verse where this other word is used so the reader can see the contrast clearly"
        }
      ]
    }
  ],

  "mentionAnalysis": [
    {
      "concept": "The key concept being traced",
      "firstMention": {
        "reference": "Where this concept first appears in scripture",
        "verseText": "Text of first mention or null",
        "whatItEstablishes": "What the first mention establishes as the foundational meaning — the seed form of the concept that all later occurrences develop. Why does it matter that THIS is where it first appears?"
      },
      "developmentMentions": [
        {
          "reference": "A significant subsequent mention",
          "development": "How this mention develops, nuances, or deepens the concept established at first mention"
        }
      ],
      "emphasisPattern": "Does the biblical author repeat this word deliberately within this passage or book? If so, what does the repetition pattern reveal about its importance? Cite all instances of the repetition."
    }
  ],

  "discourseAnalysis": {
    "rhetoricalFunction": "What is this text trying to accomplish in the reader? Command | Promise | Warning | Comfort | Argument | Narrative | Doxology | Lament | Question | Declaration. This is not just a label — explain what the author intends the reader to believe, feel, or do as a result of this text.",
    "logicalConnectors": [
      {
        "word": "A logical connector: therefore, but, for, because, so that, since, although, if, then, now",
        "originalWord": "Greek: οὖν, δέ, γάρ, ὅτι, ἵνα, εἰ etc. Or Hebrew equivalent",
        "significance": "How this connector carries the argument's logical weight. What comes before it, what comes after, and what logical relationship does it establish? Martin Luther said 'whenever you see therefore in Paul, find out what it is there for' — apply that principle here."
      }
    ],
    "authorIntent": "What was the author trying to achieve by writing THIS text at THIS point in their argument or narrative? What response were they seeking from the original reader?"
  },

  "crossReferences": [
    {
      "reference": "Book Chapter:Verse or range",
      "verseText": "Exact text or null",
      "connectionType": "Parallel | OT-Quotation | OT-Allusion | Contrast | Development | Fulfillment | Same-Author-Same-Word | Interpretive-Key",
      "specificContribution": "This is NOT a reference list. Explain specifically what THIS reference adds to understanding THIS text. What would be lost if this connection were missed? Minimum 40 words per reference."
    }
  ],

  "intertextualAllusions": [
    {
      "sourceText": "The OT text being alluded to (most allusions move OT→NT, though some NT texts allude to earlier NT)",
      "sourceVerseText": "Text of the source or null",
      "allusionText": "The studied text that contains the allusion",
      "howToHearIt": "A scripture-saturated first-century reader would have immediately heard [source text] when they read [this text]. The allusion works because [explain the shared language, concept, or narrative]. Understanding this allusion reveals that the author is claiming [theological implication]. Minimum 60 words."
    }
  ],

  "textualApparatusNotes": {
    "include": true,
    "notes": "ONLY when manuscript issues genuinely affect interpretation. 'The oldest manuscripts (p46, Sinaiticus, Vaticanus) read X. Some later manuscripts add Y. Most scholars prefer X because Z. This matters for interpretation because...' Written plainly — not to create doubt but to create clarity. Or null if include is false."
  },

  "impliedTheologicalClaim": "Every text makes an implicit claim about God, humanity, sin, salvation, or the world. State the claim this text makes explicitly: 'This text requires the reader to believe that...' Then show where else in scripture this claim is confirmed, developed, or grounded. Minimum 80 words. Cite 3+ references.",

  "whatItCannotMean": [
    {
      "commonMisreading": "A specific reading of this text that is widespread but wrong — stated charitably and accurately",
      "whyItIsWrong": "The precise linguistic or contextual reason this reading is impossible. Not 'it seems unlikely' but 'this reading requires [X] but the text says [Y] because the word used is [Z + Strong's] which means...' Cite the specific evidence that rules it out.",
      "whatItActuallyMeans": "The correction — grounded in everything the analysis above has established. Written as a relief, not a rebuke."
    }
  ],

  "fromTextToLife": "Application that flows directly from the text's original intent — not from cultural priorities imported into it. The original meaning established above determines what application is legitimate. Never moralism. Never guilt. Show how the truth the text establishes changes a specific perspective, practice, or prayer. Minimum 80 words. Cite 2+ supporting references.",

  "somethingToSitWith": "One meditation question or thought the reader carries away. Not a comprehension question — a personal encounter with the truth this text contains. Built specifically from this text's content."
}
''';

  // ── SECTION 05 — TOPIC PROMPT ────────────────────────────────────────
  static const String _kTopicPrompt = r'''
Conduct a text-anchored study of the biblical concept: "{TOPIC_NAME}"
Specific angle (optional): "{SPECIFIC_ANGLE}"

IMPORTANT: This is NOT a thematic survey. Identify the 3–5 passages
that most definitively establish what the Bible means by this concept
and exegete each one. The user understands the concept by understanding
the texts — not by reading a general overview of the texts.

{
  "entryType": "topic",
  "subject": "{TOPIC_NAME}",

  "bigPicture": "What does the Bible actually mean by this concept — as distinct from what culture assumes it means? State the most important reframing in 2–3 sentences. Must cite the most definitive scripture for this concept.",

  "conceptDefinition": {
    "hebrewWord": {
      "word": "Primary Hebrew word for this concept (OT)",
      "originalScript": "Hebrew script",
      "transliteration": "...",
      "strongsNumber": "H####",
      "fullSemanticRange": "Everything this Hebrew word can mean. Cite 3 OT passages showing its range of use."
    },
    "greekWord": {
      "word": "Primary Greek word for this concept (NT)",
      "originalScript": "Greek script",
      "transliteration": "...",
      "strongsNumber": "G####",
      "fullSemanticRange": "Everything this Greek word can mean. What shifts between the Hebrew and Greek usage? Cite 3 NT passages showing its range."
    },
    "semanticDisambiguation": "Are there MULTIPLE Hebrew or Greek words that translate to this English concept — each with different shades of meaning? (e.g. 'faith': πίστις vs. ἐλπίς vs. πεποίθησις; 'love': ἀγάπη vs. φιλέω vs. στοργή vs. ἔρως) Explain each distinct word, its specific meaning, and a verse where it appears so the user can see the distinctions in context. This is critical — if the user doesn't know these distinctions, they cannot understand the concept fully.",
    "modernVsAncient": "Where does the modern understanding of this concept diverge from the biblical one? This is where the most important reframing happens. Be specific and cite the texts that establish the biblical definition."
  },

  "firstMention": {
    "reference": "Where this concept first appears in scripture",
    "verseText": "Text of first mention or null",
    "whatItEstablishes": "What the first appearance establishes as the seed form of this concept — everything later development builds on. Why does it matter that THIS is where it first appears? What form does it take?"
  },

  "definingPassages": [
    {
      "reference": "One of the 3–5 most definitionally important passages",
      "verseText": "Exact text or null",
      "whyDefinitive": "Why THIS passage is one of the most important texts for understanding this concept",
      "historicalCulturalContext": "The specific historical and cultural context of this passage that shapes how the concept is used here. Minimum 50 words. Cite supporting references.",
      "wordStudy": [
        {
          "englishWord": "The English word as it appears in the provided translation",
          "verseRef": "Which verse in the selection this word appears in",
          "originalWord": "Original script: Hebrew (OT) or Greek (NT)",
          "transliteration": "Romanised phonetic spelling",
          "strongsNumber": "H#### or G#### — REQUIRED",
          "lexicalDefinition": "The full lexical meaning and semantic range",
          "meaningInThisContext": "Which specific meaning is activated here and why?",
          "discoveryNote": "The revelation moment for this word in this passage.",
          "otherOccurrences": [
            {
              "reference": "Book Chapter:Verse",
              "context": "How this word is used here and what it reveals"
            }
          ]
        }
      ],
      "morphologicalNote": "The most important grammatical observation about how the concept word functions in this passage. Plain English. Cite a contrasting passage.",
      "whatThisPassageSays": "What does THIS passage specifically contribute to understanding this concept? Not what the concept is generally — but what THIS text's specific angle adds. Minimum 80 words. Cite 3+ references from within and around this passage.",
      "connectionsToOtherDefiningPassages": "How does this passage relate to the other defining passages? Does it build on, nuance, fulfil, or stand in tension with them?"
    }
  ],

  "canonicalProgression": "How does this concept develop across the canon from its first mention to its fullest expression? Not a general survey — a specific progression: 'In the Torah, [concept] appears as [X] — seen in [cite passage]. By the time of the Prophets, it has developed into [Y] — see [cite passage]. In the Gospels, Jesus redefines it as [Z] by [cite specific words of Jesus]. Paul then develops it as [W] in [cite passage]. Revelation shows its final form as [V] in [cite passage].' Minimum 150 words. Cite minimum 7 references across the canon.",

  "commonDistortions": [
    {
      "distortion": "A common misunderstanding or misuse of this concept",
      "howItEnters": "Why this distortion is so widespread",
      "linguisticCorrection": "The specific word-level reason this distortion is wrong — which word is being misread, and what does the original language actually say? Cite 2+ references."
    }
  ],

  "impliedTheologicalClaim": "What does the full biblical treatment of this concept require the reader to believe about God, humanity, or salvation? State it as a claim. Cite 3+ texts that together establish this claim.",

  "whatItCannotMean": [
    {
      "commonMisreading": "A specific reading that is widespread but wrong",
      "whyItIsWrong": "The precise linguistic or contextual reason this reading is impossible.",
      "whatItActuallyMeans": "The correction — grounded in everything the analysis above has established."
    }
  ],

  "fromTextToLife": "How understanding this concept as the texts define it — rather than as culture defines it — changes how the believer reads scripture, prays, or lives. Be specific. Cite 2+ references.",

  "somethingToSitWith": "One meditation question that invites the reader to sit inside this concept personally."
}
''';
}
