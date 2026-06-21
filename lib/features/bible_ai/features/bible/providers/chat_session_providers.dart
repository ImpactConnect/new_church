import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/chat_session_repository.dart';
import '../../../data/models/ai/chat_session_model.dart';

export '../../../data/repositories/chat_session_repository.dart';

final chatSessionsProvider = FutureProvider<List<ChatSessionModel>>((
  ref,
) async {
  final repo = ref.read(chatSessionRepositoryProvider.notifier);
  return repo.getAllSessions();
});
