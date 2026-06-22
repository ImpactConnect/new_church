import 'dart:convert';
import 'dart:developer' as developer;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gen_ai;
import 'package:dart_openai/dart_openai.dart';
import '../data/models/ai/ai_models.dart';
import '../data/models/bible/bible_version.dart';
import '../data/repositories/prompt_repository.dart';
import 'ai_config_service.dart';

class AiService {
  AiService({String? apiKey});

  FirebaseFunctions? _getFunctions() {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFunctions.instanceFor(region: 'us-central1');
      }
    } catch (_) {}
    return null;
  }

  // --- Verse Analysis ---

  Future<dynamic> explainVerse({
    required String bookName,
    required int chapterNumber,
    required int verseNumber,
    required String verseText,
    required BibleVersion version,
    required AiMode mode,
    required VerseFeature feature,
  }) async {
    final funcs = _getFunctions();
    if (funcs != null) {
      try {
        final callable = funcs.httpsCallable('explainVerse');
        final result = await callable.call({
          'bookName': bookName,
          'chapterNumber': chapterNumber,
          'verseNumber': verseNumber,
          'verseText': verseText,
          'version': version.name,
          'mode': mode.name,
          'feature': feature.name,
        });

        final data = Map<String, dynamic>.from(result.data as Map);
        return _parseVerseFeatureData(feature, data);
      } catch (e) {
        // Fallback to local
      }
    }

    // Local Fallback
    final repo = PromptRepository();
    String? systemPrompt = await repo.getPrompt(
      'explain_verse_${feature.name}',
    );

    // Sanitize poisoned Firestore prompts
    if (systemPrompt == null ||
        systemPrompt.contains('Deep theological explanation')) {
      systemPrompt = _getHardcodedPrompt(feature);
    }

    final userPrompt =
        'Analyze $bookName $chapterNumber:$verseNumber (${version.name}): "$verseText"';

    print('=== SYSTEM PROMPT for ${feature.name} ===');
    print(systemPrompt);
    print('=== END SYSTEM PROMPT ===');

    final responseText = await getAiResponse(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
    );

    if (responseText.isEmpty) throw Exception('No response from AI');

    developer.log(responseText, name: 'AI_RAW_RESPONSE_${feature.name}');

    final data = jsonDecode(responseText);
    return _parseVerseFeatureData(feature, Map<String, dynamic>.from(data));
  }

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

  dynamic _parseVerseFeatureData(
    VerseFeature feature,
    Map<String, dynamic> data,
  ) {
    // Normalize snake_case keys to camelCase
    var cleanedData = _normalizeKeys(data);

    // If response is wrapped in a feature-name key, unwrap it
    if (cleanedData.containsKey(feature.name) &&
        cleanedData[feature.name] is Map) {
      cleanedData = _normalizeKeys(
        Map<String, dynamic>.from(cleanedData[feature.name]),
      );
    }

    print('=== PARSED DATA for ${feature.name} ===');
    print('Keys: ${cleanedData.keys.toList()}');
    if (feature == VerseFeature.keyWord &&
        cleanedData.containsKey('keywords')) {
      print('KEYWORDS LENGTH: ${(cleanedData['keywords'] as List).length}');
    }
    print('=== END PARSED DATA ===');

    switch (feature) {
      case VerseFeature.explain:
        return ExplainAnalysis.fromJson(cleanedData);
      case VerseFeature.context:
        return ContextAnalysis.fromJson(cleanedData);
      case VerseFeature.keyWord:
        return KeyWordAnalysis.fromJson(cleanedData);
      case VerseFeature.crossRefs:
        return CrossReferencesAnalysis.fromJson(cleanedData);
      case VerseFeature.application:
        return ApplicationAnalysis.fromJson(cleanedData);
    }
  }

  String _getHardcodedPrompt(VerseFeature feature) {
    switch (feature) {
      case VerseFeature.explain:
        return '''You are a Bible exposition assistant. Analyze the given verse in its immediate and broader passage context.
Requirements: 
- Provide a `connectedThoughtRange` to summarize the broader passage flow. DO NOT just return the verse numbers. You MUST return the verse range followed by a summary of the speaker, audience, and narrative context in one line. Example format: "Matthew 7:1-10, Jesus preaching popularly called sermon on the mount, teaching the Israelites".
- Identify speaker and audience.
- Explain historical and literary context.
- Provide theological explanation.
- CRITICAL: You MUST identify at least one significant or interesting theological word in the verse, even if it seems straightforward. You MUST provide its Hebrew/Greek meaning in the `ambiguousTerms` array. This array MUST contain AT LEAST ONE item. DO NOT return an empty array [].
- Quote at least two supporting Scriptures, or other verses or stories describing the same thing.
- Avoid speculation.
- Identify which biblical covenant framework the verse belongs to.

Return strictly valid JSON matching this schema:
{
  "verseReference": "",
  "connectedThoughtRange": "",
  "speaker": "",
  "audience": "",
  "historicalContext": "",
  "literaryContext": "",
  "explanation": "",
  "ambiguousTerms": [
    {
      "term": "English word",
      "originalWord": "Greek/Hebrew word",
      "transliteration": "Transliteration",
      "definition": "Definition",
      "whyItMatters": "Why it matters contextually"
    }
  ],
  "supportingVerse": "",
  "covenant": [
    {
      "covenant": "",
      "applicability": "Direct | Principle-Based | Historical | Fulfilled",
      "explanation": ""
    }
  ]
}''';
      case VerseFeature.context:
        return '''You are a Bible context analysis assistant. Explain the verse within its surrounding passage.
Requirements: - Summarize verses before and after. - Identify chapter theme. - Clarify speaker and audience. - Identify literary type. - Note common out-of-context uses. - Quote at least one nearby verse.  - Provide relevant cultural or historical background that clarifies the verse. Explain how it affects interpretation. 
Return strictly valid JSON matching this schema:
{
  "immediateContextBefore": "",
  "immediateContextAfter": "",
  "chapterTheme": "",
  "speaker": "",
  "audience": "",
  "literaryType": "",
  "culturalBackgroundInsight": "",
  "culturalInterpretiveImpact": "",
  "commonMisunderstandings": "",
  "supportingVerse": ""
}''';
      case VerseFeature.keyWord:
        return '''You are a biblical word study assistant.

Requirements: 
- CRITICAL: You MUST identify and explain AT LEAST 3 to 5 significant theological words from the verse. DO NOT return fewer than 3 words.
- For each word, provide Hebrew/Greek original and transliteration.
- Provide concise lexical definition.
- Explain usage in this verse and elsewhere.
- Provide at least one additional verse reference.

Return strictly valid JSON matching this schema:
{
  "keywords": [
    {
      "word": "",
      "original": "",
      "transliteration": "",
      "definition": "",
      "usageInVerse": "",
      "usageElsewhere": "",
      "theologicalSignificance": "",
      "crossReference": ""
    }
  ]
}''';
      case VerseFeature.crossRefs:
        return '''You are a cross-reference generator.
Requirements: - Identify central theological theme. - Provide 3-5 strong cross references. - Explain connection clearly. - Avoid weak associations. 
Return strictly valid JSON matching this schema:
{
  "theme": "",
  "references": [
    {
      "reference": "",
      "connection": ""
    }
  ]
}''';
      case VerseFeature.application:
        return '''You are a Bible application assistant.
Requirements: - Restate central truth of verse. - Provide applications for personal, family, church, workplace, society. - Avoid moralism disconnected from context. - Include at least one supporting verse. - Identify if the verse is commonly misused. Explain the misuse and clarify correct interpretation using context.
Return strictly valid JSON matching this schema:
{
  "centralTruth": "",
  "commonMisuse": "",
  "applications": "",
  "applicationsAreas": {
    "personal": "",
    "family": "",
    "church": "",
    "workplace": "",
    "society": ""
  },
  "clarification": "",
  "supportingVerse": ""
}''';
    }
  }

  // --- Passage Analysis ---

  Future<PassageAnalysis> analyzePassage({
    required String bookName,
    required int chapterNumber,
    required int startVerse,
    required int endVerse,
    required String passageText,
    required BibleVersion version,
    required AiMode mode,
  }) async {
    final funcs = _getFunctions();
    if (funcs != null) {
      try {
        final callable = funcs.httpsCallable('analyzePassage');
        final result = await callable.call({
          'bookName': bookName,
          'chapterNumber': chapterNumber,
          'startVerse': startVerse,
          'endVerse': endVerse,
          'passageText': passageText,
          'version': version.name,
          'mode': mode.name,
        });

        final data = Map<String, dynamic>.from(result.data as Map);
        return PassageAnalysis.fromJson(data);
      } catch (e) {
        throw Exception('Failed to analyze passage: $e');
      }
    }
    throw Exception('Firebase is not initialized. Cannot analyze passage.');
  }

  // --- Chapter Analysis ---

  Future<ChapterAnalysis> analyzeChapter({
    required String bookName,
    required int chapterNumber,
    required String chapterText,
    required BibleVersion version,
    required AiMode mode,
  }) async {
    final funcs = _getFunctions();
    if (funcs != null) {
      try {
        final callable = funcs.httpsCallable('analyzeChapter');
        final result = await callable.call({
          'bookName': bookName,
          'chapterNumber': chapterNumber,
          'chapterText': chapterText,
          'version': version.name,
          'mode': mode.name,
        });

        final data = Map<String, dynamic>.from(result.data as Map);
        return ChapterAnalysis.fromJson(data);
      } catch (e) {
        throw Exception('Failed to analyze chapter: $e');
      }
    }
    throw Exception('Firebase is not initialized. Cannot analyze chapter.');
  }

  // --- Book Introduction ---

  Future<BookIntroduction> introduceBook({
    required String bookName,
    required BibleVersion version,
    required AiMode mode,
  }) async {
    final funcs = _getFunctions();
    if (funcs != null) {
      try {
        final callable = funcs.httpsCallable('introduceBook');
        final result = await callable.call({
          'bookName': bookName,
          'version': version.name,
          'mode': mode.name,
        });

        final data = Map<String, dynamic>.from(result.data as Map);
        return BookIntroduction.fromJson(data);
      } catch (e) {
        throw Exception('Failed to introduce book: $e');
      }
    }
    throw Exception('Firebase is not initialized. Cannot introduce book.');
  }
  // --- Chat ---

  Stream<String> chatWithVerse({
    required String bookName,
    required int chapterNumber,
    required int verseNumber,
    required String verseText,
    required String userMessage,
    required BibleVersion version,
    required List<ChatMessage> history,
    String? userName,
  }) async* {
    final repo = PromptRepository();
    final remotePrompt = await repo.getPrompt('chat_verse');

    final verseContext =
        '''
The user is asking about $bookName $chapterNumber:$verseNumber (${version.name}).
Verse Text: "$verseText"''';

    final gswIdentity = '''
You are Pastor GSW, the warm, encouraging, and shepherd-like pastor of the ministry. You are available 24/7 to answer members' questions and provide spiritual care.
Address the user as ${userName ?? 'there'} naturally, with the warmth of a loving pastor.
Speak in a pastoral, wise, compassionate, and spiritually sound tone. Always aim to nurture their faith and guide them closer to God through the Scriptures.''';

    final systemPrompt = remotePrompt != null
        ? '$gswIdentity\n\n$remotePrompt\n\n$verseContext'
        : '''
$gswIdentity
$verseContext

Rules:
1. Answer the user's question clearly, concisely, and with pastoral care.
2. ALWAYS quote at least one relevant Bible verse to support your answer.
3. Keep the tone helpful, encouraging, and theologically sound (balanced interpretation, reflecting your pastoral guidance).
4. If the user asks something unrelated to the Bible or faith, gently bring them back to the topic.
''';

    yield* getAiStream(
      systemPrompt: systemPrompt,
      userPrompt: userMessage,
      history: history,
    );
  }

  Stream<String> chatGeneral({
    required String userMessage,
    required List<ChatMessage> history,
    String? preloadedContext,
    String? userName,
  }) async* {
    final repo = PromptRepository();
    final remotePrompt = await repo.getPrompt('chat_general');

    final contextInstruction = preloadedContext != null
        ? '\n\nContext for this conversation:\n$preloadedContext'
        : '';

    final gswIdentity = '''
You are Pastor GSW, the warm, encouraging, and shepherd-like pastor of the ministry. You are available 24/7 to answer members' questions and provide spiritual care.
Address the user as ${userName ?? 'there'} naturally, with the warmth of a loving pastor.
Speak in a pastoral, wise, compassionate, and spiritually sound tone. Always aim to nurture their faith and guide them closer to God through the Scriptures.''';

    final systemPrompt = remotePrompt != null
        ? '$gswIdentity\n\n$remotePrompt$contextInstruction'
        : '''
$gswIdentity$contextInstruction

Rules:
1. Answer the user's question clearly, concisely, and with pastoral care.
2. ALWAYS quote at least one relevant Bible verse to support your answer if applicable.
3. Keep your tone encouraging, pastoral, and aligned with sound scripture.
4. If the user asks something unrelated to the Bible or faith, gently bring them back to the topic.
''';

    yield* getAiStream(
      systemPrompt: systemPrompt,
      userPrompt: userMessage,
      history: history,
    );
  }

  // --- Exegesis Engine ---

  final _exegesisSystemPrompt =
      '''You are a biblical exegesis engine. Produce historically grounded, context-aware, theologically balanced exegesis. Avoid devotional tone and speculation. Return structured JSON only. Do not include commentary outside JSON. Be concise but academically sound.''';

  Future<CharacterExegesis> generateCharacterExegesis(
    String character, {
    String depth = 'standard',
  }) async {
    final repo = PromptRepository();
    final sysPrompt =
        await repo.getExegesisPrompt('system') ?? _exegesisSystemPrompt;
    final template =
        await repo.getExegesisPrompt('character') ??
        '''Generate a {depth} depth character exegesis for: {character}.
Return strictly valid JSON matching this schema:
{
  "character": "",
  "historicalContext": "",
  "narrativeRole": "",
  "covenantalContext": "",
  "keyEvents": [""],
  "theologicalContribution": "",
  "strengths": [""],
  "failuresOrFlaws": [""],
  "progressionArc": "",
  "canonicalSignificance": "",
  "messianicOrTypologicalLinks": "",
  "scholarlyNotes": ""
}''';

    final userPrompt = template
        .replaceAll('{depth}', depth)
        .replaceAll('{character}', character);
    final responseText = await getAiResponse(
      systemPrompt: sysPrompt,
      userPrompt: userPrompt,
    );
    final data = jsonDecode(responseText);
    return CharacterExegesis.fromJson(Map<String, dynamic>.from(data));
  }

  Future<BookExegesis> generateBookExegesis(
    String book, {
    String depth = 'standard',
  }) async {
    final repo = PromptRepository();
    final sysPrompt =
        await repo.getExegesisPrompt('system') ?? _exegesisSystemPrompt;
    final template =
        await repo.getExegesisPrompt('book') ??
        '''Generate a {depth} depth book exegesis for: {book}.
Return strictly valid JSON matching this schema:
{
  "book": "",
  "authorship": "",
  "dateAndSetting": "",
  "originalAudience": "",
  "historicalBackground": "",
  "literaryStructure": "",
  "majorThemes": [""],
  "theologicalEmphases": "",
  "covenantalContext": "",
  "christologicalOrRedemptiveTrajectory": "",
  "keyPassages": [""],
  "interpretiveChallenges": "",
  "canonicalRole": ""
}''';

    final userPrompt = template
        .replaceAll('{depth}', depth)
        .replaceAll('{book}', book);
    final responseText = await getAiResponse(
      systemPrompt: sysPrompt,
      userPrompt: userPrompt,
    );
    final data = jsonDecode(responseText);
    return BookExegesis.fromJson(Map<String, dynamic>.from(data));
  }

  Future<ChapterExegesis> generateChapterExegesis(
    String book,
    int chapter, {
    String depth = 'standard',
  }) async {
    final repo = PromptRepository();
    final sysPrompt =
        await repo.getExegesisPrompt('system') ?? _exegesisSystemPrompt;
    final template =
        await repo.getExegesisPrompt('chapter') ??
        '''Generate a {depth} depth chapter exegesis for: {book} {chapter}.
Return strictly valid JSON matching this schema:
{
  "book": "",
  "chapter": "",
  "historicalContext": "",
  "literaryFlowSummary": "",
  "sectionBreakdown": [""],
  "majorThemes": [""],
  "keyTerms": [""],
  "interpretiveIssues": "",
  "canonicalConnection": "",
  "applicationPrinciples": [""]
}''';

    final userPrompt = template
        .replaceAll('{depth}', depth)
        .replaceAll('{book}', book)
        .replaceAll('{chapter}', chapter.toString());
    final responseText = await getAiResponse(
      systemPrompt: sysPrompt,
      userPrompt: userPrompt,
    );
    final data = jsonDecode(responseText);
    return ChapterExegesis.fromJson(Map<String, dynamic>.from(data));
  }

  Future<PassageExegesis> generatePassageExegesis(
    String reference, {
    String depth = 'standard',
  }) async {
    final repo = PromptRepository();
    final sysPrompt =
        await repo.getExegesisPrompt('system') ?? _exegesisSystemPrompt;
    final template =
        await repo.getExegesisPrompt('passage') ??
        '''Generate a {depth} depth passage exegesis for: {reference}.
Return strictly valid JSON matching this schema:
{
  "reference": "",
  "literaryContext": "",
  "historicalContext": "",
  "genreAnalysis": "",
  "structureAnalysis": "",
  "keyTerms": [""],
  "verseByVerseSummary": "",
  "theologicalThemes": [""],
  "covenantalSignificance": "",
  "christologicalFulfillment": "",
  "interpretiveDebates": "",
  "canonicalConnections": "",
  "doctrinalImplications": ""
}''';

    final userPrompt = template
        .replaceAll('{depth}', depth)
        .replaceAll('{reference}', reference);
    final responseText = await getAiResponse(
      systemPrompt: sysPrompt,
      userPrompt: userPrompt,
    );
    final data = jsonDecode(responseText);
    return PassageExegesis.fromJson(Map<String, dynamic>.from(data));
  }

  // --- Semantic Search ---

  Future<List<SemanticSearchResult>> semanticSearch(String query) async {
    final systemPrompt =
        '''You are a biblical search engine. The user will provide a concept, theme, or description rather than an exact quote. 
Your task is to find up to 5 Bible verses that are highly relevant to the concept: "$query".

Return strictly valid JSON matching this schema:
{
  "results": [
    {
      "bookName": "Genesis",
      "chapterNumber": 1,
      "verseNumber": 1,
      "reason": "Brief explanation of why this verse matches the concept."
    }
  ]
}''';

    final responseText = await getAiResponse(
      systemPrompt: systemPrompt,
      userPrompt: 'Find verses about: $query',
    );

    if (responseText.isEmpty) return [];

    try {
      final data = jsonDecode(responseText);
      final response = SemanticSearchResponse.fromJson(
        Map<String, dynamic>.from(data),
      );
      return response.results;
    } catch (e) {
      developer.log('Error parsing semantic search results: $e');
      return [];
    }
  }

  // --- Unified Helpers ---

  Future<String> getAiResponse({
    required String systemPrompt,
    required String userPrompt,
    String? modelOverride,
    bool isJson = true,
  }) async {
    final provider = await AiConfigService.getProvider();
    final apiKey = await AiConfigService.getApiKey();
    final modelName = modelOverride ?? await AiConfigService.getModel();

    if (provider == 'openai') {
      OpenAI.apiKey = apiKey;
      OpenAI.requestsTimeOut = const Duration(seconds: 120);
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
                userPrompt,
              ),
            ],
            role: OpenAIChatMessageRole.user,
          ),
        ],
        responseFormat: isJson ? const {"type": "json_object"} : null,
      );
      final contentList = completion.choices.first.message.content;
      if (contentList != null && contentList.isNotEmpty) {
        return _cleanJsonResponse(contentList.first.text ?? '');
      }
      return '';
    } else if (provider == 'gemini') {
      // Gemini
      final model = gen_ai.GenerativeModel(
        model: modelName,
        apiKey: apiKey,
        generationConfig: isJson ? gen_ai.GenerationConfig(
          responseMimeType: 'application/json',
        ) : null,
        systemInstruction: gen_ai.Content.system(systemPrompt),
      );
      final response = await model.generateContent([
        gen_ai.Content.text(userPrompt),
      ]).timeout(
        const Duration(seconds: 120),
        onTimeout: () => throw Exception('AI Service timed out after 2 minutes.'),
      );
      return _cleanJsonResponse(response.text ?? '');
    } else {
      throw Exception('Unsupported AI provider configured: $provider');
    }
  }

  /// Strips markdown code blocks (e.g. ```json ... ```) from AI response.
  String _cleanJsonResponse(String text) {
    var cleaned = text.trim();
    if (cleaned.startsWith('```')) {
      // Remove starting ```json or ```
      cleaned = cleaned.replaceFirst(RegExp(r'^```(json)?\s*'), '');
      // Remove ending ```
      cleaned = cleaned.replaceFirst(RegExp(r'\s*```$'), '');
    }
    return cleaned.trim();
  }

  Stream<String> getAiStream({
    required String systemPrompt,
    required String userPrompt,
    required List<ChatMessage> history,
  }) async* {
    final provider = await AiConfigService.getProvider();
    final apiKey = await AiConfigService.getApiKey();
    final modelName = await AiConfigService.getModel();

    if (provider == 'openai') {
      OpenAI.apiKey = apiKey;
      OpenAI.requestsTimeOut = const Duration(seconds: 120);
      final chatStream = OpenAI.instance.chat.createStream(
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
          ...history.map(
            (msg) => OpenAIChatCompletionChoiceMessageModel(
              content: [
                OpenAIChatCompletionChoiceMessageContentItemModel.text(
                  msg.message,
                ),
              ],
              role: msg.isUser
                  ? OpenAIChatMessageRole.user
                  : OpenAIChatMessageRole.assistant,
            ),
          ),
          OpenAIChatCompletionChoiceMessageModel(
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                userPrompt,
              ),
            ],
            role: OpenAIChatMessageRole.user,
          ),
        ],
      );

      await for (final chunk in chatStream) {
        final choices = chunk.choices;
        if (choices.isNotEmpty) {
          final content = choices.first.delta.content;
          if (content != null && content.isNotEmpty) {
            final text = content.first?.text;
            if (text != null) {
              yield text;
            }
          }
        }
      }
    } else if (provider == 'gemini') {
      // Gemini
      final model = gen_ai.GenerativeModel(
        model: modelName,
        apiKey: apiKey,
        systemInstruction: gen_ai.Content.system(systemPrompt),
      );

      final historyContent = history.map((msg) {
        return gen_ai.Content(msg.isUser ? 'user' : 'model', [
          gen_ai.TextPart(msg.message),
        ]);
      }).toList();

      final chat = model.startChat(history: historyContent);
      final response = chat.sendMessageStream(gen_ai.Content.text(userPrompt));

      await for (final chunk in response) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } else {
      throw Exception('Unsupported AI provider configured: $provider');
    }
  }
}
