import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/bookmarks/ai_content_bookmark_model.dart';

part 'ai_content_bookmarks_providers.g.dart';

/// In-memory store for AI content bookmarks (saved AI analysis results).
@riverpod
class AiContentBookmarksNotifier extends _$AiContentBookmarksNotifier {
  static const _prefsKey = 'ai_content_bookmarks';
  Future<void>? _loadFuture;

  @override
  AsyncValue<List<AiContentBookmarkModel>> build() {
    _loadFuture = _loadBookmarks();
    return const AsyncLoading();
  }

  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_prefsKey);
      if (data != null) {
        final List<dynamic> jsonList = jsonDecode(data);
        final bookmarks = jsonList.map((e) => AiContentBookmarkModel.fromJson(e)).toList();
        state = AsyncData(bookmarks);
      } else {
        state = const AsyncData([]);
      }
    } catch (e) {
      state = const AsyncData([]);
    }
  }

  Future<void> _saveBookmarks(List<AiContentBookmarkModel> bookmarks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String data = jsonEncode(bookmarks.map((e) => e.toJson()).toList());
      await prefs.setString(_prefsKey, data);
    } catch (e) {
      // Ignored
    }
  }

  Future<void> addBookmark(AiContentBookmarkModel bookmark) async {
    if (_loadFuture != null) {
      await _loadFuture;
    }
    final current = state.value ?? [];
    if (current.any((b) => b.id == bookmark.id)) return;
    final updated = [...current, bookmark];
    state = AsyncData(updated);
    await _saveBookmarks(updated);
  }

  Future<void> deleteBookmark(String id) async {
    if (_loadFuture != null) {
      await _loadFuture;
    }
    final current = state.value ?? [];
    final updated = current.where((b) => b.id != id).toList();
    state = AsyncData(updated);
    await _saveBookmarks(updated);
  }
}
