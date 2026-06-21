import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:church_mobile/features/bible_ai/services/ai_service.dart';
import '../../../data/repositories/prompt_repository.dart';
import '../models/exegesis_result_model.dart';

/// Service responsible for all Exegesis v2 AI interactions.
/// Handles system prompt loading, dynamic prompt selection by entry type,
/// and JSON parsing into ExegesisResult models.
class ExegesisAiService {
  final AiService _aiService;

  ExegesisAiService({required AiService aiService}) : _aiService = aiService;

  // ═══════════════════════════════════════════════════════════════════
  //  SYSTEM PROMPT (always active)
  // ═══════════════════════════════════════════════════════════════════

  static const String _fallbackSystemPrompt = '''
You are LOGOS — a world-class biblical exegete embedded in illuminare.
You hold mastery in biblical Hebrew, Koine Greek, and Aramaic, systematic
theology, church history, hermeneutics, and patristic literature.

═══════════════════════════════════════
CORE HERMENEUTICAL COMMITMENTS
═══════════════════════════════════════
1. GRAMMATICAL-HISTORICAL METHOD
   Determine the author's intended meaning in its original historical
   and grammatical context. Never impose modern frameworks onto
   ancient texts.

2. SCRIPTURE INTERPRETS SCRIPTURE
   Unclear passages are illuminated by clearer ones. Always cross-
   reference within the canon before reaching for external sources.

3. DISTINGUISH SHARPLY
   - What the text SAYS (observation)
   - What it MEANS in original context (interpretation)
   - What it MEANS for today (application)
   These are three separate operations. Never conflate them.

4. HONOUR LEGITIMATE SCHOLARLY DIVERSITY
   Where godly, careful scholars have disagreed for centuries,
   present the major positions fairly. Never declare one tradition's
   conclusion as "the" answer on genuinely contested ground.

5. CALIBRATE CONFIDENCE
   Be certain where scripture is certain. Be humble where scripture
   is genuinely ambiguous. Signal the difference clearly.

6. ORIGINAL LANGUAGES ARE AUTHORITATIVE
   Always engage the Hebrew, Greek, or Aramaic text. Cite Strong's
   numbers for key words. Explain translation choices where they
   affect meaning significantly.

═══════════════════════════════════════
OUTPUT RULES
═══════════════════════════════════════
- Return ONLY valid JSON. No markdown. No preamble. No commentary
  outside the JSON structure.
- Never fabricate verse text. If uncertain of exact wording, cite
  the reference and explain the meaning.
- Never invent Strong's numbers or Greek/Hebrew words.
- Tone: scholarly, accessible, pastoral, reverent — never dry or
  academic for its own sake. Write for a serious Bible student,
  not a seminary professor.
- Depth level affects response length and technical density:
  OVERVIEW = concise highlights per section, ~100-150 words each
  DEEP = full analysis per section, ~200-350 words each
  SCHOLARLY = full analysis + technical notation + named sources,
              ~350-500 words each
''';

  // ═══════════════════════════════════════════════════════════════════
  //  MAIN ENTRY POINT
  // ═══════════════════════════════════════════════════════════════════

  /// Generates an exegesis for the given [subject] based on [entryType]
  /// and [depthLevel].
  Future<ExegesisResult> generateExegesis({
    required String subject,
    required String entryType,
    required String depthLevel,
    String denomPref = 'Non-denominational',
  }) async {
    final repo = PromptRepository();
    final systemPrompt =
        await repo.getPrompt('exegesis_system_v2') ?? _fallbackSystemPrompt;

    final userPrompt = _buildDynamicPrompt(
      entryType: entryType,
      subject: subject,
      depthLevel: depthLevel,
      denomPref: denomPref,
    );

    debugPrint('⟹ Exegesis v2: Generating $entryType for "$subject" at $depthLevel');

    final responseText = await _aiService.getAiResponse(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
    );

    debugPrint('⟹ Exegesis v2 raw response length: ${responseText.length}');

    final data = jsonDecode(responseText) as Map<String, dynamic>;
    return ExegesisResult.fromJson(data);
  }

  // ═══════════════════════════════════════════════════════════════════
  //  DYNAMIC PROMPT ROUTER
  // ═══════════════════════════════════════════════════════════════════

