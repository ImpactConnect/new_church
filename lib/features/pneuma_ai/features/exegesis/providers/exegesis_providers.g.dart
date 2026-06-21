// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exegesis_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$exegesisRepositoryHash() =>
    r'bbd9f969b50f0832bc9d06dccb621d0039b8349d';

/// See also [exegesisRepository].
@ProviderFor(exegesisRepository)
final exegesisRepositoryProvider =
    AutoDisposeProvider<ExegesisRepository>.internal(
  exegesisRepository,
  name: r'exegesisRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$exegesisRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ExegesisRepositoryRef = AutoDisposeProviderRef<ExegesisRepository>;
String _$recentExegesisSessionsHash() =>
    r'e82b0d0541d65669d4aa5b2e64b97fbafbc123a0';

/// See also [recentExegesisSessions].
@ProviderFor(recentExegesisSessions)
final recentExegesisSessionsProvider =
    AutoDisposeStreamProvider<List<ExegesisSession>>.internal(
  recentExegesisSessions,
  name: r'recentExegesisSessionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$recentExegesisSessionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef RecentExegesisSessionsRef
    = AutoDisposeStreamProviderRef<List<ExegesisSession>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
