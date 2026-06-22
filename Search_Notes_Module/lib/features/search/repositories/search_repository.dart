import '../../../data/models/bible/bible_version.dart';
import '../../../data/repositories/bible_repository.dart';

import '../../../services/ai_service.dart';

class SearchResult {
  final String bookId;
  final String bookName;
  final int chapterNumber;
  final int verseNumber;
  final String text;
  final String? aiReason;

  SearchResult({
    required this.bookId,
    required this.bookName,
    required this.chapterNumber,
    required this.verseNumber,
    required this.text,
    this.aiReason,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      bookId: json['bookId'] as String,
      bookName: json['bookName'] as String,
      chapterNumber: json['chapterNumber'] as int,
      verseNumber: json['verseNumber'] as int,
      text: json['text'] as String,
      aiReason: json['aiReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'bookName': bookName,
      'chapterNumber': chapterNumber,
      'verseNumber': verseNumber,
      'text': text,
      if (aiReason != null) 'aiReason': aiReason,
    };
  }
}

class BibleSearchRepository {
  final BibleRepository bibleRepository;
  final AiService aiService;

  BibleSearchRepository(this.bibleRepository, this.aiService);

  Future<List<SearchResult>> search(String query, BibleVersion version) async {
    if (query.isEmpty || query.length < 3) return [];

    final books = await bibleRepository.getBooks(version);
    final results = <SearchResult>[];
    final lowercaseQuery = query.toLowerCase();

    for (final book in books) {
      for (final chapter in book.chapters) {
        for (final verse in chapter.verses) {
          if (verse.text.toLowerCase().contains(lowercaseQuery)) {
            results.add(
              SearchResult(
                bookId: book.id,
                bookName: book.name,
                chapterNumber: chapter.number,
                verseNumber: verse.number,
                text: verse.text,
              ),
            );
          }
        }
      }
    }

    return results;
  }

  Future<List<SearchResult>> semanticSearch(
    String query,
    BibleVersion version,
  ) async {
    if (query.isEmpty) return [];

    final aiResults = await aiService.semanticSearch(query);
    if (aiResults.isEmpty) return [];

    final books = await bibleRepository.getBooks(version);
    final results = <SearchResult>[];

    for (final aiRes in aiResults) {
      // Find the book, chapter, and verse in the local database
      final book = books.firstWhere(
        (b) => b.name.toLowerCase() == aiRes.bookName.toLowerCase(),
        orElse: () => books
            .first, // Fallback, though might be inaccurate if book name is completely mangled
      );

      // We need to carefully find the chapter and verse without crashing
      try {
        final chapter = book.chapters.firstWhere(
          (c) => c.number == aiRes.chapterNumber,
        );
        final verse = chapter.verses.firstWhere(
          (v) => v.number == aiRes.verseNumber,
        );

        results.add(
          SearchResult(
            bookId: book.id,
            bookName: book.name,
            chapterNumber: chapter.number,
            verseNumber: verse.number,
            text: verse.text,
            aiReason: aiRes.reason,
          ),
        );
      } catch (e) {
        // Skip this result if chapter/verse not found
      }
    }

    return results;
  }
}
