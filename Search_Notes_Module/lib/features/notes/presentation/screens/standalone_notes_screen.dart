import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/standalone_note_model.dart';
import '../../data/repositories/notes_repository.dart';
import '../providers/standalone_notes_providers.dart';

/// Standalone notes screen with modern UI design
class StandaloneNotesScreen extends ConsumerStatefulWidget {
  const StandaloneNotesScreen({super.key});

  @override
  ConsumerState<StandaloneNotesScreen> createState() =>
      _StandaloneNotesScreenState();
}

class _StandaloneNotesScreenState extends ConsumerState<StandaloneNotesScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedTag;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(filteredNotesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('My Notes'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colorScheme.surface, colorScheme.surfaceContainerLowest],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeroSection(context, colorScheme),
              _buildSearchAndFilter(context, colorScheme, notesAsync),
              Expanded(
                child: notesAsync.when(
                  data: (notes) => _buildNotesList(context, notes),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => _buildErrorState(context, error),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: () {
            ref.read(currentNoteProvider.notifier).state = null;
            context.push('/notes/editor');
          },
          icon: const Icon(Icons.add),
          label: const Text('New Note'),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F63D2), Color(0xFF8B3FC0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B4FC8).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(width: 20),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Write It, Remember It',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Capture spiritual insights and testimonies. “Write them on the tablet of your heart.” — Proverbs 7:3',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      height: 1.4,
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

  Widget _buildSearchAndFilter(
    BuildContext context,
    ColorScheme colorScheme,
    AsyncValue<List<StandaloneNote>> notesAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          PopupMenuButton<SortCriteria>(
            icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.tune_rounded, color: colorScheme.onSurface),
            ),
            onSelected: (criteria) {
              ref.read(sortCriteriaProvider.notifier).state = criteria;
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: SortCriteria.newestFirst,
                child: Text('Newest first'),
              ),
              PopupMenuItem(
                value: SortCriteria.oldestFirst,
                child: Text('Oldest first'),
              ),
              PopupMenuItem(
                value: SortCriteria.titleAZ,
                child: Text('Title A-Z'),
              ),
              PopupMenuItem(
                value: SortCriteria.titleZA,
                child: Text('Title Z-A'),
              ),
              PopupMenuItem(value: SortCriteria.byTags, child: Text('By tags')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList(BuildContext context, List<StandaloneNote> notes) {
    // Apply search and tag filters
    var filteredNotes = notes;

    if (_searchQuery.isNotEmpty) {
      filteredNotes = filteredNotes.where((note) {
        return note.title.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    if (filteredNotes.isEmpty) {
      return _buildEmptyState(
        context,
        _searchQuery.isNotEmpty || _selectedTag != null,
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            'My Saved Notes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: filteredNotes.length,
                itemBuilder: (context, index) {
                  final note = filteredNotes[index];
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 300 + (index * 50)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: _ModernNoteCard(
                      note: note,
                      onTap: () => context.push('/notes/detail/${note.id}'),
                      onDelete: () => _deleteNote(note),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isFiltered) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer.withValues(alpha: 0.3),
                  colorScheme.secondaryContainer.withValues(alpha: 0.3),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFiltered ? Icons.search_off : Icons.note_add_outlined,
              size: 64,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isFiltered ? 'No notes found' : 'No notes yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Try adjusting your search or filter'
                : 'Tap the + button to create your first note',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading notes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNote(StandaloneNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(notesProvider.notifier).deleteNote(note.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete note: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

/// Modern note card widget
class _ModernNoteCard extends StatelessWidget {
  final StandaloneNote note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ModernNoteCard({
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceContainerHighest,
            colorScheme.surfaceContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Title and Pin/Delete icons
                Row(
                  children: [
                    if (note.isPinned)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.push_pin,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                      ),
                    if (note.isPinned) const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        note.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                              fontFamily: 'Roboto',
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: colorScheme.error,
                      ),
                      onPressed: onDelete,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Row 2: Dates and Tags
                Row(
                  children: [
                    // Created date
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Created: ${DateFormat.yMMMd().format(note.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Modified date
                    Icon(
                      Icons.update,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Modified: ${DateFormat.yMMMd().format(note.lastModifiedAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Tags (if any)
                if (note.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: note.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primaryContainer,
                              colorScheme.secondaryContainer,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.label,
                              size: 12,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tag,
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
