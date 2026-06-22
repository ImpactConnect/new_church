import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../bible_ai/data/models/bible/bible_book.dart';
import '../../../bible_ai/data/models/bible/bible_verse.dart';
import '../../../bible_ai/data/models/bible/bible_version.dart';
import '../../../bible_ai/features/bible/providers/bible_providers.dart';
import '../../../bible_ai/features/bible/screens/ai_chat_screen.dart';
import '../../../bible_ai/features/bible/screens/ai_explanation_screen.dart';

// Robust Reference Parser
class ParsedReference {
  final String bookName;
  final int chapter;
  final int? startVerse;
  final int? endVerse;

  ParsedReference({
    required this.bookName,
    required this.chapter,
    this.startVerse,
    this.endVerse,
  });

  static ParsedReference? parse(String refStr) {
    var cleaned = refStr.trim().replaceFirst(RegExp(r'^cf\.\s+', caseSensitive: false), '');
    final regex = RegExp(
      r'^((?:\d\s+)?[A-Za-z]+(?:\s+[A-Za-z]+)*)\s+(\d+)(?::(\d+)(?:[-–](\d+))?)?$',
    );
    final match = regex.firstMatch(cleaned);
    if (match == null) return null;

    final book = match.group(1)!.trim();
    final chapter = int.tryParse(match.group(2) ?? '') ?? 1;
    final startV = int.tryParse(match.group(3) ?? '');
    final endV = int.tryParse(match.group(4) ?? '');

    return ParsedReference(
      bookName: book,
      chapter: chapter,
      startVerse: startV,
      endVerse: endV,
    );
  }
}

class BiblePassageBottomSheet extends ConsumerStatefulWidget {
  final String reference;
  final String? text;

  const BiblePassageBottomSheet({
    super.key,
    required this.reference,
    this.text,
  });

  @override
  ConsumerState<BiblePassageBottomSheet> createState() => _BiblePassageBottomSheetState();
}

