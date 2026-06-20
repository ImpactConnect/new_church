/// Service for formatting Bible verses and other content for insertion into notes.
class ContentLinkerService {
  /// Formats a Bible verse reference for insertion into a standalone note.
  static String formatBibleVerse({
    required String bookName,
    required int chapter,
    required int verse,
    required String verseText,
  }) {
    return '**$bookName $chapter:$verse** — "$verseText"';
  }
}
