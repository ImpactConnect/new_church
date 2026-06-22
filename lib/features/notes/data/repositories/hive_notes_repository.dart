import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/standalone_note_model.dart';
import '../models/linked_content_reference.dart';
import '../models/note_tag_model.dart';
import 'notes_repository.dart';

/// Hive implementation of NotesRepository
class HiveNotesRepository implements NotesRepository {
  static const String _notesBoxName = 'notes_box';
  static const String _tagsBoxName = 'tags_box';
  static const String _preferencesBoxName = 'notes_preferences_box';

  Box<StandaloneNote>? _notesBox;
  Box<NoteTag>? _tagsBox;
  Box<dynamic>? _preferencesBox;

  final _uuid = const Uuid();

  /// Initializes Hive boxes for notes, tags, and preferences
  @override
  Future<void> initialize() async {
    try {
      // Use Hive.box() since boxes are already opened in main.dart
      _notesBox = Hive.box<StandaloneNote>(_notesBoxName);
      _tagsBox = Hive.box<NoteTag>(_tagsBoxName);
      _preferencesBox = Hive.box(_preferencesBoxName);
    } catch (e) {
      throw Exception('Failed to initialize HiveNotesRepository: $e');
    }
  }

  /// Closes all Hive boxes and releases resources
  @override
  Future<void> close() async {
    await _notesBox?.close();
    await _tagsBox?.close();
    await _preferencesBox?.close();
  }

  /// Ensures boxes are initialized before operations
  void _ensureInitialized() {
    if (_notesBox == null || _tagsBox == null || _preferencesBox == null) {
      throw Exception('HiveNotesRepository not initialized. Call initialize() first.');
    }
  }

  @override
  Future<StandaloneNote> createNote(StandaloneNote note) async {
    _ensureInitialized();

    // Validate title
    if (note.title.trim().isEmpty) {
      throw ArgumentError('Note title cannot be empty');
    }

    try {
      // Generate ID if not provided
      final noteWithId = note.id.isEmpty
          ? note.copyWith(
              id: _uuid.v4(),
              createdAt: DateTime.now(),
              lastModifiedAt: DateTime.now(),
            )
          : note.copyWith(
              createdAt: DateTime.now(),
              lastModifiedAt: DateTime.now(),
            );

      // Save note to Hive
      await _notesBox!.put(noteWithId.id, noteWithId);

      // Update tag usage counts
      await _updateTagUsage(noteWithId.tags, increment: true);

      return noteWithId;
    } catch (e) {
      if (e is ArgumentError) rethrow;
      throw Exception('Failed to create note: $e');
    }
  }

  @override
  Future<StandaloneNote?> getNoteById(String id) async {
    _ensureInitialized();

    try {
      return _notesBox!.get(id);
    } catch (e) {
      throw Exception('Failed to get note by ID: $e');
    }
  }

  @override
  Future<List<StandaloneNote>> getAllNotes() async {
    _ensureInitialized();

    try {
      return _notesBox!.values.toList();
    } catch (e) {
      throw Exception('Failed to get all notes: $e');
    }
  }

  @override
  Future<void> updateNote(StandaloneNote note) async {
    _ensureInitialized();

    // Validate title
    if (note.title.trim().isEmpty) {
      throw ArgumentError('Note title cannot be empty');
    }

    // Get existing note to compare tags
    final existingNote = await getNoteById(note.id);
    if (existingNote == null) {
      throw ArgumentError('Note with ID ${note.id} not found');
    }

    try {
      // Update last modified timestamp
      final updatedNote = note.copyWith(
        lastModifiedAt: DateTime.now(),
      );

      // Save updated note
      await _notesBox!.put(updatedNote.id, updatedNote);

      // Update tag usage counts
      await _updateTagUsageOnEdit(existingNote.tags, updatedNote.tags);
    } catch (e) {
      if (e is ArgumentError) rethrow;
      throw Exception('Failed to update note: $e');
    }
  }

