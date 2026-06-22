// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_session_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatSessionRepositoryHash() =>
    r'586b88d34ace470e3573a01a0845fc6d98dfd32c';

/// Firestore-backed chat session store for AI Bible chat.
///
/// Copied from [ChatSessionRepository].
@ProviderFor(ChatSessionRepository)
final chatSessionRepositoryProvider =
    NotifierProvider<ChatSessionRepository, List<ChatSessionModel>>.internal(
  ChatSessionRepository.new,
  name: r'chatSessionRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$chatSessionRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ChatSessionRepository = Notifier<List<ChatSessionModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
