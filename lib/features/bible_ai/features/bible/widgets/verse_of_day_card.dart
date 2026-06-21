import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/ai/ai_models.dart';
import '../../../data/models/bookmarks/bookmark_model.dart';
import '../../bookmarks/providers/bookmarks_providers.dart';
import '../providers/bible_providers.dart';
import '../screens/verse_ai_results_screen.dart';

// Popular uplifting verses to cycle through (31 verses for 31 days)
final List<Map<String, dynamic>> _dailyVerses = [
  {'bookId': 'JHN', 'bookName': 'John', 'chapter': 3, 'verse': 16},
  {'bookId': 'PHP', 'bookName': 'Philippians', 'chapter': 4, 'verse': 13},
  {'bookId': 'PRO', 'bookName': 'Proverbs', 'chapter': 3, 'verse': 5},
  {'bookId': 'ROM', 'bookName': 'Romans', 'chapter': 8, 'verse': 28},
  {'bookId': 'JER', 'bookName': 'Jeremiah', 'chapter': 29, 'verse': 11},
  {'bookId': 'PSA', 'bookName': 'Psalms', 'chapter': 23, 'verse': 1},
  {'bookId': 'ISA', 'bookName': 'Isaiah', 'chapter': 41, 'verse': 10},
  {'bookId': 'ROM', 'bookName': 'Romans', 'chapter': 12, 'verse': 2},
  {'bookId': 'PSA', 'bookName': 'Psalms', 'chapter': 46, 'verse': 1},
  {'bookId': 'PHP', 'bookName': 'Philippians', 'chapter': 4, 'verse': 6},
  {'bookId': 'MAT', 'bookName': 'Matthew', 'chapter': 11, 'verse': 28},
  {'bookId': 'PSA', 'bookName': 'Psalms', 'chapter': 119, 'verse': 105},
  {'bookId': 'ISA', 'bookName': 'Isaiah', 'chapter': 40, 'verse': 31},
  {'bookId': '2CO', 'bookName': '2 Corinthians', 'chapter': 5, 'verse': 17},
  {'bookId': 'GAL', 'bookName': 'Galatians', 'chapter': 5, 'verse': 22},
  {'bookId': 'HEB', 'bookName': 'Hebrews', 'chapter': 11, 'verse': 1},
  {'bookId': '1PE', 'bookName': '1 Peter', 'chapter': 5, 'verse': 7},
  {'bookId': '1JN', 'bookName': '1 John', 'chapter': 4, 'verse': 19},
  {'bookId': 'EPH', 'bookName': 'Ephesians', 'chapter': 2, 'verse': 8},
  {'bookId': 'ROM', 'bookName': 'Romans', 'chapter': 15, 'verse': 13},
  {'bookId': 'PSA', 'bookName': 'Psalms', 'chapter': 27, 'verse': 1},
  {'bookId': 'JOS', 'bookName': 'Joshua', 'chapter': 1, 'verse': 9},
  {'bookId': 'ZEC', 'bookName': 'Zechariah', 'chapter': 4, 'verse': 6},
  {'bookId': 'MAT', 'bookName': 'Matthew', 'chapter': 6, 'verse': 33},
  {'bookId': 'MRK', 'bookName': 'Mark', 'chapter': 11, 'verse': 24},
  {'bookId': 'LUK', 'bookName': 'Luke', 'chapter': 1, 'verse': 37},
  {'bookId': 'JHN', 'bookName': 'John', 'chapter': 14, 'verse': 6},
  {'bookId': 'ROM', 'bookName': 'Romans', 'chapter': 5, 'verse': 8},
  {'bookId': '1CO', 'bookName': '1 Corinthians', 'chapter': 13, 'verse': 4},
  {'bookId': 'COL', 'bookName': 'Colossians', 'chapter': 3, 'verse': 2},
  {'bookId': 'JAM', 'bookName': 'James', 'chapter': 1, 'verse': 5},
];

class VerseOfDayCard extends ConsumerWidget {
  const VerseOfDayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    // Daily seed ensures the verse changes exactly once per day.
    final dailyIndex = (now.year * 10000 + now.month * 100 + now.day) % _dailyVerses.length;
    final verseConfig = _dailyVerses[dailyIndex];

    final bookId = verseConfig['bookId'] as String;
    final bookName = verseConfig['bookName'] as String;
    final chapter = verseConfig['chapter'] as int;
    final verseNum = verseConfig['verse'] as int;

    final booksAsync = ref.watch(bibleBooksProvider);

    return booksAsync.when(
      data: (books) {
        // Find text for the verse
        final book = books.where((b) => b.id.toLowerCase() == bookId.toLowerCase()).firstOrNull;
        if (book == null) return const SizedBox.shrink();
        final actualBookId = book.id;

        final chapterObj = book.chapters.where((c) => c.number == chapter).firstOrNull;
        if (chapterObj == null) return const SizedBox.shrink();
        
        final verseObj = chapterObj.verses.where((v) => v.number == verseNum).firstOrNull;
        if (verseObj == null) return const SizedBox.shrink();

        final verseText = verseObj.text;
        final reference = '$bookName $chapter:$verseNum';

        // Check if bookmarked
        final existingBookmarks = ref.watch(bookmarksNotifierProvider).value ?? [];
        final isBookmarked = existingBookmarks.any((b) => 
            b.bookId == actualBookId && 
            b.chapterNumber == chapter && 
            b.verseNumber == verseNum);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColorDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  Icons.format_quote_rounded,
                  size: 140,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text('Verse of the Day', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '"$verseText"',
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.5,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '- $reference',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // AI Explain Button
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                builder: (context) => VerseAiResultsScreen(
                                  bookName: bookName,
                                  chapterNumber: chapter,
                                  verseNumber: verseNum,
                                  verseText: verseText,
                                  initialMode: VerseFeature.explain,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.indigo),
                          label: const Text('AI Explain', style: TextStyle(color: Colors.indigo)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(0, 36),
                          ),
                        ),
                        const Spacer(),
                        // Bookmark Button
                        IconButton(
                          icon: Icon(
                            isBookmarked ? Icons.bookmark : Icons.bookmark_border, 
                            color: Colors.white
                          ),
                          onPressed: () {
                            if (isBookmarked) {
                              final b = existingBookmarks.firstWhere((b) => 
                                b.bookId == bookId && 
                                b.chapterNumber == chapter && 
                                b.verseNumber == verseNum);
                              ref.read(bookmarksNotifierProvider.notifier).deleteBookmark(b.id);
                            } else {
                              final bookmark = BookmarkModel(
                                id: const Uuid().v4(),
                                bookId: actualBookId,
                                bookName: bookName,
                                chapterNumber: chapter,
                                verseNumber: verseNum,
                                verseText: verseText,
                                createdAt: DateTime.now(),
                              );
                              ref.read(bookmarksNotifierProvider.notifier).addBookmark(bookmark);
                            }
                          },
                        ),
                        // Share Button
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.white),
                          onPressed: () {
                            Share.share('"$verseText" - $reference');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