  @override
  Future<void> deleteNote(String id) async {
    _ensureInitialized();

    final note = await getNoteById(id);
    if (note == null) {
      throw ArgumentError('Note with ID $id not found');
    }

    try {
      // Delete note from Hive
      await _notesBox!.delete(id);

      // Update tag usage counts
      await _updateTagUsage(note.tags, increment: false);
    } catch (e) {
      if (e is ArgumentError) rethrow;
      throw Exception('Failed to delete note: $e');
    }
  }

  @override
  Future<List<StandaloneNote>> searchNotes(String query) async {
    _ensureInitialized();

    try {
      if (query.trim().isEmpty) {
        return getAllNotes();
      }

      final lowerQuery = query.toLowerCase();
      final allNotes = await getAllNotes();

      return allNotes.where((note) {
        return note.title.toLowerCase().contains(lowerQuery) ||
            note.richTextContent.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search notes: $e');
    }
  }

  @override
  Future<List<StandaloneNote>> filterByTags(List<String> tags) async {
    _ensureInitialized();

    try {
      if (tags.isEmpty) {
        return getAllNotes();
      }

      final allNotes = await getAllNotes();

      return allNotes.where((note) {
        return note.tags.any((tag) => tags.contains(tag));
      }).toList();
    } catch (e) {
      throw Exception('Failed to filter notes by tags: $e');
    }
  }

  @override
  Future<List<StandaloneNote>> sortNotes(
    List<StandaloneNote> notes,
    SortCriteria criteria,
  ) async {
    try {
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
          // Group by first tag, then sort alphabetically
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
    } catch (e) {
      throw Exception('Failed to sort notes: $e');
    }
  }

  @override
  Future<void> addLinkedContent(
    String noteId,
    LinkedContentReference ref,
  ) async {
    _ensureInitialized();

    try {
      final note = await getNoteById(noteId);
      if (note == null) {
        throw ArgumentError('Note with ID $noteId not found');
      }

      // Add linked content reference
      final updatedLinkedContent = [...note.linkedContent, ref];
      final updatedNote = note.copyWith(
        linkedContent: updatedLinkedContent,
        lastModifiedAt: DateTime.now(),
      );

      await _notesBox!.put(noteId, updatedNote);
    } catch (e) {
      throw Exception('Failed to add linked content: $e');
    }
  }

  @override
  Future<void> removeLinkedContent(String noteId, String refId) async {
    _ensureInitialized();

    try {
      final note = await getNoteById(noteId);
      if (note == null) {
        throw ArgumentError('Note with ID $noteId not found');
      }

      // Remove linked content reference
      final updatedLinkedContent = note.linkedContent
          .where((ref) => ref.id != refId)
          .toList();

      final updatedNote = note.copyWith(
        linkedContent: updatedLinkedContent,
        lastModifiedAt: DateTime.now(),
      );

      await _notesBox!.put(noteId, updatedNote);
    } catch (e) {
      throw Exception('Failed to remove linked content: $e');
    }
  }

  /// Updates tag usage counts when tags are added or removed
  Future<void> _updateTagUsage(List<String> tags, {required bool increment}) async {
    for (final tagName in tags) {
      final existingTag = _tagsBox!.get(tagName);

      if (existingTag != null) {
        final newCount = increment
            ? existingTag.usageCount + 1
            : (existingTag.usageCount - 1).clamp(0, double.infinity).toInt();

        if (newCount == 0) {
          // Remove tag if usage count reaches 0
          await _tagsBox!.delete(tagName);
        } else {
          await _tagsBox!.put(
            tagName,
            existingTag.copyWith(usageCount: newCount),
          );
        }
      } else if (increment) {
        // Create new tag
        await _tagsBox!.put(
          tagName,
          NoteTag(
            name: tagName,
            usageCount: 1,
            createdAt: DateTime.now(),
          ),
        );
      }
    }
  }

  /// Updates tag usage counts when a note is edited
  Future<void> _updateTagUsageOnEdit(
    List<String> oldTags,
    List<String> newTags,
  ) async {
    // Find removed tags
    final removedTags = oldTags.where((tag) => !newTags.contains(tag)).toList();
    await _updateTagUsage(removedTags, increment: false);

    // Find added tags
    final addedTags = newTags.where((tag) => !oldTags.contains(tag)).toList();
    await _updateTagUsage(addedTags, increment: true);
  }
}
