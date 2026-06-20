import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../bookmarks/providers/bookmarks_providers.dart';
import '../../highlights/providers/highlights_providers.dart';
import '../../notes/providers/notes_providers.dart';
import '../../../data/models/ai/ai_models.dart';
import '../../../data/models/bible/bible_book.dart';
import '../../../data/models/bookmarks/bookmark_model.dart';
import '../../../data/models/highlights/highlight_model.dart';
import '../../../data/models/notes/note_model.dart';
import '../providers/bible_providers.dart';
import '../../../data/repositories/user_settings_repository.dart';

import '../widgets/ai_exposition_selection_sheet.dart';
import 'ai_book_exegesis_screen.dart';
import 'ai_chapter_exegesis_screen.dart';
import 'ai_chat_screen.dart';
import 'verse_ai_results_screen.dart';
import '../widgets/bible_selector_sheet.dart';

// Import standalone notes feature
import '../../notes/presentation/widgets/add_to_note_dialog.dart';
import '../../notes/services/content_linker_service.dart';
import '../../notes/data/models/linked_content_reference.dart';
import '../../exegesis/models/exegesis_final_model.dart';
import '../../monetization/widgets/banner_ad_widget.dart';

/// Chapter reading screen - displays verses with interactive features
class ChapterScreen extends ConsumerStatefulWidget {
  final String bookId;
  final int chapterNumber;
  final int? initialVerseNumber;

  const ChapterScreen({
    super.key,
    required this.bookId,
    required this.chapterNumber,
    this.initialVerseNumber,
  });

  @override
  ConsumerState<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends ConsumerState<ChapterScreen> {
  final Set<int> _selectedVerses = {};
  final Map<int, GlobalKey> _verseKeys = {};
  final ScrollController _scrollController = ScrollController();
  bool get _isSelectionMode => _selectedVerses.isNotEmpty;
  bool _didScrollToInitialVerse = false;

  @override
  void initState() {
    super.initState();
    _saveLastRead();
    _applyInitialVerseSelection();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChapterScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookId != widget.bookId ||
        oldWidget.chapterNumber != widget.chapterNumber ||
        oldWidget.initialVerseNumber != widget.initialVerseNumber) {
      _saveLastRead();
      _selectedVerses.clear();
      _verseKeys.clear();
      _didScrollToInitialVerse = false;
      _applyInitialVerseSelection();
    }
  }

  void _applyInitialVerseSelection() {
    final verseNumber = widget.initialVerseNumber;
    if (verseNumber == null) return;
    _selectedVerses
      ..clear()
      ..add(verseNumber);
  }

  void _saveLastRead() {
    // Fire and forget save
    ref.read(userSettingsRepositoryProvider.future).then((repo) {
      repo.saveLastRead(widget.bookId, widget.chapterNumber);
    });
  }

  void _toggleSelection(int verseNumber) {
    setState(() {
      if (_selectedVerses.contains(verseNumber)) {
        _selectedVerses.remove(verseNumber);
      } else {
        _selectedVerses.add(verseNumber);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedVerses.clear();
    });
  }

  void _scrollToInitialVerseIfNeeded() {
    final verseNumber = widget.initialVerseNumber;
    if (_didScrollToInitialVerse || verseNumber == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptScrollToVerse(verseNumber, 0);
    });
  }

