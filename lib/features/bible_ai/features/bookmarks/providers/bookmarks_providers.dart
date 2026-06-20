import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../data/models/bookmarks/bookmark_model.dart';

part 'bookmarks_providers.g.dart';

/// In-memory bookmarks store for the Bible AI reader.
/// Persists within the app session; future iterations can add Hive/Firestore persistence.
@riverpod
class BookmarksNotifier extends _$BookmarksNotifier {
  @override
  AsyncValue<List<BookmarkModel>> build() {
    return const AsyncData([]);
  }

  Future<void> addBookmark(BookmarkModel bookmark) async {
    final current = state.value ?? [];
    state = AsyncData([...current, bookmark]);
  }

  Future<void> deleteBookmark(String id) async {
    final current = state.value ?? [];
    state = AsyncData(current.where((b) => b.id != id).toList());
  }
}
