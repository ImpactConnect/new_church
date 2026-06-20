import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../data/models/highlights/highlight_model.dart';

part 'highlights_providers.g.dart';

/// In-memory highlights store for the Bible AI reader.
@riverpod
class HighlightsNotifier extends _$HighlightsNotifier {
  @override
  AsyncValue<List<HighlightModel>> build() {
    return const AsyncData([]);
  }

  Future<void> addHighlight(HighlightModel highlight) async {
    final current = state.value ?? [];
    // Replace if same verse already highlighted
    final updated = current.where(
      (h) => !(h.bookId == highlight.bookId &&
               h.chapterNumber == highlight.chapterNumber &&
               h.verseNumber == highlight.verseNumber),
    ).toList()
      ..add(highlight);
    state = AsyncData(updated);
  }

  Future<void> deleteHighlight(String id) async {
    final current = state.value ?? [];
    state = AsyncData(current.where((h) => h.id != id).toList());
  }
}
