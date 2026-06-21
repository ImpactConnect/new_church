import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exegesis_final_model.dart';
import '../repositories/exegesis_repository_final.dart';
import '../services/exegesis_ai_service_final.dart';
import 'package:church_mobile/features/bible_ai/features/bible/providers/bible_providers.dart';
import '../../../data/repositories/prompt_repository.dart';

// ── Prompt Repository ─────────────────────────────────────────────────
final promptRepositoryProvider = Provider<PromptRepository>((ref) {
  return PromptRepository();
});

// ── Repository ────────────────────────────────────────────────────────
final exegesisRepositoryFinalProvider =
    Provider<ExegesisRepositoryFinal>((ref) {
  return ExegesisRepositoryFinal(firestore: FirebaseFirestore.instance);
});

// ── AI Service ────────────────────────────────────────────────────────
final exegesisAiServiceFinalProvider =
    Provider<ExegesisAiServiceFinal>((ref) {
  return ExegesisAiServiceFinal(
    aiService: ref.watch(aiServiceProvider),
    promptRepo: ref.watch(promptRepositoryProvider),
  );
});

// ── Entry Type Selection ──────────────────────────────────────────────
final exegesisEntryTypeProvider =
    StateProvider<ExegesisEntryType>((ref) => ExegesisEntryType.verse);

// ── Generation State ──────────────────────────────────────────────────
enum ExegesisFinalGenerationState { idle, generating, completed, error }

final exegesisFinalGenerationStateProvider =
    StateProvider<ExegesisFinalGenerationState>(
        (ref) => ExegesisFinalGenerationState.idle);

final exegesisFinalGenerationErrorProvider =
    StateProvider<String?>((ref) => null);

// ── Phase label for loading screen ───────────────────────────────────
final exegesisFinalPhaseProvider = StateProvider<String>(
    (ref) => 'Investigating the original text…');

// ── Current Result ────────────────────────────────────────────────────
/// Holds the last generated VerseExegesis (from new form or bible reader)
final currentVerseExegesisProvider =
    StateProvider<VerseExegesis?>((ref) => null);

/// Holds the last generated TopicExegesis
final currentTopicExegesisProvider =
    StateProvider<TopicExegesis?>((ref) => null);

// ── Library (history) Stream ─────────────────────────────────────────
final exegesisLibraryStreamProvider =
    StreamProvider<List<ExegesisLibraryItem>>((ref) {
  final repo = ref.watch(exegesisRepositoryFinalProvider);
  return repo.watchAll();
});

/// Notifier that orchestrates generation + persistence for a verse exegesis
class VerseExegesisNotifier extends StateNotifier<AsyncValue<VerseExegesis?>> {
  final Ref _ref;

  VerseExegesisNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> generate({
    required List<VerseRef> verseRefs,
    required Map<String, String> verseTexts,
    String translation = 'ESV',
    bool isRange = false,
    String? userQuestion,
    ExegesisSource source = ExegesisSource.newForm,
  }) async {
    state = const AsyncValue.loading();
    _ref.read(exegesisFinalPhaseProvider.notifier).state =
        'Investigating the original text…';

    // Phase label swap midway
    Future.delayed(const Duration(seconds: 12), () {
      if (mounted) {
        _ref.read(exegesisFinalPhaseProvider.notifier).state =
            'Tracing the meaning through scripture…';
      }
    });

    try {
      final service = _ref.read(exegesisAiServiceFinalProvider);
      final result = await service.generateVerseExegesis(
        verseRefs: verseRefs,
        verseTexts: verseTexts,
        translation: translation,
        isRange: isRange,
        userQuestion: userQuestion,
        source: source,
      );
      state = AsyncValue.data(result);
      _ref.read(currentVerseExegesisProvider.notifier).state = result;

      // Auto-save
      final repo = _ref.read(exegesisRepositoryFinalProvider);
      await repo.saveVerse(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final verseExegesisNotifierProvider =
    StateNotifierProvider<VerseExegesisNotifier, AsyncValue<VerseExegesis?>>(
        (ref) => VerseExegesisNotifier(ref));

/// Notifier that orchestrates generation + persistence for a topic exegesis
class TopicExegesisNotifier extends StateNotifier<AsyncValue<TopicExegesis?>> {
  final Ref _ref;

  TopicExegesisNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> generate({
    required String topicName,
    String? specificAngle,
    ExegesisSource source = ExegesisSource.newForm,
  }) async {
    state = const AsyncValue.loading();
    _ref.read(exegesisFinalPhaseProvider.notifier).state =
        'Investigating the original text…';

    Future.delayed(const Duration(seconds: 18), () {
      if (mounted) {
        _ref.read(exegesisFinalPhaseProvider.notifier).state =
            'Tracing the meaning through scripture…';
      }
    });

    try {
      final service = _ref.read(exegesisAiServiceFinalProvider);
      final result = await service.generateTopicExegesis(
        topicName: topicName,
        specificAngle: specificAngle,
        source: source,
      );
      state = AsyncValue.data(result);
      _ref.read(currentTopicExegesisProvider.notifier).state = result;

      final repo = _ref.read(exegesisRepositoryFinalProvider);
      await repo.saveTopic(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final topicExegesisNotifierProvider =
    StateNotifierProvider<TopicExegesisNotifier, AsyncValue<TopicExegesis?>>(
        (ref) => TopicExegesisNotifier(ref));
