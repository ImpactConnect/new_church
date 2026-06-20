// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notesNotifierHash() => r'f4d7b50ecfdb88029e14437ff3f1da8a430b5276';

/// In-memory verse notes store for the Bible AI reader.
///
/// Copied from [NotesNotifier].
@ProviderFor(NotesNotifier)
final notesNotifierProvider = AutoDisposeNotifierProvider<NotesNotifier,
    AsyncValue<List<NoteModel>>>.internal(
  NotesNotifier.new,
  name: r'notesNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notesNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NotesNotifier = AutoDisposeNotifier<AsyncValue<List<NoteModel>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