class _BiblePassageBottomSheetState extends ConsumerState<BiblePassageBottomSheet> {
  // Helper to find book in the loaded list
  BibleBook? _findBook(List<BibleBook> books, String bookName) {
    final query = bookName.trim().toLowerCase();
    String normalize(String s) => s.toLowerCase().replaceAll(' ', '').replaceAll('.', '').replaceAll('chapter', '').trim();
    final normQuery = normalize(query);

    for (final book in books) {
      if (normalize(book.name) == normQuery || normalize(book.id) == normQuery) {
        return book;
      }
    }

    if (normQuery == 'psalm' || normQuery == 'psalms') {
      for (final book in books) {
        final normName = normalize(book.name);
        if (normName == 'psalms' || normName == 'psa' || normName == 'psalm') {
          return book;
        }
      }
    }

    final abbreviations = {
      'gen': 'genesis', 'exo': 'exodus', 'lev': 'leviticus', 'num': 'numbers', 'deu': 'deuteronomy',
      'jos': 'joshua', 'jdg': 'judges', 'rut': 'ruth', '1sa': '1 samuel', '2sa': '2 samuel',
      '1ki': '1 kings', '2ki': '2 kings', '1ch': '1 chronicles', '2ch': '2 chronicles',
      'ezr': 'ezra', 'neh': 'nehemiah', 'est': 'esther', 'job': 'job', 'psa': 'psalms',
      'pro': 'proverbs', 'ecc': 'ecclesiastes', 'sol': 'song of solomon', 'isa': 'isaiah',
      'jer': 'jeremiah', 'lam': 'lamentations', 'eze': 'ezekiel', 'dan': 'daniel',
      'hos': 'hosea', 'joe': 'joel', 'amo': 'amos', 'oba': 'obadiah', 'jon': 'jonah',
      'mic': 'micah', 'nah': 'nahum', 'hab': 'habakkuk', 'zep': 'zephaniah', 'hag': 'haggai',
      'zec': 'zechariah', 'mal': 'malachi', 'mat': 'matthew', 'mar': 'mark', 'luk': 'luke',
      'joh': 'john', 'act': 'acts', 'rom': 'romans', '1co': '1 corinthians', '2co': '2 corinthians',
      'gal': 'galatians', 'eph': 'ephesians', 'phi': 'philippians', 'col': 'colossians',
      '1th': '1 thessalonians', '2th': '2 thessalonians', '1ti': '1 timothy', '2ti': '2 timothy',
      'tit': 'titus', 'phm': 'philemon', 'heb': 'hebrews', 'jam': 'james', '1pe': '1 peter',
      '2pe': '2 peter', '1jo': '1 john', '2jo': '2 john', '3jo': '3 john', 'jud': 'jude',
      'rev': 'revelation'
    };

    final mPrefix = normQuery.length >= 3 ? normQuery.substring(0, 3) : normQuery;
    final mapped = abbreviations[mPrefix];
    if (mapped != null) {
      final normMapped = normalize(mapped);
      for (final book in books) {
        if (normalize(book.name) == normMapped || normalize(book.id) == normMapped) {
          return book;
        }
      }
    }

    for (final book in books) {
      final normName = normalize(book.name);
      if (normName.startsWith(normQuery) || normQuery.startsWith(normName)) {
        return book;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(bibleBooksProvider);
    final currentVersion = ref.watch(bibleVersionNotifierProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 8, left: 20, right: 20, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          booksAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  const Text('Error loading Bible data', style: TextStyle(color: Colors.red)),
                  if (widget.text != null) ...[
                    const SizedBox(height: 12),
                    Text(widget.text!, style: const TextStyle(fontSize: 15, height: 1.5)),
                  ],
                ],
              ),
            ),
            data: (books) {
              final parsed = ParsedReference.parse(widget.reference);
              if (parsed == null) {
                return _buildErrorContent('Could not parse reference "${widget.reference}"');
              }

              final book = _findBook(books, parsed.bookName);
              if (book == null) {
                return _buildErrorContent('Book "${parsed.bookName}" not found');
              }

              int chapterNum = parsed.chapter;
              int? startVerse = parsed.startVerse;
              int? endVerse = parsed.endVerse;

              // Handle single chapter books
              if (book.chapters.length == 1) {
                chapterNum = 1;
                if (parsed.startVerse == null) {
                  startVerse = parsed.chapter;
                }
              }

              final chapter = book.chapters.firstWhere(
                (c) => c.number == chapterNum,
                orElse: () => book.chapters.first,
              );

              List<BibleVerse> verses = [];
              if (startVerse != null) {
                final start = startVerse;
                final end = endVerse ?? start;
                verses = chapter.verses.where((v) => v.number >= start && v.number <= end).toList();
              } else {
                verses = chapter.verses;
              }

              if (verses.isEmpty && chapter.verses.isNotEmpty) {
                verses = [chapter.verses.first];
              }

              final displayRef = startVerse != null
                  ? '${book.name} $chapterNum:$startVerse${endVerse != null && endVerse != startVerse ? "-$endVerse" : ""}'
                  : '${book.name} $chapterNum';

              final passageString = verses.map((v) => '${v.number}. ${v.text}').join('\n');
              final shareText = '"$passageString"\n— $displayRef (${currentVersion.abbreviation})';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title + Version Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          displayRef,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Version Selector
                      PopupMenuButton<BibleVersion>(
                        initialValue: currentVersion,
                        onSelected: (version) {
                          ref.read(bibleVersionNotifierProvider.notifier).setVersion(version);
                        },
                        itemBuilder: (context) => BibleVersion.values
                            .map((v) => PopupMenuItem(
                                  value: v,
                                  child: Text('${v.abbreviation} - ${v.fullName}'),
                                ))
                            .toList(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.primary),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                currentVersion.abbreviation,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_drop_down,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Scripture Content Box
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: SingleChildScrollView(
                      child: SelectableText.rich(
                        TextSpan(
                          children: verses.map((v) {
                            return TextSpan(
                              children: [
                                TextSpan(
                                  text: ' ${v.number} ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                TextSpan(
                                  text: '${v.text} ',
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.6,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Actions Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Copy & Share
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy),
                            tooltip: 'Copy Passage',
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: shareText));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Copied to clipboard')),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.share),
                            tooltip: 'Share Passage',
                            onPressed: () {
                              Share.share(shareText);
                            },
                          ),
                        ],
                      ),
                      // AI Study Actions
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AiChatScreen(
                                    bookName: book.name,
                                    chapterNumber: chapterNum,
                                    verseNumber: startVerse ?? 1,
                                    verseText: verses.isNotEmpty ? verses.first.text : '',
                                    preloadedContext: 'I am studying $displayRef:\n$passageString',
                                    showWelcomeMessageOnNewSession: true,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline, size: 16),
                            label: const Text('Ask GSW'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AiExplanationScreen(
                                    bookName: book.name,
                                    chapterNumber: chapterNum,
                                    verseNumber: startVerse ?? 1,
                                    verseText: verses.isNotEmpty ? verses.first.text : '',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.auto_awesome, size: 16),
                            label: const Text('Explain'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(String errorMsg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.reference,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            errorMsg,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          if (widget.text != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.text!,
                style: const TextStyle(fontSize: 15, height: 1.5, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

void showBiblePassageBottomSheet(BuildContext context, String reference, {String? text}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BiblePassageBottomSheet(reference: reference, text: text),
  );
}
