import 'package:shared_preferences/shared_preferences.dart';

/// Persists user Bible reading preferences (last-read book and chapter).
class UserSettingsRepository {
  final SharedPreferences _prefs;
  static const _keyLastReadBook = 'bible_ai_last_read_book';
  static const _keyLastReadChapter = 'bible_ai_last_read_chapter';
  static const _keyBibleVersion = 'bible_ai_version';

  UserSettingsRepository(this._prefs);

  /// Returns the last read (bookId, chapterNumber) or null if none saved.
  (String, int)? getLastRead() {
    final bookId = _prefs.getString(_keyLastReadBook);
    final chapter = _prefs.getInt(_keyLastReadChapter);
    if (bookId == null || chapter == null) return null;
    return (bookId, chapter);
  }

  Future<void> saveLastRead(String bookId, int chapterNumber) async {
    await _prefs.setString(_keyLastReadBook, bookId);
    await _prefs.setInt(_keyLastReadChapter, chapterNumber);
  }

  String getBibleVersion() {
    return _prefs.getString(_keyBibleVersion) ?? 'KJV';
  }

  Future<void> setBibleVersion(String version) async {
    await _prefs.setString(_keyBibleVersion, version);
  }
}
