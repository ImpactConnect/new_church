import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/standalone_note_model.dart';
import '../../data/repositories/notes_repository.dart';

/// State notifier for managing notes list and CRUD operations
class NotesNotifier extends StateNotifier<AsyncValue<List<StandaloneNote>>> {
  NotesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadNotes();
  }

  final NotesRepository _repository;

  /// Loads all notes from repository
  Future<void> loadNotes() async {
    state = const AsyncValue.loading();
    try {
      final notes = await _repository.getAllNotes();
      state = AsyncValue.data(notes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Creates a new note
  Future<void> createNote(StandaloneNote note) async {
    try {
      await _repository.createNote(note);
      await loadNotes();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Updates an existing note
  Future<void> updateNote(StandaloneNote note) async {
    try {
      await _repository.updateNote(note);
      await loadNotes();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Deletes a note by ID
  Future<void> deleteNote(String id) async {
    try {
      await _repository.deleteNote(id);
      await loadNotes();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Toggles pin status of a note
  Future<void> togglePin(String id) async {
    try {
      final note = await _repository.getNoteById(id);
      if (note != null) {
        final updatedNote = note.copyWith(isPinned: !note.isPinned);
        await _repository.updateNote(updatedNote);
        await loadNotes();
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Removes a linked content reference from a note
  Future<void> removeLinkedContent(String noteId, String referenceId) async {
    try {
      await _repository.removeLinkedContent(noteId, referenceId);
      await loadNotes();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}
