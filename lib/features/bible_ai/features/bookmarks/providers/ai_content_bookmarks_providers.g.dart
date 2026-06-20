// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_content_bookmarks_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$aiContentBookmarksNotifierHash() =>
    r'd09d7dcd3096c9e1956570c5fd809c044b64faac';

/// In-memory store for AI content bookmarks (saved AI analysis results).
///
/// Copied from [AiContentBookmarksNotifier].
@ProviderFor(AiContentBookmarksNotifier)
final aiContentBookmarksNotifierProvider = AutoDisposeNotifierProvider<
    AiContentBookmarksNotifier,
    AsyncValue<List<AiContentBookmarkModel>>>.internal(
  AiContentBookmarksNotifier.new,
  name: r'aiContentBookmarksNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$aiContentBookmarksNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AiContentBookmarksNotifier
    = AutoDisposeNotifier<AsyncValue<List<AiContentBookmarkModel>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
