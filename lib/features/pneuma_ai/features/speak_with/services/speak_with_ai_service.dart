import 'dart:convert';
import 'dart:developer' as developer;
import '../../../data/repositories/prompt_repository.dart';
import 'package:church_mobile/features/bible_ai/services/ai_service.dart';
import '../models/speak_with_models.dart';

class SpeakWithAiService {
  SpeakWithAiService(this._aiService, this._promptRepo);

  final AiService _aiService;
  final PromptRepository _promptRepo;

  /// Have a conversation in Author, Character, or Dual mode.
  /// Returns a plain text message string (not JSON).
  Future<String> chatWithFigure({
    required ConversationMode mode,
    required BiblicalFigure figure,
    required String userMessage,
    required List<ChatMessage> history,
    BiblicalFigure? figureB,
  }) async {
    // Use a direct persona system prompt.
    // We do NOT fetch from Firebase here because the stored prompt instructs
    // JSON output and conflicts with prose-based conversation.
    final systemPrompt = _buildSystemPrompt(figure, mode, figureB);

    // Build the user prompt with actual figure data injected
    final userPrompt = _buildUserPrompt(
      mode: mode,
      figure: figure,
      figureB: figureB,
      userMessage: userMessage,
      history: history,
    );

    // Call AI
    final responseText = await _aiService.getAiResponse(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      isJson: false,
    );

    if (responseText.isEmpty) throw Exception('No response from AI');

    // Clean and return the response
    return _extractMessage(responseText);
  }

  /// Builds a character-specific system prompt for this persona.
  /// NOT fetched from Firebase — the stored prompt uses a JSON schema that
  /// conflicts with prose-based conversation.
  String _buildSystemPrompt(
    BiblicalFigure figure,
    ConversationMode mode,
    BiblicalFigure? figureB,
  ) {
    final who = mode == ConversationMode.dual && figureB != null
        ? '${figure.name} and ${figureB.name}, two biblical figures'
        : mode == ConversationMode.author
        ? '${figure.name}, the biblical author'
        : '${figure.name}, a biblical figure';

    return 'You are $who speaking in illuminare\'s "Speak With" feature.\n'
        'PERSONA RULES:\n'
        '- Speak exclusively in first person as if you truly are this figure.\n'
        '- Draw on your own scriptural accounts, experiences, and historical context.\n'
        '- You do not know events after your lifetime unless God revealed them to you.\n'
        '- Stay entirely in character. Never break the persona.\n'
        '- If asked something outside your knowledge, say so in character.\n'
        'RESPONSE FORMAT:\n'
        '- Structure your response using markdown (headings, bullet/number lists, paragraphs, bold text) to provide a good user experience.\n'
        '- Do NOT output JSON, raw code blocks, or curly braces {}.\n'
        '- Do NOT prefix your response with your name (e.g., avoid "**Jesus:** "). Just start speaking.\n'
        '- Aim for 100-250 words per response. Be personal, warm, and rooted in scripture.\n'
        '- Cite scriptures using their reference in parentheses, e.g. (John 3:16).';
  }

