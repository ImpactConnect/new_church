import 'package:freezed_annotation/freezed_annotation.dart';

part 'series_map_item.freezed.dart';
part 'series_map_item.g.dart';

/// Represents a single session in the series map breakdown
@freezed
class SeriesMapItem with _$SeriesMapItem {
  const factory SeriesMapItem({
    required int sessionNumber,
    required String sessionRole,
    required String sessionTitle,
    String? sessionSubtitle,
    String? primaryScripture,
    String? lifePhase,        // Character Study
    String? chapterRange,     // Book Study
    String? eraFocus,         // Theme Study
    String? focusArea,        // General focus description
  }) = _SeriesMapItem;

  factory SeriesMapItem.fromJson(Map<String, dynamic> json) =>
      _$SeriesMapItemFromJson(json);
}

/// State for the breakdown preview screen
@freezed
class StudyBreakdownState with _$StudyBreakdownState {
  const factory StudyBreakdownState({
    required String studyId,
    required String studyTitle,
    required String studyType,
    required int totalSessions,
    required List<SeriesMapItem> sessions,
    String? seriesOverview,
    @Default(false) bool isRegenerating,
    @Default(false) bool isApproving,
  }) = _StudyBreakdownState;

  factory StudyBreakdownState.fromJson(Map<String, dynamic> json) =>
      _$StudyBreakdownStateFromJson(json);
}
