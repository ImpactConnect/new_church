import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../config/app_config.dart';
import '../../../data/models/notes/note_model.dart';
import '../../../data/repositories/notes_repository.dart';

const String _notesSortPrefKey = 'notes_sort';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return HiveNotesRepository();
});

final notesNotifierProvider =
    StateNotifierProvider<NotesNotifier, AsyncValue<List<NoteModel>>>(
  (ref) => NotesNotifier(ref),
);

class NotesNotifier extends StateNotifier<AsyncValue<List<NoteModel>>> {
  NotesNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadNotes();
  }

  final Ref _ref;

  Future<Box<dynamic>> _getPrefsBox() {
    return Hive.openBox<dynamic>(AppConfig.userPrefsBoxName);
  }

  Future<String?> _getStoredSort() async {
    final box = await _getPrefsBox();
    final value = box.get(_notesSortPrefKey);
    if (value is String) return value;
    return null;
  }

  Future<void> _storeSort(String sortKey) async {
    final box = await _getPrefsBox();
    await box.put(_notesSortPrefKey, sortKey);
  }

  Future<void> _loadNotes() async {
    try {
      final repository = _ref.read(notesRepositoryProvider);
      final notes = await repository.getNotes();
      final sortKey = await _getStoredSort();
      final sorted = [...notes];
      switch (sortKey) {
        case 'oldest':
          sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
        case 'book':
          sorted.sort(
            (a, b) {
              final bookCompare = a.bookName.compareTo(b.bookName);
              if (bookCompare != 0) return bookCompare;
              final chapterCompare =
                  a.chapterNumber.compareTo(b.chapterNumber);
              if (chapterCompare != 0) return chapterCompare;
              return a.verseNumber.compareTo(b.verseNumber);
            },
          );
          break;
        default:
          sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
      }
      state = AsyncValue.data(sorted);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addNote(NoteModel note) async {
    final repository = _ref.read(notesRepositoryProvider);
    await repository.addNote(note);
    await _loadNotes();
  }

  Future<void> deleteNote(String id) async {
    final repository = _ref.read(notesRepositoryProvider);
    await repository.deleteNote(id);
    await _loadNotes();
  }

  Future<void> updateNote(NoteModel note) async {
    final repository = _ref.read(notesRepositoryProvider);
    await repository.updateNote(note);
    await _loadNotes();
  }

  Future<void> sortByDateDescending() async {
    await _storeSort('newest');
    final current = state;
    state = current.whenData(
      (notes) => [
        ...notes
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      ],
    );
  }

  Future<void> sortByDateAscending() async {
    await _storeSort('oldest');
    final current = state;
    state = current.whenData(
      (notes) => [
        ...notes
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
      ],
    );
  }

  Future<void> sortByReference() async {
    await _storeSort('book');
    final current = state;
    state = current.whenData(
      (notes) => [
        ...notes
          ..sort(
            (a, b) {
              final bookCompare = a.bookName.compareTo(b.bookName);
              if (bookCompare != 0) return bookCompare;
              final chapterCompare =
                  a.chapterNumber.compareTo(b.chapterNumber);
              if (chapterCompare != 0) return chapterCompare;
              return a.verseNumber.compareTo(b.verseNumber);
            },
          ),
      ],
    );
  }
}
