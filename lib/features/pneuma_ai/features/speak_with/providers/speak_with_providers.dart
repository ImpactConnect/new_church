import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../data/repositories/prompt_repository.dart';
import '../../../data/repositories/speak_with_repository.dart';
import 'package:church_mobile/features/bible_ai/features/bible/providers/bible_providers.dart';
import '../services/speak_with_ai_service.dart';
import '../models/speak_with_models.dart';

part 'speak_with_providers.g.dart';

@Riverpod(keepAlive: true)
SpeakWithRepository speakWithRepository(SpeakWithRepositoryRef ref) {
  return SpeakWithRepository();
}

@Riverpod(keepAlive: true)
SpeakWithAiService speakWithAiService(SpeakWithAiServiceRef ref) {
  final aiService = ref.watch(aiServiceProvider);
  final promptRepo = PromptRepository();
  return SpeakWithAiService(aiService, promptRepo);
}

@riverpod
Future<List<BiblicalFigure>> curatedFigures(CuratedFiguresRef ref) async {
  final repo = ref.watch(speakWithRepositoryProvider);
  return repo.getCuratedFigures();
}

@riverpod
Future<List<BiblicalFigure>> customFigures(CustomFiguresRef ref) async {
  final repo = ref.watch(speakWithRepositoryProvider);
  return repo.getCustomFigures();
}

@riverpod
class SpeakWithSearchQuery extends _$SpeakWithSearchQuery {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

@riverpod
Future<List<BiblicalFigure>> filteredFigures(FilteredFiguresRef ref) async {
  final curated = await ref.watch(curatedFiguresProvider.future);
  final custom = await ref.watch(customFiguresProvider.future);
  final query = ref.watch(speakWithSearchQueryProvider).toLowerCase();

  final all = [...curated, ...custom];
  if (query.isEmpty) return all;

  return all.where((f) => 
    f.displayName.toLowerCase().contains(query) || 
    f.role.toLowerCase().contains(query) ||
    f.name.toLowerCase().contains(query)
  ).toList();
}

@riverpod
Future<List<SpeakWithConversation>> savedConversations(SavedConversationsRef ref) async {
  final repo = ref.watch(speakWithRepositoryProvider);
  return repo.getSavedConversations();
}

@Riverpod(keepAlive: true)
class AskSpeakWithController extends _$AskSpeakWithController {
  @override
  SpeakWithConversation? build() => null;

  void setConversation(SpeakWithConversation conv) {
    state = conv;
    // Save immediately so it appears in recent sessions list
    ref.read(speakWithRepositoryProvider).saveConversation(conv);
    ref.invalidate(savedConversationsProvider);
  }

  /// Resume an existing conversation WITHOUT saving a new record.
  void resumeConversation(SpeakWithConversation conv) {
    state = conv; // Just load it into memory — don't create a duplicate entry
  }

  Future<void> sendMessage(String text) async {
    if (state == null) return;
    
    final aiService = ref.read(speakWithAiServiceProvider);
    final repo = ref.read(speakWithRepositoryProvider);
    
    // Add User message
    final userMsg = ChatMessage(
      id: DateTime.now().toIso8601String(),
      isUser: true,
      message: text,
      sentAt: DateTime.now()
    );
    
    state = SpeakWithConversation(
      id: state!.id,
      mode: state!.mode,
      figureA: state!.figureA,
      figureB: state!.figureB,
      title: state!.title,
      messages: [...state!.messages, userMsg],
      createdAt: state!.createdAt,
      lastMessageAt: DateTime.now(),
    );

    try {
      // Pass all prior messages as history for chain-of-thought.
      // Exclude the message just added (userMsg) so the AI sees the full
      // conversation that preceded this turn.
      final priorHistory = state!.messages
          .where((m) => m.id != userMsg.id)
          .toList();

      final aiText = await aiService.chatWithFigure(
        mode: state!.mode,
        figure: state!.figureA,
        figureB: state!.figureB,
        userMessage: text,
        history: priorHistory,
      );

      final aiResponse = ChatMessage(
        id: DateTime.now().toIso8601String(),
        isUser: false,
        message: aiText,
        sentAt: DateTime.now(),
      );

      state = SpeakWithConversation(
        id: state!.id,
        mode: state!.mode,
        figureA: state!.figureA,
        figureB: state!.figureB,
        title: state!.title,
        messages: [...state!.messages, aiResponse],
        createdAt: state!.createdAt,
        lastMessageAt: DateTime.now(),
      );
      
      await repo.saveConversation(state!);
      // Refresh the recent sessions list on the home screen
      ref.invalidate(savedConversationsProvider);
    } catch (e) {
      print('AskSpeakWithController Error: $e');
    }
  }
}
