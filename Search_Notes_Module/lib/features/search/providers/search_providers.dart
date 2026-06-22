import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../bible/providers/bible_providers.dart';
import '../repositories/search_repository.dart';

part 'search_providers.g.dart';

@riverpod
BibleSearchRepository searchRepository(SearchRepositoryRef ref) {
  final bibleRepo = ref.watch(bibleRepositoryProvider);
  final aiService = ref.watch(aiServiceProvider);
  return BibleSearchRepository(bibleRepo, aiService);
}

@riverpod
class SearchQueryNotifier extends _$SearchQueryNotifier {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

@riverpod
Future<List<SearchResult>> searchResults(SearchResultsRef ref) {
  final query = ref.watch(searchQueryNotifierProvider);
  final repository = ref.watch(searchRepositoryProvider);
  final version = ref.watch(bibleVersionNotifierProvider);

  if (query.isEmpty) return Future.value([]);

  return repository.search(query, version);
}

@riverpod
class SemanticSearchNotifier extends _$SemanticSearchNotifier {
  @override
  FutureOr<List<SearchResult>> build() => [];

  Future<void> performSemanticSearch(String query) async {
    if (query.isEmpty) return;

    state = const AsyncValue.loading();

    try {
      final box = await Hive.openBox<String>('semantic_searches');
      final cacheKey =
          '${query.toLowerCase()}_${ref.read(bibleVersionNotifierProvider).name}';

      final cachedJson = box.get(cacheKey);
      if (cachedJson != null) {
        final List<dynamic> decoded = jsonDecode(cachedJson);
        final cachedResults = decoded
            .map((e) => SearchResult.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        state = AsyncValue.data(cachedResults);
        return;
      }

      final repository = ref.read(searchRepositoryProvider);
      final version = ref.read(bibleVersionNotifierProvider);

      final results = await repository.semanticSearch(query, version);

      if (results.isNotEmpty) {
        final encoded = jsonEncode(results.map((r) => r.toJson()).toList());
        await box.put(cacheKey, encoded);
      }

      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
