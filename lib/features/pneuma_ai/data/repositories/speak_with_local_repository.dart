import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/speak_with/models/speak_with_models.dart';

/// Local Hive-backed repository for ScriptTalk conversations.
/// Stores entirely on-device — no authentication required.
class SpeakWithLocalRepository {
  static const _boxName = 'speak_with_conversations';

  Box<String>? _box;

  Future<Box<String>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<String>(_boxName);
    return _box!;
  }

  Future<List<SpeakWithConversation>> getSavedConversations() async {
    try {
      final box = await _getBox();
      final List<SpeakWithConversation> results = [];
      for (final key in box.keys) {
        try {
          final raw = box.get(key as String);
          if (raw == null) continue;
          final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
          results.add(SpeakWithConversation.fromJson(map));
        } catch (e) {
          debugPrint('SpeakWithLocalRepository: parse error for $key: $e');
        }
      }
      // Sort newest-first
      results.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      return results;
    } catch (e) {
      debugPrint('SpeakWithLocalRepository.getSavedConversations: $e');
      return [];
    }
  }

  Future<void> saveConversation(SpeakWithConversation conversation) async {
    try {
      final box = await _getBox();
      final json = jsonEncode(conversation.toJson());
      await box.put(conversation.id, json);
    } catch (e) {
      debugPrint('SpeakWithLocalRepository.saveConversation: $e');
    }
  }

  Future<void> deleteConversation(String id) async {
    try {
      final box = await _getBox();
      await box.delete(id);
    } catch (e) {
      debugPrint('SpeakWithLocalRepository.deleteConversation: $e');
    }
  }
}
