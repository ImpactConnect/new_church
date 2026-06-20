import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../data/models/notes/note_model.dart';

part 'notes_providers.g.dart';

/// In-memory verse notes store for the Bible AI reader.
@riverpod
class NotesNotifier extends _$NotesNotifier {
  @override
  AsyncValue<List<NoteModel>> build() {
    return const AsyncData([]);
  }

  Future<void> addNote(NoteModel note) async {
    final current = state.value ?? [];
    state = AsyncData([...current, note]);
  }

  Future<void> deleteNote(String id) async {
    final current = state.value ?? [];
    state = AsyncData(current.where((n) => n.id != id).toList());
  }
}
