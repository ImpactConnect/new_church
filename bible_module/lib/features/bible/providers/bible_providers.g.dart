// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bible_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bibleRepositoryHash() => r'662630d773b6798b927dc5178b72312c78725b9c';

/// See also [bibleRepository].
@ProviderFor(bibleRepository)
final bibleRepositoryProvider = Provider<BibleRepository>.internal(
  bibleRepository,
  name: r'bibleRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$bibleRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BibleRepositoryRef = ProviderRef<BibleRepository>;
String _$aiServiceHash() => r'7ba18e895601e5956a96c94ec9f62f4783262f51';

/// See also [aiService].
@ProviderFor(aiService)
final aiServiceProvider = Provider<AiService>.internal(
  aiService,
  name: r'aiServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$aiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AiServiceRef = ProviderRef<AiService>;
String _$aiExplanationServiceHash() =>
    r'743275348294bd38cec14bad2c0ef67f84cbd19c';

/// See also [aiExplanationService].
@ProviderFor(aiExplanationService)
final aiExplanationServiceProvider = Provider<AIExplanationService>.internal(
  aiExplanationService,
  name: r'aiExplanationServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$aiExplanationServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AiExplanationServiceRef = ProviderRef<AIExplanationService>;
String _$bibleBooksHash() => r'66b58d7100914366c6ce9075a30e6da260ea516f';

/// See also [bibleBooks].
@ProviderFor(bibleBooks)
final bibleBooksProvider = AutoDisposeFutureProvider<List<BibleBook>>.internal(
  bibleBooks,
  name: r'bibleBooksProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$bibleBooksHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BibleBooksRef = AutoDisposeFutureProviderRef<List<BibleBook>>;
String _$bibleChapterHash() => r'498aa1c5480f8df9216269ab537de6d3d77ce59a';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [bibleChapter].
@ProviderFor(bibleChapter)
const bibleChapterProvider = BibleChapterFamily();

/// See also [bibleChapter].
class BibleChapterFamily extends Family<AsyncValue<BibleChapter?>> {
  /// See also [bibleChapter].
  const BibleChapterFamily();

  /// See also [bibleChapter].
  BibleChapterProvider call(
    String bookId,
    int chapterNumber,
  ) {
    return BibleChapterProvider(
      bookId,
      chapterNumber,
    );
  }

  @override
  BibleChapterProvider getProviderOverride(
    covariant BibleChapterProvider provider,
  ) {
    return call(
      provider.bookId,
      provider.chapterNumber,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'bibleChapterProvider';
}

/// See also [bibleChapter].
class BibleChapterProvider extends AutoDisposeFutureProvider<BibleChapter?> {
  /// See also [bibleChapter].
  BibleChapterProvider(
    String bookId,
    int chapterNumber,
  ) : this._internal(
          (ref) => bibleChapter(
            ref as BibleChapterRef,
            bookId,
            chapterNumber,
          ),
          from: bibleChapterProvider,
          name: r'bibleChapterProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$bibleChapterHash,
          dependencies: BibleChapterFamily._dependencies,
          allTransitiveDependencies:
              BibleChapterFamily._allTransitiveDependencies,
          bookId: bookId,
          chapterNumber: chapterNumber,
        );

  BibleChapterProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.bookId,
    required this.chapterNumber,
  }) : super.internal();

  final String bookId;
  final int chapterNumber;

  @override
  Override overrideWith(
    FutureOr<BibleChapter?> Function(BibleChapterRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BibleChapterProvider._internal(
        (ref) => create(ref as BibleChapterRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        bookId: bookId,
        chapterNumber: chapterNumber,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<BibleChapter?> createElement() {
    return _BibleChapterProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BibleChapterProvider &&
        other.bookId == bookId &&
        other.chapterNumber == chapterNumber;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, bookId.hashCode);
    hash = _SystemHash.combine(hash, chapterNumber.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin BibleChapterRef on AutoDisposeFutureProviderRef<BibleChapter?> {
  /// The parameter `bookId` of this provider.
  String get bookId;

  /// The parameter `chapterNumber` of this provider.
  int get chapterNumber;
}

class _BibleChapterProviderElement
    extends AutoDisposeFutureProviderElement<BibleChapter?>
    with BibleChapterRef {
  _BibleChapterProviderElement(super.provider);

  @override
  String get bookId => (origin as BibleChapterProvider).bookId;
  @override
  int get chapterNumber => (origin as BibleChapterProvider).chapterNumber;
}

String _$aiModeNotifierHash() => r'80b1a8455c746037455a0d781b7be1008ddde05b';

/// See also [AiModeNotifier].
@ProviderFor(AiModeNotifier)
final aiModeNotifierProvider =
    AutoDisposeNotifierProvider<AiModeNotifier, AiMode>.internal(
  AiModeNotifier.new,
  name: r'aiModeNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$aiModeNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AiModeNotifier = AutoDisposeNotifier<AiMode>;
String _$bibleVersionNotifierHash() =>
    r'95d5ab7f487fc9ac4d0ef87ea92e169fae487979';

/// See also [BibleVersionNotifier].
@ProviderFor(BibleVersionNotifier)
final bibleVersionNotifierProvider =
    AutoDisposeNotifierProvider<BibleVersionNotifier, BibleVersion>.internal(
  BibleVersionNotifier.new,
  name: r'bibleVersionNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$bibleVersionNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BibleVersionNotifier = AutoDisposeNotifier<BibleVersion>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