  String _buildDynamicPrompt({
    required String entryType,
    required String subject,
    required String depthLevel,
    required String denomPref,
  }) {
    switch (entryType) {
      case 'Single Verse':
        return _buildVersePrompt(subject, depthLevel, denomPref);
      case 'Passage':
        return _buildPassagePrompt(subject, depthLevel, denomPref);
      case 'Bible Book':
        return _buildBookPrompt(subject, depthLevel, denomPref);
      case 'Bible Character':
        return _buildCharacterPrompt(subject, depthLevel, denomPref);
      case 'Theme':
        return _buildThemePrompt(subject, depthLevel, denomPref);
      default:
        return _buildVersePrompt(subject, depthLevel, denomPref);
    }
  }

  // ─── PROMPT 1: Single Verse ─────────────────────────────────────

  String _buildVersePrompt(String verse, String depth, String denom) {
    return '''
Conduct a complete exegetical analysis of $verse.

Depth level: $depth
User's theological background: $denom

Return a JSON object with EXACTLY these keys:

{
  "entryType": "Single Verse",
  "subject": "$verse",
  "depthLevel": "$depth",
  "originalLanguage": "Hebrew | Greek | Aramaic",

  "executiveSummary": "2-4 sentence overview of what this verse says, means, and why it matters canonically. Write this as the most insightful thing a student could read in 30 seconds.",

  "historicalContext": {
    "author": "Who wrote this and what we know about them",
    "audience": "Original recipients and their situation",
    "date": "Approximate date and basis for dating",
    "politicalSetting": "Relevant political/social context",
    "geographicContext": "Location and geographical significance",
    "culturalNotes": "Cultural assumptions the original reader brought to this text that modern readers miss"
  },

  "literaryStructure": {
    "genre": "Narrative|Epistle|Poetry|Prophecy|Wisdom|Apocalyptic|Law|Gospel",
    "structure": "How this verse is structured syntactically and where it sits in the surrounding argument or narrative",
    "literaryDevices": ["List any metaphor, chiasm, parallelism, hyperbole, typology, irony present"],
    "positionInBook": "How this verse functions within its chapter and book — is it a thesis, illustration, conclusion, climax?"
  },

  "languageStudy": [
    {
      "word": "Original script (Hebrew/Greek)",
      "transliteration": "Romanised phonetic spelling",
      "strongsNumber": "H1234 or G5678",
      "partOfSpeech": "Verb/Noun/Adjective/Preposition etc",
      "definition": "Core lexical meaning",
      "semanticRange": "Full range of meanings this word carries in biblical literature",
      "usageNote": "Why this specific word choice matters here",
      "translationComparison": "How KJV, ESV, NIV, NASB translate this word and what that difference reveals"
    }
  ],

  "grammaticalNotes": "Narrative analysis of the most significant grammatical features: verb tenses and their theological implications, pronoun references, connecting particles, and sentence structure.",

  "theologicalMeaning": {
    "doctrineEstablished": "What theological truth this verse grounds, supports, or nuances",
    "metaNarrativePlacement": "Where in the Creation→Fall→Redemption→Restoration arc does this verse sit",
    "christologicalConnection": "How does this text point to, reveal, or find its fulfilment in Jesus Christ?",
    "otNtConnection": "OT texts this alludes to (if NT) or NT texts that develop this theme (if OT)"
  },

  "interpretiveTraditions": [
    {
      "traditionName": "e.g. Reformed | Arminian | Catholic | Orthodox",
      "interpretation": "Their reading of this verse",
      "supportingVerses": ["References they cite"],
      "agreementWithOthers": "Where they agree with other traditions"
    }
  ],

  "applicationBridge": {
    "originalIntent": "What the author intended the original audience to do, feel, or believe",
    "timelessPrinciple": "The universal truth that transcends the original cultural context",
    "modernApplication": "How a faithful Christian today can apply this — specific, not generic",
    "misapplicationWarnings": ["Common ways this verse is taken out of context or misused"]
  },

  "crossReferences": [
    {
      "reference": "Book Chapter:Verse",
      "connectionType": "Parallel|Allusion|Fulfillment|Contrast|Development",
      "explanation": "How this reference illuminates the subject verse"
    }
  ],

  "scholarlyDebates": [
    {
      "topic": "The precise exegetical question scholars debate",
      "positionA": "First scholarly position with named proponents",
      "positionB": "Second scholarly position with named proponents",
      "commonGround": "What both positions agree on"
    }
  ],

  "comprehensionQuiz": [
    {
      "question": "A deep interpretive question, not trivia",
      "answer": "The answer grounded in the exegesis above",
      "explanation": "Why this matters for understanding the text"
    }
  ],

  "studyNextSteps": ["2-3 natural next subjects that would deepen understanding"]
}

Include 3-6 key words in languageStudy. Provide 5-9 cross-references. Include exactly 5 comprehension questions. Omit scholarlyDebates if depth is Overview. Include 2-3 traditions only where genuine interpretive diversity exists.
''';
  }

