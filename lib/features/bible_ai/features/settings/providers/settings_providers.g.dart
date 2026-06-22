// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userSettingsRepositoryHash() =>
    r'153305fdf98b5ba88c870796ec2780759efa7628';

/// Provides the [UserSettingsRepository] backed by SharedPreferences.
///
/// Copied from [userSettingsRepository].
@ProviderFor(userSettingsRepository)
final userSettingsRepositoryProvider =
    FutureProvider<UserSettingsRepository>.internal(
  userSettingsRepository,
  name: r'userSettingsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userSettingsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UserSettingsRepositoryRef = FutureProviderRef<UserSettingsRepository>;
String _$appSettingsNotifierHash() =>
    r'ee02d3f128918300c1c3b29701259e7e855b1afd';

/// Notifier for app-level settings (bible version selection, etc.).
///
/// Copied from [AppSettingsNotifier].
@ProviderFor(AppSettingsNotifier)
final appSettingsNotifierProvider =
    AutoDisposeNotifierProvider<AppSettingsNotifier, AppSettings>.internal(
  AppSettingsNotifier.new,
  name: r'appSettingsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appSettingsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AppSettingsNotifier = AutoDisposeNotifier<AppSettings>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