  Future<void> _attemptScrollToVerse(int verseNumber, int attempt) async {
    if (!mounted || _didScrollToInitialVerse) return;

    final verseContext = _verseKeys[verseNumber]?.currentContext;
    final renderObject = verseContext?.findRenderObject();

    if (renderObject != null &&
        renderObject.attached &&
        _scrollController.hasClients) {
      final viewport = RenderAbstractViewport.of(renderObject);
      final targetOffset = viewport
          .getOffsetToReveal(renderObject, 0.12)
          .offset
          .clamp(
            _scrollController.position.minScrollExtent,
            _scrollController.position.maxScrollExtent,
          );

      _didScrollToInitialVerse = true;
      if (mounted && !_selectedVerses.contains(verseNumber)) {
        setState(() {
          _selectedVerses
            ..clear()
            ..add(verseNumber);
        });
      }

      await _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    if (attempt >= 10) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    _attemptScrollToVerse(verseNumber, attempt + 1);
  }

  String _formatVerseRange(List<int> verses) {
    if (verses.isEmpty) return '';
    if (verses.length == 1) return verses.first.toString();

    // Check if contiguous
    bool contiguous = true;
    for (int i = 0; i < verses.length - 1; i++) {
      if (verses[i + 1] - verses[i] != 1) {
        contiguous = false;
        break;
      }
    }
    if (contiguous) {
      return '${verses.first}-${verses.last}';
    } else {
      return verses.join(', ');
    }
  }

  void _openBatchActionsSheet() {
    final chapter = ref
        .read(bibleChapterProvider(widget.bookId, widget.chapterNumber))
        .value;
    if (chapter == null || _selectedVerses.isEmpty) return;

    final sortedVerses = _selectedVerses.toList()..sort();
    final buffer = StringBuffer();
    for (final verseNum in sortedVerses) {
      final verse = chapter.verses.firstWhere((v) => v.number == verseNum);
      if (sortedVerses.length > 1) {
        buffer.write('[${verse.number}] ${verse.text} ');
      } else {
        buffer.write('${verse.text} ');
      }
    }
    final combinedText = buffer.toString().trim();

    String? singleHighlightId;
    if (sortedVerses.length == 1) {
      final highlight = ref
          .read(highlightsNotifierProvider)
          .value
          ?.where(
            (h) =>
                h.bookId == widget.bookId &&
                h.chapterNumber == widget.chapterNumber &&
                h.verseNumber == sortedVerses.first,
          )
          .firstOrNull;
      singleHighlightId = highlight?.id;
    }

    _showVerseActions(
      context,
      ref,
      sortedVerses,
      combinedText,
      singleHighlightId,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the chapter provider
    final chapterAsync = ref.watch(
      bibleChapterProvider(widget.bookId, widget.chapterNumber),
    );
    final booksAsync = ref.watch(bibleBooksProvider);
    final highlightsAsync = ref.watch(highlightsNotifierProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/bible');
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: _isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSelection,
                )
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/bible'),
                ),
          title: _isSelectionMode
              ? Text('${_selectedVerses.length} selected')
              : booksAsync.when(
                  data: (books) {
                    final book = books.firstWhere(
                      (b) => b.id == widget.bookId,
                      orElse: () => books.first,
                    );
                    return InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => BibleSelectorSheet(
                            currentBookId: widget.bookId,
                            currentChapter: widget.chapterNumber,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                '${book.name} ${widget.chapterNumber}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => Text(
                    '${widget.bookId.toUpperCase()} ${widget.chapterNumber}',
                  ),
                  error: (_, __) => Text(
                    '${widget.bookId.toUpperCase()} ${widget.chapterNumber}',
                  ),
                ),
          actions: [
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              onPressed: () {
                _showAiExpositionOptions(context, ref);
              },
              tooltip: 'Chapter Summary',
            ),
          ],
        ),
        floatingActionButton: _isSelectionMode
            ? FloatingActionButton.extended(
                onPressed: _openBatchActionsSheet,
                label: const Text('Actions'),
                icon: const Icon(Icons.bolt),
              )
            : null,
        body: Column(
          children: [
            Expanded(
              child: chapterAsync.when(
                data: (chapter) {
                  if (chapter == null) {
                    return const Center(child: Text('Chapter not found'));
                  }

                  if (chapter.verses.isEmpty) {
                    return const Center(
                      child: Text('No verses in this chapter'),
                    );
                  }

                  _scrollToInitialVerseIfNeeded();

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: SingleChildScrollView(
                        key: ValueKey(
                          '${widget.bookId}-${widget.chapterNumber}',
                        ),
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, 22),
                        child: Column(
                          children: [
                            for (final verse in chapter.verses)
                              Container(
                                key: _verseKeys.putIfAbsent(
                                  verse.number,
                                  () => GlobalKey(),
                                ),
                                child: Builder(
                                  builder: (context) {
                                    final highlight = highlightsAsync.value
                                        ?.where(
                                          (h) =>
                                              h.bookId == widget.bookId &&
                                              h.chapterNumber ==
                                                  widget.chapterNumber &&
                                              h.verseNumber == verse.number,
                                        )
                                        .firstOrNull;

                                    final isSelected = _selectedVerses.contains(
                                      verse.number,
                                    );

                                    return _VerseTile(
                                      verseNumber: verse.number,
                                      text: verse.text,
                                      isHighlighted: highlight != null,
                                      isSelected: isSelected,
                                      highlightColor: highlight != null
                                          ? Color(highlight.colorValue)
                                          : null,
                                      onTap: () {
                                        _toggleSelection(verse.number);
                                      },
                                      onLongPress: () {
                                        if (!_isSelectionMode) {
                                          _toggleSelection(verse.number);
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
            _ChapterNavigation(
              bookId: widget.bookId,
              currentChapter: widget.chapterNumber,
              booksAsync: booksAsync,
            ),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  void _showAiVerseSheet(
    BuildContext context,
    String bookName,
    int chapterNumber,
    int verseNumber,
    String text,
    VerseFeature feature,
  ) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => VerseAiResultsScreen(
          bookName: bookName,
          chapterNumber: chapterNumber,
          verseNumber: verseNumber,
          verseText: text,
          initialMode: feature,
        ),
      ),
    );
  }

  void _showAiExpositionOptions(BuildContext context, WidgetRef ref) async {
    final books = ref.read(bibleBooksProvider).value ?? [];
    final book = books.firstWhere(
      (b) => b.id == widget.bookId,
      orElse: () => books.first,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => AiExpositionSelectionSheet(
        bookName: book.name,
        chapterNumber: widget.chapterNumber,
        onSelectBook: () {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (context) => AiBookExegesisScreen(bookName: book.name),
            ),
          );
        },
        onSelectChapter: () {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (context) => AiChapterExegesisScreen(
                bookName: book.name,
                chapterNumber: widget.chapterNumber,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showVerseActions(
    BuildContext context,
    WidgetRef ref,
    List<int> verseNumbers,
    String text,
    String? currentHighlightId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow it to take needed height
      builder: (context) => SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.bookId.toUpperCase()} ${widget.chapterNumber}:${_formatVerseRange(verseNumbers)}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 24),
              // --- AI Section ---
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Exposition',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 12,
                children: [
                  _ActionChip(
                    icon: Icons.lightbulb_outline,
                    label: 'Verse Explain',
                    isAi: true,
                    onTap: () => _openAiSheet(
                      context,
                      ref,
                      verseNumbers.first,
                      text,
                      VerseFeature.explain,
                    ),
                  ),
                  _ActionChip(
                    icon: Icons.auto_stories_outlined,
                    label: 'Deep Exegesis',
                    isAi: true,
                    onTap: () {
                      Navigator.pop(context);
                      final books = ref.read(bibleBooksProvider).value ?? [];
                      final book = books.firstWhere(
                        (b) => b.id == widget.bookId,
                        orElse: () => books.first,
                      );
                      final verseRef = VerseRef(
                        book: book.name,
                        chapter: widget.chapterNumber,
                        verse: verseNumbers.first,
                        endVerse: verseNumbers.length > 1
                            ? verseNumbers.last
                            : null,
                      );
                      context.push(
                        '/exegesis/final/new',
                        extra: {
                          'prefillVerseRef': verseRef.toJson(),
                          'prefillVerseText': text,
                        },
                      );
                    },
                  ),
                  _ActionChip(
                    icon: Icons.chat_bubble_outline,
                    label: 'Ask Rabbi',
                    isAi: true,
                    onTap: () {
                      Navigator.pop(context);
                      final books = ref.read(bibleBooksProvider).value ?? [];
                      final book = books.firstWhere(
                        (b) => b.id == widget.bookId,
                        orElse: () => books.first,
                      );
                      final subject = verseNumbers.length > 1
                          ? 'passage'
                          : 'verse';
                      final autoPrompt =
                          'I want to study **${book.name} ${widget.chapterNumber}:${_formatVerseRange(verseNumbers)}** ("$text").\n\nPlease provide a very concise introductory summary of this $subject. '
                          'Start by highlighting my query in bold. Then, give a 1-paragraph bottom-line submission. '
                          'End by asking me to ask further questions for clarification.';
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (context) => AiChatScreen(
                            bookName: book.name,
                            chapterNumber: widget.chapterNumber,
                            verseNumber: verseNumbers.first,
                            verseText: text,
                            hiddenAutoPrompt: autoPrompt,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // --- Actions Section ---
              Text(
                'Actions',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 12,
                children: [
                  _ActionChip(
                    icon: currentHighlightId != null
                        ? Icons.highlight_off
                        : Icons.highlight,
                    label: currentHighlightId != null
                        ? 'Remove Highlight'
                        : 'Highlight',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentHighlightId != null) {
                        _removeHighlight(context, ref, verseNumbers);
                      } else {
                        _showHighlightColors(context, ref, verseNumbers, text);
                      }
                    },
                  ),
                  _ActionChip(
                    icon: Icons.bookmark_add,
                    label: 'Bookmark',
                    onTap: () {
                      Navigator.pop(context);
                      _addBookmark(context, ref, verseNumbers, text);
                    },
                  ),
                  _ActionChip(
                    icon: Icons.note_add,
                    label: 'Add Note',
                    onTap: () {
                      Navigator.pop(context);
                      _addNote(context, ref, verseNumbers, text);
                    },
                  ),
                  _ActionChip(
                    icon: Icons.note_add_outlined,
                    label: 'Save to Note',
                    onTap: () {
                      Navigator.pop(context);
                      _addToStandaloneNote(context, ref, verseNumbers, text);
                    },
                  ),
                  _ActionChip(
                    icon: Icons.copy,
                    label: 'Copy',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Copy to clipboard
                    },
                  ),
                  _ActionChip(
                    icon: Icons.share,
                    label: 'Share',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Share verse
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _openAiSheet(
    BuildContext context,
    WidgetRef ref,
    int verseNumber,
    String text,
    VerseFeature feature,
  ) {
    Navigator.pop(context);
    final books = ref.read(bibleBooksProvider).value ?? [];
    final book = books.firstWhere(
      (b) => b.id == widget.bookId,
      orElse: () => books.first,
    );
    _showAiVerseSheet(
      context,
      book.name,
      widget.chapterNumber,
      verseNumber,
      text,
      feature,
    );
  }

  Future<void> _addBookmark(
    BuildContext context,
    WidgetRef ref,
    List<int> verseNumbers,
    String text,
  ) async {
    final existingBookmarks = ref.read(bookmarksNotifierProvider).value ?? [];
    final books = ref.read(bibleBooksProvider).value ?? [];
    if (books.isEmpty) return;

    final book = books.firstWhere(
      (b) => b.id == widget.bookId,
      orElse: () => books.first,
    );

    for (final verseNumber in verseNumbers) {
      bool exists = false;
      for (final bookmark in existingBookmarks) {
        if (bookmark.bookId == widget.bookId &&
            bookmark.chapterNumber == widget.chapterNumber &&
            bookmark.verseNumber == verseNumber) {
          await ref
              .read(bookmarksNotifierProvider.notifier)
              .deleteBookmark(bookmark.id);
          exists = true;
          break;
        }
      }

      if (!exists) {
        final bookmark = BookmarkModel(
          id: const Uuid().v4(),
          bookId: widget.bookId,
          bookName: book.name,
          chapterNumber: widget.chapterNumber,
          verseNumber: verseNumber,
          verseText: text,
          createdAt: DateTime.now(),
          category: null,
        );
        await ref
            .read(bookmarksNotifierProvider.notifier)
            .addBookmark(bookmark);
      }
    }

    if (!context.mounted) return;
    _clearSelection();
    final msg = verseNumbers.length > 1
        ? 'Bookmarks updated'
        : 'Bookmark updated';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _addNote(
    BuildContext context,
    WidgetRef ref,
    List<int> verseNumbers,
    String text,
  ) async {
    final controller = TextEditingController();

    final content = await showDialog<String>(
      context: context,
      builder: (context) {
        final books = ref.read(bibleBooksProvider).value ?? [];
        String reference =
            '${widget.bookId.toUpperCase()} ${widget.chapterNumber}:${_formatVerseRange(verseNumbers)}';
        if (books.isNotEmpty) {
          final book = books.firstWhere(
            (b) => b.id == widget.bookId,
            orElse: () => books.first,
          );
          reference =
              '${book.name} ${widget.chapterNumber}:${_formatVerseRange(verseNumbers)}';
        }
        return AlertDialog(
          title: Text(reference),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Write your note here...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (content == null || content.isEmpty) return;

    final books = ref.read(bibleBooksProvider).value ?? [];
    if (books.isEmpty) return;

    final book = books.firstWhere(
      (b) => b.id == widget.bookId,
      orElse: () => books.first,
    );

    for (final verseNumber in verseNumbers) {
      final note = NoteModel(
        id: const Uuid().v4(),
        bookId: widget.bookId,
        bookName: book.name,
        chapterNumber: widget.chapterNumber,
        verseNumber: verseNumber,
        content: content,
        createdAt: DateTime.now(),
        verseText: text,
      );
      await ref.read(notesNotifierProvider.notifier).addNote(note);
    }

    if (!context.mounted) return;
    _clearSelection();
    final msg = verseNumbers.length > 1 ? 'Notes added' : 'Note added';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Adds verse(s) to a standalone note using the AddToNoteDialog
  Future<void> _addToStandaloneNote(
    BuildContext context,
    WidgetRef ref,
    List<int> verseNumbers,
    String text,
  ) async {
    final books = ref.read(bibleBooksProvider).value ?? [];
    if (books.isEmpty) return;

    final book = books.firstWhere(
      (b) => b.id == widget.bookId,
      orElse: () => books.first,
    );

    // Format the verse reference
    final verseRange = _formatVerseRange(verseNumbers);
    final reference = '${book.name} ${widget.chapterNumber}:$verseRange';

    // Format the content using ContentLinkerService
    final formattedContent = ContentLinkerService.formatBibleVerse(
      bookName: book.name,
      chapter: widget.chapterNumber,
      verse: verseNumbers.first,
      verseText: text,
    );

    // Create the linked content reference
    final linkedContentRef = LinkedContentReference(
      id: const Uuid().v4(),
      type: LinkedContentType.verse,
      sourceId: '${widget.bookId}_${widget.chapterNumber}_$verseRange',
      sourceReference: reference,
      linkedAt: DateTime.now(),
      metadata: {
        'bookId': widget.bookId,
        'bookName': book.name,
        'chapterNumber': widget.chapterNumber.toString(),
        'verseNumbers': verseNumbers.map((v) => v.toString()).toList(),
        'verseText': text,
      },
    );

    // Show the AddToNoteDialog
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AddToNoteDialog(
        formattedContent: formattedContent,
        linkedContentReference: linkedContentRef,
        suggestedTitle: reference,
      ),
    );

    _clearSelection();
  }

  void _showHighlightColors(
    BuildContext context,
    WidgetRef ref,
    List<int> verseNumbers,
    String text,
  ) {
    final colors = [
      0xFFFFEB3B, // Yellow
      0xFF4CAF50, // Green
      0xFF2196F3, // Blue
      0xFF9C27B0, // Purple
      0xFFF44336, // Red
      0xFFFF9800, // Orange
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Highlight Color',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: colors.map((colorValue) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _saveHighlight(
                      context,
                      ref,
                      verseNumbers,
                      text,
                      colorValue,
                    );
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(colorValue),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _saveHighlight(
    BuildContext context,
    WidgetRef ref,
    List<int> verseNumbers,
    String text,
    int colorValue,
  ) async {
    final books = ref.read(bibleBooksProvider).value ?? [];
    if (books.isEmpty) return;

    final book = books.firstWhere(
      (b) => b.id == widget.bookId,
      orElse: () => books.first,
    );

    final existingHighlights = ref.read(highlightsNotifierProvider).value ?? [];

    for (final verseNumber in verseNumbers) {
      final existingId = existingHighlights
          .where(
            (h) =>
                h.bookId == widget.bookId &&
                h.chapterNumber == widget.chapterNumber &&
                h.verseNumber == verseNumber,
          )
          .firstOrNull
          ?.id;

      final highlight = HighlightModel(
        id: existingId ?? const Uuid().v4(),
        bookId: widget.bookId,
        bookName: book.name,
        chapterNumber: widget.chapterNumber,
        verseNumber: verseNumber,
        verseText: text,
        colorValue: colorValue,
        createdAt: DateTime.now(),
      );

      await ref
          .read(highlightsNotifierProvider.notifier)
          .addHighlight(highlight);
    }

    if (!context.mounted) return;
    _clearSelection();
  }

  Future<void> _removeHighlight(
    BuildContext context,
    WidgetRef ref,
    List<int> verseNumbers,
  ) async {
    final existingHighlights = ref.read(highlightsNotifierProvider).value ?? [];

    for (final verseNumber in verseNumbers) {
      final existingId = existingHighlights
          .where(
            (h) =>
                h.bookId == widget.bookId &&
                h.chapterNumber == widget.chapterNumber &&
                h.verseNumber == verseNumber,
          )
          .firstOrNull
          ?.id;

      if (existingId != null) {
        await ref
            .read(highlightsNotifierProvider.notifier)
            .deleteHighlight(existingId);
      }
    }

    if (!context.mounted) return;
    _clearSelection();
  }
}

class _VerseTile extends StatelessWidget {
  final int verseNumber;
  final String text;
  final bool isHighlighted;
  final bool isSelected;
  final Color? highlightColor;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _VerseTile({
    required this.verseNumber,
    required this.text,
    this.isHighlighted = false,
    this.isSelected = false,
    this.highlightColor,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
              : isHighlighted
              ? (highlightColor ?? Colors.yellow.withOpacity(0.3))
              : null,
          borderRadius: BorderRadius.circular(4),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.5,
                )
              : null,
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$verseNumber ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              TextSpan(
                text: text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.85,
                  fontSize: 18,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isAi;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isAi = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    final surfaceTint = colorScheme.surfaceTint;

    return Material(
      color: isAi ? surfaceTint.withOpacity(0.15) : primary.withOpacity(0.05),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isAi ? primary : primary.withOpacity(0.8),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isAi ? primary : primary.withOpacity(0.8),
                  fontWeight: isAi ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterNavigation extends StatelessWidget {
  final String bookId;
  final int currentChapter;
  final AsyncValue<List<BibleBook>> booksAsync;

  const _ChapterNavigation({
    required this.bookId,
    required this.currentChapter,
    required this.booksAsync,
  });

  @override
  Widget build(BuildContext context) {
    return booksAsync.when(
      data: (books) {
        final book = books.firstWhere(
          (b) => b.id == bookId,
          orElse: () => books.first,
        );
        final totalChapters = book.chapters.length;

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                onPressed: currentChapter > 1
                    ? () => context.go('/bible/$bookId/${currentChapter - 1}')
                    : null,
                tooltip: 'Previous Chapter',
              ),
              Expanded(
                child: Text(
                  'Chapter $currentChapter of $totalChapters',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: currentChapter < totalChapters
                    ? () => context.go('/bible/$bookId/${currentChapter + 1}')
                    : null,
                tooltip: 'Next Chapter',
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