  // ─── PROMPT 2: Passage / Chapter ─────────────────────────────────

  String _buildPassagePrompt(String passage, String depth, String denom) {
    return '''
Conduct a complete exegetical analysis of $passage as a unified literary and theological unit.

Depth level: $depth
User's theological background: $denom

KEY INSTRUCTIONS FOR PASSAGE TYPE:
- The literary structure section must address the ARGUMENT FLOW across the whole passage.
- The languageStudy section focuses on 4-8 KEY TERMS load-bearing for the passage's main argument.
- The grammaticalNotes section must identify the passage's theological HINGE VERSES.

Return a JSON object with EXACTLY these keys:

{
  "entryType": "Passage",
  "subject": "$passage",
  "depthLevel": "$depth",
  "originalLanguage": "Hebrew | Greek | Aramaic",
  "executiveSummary": "What is the single main argument or narrative this passage makes? 2-4 sentences.",
  "historicalContext": {
    "author": "...", "audience": "...", "date": "...",
    "politicalSetting": "...", "geographicContext": "...", "culturalNotes": "..."
  },
  "literaryStructure": {
    "genre": "Primary genre",
    "argumentFlow": "Walk through the logical or narrative progression. Identify HINGE VERSE(S).",
    "structure": "",
    "literaryDevices": ["Devices used across the passage"],
    "passageOutline": "e.g. vv.1-5: Theme A / vv.6-11: Theme B / vv.12-17: Climax",
    "positionInBook": "How this passage functions within the book"
  },
  "languageStudy": [
    {
      "verseRef": "Which verse this word appears in",
      "word": "...", "transliteration": "...", "strongsNumber": "...",
      "definition": "...", "semanticRange": "...", "usageNote": "..."
    }
  ],
  "grammaticalNotes": "Focus on CONNECTING WORDS between sections. Identify the grammatical structure signaling the passage's main point.",
  "theologicalMeaning": {
    "centralThesis": "What single theological truth is this passage primarily establishing?",
    "doctrineEstablished": "...",
    "metaNarrativePlacement": "...",
    "christologicalConnection": "...",
    "otNtConnection": "..."
  },
  "interpretiveTraditions": [{"traditionName":"...","interpretation":"...","supportingVerses":["..."],"agreementWithOthers":"..."}],
  "applicationBridge": {"originalIntent":"...","timelessPrinciple":"...","modernApplication":"...","misapplicationWarnings":["..."]},
  "crossReferences": [{"reference":"...","connectionType":"...","explanation":"..."}],
  "scholarlyDebates": [{"topic":"...","positionA":"...","positionB":"...","commonGround":"..."}],
  "comprehensionQuiz": [{"question":"...","answer":"...","explanation":"..."}],
  "studyNextSteps": ["..."]
}

Include 4-8 key words. Provide 5-9 cross-references. Include exactly 5 quiz questions.
''';
  }

  // ─── PROMPT 3: Bible Book ────────────────────────────────────────

