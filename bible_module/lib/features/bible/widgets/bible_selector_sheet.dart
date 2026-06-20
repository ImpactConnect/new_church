import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/bible/bible_book.dart';
import '../providers/bible_providers.dart';

class BibleSelectorSheet extends ConsumerStatefulWidget {
  final String currentBookId;
  final int currentChapter;

  const BibleSelectorSheet({
    super.key,
    required this.currentBookId,
    required this.currentChapter,
  });

  @override
  ConsumerState<BibleSelectorSheet> createState() => _BibleSelectorSheetState();
}

class _BibleSelectorSheetState extends ConsumerState<BibleSelectorSheet> {
  late String _selectedBookId;
  int? _selectedChapterNumber;

  @override
  void initState() {
    super.initState();
    _selectedBookId = widget.currentBookId;
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(bibleBooksProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: booksAsync.when(
              data: (books) {
                if (books.isEmpty) {
                  return const Center(child: Text('No books available'));
                }

                final selectedBook = books.firstWhere(
                  (b) => b.id == _selectedBookId,
                  orElse: () => books.first,
                );

                return Row(
                  children: [
                    // Left Pane: Books List
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
                        child: ListView.builder(
                          itemCount: books.length,
                          itemBuilder: (context, index) {
                            final book = books[index];
                            final isSelected = book.id == _selectedBookId;

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedBookId = book.id;
                                  _selectedChapterNumber = null;
                                });
                              },
                              child: Container(
                                color: isSelected
                                    ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                          .withOpacity(0.3)
                                    : null,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Text(
                                  book.name,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Right Pane: Chapters / Verses
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                if (_selectedChapterNumber != null)
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedChapterNumber = null;
                                      });
                                    },
                                    icon: const Icon(Icons.arrow_back_ios_new),
                                    tooltip: 'Back to chapters',
                                    visualDensity: VisualDensity.compact,
                                  ),
                                Expanded(
                                  child: Text(
                                    _selectedChapterNumber == null
                                        ? selectedBook.name
                                        : '${selectedBook.name} $_selectedChapterNumber',
                                    style: Theme.of(context).textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _selectedChapterNumber == null
                                ? GridView.builder(
                                    padding: const EdgeInsets.all(16),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 5,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                        ),
                                    itemCount: selectedBook.chapters.length,
                                    itemBuilder: (context, index) {
                                      final chapter =
                                          selectedBook.chapters[index];
                                      final isCurrent =
                                          widget.currentBookId ==
                                              _selectedBookId &&
                                          widget.currentChapter ==
                                              chapter.number;

                                      return InkWell(
                                        onTap: () {
                                          setState(() {
                                            _selectedChapterNumber =
                                                chapter.number;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: isCurrent
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                : Theme.of(context)
                                                      .colorScheme
                                                      .surfaceContainerHighest,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${chapter.number}',
                                            style: TextStyle(
                                              color: isCurrent
                                                  ? Colors.white
                                                  : Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Builder(
                                    builder: (context) {
                                      final chapter = selectedBook.chapters.firstWhere(
                                        (c) =>
                                            c.number ==
                                            _selectedChapterNumber,
                                        orElse: () =>
                                            selectedBook.chapters.first,
                                      );

                                      return GridView.builder(
                                        padding: const EdgeInsets.all(16),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 6,
                                              crossAxisSpacing: 10,
                                              mainAxisSpacing: 10,
                                              childAspectRatio: 1.0,
                                            ),
                                        itemCount: chapter.verses.length,
                                        itemBuilder: (context, index) {
                                          final verse =
                                              chapter.verses[index];
                                          return InkWell(
                                            onTap: () {
                                              final router =
                                                  GoRouter.of(context);
                                              Navigator.of(context).pop();
                                              router.pushReplacement(
                                                '/bible/${selectedBook.id}/${chapter.number}?verse=${verse.number}',
                                              );
                                            },
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: Theme.of(context)
                                                      .dividerColor
                                                      .withOpacity(0.25),
                                                ),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                '${verse.number}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class VerseSelectorSheet extends StatelessWidget {
  final BibleBook book;
  final int chapterNumber;
  final ValueChanged<int> onVerseSelected;

  const VerseSelectorSheet({
    super.key,
    required this.book,
    required this.chapterNumber,
    required this.onVerseSelected,
  });

  @override
  Widget build(BuildContext context) {
    final chapter = book.chapters.firstWhere(
      (c) => c.number == chapterNumber,
      orElse: () => book.chapters.first,
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${book.name} $chapterNumber',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'Select Verse',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              itemCount: chapter.verses.length,
              itemBuilder: (context, index) {
                final verse = chapter.verses[index];
                return InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    onVerseSelected(verse.number);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${verse.number}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
