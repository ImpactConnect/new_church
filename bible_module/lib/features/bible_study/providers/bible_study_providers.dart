import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bible_study_models.dart';
import '../models/series_map_item.dart';
import '../repository/bible_study_repository.dart';
import '../services/bible_study_ai_service.dart';

// ─── Active Studies Provider ──────────────────────────────────────────────────
final activeBibleStudiesProvider = Provider<List<BibleStudy>>((ref) {
  return ref.watch(bibleStudyNotifierProvider);
});

// ─── Single Study Provider ────────────────────────────────────────────────────
final singleBibleStudyProvider = Provider.family<BibleStudy?, String>((
  ref,
  id,
) {
  ref.watch(bibleStudyNotifierProvider); // subscribe to updates
  return ref.read(bibleStudyNotifierProvider.notifier).getStudy(id);
});

// ─── Main Notifier ────────────────────────────────────────────────────────────
final bibleStudyNotifierProvider =
    StateNotifierProvider<BibleStudyNotifier, List<BibleStudy>>((ref) {
      final repo = ref.watch(bibleStudyRepositoryProvider);
      final ai = ref.watch(bibleStudyAiServiceProvider);
      return BibleStudyNotifier(repo, ai);
    });

class BibleStudyNotifier extends StateNotifier<List<BibleStudy>> {
  final BibleStudyRepository _repo;
  final BibleStudyAiService _ai;

  BibleStudyNotifier(this._repo, this._ai) : super([]) {
    _loadStudies();
    _resumePendingGenerations();
  }

  void _loadStudies() {
    state = List.of(_repo.getActiveStudies());
  }

