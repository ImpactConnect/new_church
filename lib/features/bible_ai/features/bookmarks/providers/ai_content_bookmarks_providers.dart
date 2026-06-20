import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../data/models/bookmarks/ai_content_bookmark_model.dart';

part 'ai_content_bookmarks_providers.g.dart';

/// In-memory store for AI content bookmarks (saved AI analysis results).
@riverpod
class AiContentBookmarksNotifier extends _$AiContentBookmarksNotifier {
  @override
  AsyncValue<List<AiContentBookmarkModel>> build() {
    return const AsyncData([]);
  }

  Future<void> addBookmark(AiContentBookmarkModel bookmark) async {
    final current = state.value ?? [];
    state = AsyncData([...current, bookmark]);
  }

  Future<void> deleteBookmark(String id) async {
    final current = state.value ?? [];
    state = AsyncData(current.where((b) => b.id != id).toList());
  }
}
