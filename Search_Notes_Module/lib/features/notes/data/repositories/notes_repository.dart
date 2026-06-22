import '../models/standalone_note_model.dart';
import '../models/linked_content_reference.dart';

/// Sort criteria for notes
enum SortCriteria {
  newestFirst,
  oldestFirst,
  titleAZ,
  titleZA,
  byTags,
}

/// Abstract repository interface for notes data access
abstract class NotesRepository {
  // ── CRUD Operations ──
  
  /// Creates a new note and returns the created note
  Future<StandaloneNote> createNote(StandaloneNote note);
  
  /// Retrieves a note by its ID, returns null if not found
  Future<StandaloneNote?> getNoteById(String id);
  
  /// Retrieves all notes
  Future<List<StandaloneNote>> getAllNotes();
  
  /// Updates an existing note
  Future<void> updateNote(StandaloneNote note);
  
  /// Deletes a note by its ID
  Future<void> deleteNote(String id);
  
  // ── Query Operations ──
  
  /// Searches notes by text query (case-insensitive)
  Future<List<StandaloneNote>> searchNotes(String query);
  
  /// Filters notes by tags (OR logic - any selected tag)
  Future<List<StandaloneNote>> filterByTags(List<String> tags);
  
  /// Sorts notes by specified criteria
  Future<List<StandaloneNote>> sortNotes(
    List<StandaloneNote> notes,
    SortCriteria criteria,
  );
  
  // ── Linked Content Operations ──
  
  /// Adds linked content reference to a note
  Future<void> addLinkedContent(String noteId, LinkedContentReference ref);
  
  /// Removes linked content reference from a note
  Future<void> removeLinkedContent(String noteId, String refId);
  
  // ── Lifecycle Methods ──
  
  /// Initializes the repository
  Future<void> initialize();
  
  /// Closes the repository and releases resources
  Future<void> close();
}
