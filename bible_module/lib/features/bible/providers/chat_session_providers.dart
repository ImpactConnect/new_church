import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/chat_session_repository.dart';
import '../../../data/models/ai/chat_session_model.dart';

final chatSessionRepositoryProvider = Provider<ChatSessionRepository>((ref) {
  return ChatSessionRepository();
});

final chatSessionsProvider = FutureProvider<List<ChatSessionModel>>((
  ref,
) async {
  final repo = ref.read(chatSessionRepositoryProvider);
  return repo.getAllSessions();
});
