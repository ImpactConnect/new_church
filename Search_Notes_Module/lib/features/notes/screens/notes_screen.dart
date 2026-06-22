import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/notes/note_model.dart';
import '../../monetization/widgets/inline_ad_card.dart';
import '../providers/notes_providers.dart';

/// Annotations screen — lists verse notes with search and sort
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _SortOption _currentSort = _SortOption.newest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Hero ──
          _NotesHero(),

          // ── Search + Filter Row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search notes...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      isDense: true,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  ),
                ),
                const SizedBox(width: 10),
                PopupMenuButton<_SortOption>(
                  onSelected: (option) {
                    final notifier = ref.read(notesNotifierProvider.notifier);
                    setState(() => _currentSort = option);
                    switch (option) {
                      case _SortOption.newest:
                        notifier.sortByDateDescending();
                      case _SortOption.oldest:
                        notifier.sortByDateAscending();
                      case _SortOption.book:
                        notifier.sortByReference();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: _SortOption.newest,
                      child: Text('Newest first'),
                    ),
                    PopupMenuItem(
                      value: _SortOption.oldest,
                      child: Text('Oldest first'),
                    ),
                    PopupMenuItem(value: _SortOption.book, child: Text('By book')),
                  ],
                  icon: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _currentSort == _SortOption.book
                          ? Icons.filter_alt_rounded
                          : Icons.tune_rounded,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── List ──
          Expanded(
            child: notesAsync.when(
              data: (notes) {
                if (notes.isEmpty) return _buildEmptyState();

                // Filter by search query
                var filtered = notes;
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  filtered = notes
                      .where(
                        (n) =>
                            n.reference.toLowerCase().contains(q) ||
                            n.content.toLowerCase().contains(q) ||
                            n.verseText.toLowerCase().contains(q),
                      )
                      .toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No matching annotations',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    // ── Count ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${filtered.length} annotation${filtered.length == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final note = filtered[index];
                          final isAdSlot = (index + 1) % 3 == 0 && index != filtered.length - 1;
                          
                          return Column(
                            children: [
                              _NoteCard(
                                note: note,
                                onTap: () => context.push(
                                  '/bible/${note.bookId}/${note.chapterNumber}',
                                ),
                                onDelete: () => ref
                                    .read(notesNotifierProvider.notifier)
                                    .deleteNote(note.id),
                                onEdit: () => _editNote(context, ref, note),
                              ),
                              if (isAdSlot)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 10),
                                  child: InlineAdCard(),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.edit_note_rounded,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No annotations yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add notes to any verse while reading.\nYour annotations will appear here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editNote(
    BuildContext context,
    WidgetRef ref,
    NoteModel note,
  ) async {
    final controller = TextEditingController(text: note.content);

    final updatedContent = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(note.reference),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.verseText,
                style: Theme.of(
                  dialogContext,
                ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Update your note...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (updatedContent == null ||
        updatedContent.isEmpty ||
        updatedContent == note.content) {
      return;
    }

    final updatedNote = NoteModel(
      id: note.id,
      bookId: note.bookId,
      bookName: note.bookName,
      chapterNumber: note.chapterNumber,
      verseNumber: note.verseNumber,
      content: updatedContent,
      createdAt: note.createdAt,
      verseText: note.verseText,
    );

    await ref.read(notesNotifierProvider.notifier).updateNote(updatedNote);

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Annotation updated')));
  }
}

// ── Note Card ──

class _NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: onEdit,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        note.reference,
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat.yMMMd().format(note.createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Verse Text ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(
                        color: cs.primary.withValues(alpha: 0.4),
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    note.verseText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Note Content ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 16,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        note.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotesHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cs.primary.withValues(alpha: 0.14),
              cs.secondary.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.edit_note_rounded, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Write It, Remember It',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Keep insights from scripture close. “Write them on the tablet of your heart.” — Proverbs 7:3',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _SortOption { newest, oldest, book }
