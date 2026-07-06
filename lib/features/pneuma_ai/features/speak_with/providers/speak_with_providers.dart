import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../data/repositories/prompt_repository.dart';
import '../../../data/repositories/speak_with_local_repository.dart';
import '../../../data/repositories/speak_with_repository.dart'; // For curated figures only
import 'package:church_mobile/features/bible_ai/features/bible/providers/bible_providers.dart';
import '../services/speak_with_ai_service.dart';
import '../models/speak_with_models.dart';

part 'speak_with_providers.g.dart';

// ── Local repository (Hive — offline, no auth) ──────────────────────────────
final speakWithLocalRepoProvider = Provider<SpeakWithLocalRepository>(
  (ref) => SpeakWithLocalRepository(),
);

// Keep the code-gen provider alive but point it to local repo
// (the generated .g.dart references speakWithRepositoryProvider with
//  SpeakWithRepository type — we shadow it with a manual provider below)
@Riverpod(keepAlive: true)
SpeakWithRepository speakWithRepository(SpeakWithRepositoryRef ref) {
  return SpeakWithRepository(); // Used only for curated figures
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

// savedConversations now reads from local Hive repo
@riverpod
Future<List<SpeakWithConversation>> savedConversations(SavedConversationsRef ref) async {
  final repo = ref.watch(speakWithLocalRepoProvider);
  return repo.getSavedConversations();
}

@Riverpod(keepAlive: true)
class AskSpeakWithController extends _$AskSpeakWithController {
  @override
  SpeakWithConversation? build() => null;

  void setConversation(SpeakWithConversation conv) {
    state = conv;
    // Save to local Hive storage
    ref.read(speakWithLocalRepoProvider).saveConversation(conv);
    ref.invalidate(savedConversationsProvider);
  }

  /// Clear state before starting a brand-new conversation.
  void reset() => state = null;

  /// Resume an existing conversation WITHOUT saving a new record.
  void resumeConversation(SpeakWithConversation conv) {
    state = conv;
  }

  Future<void> sendMessage(String text) async {
    if (state == null) return;
    
    final aiService = ref.read(speakWithAiServiceProvider);
    final localRepo = ref.read(speakWithLocalRepoProvider);
    
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
      final priorHistory = state!.messages
          .where((m) => m.id != userMsg.id)
          .toList();

      final version = ref.read(bibleVersionNotifierProvider);

      final aiText = await aiService.chatWithFigure(
        mode: state!.mode,
        figure: state!.figureA,
        figureB: state!.figureB,
        userMessage: text,
        history: priorHistory,
        bibleVersionName: version.name,
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
      
      await localRepo.saveConversation(state!);
      ref.invalidate(savedConversationsProvider);
    } catch (e) {
      print('AskSpeakWithController Error: $e');
    }
  }
}