  Future<void> _resumePendingGenerations() async {
    final activeStudies = _repo.getActiveStudies();
    for (final study in activeStudies) {
      if (study.originalInput == null) continue;

      try {
        final input = study.originalInput!;

        bool shouldResumeQueue = false;

        for (final session in study.sessions) {
          // If a session was left in a 'generating' state but the app restarted,
          // it means the process died. We should reset and resume it.
          if (!session.isGenerated && session.isGenerating) {
            await _repo.updateSessionGenerationState(
              study.id,
              session.sessionNumber,
              isGenerating: false,
              generationStage: 'Pending',
            );
            shouldResumeQueue = true;
          }
        }

        // Find the first session that needs generation AND hasn't failed permanently
        int? resumeFromSession;
        final refreshedStudy = _repo.getStudy(study.id);
        if (refreshedStudy != null) {
          for (final session in refreshedStudy.sessions) {
            if (!session.isGenerated && session.lastGenerationError == null) {
              resumeFromSession = session.sessionNumber;
              shouldResumeQueue =
                  true; // It was never completed, queue must have died
              break;
            }
          }

          if (shouldResumeQueue && resumeFromSession != null) {
            unawaited(
              _progressiveGenerateRemaining(
                refreshedStudy.id,
                input,
                resumeFromSession,
                refreshedStudy.sessions,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Failed to resume generation for study ${study.id}: $e');
      }
    }
  }

  List<BibleStudy> getAllStudies() => _repo.getAllStudies();
  BibleStudy? getStudy(String id) => _repo.getStudy(id);
  List<BibleStudy> getCompletedStudies() => _repo.getCompletedStudies();

  // ── Create Study Breakdown (Phase 4) ─────────────────────────────────────
  Future<StudyBreakdownState> createStudyBreakdown(
    BibleStudyInput input,
  ) async {
    // Create the study record first
    final study = await _repo.createStudy(
      studyType: input.studyType,
      format: input.format,
      subject: input.subject,
      studyTitle: 'Generating...',
      totalSessions: input.sessionCount,
      originalInput: input,
      startDate: input.startDate,
      personalContext: input.personalContext,
    );
    _loadStudies();

    // Generate the series map
    final mapJson = await _ai.generateSeriesMap(input);

    final sessions = <SeriesMapItem>[];
    final rawSessions = (mapJson['sessions'] as List<dynamic>?) ?? [];
    for (final s in rawSessions) {
      final num = (s['sessionNumber'] is int)
          ? s['sessionNumber'] as int
          : int.tryParse(s['sessionNumber'].toString()) ?? 1;
      sessions.add(
        SeriesMapItem(
          sessionNumber: num,
          sessionRole: s['sessionRole'] ?? 'foundation',
          sessionTitle: s['sessionTitle'] ?? '',
          sessionSubtitle: s['sessionSubtitle'],
          primaryScripture: s['primaryScripture'],
          lifePhase: s['lifePhase'],
          chapterRange: s['chapterRange'],
          eraFocus: s['eraFocus'],
          focusArea: s['focusArea'],
        ),
      );
    }

    return StudyBreakdownState(
      studyId: study.id,
      studyTitle: mapJson['studyTitle'] as String? ?? study.subject,
      studyType: input.studyType.name,
      totalSessions: sessions.isEmpty ? input.sessionCount : sessions.length,
      sessions: sessions,
      seriesOverview: mapJson['seriesOverview'] as String?,
    );
  }

  // ── Approve Breakdown & Start Generation (Progressive) ───────────────────────
  Future<void> approveBreakdownAndGenerate(
    StudyBreakdownState breakdown,
    BibleStudyInput input,
  ) async {
    final study = _repo.getStudy(breakdown.studyId);
    if (study == null) return;

    // Convert SeriesMapItem to StudySession
    final sessions = breakdown.sessions.map((item) {
      return StudySession(
        sessionNumber: item.sessionNumber,
        sessionTitle: item.sessionTitle,
        sessionSubtitle: item.sessionSubtitle,
        primaryScripture: item.primaryScripture,
        sessionRole: SessionRole.values.firstWhere(
          (r) => r.name == item.sessionRole,
          orElse: () => SessionRole.foundation,
        ),
        lifePhase: item.lifePhase,
        chapterRange: item.chapterRange,
        eraFocus: item.eraFocus,
        unlocksAt:
            input.studyType == StudyType.devotional && input.startDate != null
            ? input.startDate!.add(Duration(days: item.sessionNumber - 1))
            : null,
      );
    }).toList();

    // Update study with approved breakdown
    final updatedStudy = BibleStudy(
      id: study.id,
      studyType: study.studyType,
      format: study.format,
      status: StudyStatus.active,
      subject: study.subject,
      studyTitle: breakdown.studyTitle,
      seriesOverview: breakdown.seriesOverview,
      totalSessions: breakdown.totalSessions,
      sessions: sessions,
      createdAt: study.createdAt,
      startDate: study.startDate,
      personalContext: study.personalContext,
      originalInput: study.originalInput,
    );
    await _repo.saveStudy(updatedStudy);
    _loadStudies();

    // Generate only Session 1 before leaving the loading screen.
    if (sessions.isNotEmpty) {
      final s1 = sessions.first;
      await _generateSession(
        updatedStudy,
        input,
        1,
        s1.sessionTitle,
        s1.eraFocus,
        null,
        null,
        s1.sessionRole,
      );
    }

    // Generate remaining sessions in background (non-blocking)
    if (sessions.length > 1) {
      unawaited(
        _progressiveGenerateRemaining(updatedStudy.id, input, 2, sessions),
      );
    }
  }

  // ── Regenerate Breakdown ─────────────────────────────────────────────────
  Future<StudyBreakdownState> regenerateBreakdown(
    String studyId,
    BibleStudyInput input,
  ) async {
    // Generate a fresh series map
    final mapJson = await _ai.regenerateSeriesMap(input);

    final sessions = <SeriesMapItem>[];
    final rawSessions = (mapJson['sessions'] as List<dynamic>?) ?? [];
    for (final s in rawSessions) {
      final num = (s['sessionNumber'] is int)
          ? s['sessionNumber'] as int
          : int.tryParse(s['sessionNumber'].toString()) ?? 1;
      sessions.add(
        SeriesMapItem(
          sessionNumber: num,
          sessionRole: s['sessionRole'] ?? 'foundation',
          sessionTitle: s['sessionTitle'] ?? '',
          sessionSubtitle: s['sessionSubtitle'],
          primaryScripture: s['primaryScripture'],
          lifePhase: s['lifePhase'],
          chapterRange: s['chapterRange'],
          eraFocus: s['eraFocus'],
          focusArea: s['focusArea'],
        ),
      );
    }

    return StudyBreakdownState(
      studyId: studyId,
      studyTitle: mapJson['studyTitle'] as String? ?? input.subject,
      studyType: input.studyType.name,
      totalSessions: sessions.isEmpty ? input.sessionCount : sessions.length,
      sessions: sessions,
      seriesOverview: mapJson['seriesOverview'] as String?,
    );
  }

  // ── Create & Generate a new study ─────────────────────────────────────────
  Future<BibleStudy> createAndGenerateStudy(BibleStudyInput input) async {
    final isSingle =
        input.format == StudyFormat.single ||
        input.studyType == StudyType.verse ||
        input.studyType == StudyType.topical;

    final study = await _repo.createStudy(
      studyType: input.studyType,
      format: input.format,
      subject: input.subject,
      studyTitle: isSingle ? input.subject : 'Generating...',
      totalSessions: isSingle ? 1 : input.sessionCount,
      originalInput: input,
      startDate: input.startDate,
      personalContext: input.personalContext,
    );
    _loadStudies();

    if (isSingle) {
      await _generateSession(
        study,
        input,
        1,
        input.subject,
        null,
        null,
        null,
        null,
      );
    } else {
      await _generateSeries(study, input);
    }

    return _repo.getStudy(study.id) ?? study;
  }

  Future<void> _generateSeries(BibleStudy study, BibleStudyInput input) async {
    final mapJson = await _ai.generateSeriesMap(input);

    final sessions = <StudySession>[];
    final rawSessions = (mapJson['sessions'] as List<dynamic>?) ?? [];
    for (final s in rawSessions) {
      final num = (s['sessionNumber'] is int)
          ? s['sessionNumber'] as int
          : int.tryParse(s['sessionNumber'].toString()) ?? 1;
      final roleStr = s['sessionRole'] as String? ?? 'foundation';
      final sessionRole = SessionRole.values.firstWhere(
        (r) => r.name == roleStr,
        orElse: () => SessionRole.foundation,
      );
      sessions.add(
        StudySession(
          sessionNumber: num,
          sessionRole: sessionRole,
          sessionTitle: s['sessionTitle'] ?? '',
          sessionSubtitle: s['sessionSubtitle'],
          primaryScripture: s['primaryScripture'],
          lifePhase: s['lifePhase'],
          chapterRange: s['chapterRange'],
          eraFocus: s['eraFocus'],
          unlocksAt:
              input.studyType == StudyType.devotional && input.startDate != null
              ? input.startDate!.add(Duration(days: num - 1))
              : null,
        ),
      );
    }

    final updatedStudy = BibleStudy(
      id: study.id,
      studyType: study.studyType,
      format: study.format,
      status: StudyStatus.active,
      subject: study.subject,
      studyTitle: mapJson['studyTitle'] as String? ?? study.subject,
      seriesOverview: mapJson['seriesOverview'] as String?,
      totalSessions: sessions.isEmpty ? input.sessionCount : sessions.length,
      sessions: sessions,
      createdAt: study.createdAt,
      startDate: study.startDate,
      personalContext: study.personalContext,
      originalInput: study.originalInput,
    );
    await _repo.saveStudy(updatedStudy);
    _loadStudies();

    // Generate only Session 1 synchronously to reduce initial wait.
    if (sessions.isNotEmpty) {
      final s1 = sessions.first;
      await _generateSession(
        updatedStudy,
        input,
        1,
        s1.sessionTitle,
        s1.eraFocus,
        null,
        null,
        s1.sessionRole,
      );
    }

    // Generate remaining sessions in background (non-blocking)
    if (sessions.length > 1) {
      unawaited(
        _progressiveGenerateRemaining(updatedStudy.id, input, 2, sessions),
      );
    }
  }

  Future<void> _generateSession(
    BibleStudy study,
    BibleStudyInput input,
    int sessionNumber,
    String sessionTitle,
    String? eraFocus,
    String? arcPhase,
    String? seriesContext,
    SessionRole? sessionRole,
  ) async {
    final latestStudy = _repo.getStudy(study.id) ?? study;
    final existingSession = latestStudy.sessions.firstWhere(
      (s) => s.sessionNumber == sessionNumber,
      orElse: () => StudySession(
        sessionNumber: sessionNumber,
        sessionTitle: sessionTitle,
      ),
    );
    final wordsAlreadyDefined = sessionNumber > 1
        ? await _repo.getDefinedWordsForPrompt(study.id)
        : null;
    final previousSessionSummaries = sessionNumber > 1
        ? await _repo.getPreviousSessionSummaries(study.id, sessionNumber)
        : null;

    await _repo.updateSessionGenerationState(
      study.id,
      sessionNumber,
      isGenerating: true,
      isGenerated: false,
      generationStage: 'Preparing content',
      lastGenerationError: null,
    );
    _loadStudies();

    try {
      final contentMap = await _ai.generateSession(
        input: input,
        sessionNumber: sessionNumber,
        sessionTitle: sessionTitle,
        seriesContext: seriesContext,
        eraFocus: eraFocus,
        arcPhase: arcPhase,
        sessionRole: sessionRole?.name,
        totalSessions: study.totalSessions,
        wordsAlreadyDefined: wordsAlreadyDefined,
        previousSessionSummaries: previousSessionSummaries,
        onPartialContent: (partialContent, stage) async {
          await _repo.updateSessionGenerationState(
            study.id,
            sessionNumber,
            isGenerating: true,
            partialContentJson: jsonEncode(partialContent),
            generationStage: _stageLabel(stage),
            lastGenerationError: null,
          );
          _loadStudies();
        },
      );

      String? primaryScripture;
      final anchorPassage = contentMap['anchorPassage'];
      final anchorScripture = contentMap['anchorScripture'];
      if (anchorPassage is Map) {
        primaryScripture = anchorPassage['reference'] as String?;
      } else if (anchorScripture is Map) {
        primaryScripture = anchorScripture['reference'] as String?;
      } else {
        primaryScripture = contentMap['primaryScripture'] as String?;
      }

      final session = StudySession(
        sessionNumber: sessionNumber,
        sessionRole: sessionRole ?? existingSession.sessionRole,
        sessionTitle: sessionTitle,
        sessionSubtitle: existingSession.sessionSubtitle ?? eraFocus,
        primaryScripture: primaryScripture ?? existingSession.primaryScripture,
        lifePhase: existingSession.lifePhase,
        chapterRange: existingSession.chapterRange,
        eraFocus: existingSession.eraFocus ?? eraFocus,
        isGenerated: true,
        isGenerating: false,
        contentJson: jsonEncode(contentMap),
        partialContentJson: null,
        generationStage: null,
        lastGenerationError: null,
        generatedAt: DateTime.now(),
        unlocksAt: existingSession.unlocksAt,
      );

      await _repo.addSessionToStudy(study.id, session);
      _loadStudies();
    } catch (e) {
      await _repo.updateSessionGenerationState(
        study.id,
        sessionNumber,
        isGenerating: false,
        isGenerated: false,
        generationStage: 'Failed',
        lastGenerationError: e.toString(),
      );
      _loadStudies();
      rethrow;
    }
  }

  // ── Progressive Generation (Background) ──────────────────────────────────
  Future<void> _progressiveGenerateRemaining(
    String studyId,
    BibleStudyInput input,
    int startFrom,
    List<StudySession> allSessions,
  ) async {
    for (int i = startFrom - 1; i < allSessions.length; i++) {
      final study = _repo.getStudy(studyId);
      if (study == null) return;

      final sessionInfo = allSessions[i];
      final sessionNumber = sessionInfo.sessionNumber;

      // Check if already generated
      final existing = study.sessions.firstWhere(
        (s) => s.sessionNumber == sessionNumber,
        orElse: () => sessionInfo,
      );
      if (existing.isGenerated) continue;

      try {
        await _generateSession(
          study,
          input,
          sessionNumber,
          sessionInfo.sessionTitle,
          sessionInfo.eraFocus,
          null,
          null,
          sessionInfo.sessionRole,
        );
      } catch (e) {
        // Log error but continue with next session
        debugPrint('Error generating session $sessionNumber: $e');
      }
    }
  }

  Future<void> retrySessionGeneration(String studyId, int sessionNumber) async {
    final study = _repo.getStudy(studyId);
    if (study == null) return;
    final input = study.originalInput;
    if (input == null) {
      throw Exception(
        'This study does not have enough saved input to retry generation.',
      );
    }
    final sessionInfo = study.sessions.firstWhere(
      (s) => s.sessionNumber == sessionNumber,
      orElse: () => StudySession(
        sessionNumber: sessionNumber,
        sessionTitle: study.subject,
      ),
    );
    await _generateSession(
      study,
      input,
      sessionNumber,
      sessionInfo.sessionTitle,
      sessionInfo.eraFocus,
      null,
      null,
      sessionInfo.sessionRole,
    );
  }

  Future<void> markSessionComplete(
    String studyId,
    int sessionNumber,
    BibleStudyInput input,
  ) async {
    await _repo.markSessionComplete(studyId, sessionNumber);
    _loadStudies();

    // PREDICTIVE GENERATION: Ensure next 2 sessions are ready
    final study = _repo.getStudy(studyId);
    if (study == null) return;

    // Check if next session needs generation
    if (sessionNumber + 1 <= study.totalSessions) {
      final nextSession = study.sessions.firstWhere(
        (s) => s.sessionNumber == sessionNumber + 1,
        orElse: () =>
            StudySession(sessionNumber: sessionNumber + 1, sessionTitle: ''),
      );
      if (!nextSession.isGenerated && !nextSession.isGenerating) {
        unawaited(_generateSessionIfNeeded(studyId, input, sessionNumber + 1));
      }
    }

    // Check if session after next needs generation (predictive)
    if (sessionNumber + 2 <= study.totalSessions) {
      final nextNextSession = study.sessions.firstWhere(
        (s) => s.sessionNumber == sessionNumber + 2,
        orElse: () =>
            StudySession(sessionNumber: sessionNumber + 2, sessionTitle: ''),
      );
      if (!nextNextSession.isGenerated && !nextNextSession.isGenerating) {
        unawaited(_generateSessionIfNeeded(studyId, input, sessionNumber + 2));
      }
    }
  }

  Future<void> _generateSessionIfNeeded(
    String studyId,
    BibleStudyInput input,
    int sessionNumber,
  ) async {
    final study = _repo.getStudy(studyId);
    if (study == null) return;

    final sessionInfo = study.sessions.firstWhere(
      (s) => s.sessionNumber == sessionNumber,
      orElse: () => StudySession(
        sessionNumber: sessionNumber,
        sessionTitle: study.subject,
      ),
    );

    if (sessionInfo.isGenerated) return;

    try {
      await _generateSession(
        study,
        input,
        sessionNumber,
        sessionInfo.sessionTitle,
        sessionInfo.eraFocus,
        null,
        null,
        sessionInfo.sessionRole,
      );
    } catch (e) {
      debugPrint('Error generating session $sessionNumber: $e');
    }
  }

  Future<void> deleteStudy(String id) async {
    await _repo.deleteStudy(id);
    _loadStudies();
  }

  Future<void> archiveStudy(String id) async {
    await _repo.archiveStudy(id);
    _loadStudies();
  }
}

String _stageLabel(String stage) {
  switch (stage) {
    case 'metadata_complete':
      return 'Finalizing session';
    default:
      if (stage.startsWith('sections_')) {
        return 'Generating ${stage.replaceFirst('sections_', 'sections ')}';
      }
      return stage;
  }
}

void unawaited(Future<void> future) {
  future.catchError((_) {}); // silently ignore background gen errors
}