  String _buildBookPrompt(String book, String depth, String denom) {
    return '''
Conduct a comprehensive introductory and thematic exegesis of the $book as a complete canonical unit.

Depth level: $depth
User's theological background: $denom

KEY INSTRUCTIONS FOR BOOK TYPE:
- Do NOT drill into individual verse grammar.
- Focus on: authorship, structure, major themes, canonical purpose, and the book's place in redemptive history.
- languageStudy means THEOLOGICALLY KEY TERMS unique to or central in this book.

Return a JSON object with EXACTLY these keys:

{
  "entryType": "Bible Book",
  "subject": "$book",
  "depthLevel": "$depth",
  "originalLanguage": "Hebrew | Greek | Aramaic | Mixed",
  "executiveSummary": "What is this book, why was it written, and why does it matter in the canon? 3-5 sentences.",
  "historicalContext": {
    "author": "Authorship — traditional view and any scholarly debates",
    "audience": "Original recipients and their circumstances",
    "date": "Date range with basis",
    "occasion": "What specific situation or crisis prompted this book?",
    "politicalSetting": "...",
    "culturalNotes": "..."
  },
  "literaryStructure": {
    "genre": "Primary and any secondary genres",
    "bookOutline": "Major sections with chapter ranges and one-line themes",
    "structure": "",
    "unifyingTheme": "The single thread that ties the whole book together",
    "literaryDevices": ["Major structural and literary features"],
    "keyPassages": [{"reference":"...","reason":"Why this passage is load-bearing"}],
    "positionInBook": ""
  },
  "languageStudy": [
    {
      "word": "Original script", "transliteration": "...", "strongsNumber": "...",
      "definition": "...", "roleInBook": "How this word functions as a theological anchor throughout this book",
      "semanticRange": "", "usageNote": ""
    }
  ],
  "grammaticalNotes": "Focus on the book's CHARACTERISTIC STYLE. What does the writing style reveal about the author's purpose?",
  "theologicalMeaning": {
    "centralPurpose": "What is God doing through this book? What does it contribute to the whole Bible's story?",
    "majorThemes": [{"theme":"...","development":"...","keyVerse":"..."}],
    "canonicalPosition": "How this book connects to what comes before and after it in the canon",
    "metaNarrativePlacement": "...",
    "christologicalConnection": "..."
  },
  "interpretiveTraditions": [{"traditionName":"...","interpretation":"...","supportingVerses":["..."],"agreementWithOthers":"..."}],
  "applicationBridge": {"originalIntent":"...","timelessPrinciple":"...","modernApplication":"...","misapplicationWarnings":["..."]},
  "crossReferences": [{"reference":"...","connectionType":"...","explanation":"..."}],
  "scholarlyDebates": [{"topic":"...","positionA":"...","positionB":"...","commonGround":"..."}],
  "comprehensionQuiz": [{"question":"...","answer":"...","explanation":"..."}],
  "studyNextSteps": ["..."]
}

Include 5-7 theologically defining terms. Include exactly 5 quiz questions.
''';
  }

  // ─── PROMPT 4: Bible Character ───────────────────────────────────

  String _buildCharacterPrompt(String character, String depth, String denom) {
    return '''
Conduct a complete biblical character study and exegesis of $character.

Depth level: $depth
User's theological background: $denom

KEY INSTRUCTIONS FOR CHARACTER TYPE:
- Adds: biographyTimeline, characterPsychology, transformationArc.
- languageStudy focuses on the character's NAME meaning and key descriptor words.
- ALL analysis must be grounded in textual evidence. No speculative psychology.

Return a JSON object with EXACTLY these keys:

{
  "entryType": "Bible Character",
  "subject": "$character",
  "depthLevel": "$depth",
  "originalLanguage": "Hebrew | Greek | Mixed",
  "executiveSummary": "Who is this person in 3-4 sentences — their role, defining moment, and why they matter.",
  "historicalContext": {
    "era": "Biblical period (Patriarchal, Exodus, Kingdom, etc.)",
    "geographicContext": "Where they lived and moved",
    "politicalSetting": "Political world around them",
    "culturalNotes": "Cultural norms that shaped their choices",
    "keyRelationships": "Most theologically significant relationships",
    "author": "", "audience": "", "date": ""
  },
  "biographyTimeline": [
    {"event":"Name of the life event","reference":"Scriptural location","significance":"Theological significance"}
  ],
  "languageStudy": [
    {
      "word": "Their name in original language",
      "transliteration": "...", "strongsNumber": "...",
      "meaning": "Name meaning and its prophetic/theological significance",
      "additionalTerms": "Key Hebrew/Greek words used to describe this person",
      "definition": "", "semanticRange": "", "usageNote": ""
    }
  ],
  "characterPsychology": {
    "coreMotivations": "What drove them — grounded in text",
    "strengths": "Textually evidenced strengths",
    "weaknesses": "Textually evidenced flaws",
    "definingMoment": "The single scene that most reveals who they are"
  },
  "transformationArc": "How did this person change across their biblical story? Ground every point in specific textual references.",
  "literaryStructure": {"genre":"","structure":"","literaryDevices":[],"positionInBook":""},
  "grammaticalNotes": "",
  "theologicalMeaning": {
    "roleInRedemptiveHistory": "What specific role does this person play in God's unfolding plan?",
    "typologicalSignificance": "Do they prefigure Christ, the church, Israel, or a theological reality?",
    "metaNarrativePlacement": "Where do they sit in the Creation→Fall→Redemption→Restoration arc?",
    "christologicalConnection": "..."
  },
  "interpretiveTraditions": [{"traditionName":"...","interpretation":"...","supportingVerses":["..."],"agreementWithOthers":"..."}],
  "applicationBridge": {
    "lessonsFromStrengths": "What their faith/obedience teaches us",
    "warningsFromFailures": "What their failures warn us against",
    "timelessPrinciple": "The universal truth their life demonstrates",
    "originalIntent": "", "modernApplication": "",
    "misapplicationWarnings": ["Common ways this character's story is misused"]
  },
  "crossReferences": [{"reference":"...","connectionType":"...","explanation":"..."}],
  "scholarlyDebates": [{"topic":"...","positionA":"...","positionB":"...","commonGround":"..."}],
  "comprehensionQuiz": [{"question":"...","answer":"...","explanation":"..."}],
  "studyNextSteps": ["..."]
}

Include 5-10 biography events. Include exactly 5 quiz questions.
''';
  }

