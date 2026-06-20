import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/bible/bible_book.dart';
import '../../../data/models/bible/bible_chapter.dart';
import '../../../data/models/bible/bible_version.dart';
import '../../../data/models/ai/ai_models.dart';
import '../../../data/repositories/bible_repository.dart';
import '../../settings/providers/settings_providers.dart';
import '../services/ai_explanation_service.dart';
import '../../../services/ai_service.dart';

part 'bible_providers.g.dart';

// Repository Provider
@Riverpod(keepAlive: true)
BibleRepository bibleRepository(BibleRepositoryRef ref) {
  return LocalJsonBibleRepository();
}

// ... existing imports ...

// AI Service Provider
@Riverpod(keepAlive: true)
AiService aiService(AiServiceRef ref) {
  const apiKey = String.fromEnvironment('GEN_AI_API_KEY');
  return AiService(apiKey: apiKey);
}

// Global AI Mode State
@riverpod
class AiModeNotifier extends _$AiModeNotifier {
  @override
  AiMode build() => AiMode.study; // Default to study

  void setMode(AiMode mode) {
    state = mode;
  }
}

// Deprecated: Use aiServiceProvider instead
@Riverpod(keepAlive: true)
AIExplanationService aiExplanationService(AiExplanationServiceRef ref) {
  return AIExplanationService();
}

// State Provider for current Bible version
@riverpod
class BibleVersionNotifier extends _$BibleVersionNotifier {
  @override
  BibleVersion build() {
    final configuredVersion = ref.watch(
      appSettingsNotifierProvider.select((settings) => settings.bibleVersion),
    );
    return BibleVersion.fromAbbreviation(configuredVersion);
  }

  Future<void> setVersion(BibleVersion version) async {
    await ref
        .read(appSettingsNotifierProvider.notifier)
        .setBibleVersion(version.abbreviation);
    state = version;
  }
}

// Future Provider for getting all books
@riverpod
Future<List<BibleBook>> bibleBooks(BibleBooksRef ref) {
  final repository = ref.watch(bibleRepositoryProvider);
  final version = ref.watch(bibleVersionNotifierProvider);
  return repository.getBooks(version);
}

// Future Provider for getting a specific chapter
@riverpod
Future<BibleChapter?> bibleChapter(
  BibleChapterRef ref,
  String bookId,
  int chapterNumber,
) async {
  final repository = ref.watch(bibleRepositoryProvider);
  final version = ref.watch(bibleVersionNotifierProvider);
  final book = await repository.getBook(bookId, version);
  if (book == null) return null;

  try {
    return book.chapters.firstWhere((c) => c.number == chapterNumber);
  } catch (e) {
    return null;
  }
}
