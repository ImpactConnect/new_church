import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../../config/app_config.dart';
import '../models/exegesis_final_model.dart';
import '../storage/exegesis_final_hive_storage.dart';

/// Repository for saving, loading, and syncing exegesis results
/// (Final Edition — VerseExegesis and TopicExegesis).
///
/// Primary storage is Hive (local). Firestore sync is always a
/// background fire-and-forget operation so the UI never waits for it.
class ExegesisRepositoryFinal {
  final FirebaseFirestore? _firestore;
  Box<ExegesisLibraryItem>? _box;

  ExegesisRepositoryFinal({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ── Box helper ─────────────────────────────────────────────────────

  Future<Box<ExegesisLibraryItem>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<ExegesisLibraryItem>(
        ExegesisFinalHiveAdapters.boxName);
    return _box!;
  }

  // ── SAVE ──────────────────────────────────────────────────────────

  Future<void> saveVerse(VerseExegesis result) async {
    final item = ExegesisLibraryItem.fromVerse(result);
    await _save(item);
  }

  Future<void> saveTopic(TopicExegesis result) async {
    final item = ExegesisLibraryItem.fromTopic(result);
    await _save(item);
  }

  Future<void> _save(ExegesisLibraryItem item) async {
    try {
      final box = await _getBox();
      await box.put(item.id, item);
      _syncToFirestore(item); // fire-and-forget
    } catch (e) {
      debugPrint('⚠️ ExegesisRepositoryFinal.save error: $e');
      rethrow;
    }
  }

  // ── FETCH ─────────────────────────────────────────────────────────

  Future<ExegesisLibraryItem?> getById(String id) async {
    try {
      final box = await _getBox();
      return box.get(id);
    } catch (e) {
      debugPrint('⚠️ ExegesisRepositoryFinal.getById error: $e');
      return null;
    }
  }

  Future<List<ExegesisLibraryItem>> getAll() async {
    try {
      final box = await _getBox();
      final items = box.values.toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (e) {
      debugPrint('⚠️ ExegesisRepositoryFinal.getAll error: $e');
      return [];
    }
  }

  Future<List<ExegesisLibraryItem>> getByType(ExegesisEntryType type) async {
    final all = await getAll();
    return all.where((i) => i.type == type).toList();
  }

  Future<List<ExegesisLibraryItem>> search(String query) async {
    final all = await getAll();
    final q = query.toLowerCase();
    return all
        .where((i) => i.subject.toLowerCase().contains(q))
        .toList();
  }

  // ── WATCH (reactive Stream) ────────────────────────────────────────

  Stream<List<ExegesisLibraryItem>> watchAll() async* {
    final box = await _getBox();
    final sorted = box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    yield sorted;
    yield* box.watch().map((_) {
      final items = box.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  // ── DELETE ────────────────────────────────────────────────────────

  Future<void> delete(String id) async {
    try {
      final box = await _getBox();
      await box.delete(id);
      _deleteFromFirestore(id);
    } catch (e) {
      debugPrint('⚠️ ExegesisRepositoryFinal.delete error: $e');
      rethrow;
    }
  }

  // ── FIRESTORE SYNC ────────────────────────────────────────────────

  void _syncToFirestore(ExegesisLibraryItem item) {
    if (_firestore == null) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid.isEmpty) return;

      _firestore
          .collection(AppConfig.usersCollection)
          .doc(user.uid)
          .collection('exegesis_final')
          .doc(item.id)
          .set(item.toMap(), SetOptions(merge: true))
          .catchError(
              (e) => debugPrint('ExegesisRepositoryFinal Firestore sync: $e'));
    } catch (e) {
      debugPrint('ExegesisRepositoryFinal Firestore sync error: $e');
    }
  }

  void _deleteFromFirestore(String id) {
    if (_firestore == null) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      _firestore
          .collection(AppConfig.usersCollection)
          .doc(user.uid)
          .collection('exegesis_final')
          .doc(id)
          .delete()
          .catchError(
              (e) => debugPrint('ExegesisRepositoryFinal Firestore delete: $e'));
    } catch (e) {
      debugPrint('ExegesisRepositoryFinal Firestore delete error: $e');
    }
  }
}
