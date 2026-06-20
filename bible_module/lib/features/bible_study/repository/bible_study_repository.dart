import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bible_study_models.dart';
import '../services/word_definition_registry_service.dart';
import '../utils/session_role_assigner.dart';

// ─── Box Names ───────────────────────────────────────────────────────────────
class BibleStudyBoxes {
  static const String studies = 'bible_studies_v1';
}

// ─── Provider ────────────────────────────────────────────────────────────────
final bibleStudyRepositoryProvider = Provider<BibleStudyRepository>((ref) {
  return BibleStudyRepository(Hive);
});

// ─── Repository ──────────────────────────────────────────────────────────────
class BibleStudyRepository {
  static const String _boxName = BibleStudyBoxes.studies;
  static const _uuid = Uuid();

  final HiveInterface _hive;
  late final WordDefinitionRegistryService _wordRegistryService;

  BibleStudyRepository(this._hive) {
    _wordRegistryService = WordDefinitionRegistryService(_hive);
  }

  Box<String> get _box => _hive.box<String>(_boxName);

  // ── Save / Update ─────────────────────────────────────────────────────────
  Future<void> saveStudy(BibleStudy study) async {
    await _box.put(study.id, jsonEncode(study.toJson()));
  }

  Future<BibleStudy> createStudy({
    required StudyType studyType,
    required StudyFormat format,
    required String subject,
    required String studyTitle,
    required int totalSessions,
    BibleStudyInput? originalInput,
    String? seriesOverview,
    DateTime? startDate,
    String? personalContext,
  }) async {
    final study = BibleStudy(
      id: _uuid.v4(),
      studyType: studyType,
      format: format,
      status: StudyStatus.generating,
      subject: subject,
      studyTitle: studyTitle,
      seriesOverview: seriesOverview,
      totalSessions: totalSessions,
      sessions: [],
      createdAt: DateTime.now(),
      startDate: startDate,
      personalContext: personalContext,
      originalInput: originalInput,
    );
    await saveStudy(study);
    return study;
  }

  // ── Add / Update Session ──────────────────────────────────────────────────
  Future<void> addSessionToStudy(String studyId, StudySession session) async {
    final study = getStudy(studyId);
    if (study == null) return;
    final existingIndex = study.sessions.indexWhere(
      (s) => s.sessionNumber == session.sessionNumber,
    );
    if (existingIndex >= 0) {
      session = _mergeSession(study.sessions[existingIndex], session);
    }
    study.sessions.removeWhere((s) => s.sessionNumber == session.sessionNumber);
    study.sessions.add(session);
    study.sessions.sort((a, b) => a.sessionNumber.compareTo(b.sessionNumber));
    if (study.status == StudyStatus.generating) {
      study.status = StudyStatus.active;
    }
    await saveStudy(study);
  }

  Future<void> updateSessionGenerationState(
    String studyId,
    int sessionNumber, {
    bool? isGenerating,
    bool? isGenerated,
    String? contentJson,
    String? partialContentJson,
    String? generationStage,
    String? lastGenerationError,
    DateTime? generatedAt,
  }) async {
    final study = getStudy(studyId);
    if (study == null) return;

    final index = study.sessions.indexWhere(
      (s) => s.sessionNumber == sessionNumber,
    );
    if (index < 0) return;

    final session = study.sessions[index];
    if (isGenerating != null) session.isGenerating = isGenerating;
    if (isGenerated != null) session.isGenerated = isGenerated;
    if (contentJson != null) session.contentJson = contentJson;
    if (partialContentJson != null) {
      session.partialContentJson = partialContentJson;
    }
    if (generationStage != null) session.generationStage = generationStage;
    if (lastGenerationError != null ||
        isGenerated == true ||
        isGenerating == true) {
      session.lastGenerationError = lastGenerationError;
    }
    if (generatedAt != null) session.generatedAt = generatedAt;

    await saveStudy(study);
  }

  Future<void> markSessionComplete(String studyId, int sessionNumber) async {
    final study = getStudy(studyId);
    if (study == null) return;
    if (!study.completedSessions.contains(sessionNumber)) {
      study.completedSessions.add(sessionNumber);
    }
    study.lastAccessedAt = DateTime.now();
    if (study.completedSessions.length >= study.totalSessions) {
      study.status = StudyStatus.completed;
    }
    await saveStudy(study);
  }

  Future<void> updateStudyStatus(String studyId, StudyStatus status) async {
    final study = getStudy(studyId);
    if (study == null) return;
    study.status = status;
    await saveStudy(study);
  }

  Future<void> updateLastAccessed(String studyId) async {
    final study = getStudy(studyId);
    if (study == null) return;
    study.lastAccessedAt = DateTime.now();
    await saveStudy(study);
  }

