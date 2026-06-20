// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmarks_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bookmarksNotifierHash() => r'7b4c307b04441b7674c7dce77bef3769157b5054';

/// In-memory bookmarks store for the Bible AI reader.
/// Persists within the app session; future iterations can add Hive/Firestore persistence.
///
/// Copied from [BookmarksNotifier].
@ProviderFor(BookmarksNotifier)
final bookmarksNotifierProvider = AutoDisposeNotifierProvider<BookmarksNotifier,
    AsyncValue<List<BookmarkModel>>>.internal(
  BookmarksNotifier.new,
  name: r'bookmarksNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$bookmarksNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BookmarksNotifier
    = AutoDisposeNotifier<AsyncValue<List<BookmarkModel>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