  /// Attempts to get the "message" field from a JSON response.
  /// If the response is not JSON (as expected), returns the raw text.
  /// Aggressively strips all JSON artifacts so nothing renders as garbage.
  String _extractMessage(String responseText) {
    // 1. Strip markdown code fences
    String cleaned = responseText
        .replaceAll(RegExp(r'```json'), '')
        .replaceAll(RegExp(r'```'), '')
        .trim();

    // 2. Try to parse as JSON and extract the message field
    if (cleaned.startsWith('{')) {
      try {
        final jsonMap = jsonDecode(cleaned) as Map<String, dynamic>;
        // Try common field names for the message
        final msg =
            (jsonMap['message'] ?? jsonMap['response'] ?? jsonMap['text'])
                as String?;
        if (msg != null && msg.isNotEmpty) return msg.trim();
      } catch (_) {
        // JSON parse failed — fall through to text extraction
      }

      // 3. JSON parse failed but text starts with '{' — try to extract the
      //    natural-language content by removing JSON syntactic garbage.
      //    Pattern: strip leading { ... : and trailing } 8 } } etc.
      // Remove the leading JSON key (if any): e.g. { "message": "
      cleaned = cleaned.replaceAll(RegExp(r'^\{\s*"\w+"\s*:\s*"?'), '');
      // Remove JSON suffix garbage like " } 8 } 8 } ...
      cleaned = cleaned.replaceAll(RegExp(r'["\}\s\d]+$'), '');

      // If the string was partially JSON encoded, it might have escaped characters.
      // Unescape common JSON escapes.
      cleaned = cleaned
          .replaceAll(r'\"', '"')
          .replaceAll(r'\/', '/')
          .replaceAll(r'\n', '\n')
          .replaceAll(r'\t', '\t')
          .replaceAll(r'\\', r'\');
    }

    // 4. Strip any remaining JSON-like trailing characters
    cleaned = cleaned
        .replaceAll(RegExp(r'\}\s*(\d+\s*\}\s*)+$'), '') // trailing } 8 } 8 }
        .replaceAll(RegExp(r'^\{[^a-zA-Z]*'), '') // leading { with no text
        .replaceAll(RegExp(r'^"'), '') // stray leading quote
        .replaceAll(RegExp(r'"$'), '') // stray trailing quote
        .trim();

    // 5. Clean up any weird slashes or braces at the start/end
    cleaned = cleaned.replaceAll(RegExp(r'^[\/\{\}]+'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[\/\{\}]+$'), '');

    // 6. Remove any remaining **Name:** prefix if the AI ignored the rule
    cleaned = cleaned.replaceFirst(RegExp(r'^\*\*[^*]+:\*\*\s*'), '');

    return cleaned.isEmpty ? responseText.trim() : cleaned.trim();
  }

  String _buildUserPrompt({
    required ConversationMode mode,
    required BiblicalFigure figure,
    required String userMessage,
    required List<ChatMessage> history,
    BiblicalFigure? figureB,
  }) {
    // Build conversation history as plain text
    final historyText = history
        .map((e) {
          final role = e.isUser ? 'User' : figure.name;
          return '$role: ${e.message}';
        })
        .join('\n');

    // Build corpus context
    final corpus =
        'Scripture: ' +
        figure.corpus.tier1Scripture +
        '\nPersonality: ' +
        figure.corpus.personalityProfile +
        (figure.corpus.tier2Historical != null
            ? '\nHistorical context: ' + figure.corpus.tier2Historical!
            : '') +
        (figure.corpus.tier3Cultural != null
            ? '\nCultural context: ' + figure.corpus.tier3Cultural!
            : '');

    if (mode == ConversationMode.dual && figureB != null) {
      return 'You are ' +
          figure.name +
          ' in conversation with ' +
          figureB.name +
          '.\n\n' +
          'Your background: ' +
          corpus +
          '\n\n' +
          (historyText.isNotEmpty
              ? 'Conversation so far:\n' + historyText + '\n\n'
              : '') +
          'User asks: "' +
          userMessage +
          '"\n\n' +
          'Respond naturally as ' +
          figure.name +
          ', speaking directly to the user. ' +
          'You may reference ' +
          figureB.name +
          ' where relevant. Keep your response to 100-250 words. ' +
          'Do NOT respond as JSON. Use markdown formatting (headings, bullet lists, bold text) to structure your response.\n' +
          'Respond as flowing, first-person prose.';
    }

    return 'You are ' +
        figure.name +
        ', a biblical ' +
        (mode == ConversationMode.author ? 'author' : 'figure') +
        '.\n\n' +
        'Your background: ' +
        corpus +
        '\n\n' +
        (historyText.isNotEmpty
            ? 'Conversation so far:\n' + historyText + '\n\n'
            : '') +
        'User asks: "' +
        userMessage +
        '"\n\n' +
        'Respond naturally as ' +
        figure.name +
        ', speaking in first person. ' +
        'Keep your response to 100-250 words. ' +
        'Do NOT respond as JSON. Use markdown formatting (headings, bullet lists, bold text) to structure your response.\n' +
        'Respond as flowing, first-person prose grounded in scripture.';
  }

  /// Generate a custom biblical figure using the Persona Builder Prompt
  Future<BiblicalFigure> buildPersona(String figureName) async {
    String? prompt = await _promptRepo.getPrompt('speak_with_persona_builder');
    prompt ??= _personaBuilderFallback;

    final userPrompt =
        'Build a complete 4-tier persona for the biblical figure: ' +
        figureName;

    final responseText = await _aiService.getAiResponse(
      systemPrompt: prompt,
      userPrompt: userPrompt,
    );

    if (responseText.isEmpty) throw Exception('No response from AI');

    try {
      final cleaned = responseText
          .replaceAll(RegExp(r'```json'), '')
          .replaceAll(RegExp(r'```'), '')
          .trim();
      final jsonMap = jsonDecode(cleaned) as Map<String, dynamic>;
      return _mapPersonaResponseToModels(jsonMap, figureName);
    } catch (e) {
      developer.log('Error parsing persona builder JSON: $e');
      throw Exception('Failed to parse Persona JSON: $e');
    }
  }

  BiblicalFigure _mapPersonaResponseToModels(
    Map<String, dynamic> json,
    String lookupId,
  ) {
    return BiblicalFigure(
      id: lookupId.toLowerCase().replaceAll(' ', '_'),
      name: json['figureName'] ?? lookupId,
      displayName: json['displayName'] ?? lookupId,
      testament: (json['testament'] == 'OT') ? Testament.ot : Testament.nt,
      figureType: _parseFigureType(json['figureType']),
      era: json['era'] ?? '',
      role: json['role'] ?? '',
      avatarEmoji: json['avatarEmoji'] ?? '📖',
      books: List<String>.from(json['books'] ?? []),
      characterIntroduction: json['characterIntroduction'] ?? '',
      topicsTheyCanSpeak: List<String>.from(json['topicsTheyCanSpeak'] ?? []),
      topicLimits: List<String>.from(json['topicLimits'] ?? []),
      suggestedOpeningQuestions: List<String>.from(
        json['suggestedOpeningQuestions'] ?? [],
      ),
      availableSourceTiers:
          (json['availableSourceTiers'] as List<dynamic>?)
              ?.map((e) => _parseSourceTier(e.toString()))
              .toList() ??
          [SourceTier.scripture],
      corpus: FigureCorpus(
        tier1Scripture:
            'Direct Words: ' +
            ((json['tier1_scripture']?['directWords'] as String?) ?? '') +
            '\nOthers Said: ' +
            ((json['tier1_scripture']?['othersSaid'] as String?) ?? '') +
            '\nActions: ' +
            ((json['tier1_scripture']?['actionsNarrative'] as String?) ?? ''),
        personalityProfile:
            json['tier1_scripture']?['personalityProfile'] ?? '',
        tier2Historical: json['tier2_historical'] as String?,
        tier3Cultural: json['tier3_cultural'] as String?,
        tier4Theological: json['tier4_theological'] as String?,
        knownRelationships:
            (json['knownRelationships'] as List<dynamic>?)
                ?.map(
                  (e) => FigureRelationship(
                    person: e['person'] as String,
                    nature: e['nature'] as String,
                    keyMoments: e['keyMoments'] as String,
                  ),
                )
                .toList() ??
            [],
      ),
      isCurated: false,
    );
  }

  FigureType _parseFigureType(String? type) {
    if (type == 'author') return FigureType.author;
    if (type == 'character') return FigureType.character;
    return FigureType.both;
  }

  SourceTier _parseSourceTier(String tier) {
    if (tier == '1' || tier == 'scripture') return SourceTier.scripture;
    if (tier == '2' || tier == 'historical') return SourceTier.historical;
    if (tier == '3' || tier == 'cultural') return SourceTier.cultural;
    if (tier == '4' || tier == 'scholarly') return SourceTier.scholarly;
    return SourceTier.scripture;
  }

  final String _personaBuilderFallback =
      'Build a complete 4-tier persona for the requested biblical figure. '
      'Return ONLY valid JSON with fields: figureName, displayName, testament, era, figureType, books, role, avatarEmoji, '
      'characterIntroduction, topicsTheyCanSpeak, topicLimits, suggestedOpeningQuestions, availableSourceTiers, '
      'tier1_scripture (with directWords, othersSaid, actionsNarrative, personalityProfile), '
      'tier2_historical, tier3_cultural, tier4_theological, '
      'knownRelationships (each with person, nature, keyMoments).';
}