  // ── Read ──────────────────────────────────────────────────────────────────
  BibleStudy? getStudy(String id) {
    final raw = _box.get(id);
    if (raw == null) return null;
    try {
      return BibleStudy.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  List<BibleStudy> getAllStudies() {
    return _box.values
        .map((raw) {
          try {
            return BibleStudy.fromJson(jsonDecode(raw));
          } catch (_) {
            return null;
          }
        })
        .whereType<BibleStudy>()
        .toList()
      ..sort(
        (a, b) => (b.lastAccessedAt ?? b.createdAt).compareTo(
          a.lastAccessedAt ?? a.createdAt,
        ),
      );
  }

  List<BibleStudy> getActiveStudies() {
    return getAllStudies()
        .where(
          (s) =>
              s.status == StudyStatus.active ||
              s.status == StudyStatus.generating,
        )
        .toList();
  }

  List<BibleStudy> getCompletedStudies() {
    return getAllStudies()
        .where((s) => s.status == StudyStatus.completed)
        .toList();
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<void> deleteStudy(String id) async {
    await _box.delete(id);
    // Also delete word registry
    await _wordRegistryService.deleteRegistry(id);
  }

  Future<void> archiveStudy(String id) async {
    final study = getStudy(id);
    if (study == null) return;
    study.status = StudyStatus.archived;
    await saveStudy(study);
  }

  // ── Session Roles ─────────────────────────────────────────────────────────

  /// Gets the session role for a specific session in a study.
  SessionRole? getSessionRole(String studyId, int sessionNumber) {
    final study = getStudy(studyId);
    if (study == null) return null;

    // First check if role is stored in session
    final session = study.sessions.firstWhere(
      (s) => s.sessionNumber == sessionNumber,
      orElse: () => study.sessions.first,
    );

    if (session.sessionRole != null) {
      return session.sessionRole;
    }

    // Otherwise calculate it
    return SessionRoleAssigner.getRoleForSession(
      sessionNumber,
      study.totalSessions,
    );
  }

  /// Gets all session roles for a study.
  List<SessionRole> getAllSessionRoles(String studyId) {
    final study = getStudy(studyId);
    if (study == null) return [];

    return SessionRoleAssigner.assignRoles(study.totalSessions);
  }

  // ── Word Registry ─────────────────────────────────────────────────────────

  /// Gets the word definition registry for a study.
  Future<WordDefinitionRegistry> getWordRegistry(String studyId) async {
    return await _wordRegistryService.loadRegistry(studyId);
  }

  /// Saves the word definition registry for a study.
  Future<void> saveWordRegistry(WordDefinitionRegistry registry) async {
    await _wordRegistryService.saveRegistry(registry);
  }

  /// Registers a word as defined in a specific session.
  Future<void> registerWordDefinition(
    String studyId,
    String strongsNumber,
    int sessionNumber,
  ) async {
    await _wordRegistryService.registerWord(
      studyId,
      strongsNumber,
      sessionNumber,
    );
  }

  /// Checks if a word has already been defined in this study.
  Future<bool> isWordDefined(String studyId, String strongsNumber) async {
    return await _wordRegistryService.isWordDefined(studyId, strongsNumber);
  }

  /// Gets all defined words formatted for prompt injection.
  Future<List<Map<String, dynamic>>> getDefinedWordsForPrompt(
    String studyId,
  ) async {
    return await _wordRegistryService.getDefinedWordsForPrompt(studyId);
  }

  // ── Previous Session Summaries ────────────────────────────────────────────

  /// Gets summaries of previous sessions for prompt injection.
  ///
  /// Returns key findings from all sessions before [currentSessionNumber].
  Future<List<Map<String, dynamic>>> getPreviousSessionSummaries(
    String studyId,
    int currentSessionNumber,
  ) async {
    final study = getStudy(studyId);
    if (study == null) return [];

    final summaries = <Map<String, dynamic>>[];

    for (int i = 1; i < currentSessionNumber; i++) {
      final session = study.sessions.firstWhere(
        (s) => s.sessionNumber == i,
        orElse: () => study.sessions.first,
      );

      if (session.isGenerated && session.parsedContent != null) {
        final content = session.parsedContent!;

        // Extract key findings from the session content
        final keyFindings = <String>[];

        // Try to extract main themes/findings from various content structures
        if (content['sessionOverview'] != null) {
          keyFindings.add(content['sessionOverview'] as String);
        }

        if (content['bigTheme'] != null) {
          keyFindings.add(content['bigTheme'] as String);
        }

        if (content['centralLesson'] != null) {
          keyFindings.add(content['centralLesson'] as String);
        }

        summaries.add({
          'sessionNumber': i,
          'sessionTitle': session.sessionTitle,
          'keyFindings': keyFindings,
        });
      }
    }

    return summaries;
  }

  // ── Initialization ────────────────────────────────────────────────────────
  static Future<void> init() async {
    await Hive.openBox<String>(_boxName);
  }

  StudySession _mergeSession(StudySession existing, StudySession incoming) {
    return StudySession(
      sessionNumber: incoming.sessionNumber,
      sessionRole: incoming.sessionRole ?? existing.sessionRole,
      sessionTitle: incoming.sessionTitle.isNotEmpty
          ? incoming.sessionTitle
          : existing.sessionTitle,
      sessionSubtitle: incoming.sessionSubtitle ?? existing.sessionSubtitle,
      primaryScripture: incoming.primaryScripture ?? existing.primaryScripture,
      lifePhase: incoming.lifePhase ?? existing.lifePhase,
      chapterRange: incoming.chapterRange ?? existing.chapterRange,
      eraFocus: incoming.eraFocus ?? existing.eraFocus,
      isGenerated: incoming.isGenerated,
      isGenerating: incoming.isGenerating,
      contentJson: incoming.contentJson ?? existing.contentJson,
      partialContentJson: incoming.isGenerated
          ? incoming.partialContentJson
          : incoming.partialContentJson ?? existing.partialContentJson,
      generationStage: incoming.isGenerated
          ? incoming.generationStage
          : incoming.generationStage ?? existing.generationStage,
      lastGenerationError: incoming.lastGenerationError,
      wordsAlreadyDefined: incoming.wordsAlreadyDefined.isNotEmpty
          ? incoming.wordsAlreadyDefined
          : existing.wordsAlreadyDefined,
      highlights: existing.highlights,
      notes: existing.notes,
      answeredQuestions: existing.answeredQuestions,
      generatedAt: incoming.generatedAt ?? existing.generatedAt,
      unlocksAt: incoming.unlocksAt ?? existing.unlocksAt,
    );
  }
}
