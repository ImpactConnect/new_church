// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_session_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatSessionRepositoryHash() =>
    r'930b59997b2a4f24bd51fd70815589144c45cdd5';

/// In-memory chat session store — saves the current chat history for AI Bible chat.
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
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
