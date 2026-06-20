// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'series_map_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SeriesMapItemImpl _$$SeriesMapItemImplFromJson(Map<String, dynamic> json) =>
    _$SeriesMapItemImpl(
      sessionNumber: (json['sessionNumber'] as num).toInt(),
      sessionRole: json['sessionRole'] as String,
      sessionTitle: json['sessionTitle'] as String,
      sessionSubtitle: json['sessionSubtitle'] as String?,
      primaryScripture: json['primaryScripture'] as String?,
      lifePhase: json['lifePhase'] as String?,
      chapterRange: json['chapterRange'] as String?,
      eraFocus: json['eraFocus'] as String?,
      focusArea: json['focusArea'] as String?,
    );

Map<String, dynamic> _$$SeriesMapItemImplToJson(_$SeriesMapItemImpl instance) =>
    <String, dynamic>{
      'sessionNumber': instance.sessionNumber,
      'sessionRole': instance.sessionRole,
      'sessionTitle': instance.sessionTitle,
      'sessionSubtitle': instance.sessionSubtitle,
      'primaryScripture': instance.primaryScripture,
      'lifePhase': instance.lifePhase,
      'chapterRange': instance.chapterRange,
      'eraFocus': instance.eraFocus,
      'focusArea': instance.focusArea,
    };

_$StudyBreakdownStateImpl _$$StudyBreakdownStateImplFromJson(
        Map<String, dynamic> json) =>
    _$StudyBreakdownStateImpl(
      studyId: json['studyId'] as String,
      studyTitle: json['studyTitle'] as String,
      studyType: json['studyType'] as String,
      totalSessions: (json['totalSessions'] as num).toInt(),
      sessions: (json['sessions'] as List<dynamic>)
          .map((e) => SeriesMapItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      seriesOverview: json['seriesOverview'] as String?,
      isRegenerating: json['isRegenerating'] as bool? ?? false,
      isApproving: json['isApproving'] as bool? ?? false,
    );

Map<String, dynamic> _$$StudyBreakdownStateImplToJson(
        _$StudyBreakdownStateImpl instance) =>
    <String, dynamic>{
      'studyId': instance.studyId,
      'studyTitle': instance.studyTitle,
      'studyType': instance.studyType,
      'totalSessions': instance.totalSessions,
      'sessions': instance.sessions,
      'seriesOverview': instance.seriesOverview,
      'isRegenerating': instance.isRegenerating,
      'isApproving': instance.isApproving,
    };
