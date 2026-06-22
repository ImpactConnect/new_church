import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/standalone_note_model.dart';
import '../../data/repositories/notes_repository.dart';
import '../../data/repositories/hive_notes_repository.dart';
import '../../services/export_service.dart';
import '../../services/note_export_service.dart';
import '../notifiers/notes_notifier.dart';
import '../notifiers/undo_redo_notifier.dart';

// ── Repository Provider ──

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  final repository = HiveNotesRepository();
  // Initialize synchronously since boxes are already open
  repository.initialize();
  return repository;
});

// ── Export Service Provider ──

final exportServiceProvider = Provider<ExportService>((ref) {
  return NoteExportService();
});

// ── Notes Provider ──

final notesProvider = StateNotifierProvider<NotesNotifier, AsyncValue<List<StandaloneNote>>>((ref) {
  return NotesNotifier(ref.watch(notesRepositoryProvider));
});

// ── Search and Filter Providers ──

final searchQueryProvider = StateProvider<String>((ref) => '');

final selectedTagsProvider = StateProvider<List<String>>((ref) => []);

final sortCriteriaProvider = StateProvider<SortCriteria>(
  (ref) => SortCriteria.newestFirst,
);

// ── Filtered Notes Provider ──

final filteredNotesProvider = Provider<AsyncValue<List<StandaloneNote>>>((ref) {
  final notesAsync = ref.watch(notesProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final selectedTags = ref.watch(selectedTagsProvider);
  final sortCriteria = ref.watch(sortCriteriaProvider);

  return notesAsync.whenData((notes) {
    var filtered = notes;

    // Apply text search
    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((note) {
        return note.title.toLowerCase().contains(query) ||
            note.richTextContent.toLowerCase().contains(query);
      }).toList();
    }

    // Apply tag filter (OR logic)
    if (selectedTags.isNotEmpty) {
      filtered = filtered.where((note) {
        return note.tags.any((tag) => selectedTags.contains(tag));
      }).toList();
    }

    // Apply sorting (synchronously since sortNotes is async but we can do it sync here)
    return _sortNotesSync(filtered, sortCriteria);
  });
});

/// Synchronous sort helper for filtered notes provider
List<StandaloneNote> _sortNotesSync(
  List<StandaloneNote> notes,
  SortCriteria criteria,
) {
  final sortedNotes = List<StandaloneNote>.from(notes);

  // Separate pinned and unpinned notes
  final pinnedNotes = sortedNotes.where((n) => n.isPinned).toList();
  final unpinnedNotes = sortedNotes.where((n) => !n.isPinned).toList();

  // Sort each group based on criteria
  switch (criteria) {
    case SortCriteria.newestFirst:
      pinnedNotes.sort((a, b) => b.lastModifiedAt.compareTo(a.lastModifiedAt));
      unpinnedNotes.sort((a, b) => b.lastModifiedAt.compareTo(a.lastModifiedAt));
      break;

    case SortCriteria.oldestFirst:
      pinnedNotes.sort((a, b) => a.lastModifiedAt.compareTo(b.lastModifiedAt));
      unpinnedNotes.sort((a, b) => a.lastModifiedAt.compareTo(b.lastModifiedAt));
      break;

    case SortCriteria.titleAZ:
      pinnedNotes.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      unpinnedNotes.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      break;

    case SortCriteria.titleZA:
      pinnedNotes.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
      unpinnedNotes.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
      break;

    case SortCriteria.byTags:
      pinnedNotes.sort((a, b) {
        final aTag = a.tags.isNotEmpty ? a.tags.first : '';
        final bTag = b.tags.isNotEmpty ? b.tags.first : '';
        return aTag.toLowerCase().compareTo(bTag.toLowerCase());
      });
      unpinnedNotes.sort((a, b) {
        final aTag = a.tags.isNotEmpty ? a.tags.first : '';
        final bTag = b.tags.isNotEmpty ? b.tags.first : '';
        return aTag.toLowerCase().compareTo(bTag.toLowerCase());
      });
      break;
  }

  // Combine pinned notes first, then unpinned
  return [...pinnedNotes, ...unpinnedNotes];
}

// ── Current Note Provider ──

final currentNoteProvider = StateProvider<StandaloneNote?>((ref) => null);

// ── Undo/Redo Provider ──

final undoRedoProvider = StateNotifierProvider<UndoRedoNotifier, UndoRedoState>((ref) {
  return UndoRedoNotifier();
});
