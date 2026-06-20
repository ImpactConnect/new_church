import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/ai/chat_session_model.dart';

part 'chat_session_repository.g.dart';

/// In-memory chat session store — saves the current chat history for AI Bible chat.
@Riverpod(keepAlive: true)
class ChatSessionRepository extends _$ChatSessionRepository {
  @override
  List<ChatSessionModel> build() => [];

  void addSession(ChatSessionModel session) {
    state = [...state, session];
  }

  void clearSessions() {
    state = [];
  }
}
