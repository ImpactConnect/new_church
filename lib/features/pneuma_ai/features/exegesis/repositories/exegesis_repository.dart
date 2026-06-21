import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/ai/exegesis_session_model.dart';
import 'package:church_mobile/features/bible_ai/services/ai_service.dart';
import '../../../config/app_config.dart';
import '../models/exegesis_result_model.dart';
import '../services/exegesis_ai_service.dart';

class ExegesisRepository {
  final AiService _aiService;
  final FirebaseFirestore _firestore;
  Box<ExegesisSessionModel>? _box;

  ExegesisRepository({
    required AiService aiService,
    FirebaseFirestore? firestore,
  })  : _aiService = aiService,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Box<ExegesisSessionModel>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<ExegesisSessionModel>(
        '${AppConfig.chatSessionsBoxName}_exegesis');
    return _box!;
  }

  // ── v2 Generation ─────────────────────────────────────────────────

  /// Generates a new exegesis using the v2 engine.
  Future<ExegesisResult> generateExegesisV2({
    required String subject,
    required String entryType,
    required String depthLevel,
  }) async {
    final service = ExegesisAiService(aiService: _aiService);
    final result = await service.generateExegesis(
      subject: subject,
      entryType: entryType,
      depthLevel: depthLevel,
    );

    // Auto-save as a session
    _autoSaveSession(
      entryType: entryType,
      subject: subject,
      depthLevel: depthLevel,
      result: result,
    );

    return result;
  }

  // ── Session CRUD ──────────────────────────────────────────────────

  Future<void> saveSession(ExegesisSessionModel session) async {
    final box = await _getBox();
    await box.put(session.id, session);
    _syncToFirestore(session);
  }

  Future<ExegesisSessionModel?> getSessionById(String id) async {
    final box = await _getBox();
    return box.get(id);
  }

  Future<void> deleteSession(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  Stream<List<ExegesisSessionModel>> watchSessions() async* {
    final box = await _getBox();
    yield box.values.toList()
      ..sort((a, b) =>
          (b.updatedAt ?? b.createdAt ?? DateTime.now())
              .compareTo(a.updatedAt ?? a.createdAt ?? DateTime.now()));

    yield* box.watch().map((_) => box.values.toList()
      ..sort((a, b) =>
          (b.updatedAt ?? b.createdAt ?? DateTime.now())
              .compareTo(a.updatedAt ?? a.createdAt ?? DateTime.now())));
  }

  void _autoSaveSession({
    required String entryType,
    required String subject,
    required String depthLevel,
    required ExegesisResult result,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final session = ExegesisSessionModel(
      id: const Uuid().v4(),
      userId: user.uid,
      type: entryType,
      query: subject,
      title: '$entryType: $subject',
      contentJson: jsonEncode(result.toJson()),
      depth: depthLevel,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    saveSession(session);
  }

  void _syncToFirestore(ExegesisSessionModel session) {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      _firestore
          .collection(AppConfig.usersCollection)
          .doc(user.uid)
          .collection('exegesis_sessions')
          .doc(session.id)
          .set(session.toMap(), SetOptions(merge: true))
          .catchError(
              (e) => debugPrint('Exegesis Firestore sync failed: $e'));
    } catch (e) {
      debugPrint('Exegesis Firestore sync error: $e');
    }
  }
}