  // ─── PROMPT 5: Topic / Theme ─────────────────────────────────────

  String _buildThemePrompt(String theme, String depth, String denom) {
    return '''
Conduct a canonical thematic exegesis of the biblical theme of $theme across the entire Scripture.

Depth level: $depth
User's theological background: $denom

KEY INSTRUCTIONS FOR THEME TYPE:
- This is a CANONICAL THREAD TRACE — follow this concept from first appearance through progressive revelation to NT fulfilment and eschatological completion.
- Requires: canonicalDevelopment with firstMention, otDevelopment, fulfillmentInChrist, ntDevelopment, eschatologicalCompletion.
- languageStudy focuses on the PRIMARY WORD(S) in Hebrew and Greek, including any semantic shift between Testaments.

Return a JSON object with EXACTLY these keys:

{
  "entryType": "Theme",
  "subject": "$theme",
  "depthLevel": "$depth",
  "originalLanguage": "Hebrew + Greek",
  "executiveSummary": "What does this theme mean in biblical terms versus how it is commonly understood today? 3-4 sentences.",
  "historicalContext": {
    "conceptDefinition": "What does this concept mean in its original ancient context?",
    "modernVsAncient": "How does the modern understanding differ from the biblical one?",
    "culturalNotes": "...",
    "author": "", "audience": "", "date": "", "politicalSetting": ""
  },
  "languageStudy": [
    {
      "testament": "Old Testament | New Testament",
      "word": "Primary word for this theme",
      "transliteration": "...", "strongsNumber": "...",
      "definition": "...", "semanticRange": "...",
      "interTestamentalShift": "How does the meaning shift from OT to NT usage?",
      "usageNote": ""
    }
  ],
  "canonicalDevelopment": {
    "firstMention": {
      "reference": "Where this theme first appears in Scripture",
      "form": "Explicit, implicit, typological, or promise?",
      "significance": "What does the first mention establish?"
    },
    "otDevelopment": "How does this theme develop through Torah → Historical → Wisdom → Prophetic?",
    "fulfillmentInChrist": "How does Jesus embody, fulfil, or redefine this theme?",
    "ntDevelopment": "How do the Apostles develop this theme post-resurrection?",
    "eschatologicalCompletion": "How does this theme find ultimate completion in the new creation?"
  },
  "literaryStructure": {
    "genre": "Which biblical genres carry this theme most prominently?",
    "keyPassages": [{"reference":"...","reason":"What unique contribution each makes"}],
    "structure": "",
    "literaryDevices": ["How this theme is carried through imagery, typology, symbolism"],
    "positionInBook": ""
  },
  "grammaticalNotes": "Focus on how the key word(s) are used grammatically — verb vs noun usage, active vs passive voice, and what grammatical patterns reveal.",
  "theologicalMeaning": {
    "doctrinalSynthesis": "What is the full biblical doctrine on this theme?",
    "metaNarrativePlacement": "How does this theme function across Creation→Fall→Redemption→Restoration?",
    "christologicalConnection": "..."
  },
  "interpretiveTraditions": [{"traditionName":"...","interpretation":"...","supportingVerses":["..."],"agreementWithOthers":"..."}],
  "applicationBridge": {"originalIntent":"...","timelessPrinciple":"...","modernApplication":"...","misapplicationWarnings":["..."]},
  "crossReferences": [{"reference":"...","connectionType":"...","explanation":"..."}],
  "scholarlyDebates": [{"topic":"...","positionA":"...","positionB":"...","commonGround":"..."}],
  "comprehensionQuiz": [{"question":"...","answer":"...","explanation":"..."}],
  "studyNextSteps": ["..."]
}

Include primary Hebrew AND Greek words. Include 7-10 cross-references with one from each major section of the canon. Include exactly 5 quiz questions.
''';
  }
}
