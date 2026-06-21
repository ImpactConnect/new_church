import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../../config/app_config.dart';
import '../models/exegesis_result_v2_model.dart';

/// Abstract interface for Exegesis v2.0 repository operations
abstract class ExegesisRepositoryV2 {
  // ── CRUD Operations ──
  
  /// Save an exegesis result to local storage
  Future<void> save(ExegesisResultV2 result);
  
  /// Get an exegesis result by ID
  Future<ExegesisResultV2?> getById(String id);
  
  /// Get all exegesis results, sorted by creation date (newest first)
  Future<List<ExegesisResultV2>> getAll();
  
  /// Delete an exegesis result by ID
  Future<void> delete(String id);
  
  /// Watch for changes to all exegesis results
  Stream<List<ExegesisResultV2>> watchAll();
  
  // ── Mode Management ──
  
  /// Cache the alternate mode result for quick switching
  Future<void> cacheAlternateMode(String originalId, ExegesisResultV2 alternateResult);
  
  /// Get the cached alternate mode result if it exists
  Future<ExegesisResultV2?> getAlternateMode(String originalId, ExegesisMode targetMode);
  
  // ── Migration Support ──
  
  /// Get all results regardless of version (v1 or v2)
  Future<List<dynamic>> getAllVersions();
  
  // ── Sync Operations ──
  
  /// Sync a result to Firestore (background operation)
  Future<void> syncToFirestore(ExegesisResultV2 result);
}

/// Implementation of ExegesisRepositoryV2 using Hive for local storage
class ExegesisRepositoryV2Impl implements ExegesisRepositoryV2 {
  final FirebaseFirestore? _firestore;
  Box<ExegesisResultV2>? _box;

  ExegesisRepositoryV2Impl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  Future<Box<ExegesisResultV2>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<ExegesisResultV2>('exegesis_v2');
    return _box!;
  }

  @override
  Future<void> save(ExegesisResultV2 result) async {
    try {
      final box = await _getBox();
      await box.put(result.id, result);
      
      // Background sync to Firestore
      syncToFirestore(result);
    } catch (e) {
      debugPrint('Error saving exegesis v2 result: $e');
      rethrow;
    }
  }

  @override
  Future<ExegesisResultV2?> getById(String id) async {
    try {
      final box = await _getBox();
      return box.get(id);
    } catch (e) {
      debugPrint('Error getting exegesis v2 result by id: $e');
      return null;
    }
  }

  @override
  Future<List<ExegesisResultV2>> getAll() async {
    try {
      final box = await _getBox();
      final results = box.values.toList();
      
      // Sort by creation date, newest first
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return results;
    } catch (e) {
      debugPrint('Error getting all exegesis v2 results: $e');
      return [];
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      final box = await _getBox();
      await box.delete(id);
      
      // Also delete from Firestore
      _deleteFromFirestore(id);
    } catch (e) {
      debugPrint('Error deleting exegesis v2 result: $e');
      rethrow;
    }
  }

  @override
  Stream<List<ExegesisResultV2>> watchAll() async* {
    final box = await _getBox();
    
    // Emit initial values
    final initial = box.values.toList();
    initial.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    yield initial;
    
    // Watch for changes
    yield* box.watch().map((_) {
      final results = box.values.toList();
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results;
    });
  }

  @override
  Future<void> cacheAlternateMode(String originalId, ExegesisResultV2 alternateResult) async {
    try {
      // Save the alternate mode result
      await save(alternateResult);
      
      // Update the original result to reference the alternate
      final original = await getById(originalId);
      if (original != null) {
        final updated = original.copyWith(
          cachedAlternateModeId: alternateResult.id,
        );
        await save(updated);
      }
      
      // Also update the alternate to reference the original
      final updatedAlternate = alternateResult.copyWith(
        cachedAlternateModeId: originalId,
      );
      await save(updatedAlternate);
    } catch (e) {
      debugPrint('Error caching alternate mode: $e');
      rethrow;
    }
  }

  @override
  Future<ExegesisResultV2?> getAlternateMode(String originalId, ExegesisMode targetMode) async {
    try {
      final original = await getById(originalId);
      if (original == null) return null;
      
      // Check if alternate mode is cached
      if (original.cachedAlternateModeId != null) {
        final alternate = await getById(original.cachedAlternateModeId!);
        if (alternate != null && alternate.mode == targetMode) {
          return alternate;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting alternate mode: $e');
      return null;
    }
  }

  @override
  Future<List<dynamic>> getAllVersions() async {
    try {
      final results = <dynamic>[];
      
      // Get v2 results
      final v2Results = await getAll();
      results.addAll(v2Results);
      
      // TODO: Add v1 results when migration is implemented
      
      return results;
    } catch (e) {
      debugPrint('Error getting all versions: $e');
      return [];
    }
  }

  @override
  Future<void> syncToFirestore(ExegesisResultV2 result) async {
    if (_firestore == null) {
      debugPrint('Firestore not initialized, skipping sync');
      return;
    }
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('Cannot sync to Firestore: User not authenticated');
        return;
      }

      if (user.uid.isEmpty) {
        debugPrint('Cannot sync to Firestore: User ID is empty');
        return;
      }

      if (result.id.isEmpty) {
        debugPrint('Cannot sync to Firestore: Result ID is empty');
        return;
      }

      await _firestore!
          .collection(AppConfig.usersCollection)
          .doc(user.uid)
          .collection('exegesis_v2')
          .doc(result.id)
          .set(result.toJson(), SetOptions(merge: true));
      
      debugPrint('Synced exegesis v2 result ${result.id} to Firestore');
    } catch (e) {
      debugPrint('Error syncing to Firestore: $e');
      // Don't rethrow - sync failures shouldn't break the app
    }
  }

  Future<void> _deleteFromFirestore(String id) async {
    if (_firestore == null) return;
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore!
          .collection(AppConfig.usersCollection)
          .doc(user.uid)
          .collection('exegesis_v2')
          .doc(id)
          .delete();
      
      debugPrint('Deleted exegesis v2 result $id from Firestore');
    } catch (e) {
      debugPrint('Error deleting from Firestore: $e');
      // Don't rethrow - sync failures shouldn't break the app
    }
  }
}
