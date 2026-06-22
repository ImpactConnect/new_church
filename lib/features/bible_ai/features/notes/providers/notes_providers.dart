import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/notes/note_model.dart';

part 'notes_providers.g.dart';

/// In-memory verse notes store for the Bible AI reader.
@riverpod
class NotesNotifier extends _$NotesNotifier {
  static const _prefsKey = 'bible_notes';

  @override
  AsyncValue<List<NoteModel>> build() {
    _loadNotes();
    return const AsyncLoading();
  }

  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_prefsKey);
      if (data != null) {
        final List<dynamic> jsonList = jsonDecode(data);
        final notes = jsonList.map((e) => NoteModel.fromJson(e)).toList();
        state = AsyncData(notes);
      } else {
        state = const AsyncData([]);
      }
    } catch (e) {
      state = const AsyncData([]);
    }
  }

  Future<void> _saveNotes(List<NoteModel> notes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String data = jsonEncode(notes.map((e) => e.toJson()).toList());
      await prefs.setString(_prefsKey, data);
    } catch (e) {
      // Ignored
    }
  }

  Future<void> addNote(NoteModel note) async {
    final current = state.value ?? [];
    if (current.any((n) => n.id == note.id)) return;
    final updated = [...current, note];
    state = AsyncData(updated);
    await _saveNotes(updated);
  }

  Future<void> deleteNote(String id) async {
    final current = state.value ?? [];
    final updated = current.where((n) => n.id != id).toList();
    state = AsyncData(updated);
    await _saveNotes(updated);
  }
}
