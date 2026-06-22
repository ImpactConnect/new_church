// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$searchRepositoryHash() => r'88649cd7137e81e35814f0c37b1927d147e37284';

/// See also [searchRepository].
@ProviderFor(searchRepository)
final searchRepositoryProvider =
    AutoDisposeProvider<BibleSearchRepository>.internal(
  searchRepository,
  name: r'searchRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$searchRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SearchRepositoryRef = AutoDisposeProviderRef<BibleSearchRepository>;
String _$searchResultsHash() => r'29f065df8d63123025bf46f04b3e3befa2cc8172';

/// See also [searchResults].
@ProviderFor(searchResults)
final searchResultsProvider =
    AutoDisposeFutureProvider<List<SearchResult>>.internal(
  searchResults,
  name: r'searchResultsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$searchResultsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SearchResultsRef = AutoDisposeFutureProviderRef<List<SearchResult>>;
String _$searchQueryNotifierHash() =>
    r'568197ef1fbf916dec73e732479bb31def14847a';

/// See also [SearchQueryNotifier].
@ProviderFor(SearchQueryNotifier)
final searchQueryNotifierProvider =
    AutoDisposeNotifierProvider<SearchQueryNotifier, String>.internal(
  SearchQueryNotifier.new,
  name: r'searchQueryNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$searchQueryNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SearchQueryNotifier = AutoDisposeNotifier<String>;
String _$semanticSearchNotifierHash() =>
    r'd2d6962a8a673d0078af73ef7ba12cf414903b0b';

/// See also [SemanticSearchNotifier].
@ProviderFor(SemanticSearchNotifier)
final semanticSearchNotifierProvider = AutoDisposeAsyncNotifierProvider<
    SemanticSearchNotifier, List<SearchResult>>.internal(
  SemanticSearchNotifier.new,
  name: r'semanticSearchNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$semanticSearchNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SemanticSearchNotifier = AutoDisposeAsyncNotifier<List<SearchResult>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
