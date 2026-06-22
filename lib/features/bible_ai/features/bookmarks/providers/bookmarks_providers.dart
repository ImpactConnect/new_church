import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/bookmarks/bookmark_model.dart';

part 'bookmarks_providers.g.dart';

/// In-memory bookmarks store for the Bible AI reader.
/// Persists within the app session; future iterations can add Hive/Firestore persistence.
@riverpod
class BookmarksNotifier extends _$BookmarksNotifier {
  static const _prefsKey = 'regular_bookmarks';

  @override
  AsyncValue<List<BookmarkModel>> build() {
    _loadBookmarks();
    return const AsyncLoading();
  }

  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_prefsKey);
      if (data != null) {
        final List<dynamic> jsonList = jsonDecode(data);
        final bookmarks = jsonList.map((e) => BookmarkModel.fromJson(e)).toList();
        state = AsyncData(bookmarks);
      } else {
        state = const AsyncData([]);
      }
    } catch (e) {
      state = const AsyncData([]);
    }
  }

  Future<void> _saveBookmarks(List<BookmarkModel> bookmarks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String data = jsonEncode(bookmarks.map((e) => e.toJson()).toList());
      await prefs.setString(_prefsKey, data);
    } catch (e) {
      // Ignored
    }
  }

  Future<void> addBookmark(BookmarkModel bookmark) async {
    final current = state.value ?? [];
    if (current.any((b) => b.id == bookmark.id)) return;
    final updated = [...current, bookmark];
    state = AsyncData(updated);
    await _saveBookmarks(updated);
  }

  Future<void> deleteBookmark(String id) async {
    final current = state.value ?? [];
    final updated = current.where((b) => b.id != id).toList();
    state = AsyncData(updated);
    await _saveBookmarks(updated);
  }
}
