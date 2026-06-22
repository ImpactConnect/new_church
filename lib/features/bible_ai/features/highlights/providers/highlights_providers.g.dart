// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'highlights_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$highlightsNotifierHash() =>
    r'6ced920419a6e2876c76af2597b800bf10a0cc91';

/// In-memory highlights store for the Bible AI reader.
///
/// Copied from [HighlightsNotifier].
@ProviderFor(HighlightsNotifier)
final highlightsNotifierProvider = AutoDisposeNotifierProvider<
    HighlightsNotifier, AsyncValue<List<HighlightModel>>>.internal(
  HighlightsNotifier.new,
  name: r'highlightsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$highlightsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$HighlightsNotifier
    = AutoDisposeNotifier<AsyncValue<List<HighlightModel>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
