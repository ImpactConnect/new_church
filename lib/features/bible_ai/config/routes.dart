/// Route name constants used by the Bible AI feature.
/// Navigation is handled via Navigator.push in this app (no GoRouter required).
class Routes {
  static const String bible = '/bible';
  static const String bibleChapter = '/bible/:bookId/:chapterId';
  static const String bookmarks = '/bible-ai/bookmarks';
  static const String notes = '/bible-ai/notes';
  static const String search = '/bible-ai/search';
  static const String readingPlans = '/bible-ai/reading-plans';
}
