// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'speak_with_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$speakWithRepositoryHash() =>
    r'27f495eb02006394d328b1e662c3226fbc4100be';

/// See also [speakWithRepository].
@ProviderFor(speakWithRepository)
final speakWithRepositoryProvider = Provider<SpeakWithRepository>.internal(
  speakWithRepository,
  name: r'speakWithRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$speakWithRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SpeakWithRepositoryRef = ProviderRef<SpeakWithRepository>;
String _$speakWithAiServiceHash() =>
    r'539e96a1c94e03e043c8fd744a3ed1f911658d23';

/// See also [speakWithAiService].
@ProviderFor(speakWithAiService)
final speakWithAiServiceProvider = Provider<SpeakWithAiService>.internal(
  speakWithAiService,
  name: r'speakWithAiServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$speakWithAiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SpeakWithAiServiceRef = ProviderRef<SpeakWithAiService>;
String _$curatedFiguresHash() => r'a8338d6ce95c7f3ffae7b3f88a2f060e01eb2751';

/// See also [curatedFigures].
@ProviderFor(curatedFigures)
final curatedFiguresProvider =
    AutoDisposeFutureProvider<List<BiblicalFigure>>.internal(
  curatedFigures,
  name: r'curatedFiguresProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$curatedFiguresHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CuratedFiguresRef = AutoDisposeFutureProviderRef<List<BiblicalFigure>>;
String _$customFiguresHash() => r'b6f245d44a8d6c7a3fe341a2b93dda2941d6da1f';

/// See also [customFigures].
@ProviderFor(customFigures)
final customFiguresProvider =
    AutoDisposeFutureProvider<List<BiblicalFigure>>.internal(
  customFigures,
  name: r'customFiguresProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$customFiguresHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CustomFiguresRef = AutoDisposeFutureProviderRef<List<BiblicalFigure>>;
String _$filteredFiguresHash() => r'4c221962b599d72a311c8300ca7e8254874cce55';

/// See also [filteredFigures].
@ProviderFor(filteredFigures)
final filteredFiguresProvider =
    AutoDisposeFutureProvider<List<BiblicalFigure>>.internal(
  filteredFigures,
  name: r'filteredFiguresProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$filteredFiguresHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FilteredFiguresRef = AutoDisposeFutureProviderRef<List<BiblicalFigure>>;
String _$savedConversationsHash() =>
    r'9e1342f362aef700679b75212be174d5ad57dd09';

/// See also [savedConversations].
@ProviderFor(savedConversations)
final savedConversationsProvider =
    AutoDisposeFutureProvider<List<SpeakWithConversation>>.internal(
  savedConversations,
  name: r'savedConversationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$savedConversationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SavedConversationsRef
    = AutoDisposeFutureProviderRef<List<SpeakWithConversation>>;
String _$speakWithSearchQueryHash() =>
    r'47f9957d42dae1096853c06e5ef3864e4e0950f5';

/// See also [SpeakWithSearchQuery].
@ProviderFor(SpeakWithSearchQuery)
final speakWithSearchQueryProvider =
    AutoDisposeNotifierProvider<SpeakWithSearchQuery, String>.internal(
  SpeakWithSearchQuery.new,
  name: r'speakWithSearchQueryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$speakWithSearchQueryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SpeakWithSearchQuery = AutoDisposeNotifier<String>;
String _$askSpeakWithControllerHash() =>
    r'5e0af4af5fe3d18eb702be59a6fd492455addc85';

/// See also [AskSpeakWithController].
@ProviderFor(AskSpeakWithController)
final askSpeakWithControllerProvider =
    NotifierProvider<AskSpeakWithController, SpeakWithConversation?>.internal(
  AskSpeakWithController.new,
  name: r'askSpeakWithControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$askSpeakWithControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AskSpeakWithController = Notifier<SpeakWithConversation?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
