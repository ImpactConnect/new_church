import 'package:path_provider/path_provider.dart';

import '../../../data/models/ai/chat_session_model.dart';
import '../../../data/models/ai/ai_models.dart';

class ChatPdfService {
  static Future<String> exportChatSession(
    ChatSessionModel session,
    List<ChatMessage> messages,
  ) async {
    // Stub implementation: PDF generation is disabled because of missing dependencies
    // in this integration phase. Returning a dummy path or throwing an error is acceptable.
    throw UnimplementedError('PDF Export is not available in this build.');
  }
}
