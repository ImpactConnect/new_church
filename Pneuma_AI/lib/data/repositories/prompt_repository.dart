import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Repository for fetching AI prompts from Firestore with Hive caching.
///
/// Usage:
///   final repo = PromptRepository();
///   final prompt = await repo.getPrompt('berean_evaluation');
///   // Returns the systemPrompt string, or null if not found
class PromptRepository {
  PromptRepository([this._firestore]);

  final FirebaseFirestore? _firestore;

  /// Generic method to fetch any prompt by feature key.
  ///
  /// Feature keys: explain_verse, analyze_passage, analyze_chapter,
  /// chat_verse, chat_general, study_guide, devotional_plan,
  /// reading_plan, berean_evaluation, book_introduction
  Future<String?> getPrompt(String featureKey) async {
    // Try Firestore directly - NO HIVE CACHING
    return await _fetchPromptFromFirestore(featureKey);
  }

  /// Fetch the full prompt config map (systemPrompt + userTemplate etc.)
  Future<Map<String, dynamic>?> getPromptConfig(String featureKey) async {
    // Try Firestore directly - NO HIVE CACHING
    return await _fetchPromptConfigFromFirestore(featureKey);
  }

  /// Fetch prompts from the `ai_exegesis` collection.
  Future<String?> getExegesisPrompt(String promptKey) async {
    try {
      final fs = _getFirestore();
      if (fs == null) return null;

      final doc = await fs.collection('ai_exegesis').doc(promptKey).get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;
      if (data['isActive'] == false) return null;

      return data['systemPrompt'] as String?;
    } catch (_) {
      return null;
    }
  }

  // --- Legacy method for devotional compatibility ---
  Future<Map<String, dynamic>?> getDevotionalPlanPrompt() async {
    return getPromptConfig('devotional_plan');
  }

  // --- Private helpers ---

  FirebaseFirestore? _getFirestore() {
    if (_firestore != null) return _firestore;
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _fetchPromptFromFirestore(String featureKey) async {
    try {
      final fs = _getFirestore();
      if (fs == null) return null;

      final doc = await fs.collection('ai_prompts').doc(featureKey).get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;
      if (data['isActive'] == false) return null;

      return data['systemPrompt'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchPromptConfigFromFirestore(
    String featureKey,
  ) async {
    try {
      final fs = _getFirestore();
      if (fs == null) return null;

      final doc = await fs.collection('ai_prompts').doc(featureKey).get();
      if (!doc.exists) return null;

      return doc.data();
    } catch (_) {
      return null;
    }
  }
}
