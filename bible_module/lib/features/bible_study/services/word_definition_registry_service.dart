import 'package:hive_flutter/hive_flutter.dart';
import '../models/bible_study_models.dart';

/// Service for managing word definition registries to prevent repetition.
/// 
/// Tracks which Hebrew/Greek words have been defined in which sessions
/// to ensure words are not re-defined across a study series.
class WordDefinitionRegistryService {
  static const String _boxName = 'word_definition_registries';
  final HiveInterface _hive;

  WordDefinitionRegistryService(this._hive);

  /// Gets the Hive box for word registries.
  Future<Box<Map>> _getBox() async {
    if (!_hive.isBoxOpen(_boxName)) {
      return await _hive.openBox<Map>(_boxName);
    }
    return _hive.box<Map>(_boxName);
  }

  /// Loads the word registry for a study.
  /// 
  /// Returns an empty registry if none exists.
  Future<WordDefinitionRegistry> loadRegistry(String studyId) async {
    try {
      final box = await _getBox();
      final data = box.get(studyId);

      if (data == null) {
        return WordDefinitionRegistry(studyId: studyId);
      }

      return WordDefinitionRegistry.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      // Return empty registry on error
      return WordDefinitionRegistry(studyId: studyId);
    }
  }

  /// Saves the word registry for a study.
  Future<void> saveRegistry(WordDefinitionRegistry registry) async {
    try {
      final box = await _getBox();
      await box.put(registry.studyId, registry.toJson());
    } catch (e) {
      // Silently fail - registry is not critical for functionality
      print('Failed to save word registry: $e');
    }
  }

  /// Registers a new word definition.
  /// 
  /// Records that [strongsNumber] was defined in [sessionNumber] of [studyId].
  Future<void> registerWord(
    String studyId,
    String strongsNumber,
    int sessionNumber,
  ) async {
    final registry = await loadRegistry(studyId);
    registry.registerWord(strongsNumber, sessionNumber);
    await saveRegistry(registry);
  }

  /// Registers multiple word definitions at once.
  Future<void> registerWords(
    String studyId,
    List<String> strongsNumbers,
    int sessionNumber,
  ) async {
    final registry = await loadRegistry(studyId);
    for (final strongsNumber in strongsNumbers) {
      registry.registerWord(strongsNumber, sessionNumber);
    }
    await saveRegistry(registry);
  }

  /// Checks if a word has already been defined in this study.
  Future<bool> isWordDefined(String studyId, String strongsNumber) async {
    final registry = await loadRegistry(studyId);
    return registry.isDefined(strongsNumber);
  }

  /// Gets the session number where a word was defined.
  /// 
  /// Returns null if the word has not been defined.
  Future<int?> getDefinedInSession(
    String studyId,
    String strongsNumber,
  ) async {
    final registry = await loadRegistry(studyId);
    return registry.getDefinedInSession(strongsNumber);
  }

  /// Gets all defined words for prompt injection.
  /// 
  /// Returns a list of maps suitable for including in AI prompts.
  Future<List<Map<String, dynamic>>> getDefinedWordsForPrompt(
    String studyId,
  ) async {
    final registry = await loadRegistry(studyId);
    return registry.toPromptArray();
  }

  /// Gets all Strong's numbers that have been defined.
  Future<List<String>> getDefinedStrongsNumbers(String studyId) async {
    final registry = await loadRegistry(studyId);
    return registry.strongsToSessionMap.keys.toList();
  }

  /// Deletes the registry for a study.
  /// 
  /// Called when a study is deleted.
  Future<void> deleteRegistry(String studyId) async {
    try {
      final box = await _getBox();
      await box.delete(studyId);
    } catch (e) {
      print('Failed to delete word registry: $e');
    }
  }

  /// Clears all registries (for testing or maintenance).
  Future<void> clearAll() async {
    try {
      final box = await _getBox();
      await box.clear();
    } catch (e) {
      print('Failed to clear word registries: $e');
    }
  }
}
