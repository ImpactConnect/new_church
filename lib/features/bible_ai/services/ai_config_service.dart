import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../config/app_config.dart';

/// Central service for fetching AI provider configuration.
///
/// Config is ONLY determined by the admin through Firestore `ai_config/settings`.
/// Hive is used as an offline cache. There are NO hardcoded provider defaults —
/// if Firestore is unreachable and there is no cache, AI features will fail
/// with a clear error message.
class AiConfigService {
  static const String _cacheKey = 'ai_config';

  // Placeholder values that should be treated as "not set"
  static const List<String> _placeholderKeys = [
    'YOUR_GEMINI_API_KEY',
    'YOUR_OPENAI_API_KEY',
    'SET_YOUR_KEY',
    'SET_YOUR_OPENAI_KEY',
    '',
  ];

  /// Get the API key for the current default provider.
  static Future<String> getApiKey() async {
    final config = await _getConfig();
    final provider = config['defaultProvider'] as String?;
    if (provider == null || provider.isEmpty) {
      throw Exception(
        'No AI provider configured. Set defaultProvider in Firestore ai_config/settings.',
      );
    }

    final providers = _deepCastMap(config['providers']);
    final providerConfig = _deepCastMap(providers[provider]);
    final key = providerConfig['apiKey'] as String? ?? '';

    if (key.isNotEmpty && !_placeholderKeys.contains(key)) {
      return key;
    }

    throw Exception(
      'No API key configured for "$provider". '
      'Set it in Firestore ai_config/settings → providers → $provider → apiKey.',
    );
  }

  /// Get the model name for the current default provider.
  static Future<String> getModel() async {
    final config = await _getConfig();
    final provider = config['defaultProvider'] as String? ?? '';
    final providers = _deepCastMap(config['providers']);
    final providerConfig = _deepCastMap(providers[provider]);
    final model = providerConfig['model'] as String?;

    if (model != null && model.isNotEmpty) return model;

    throw Exception(
      'No model configured for "$provider". '
      'Set it in Firestore ai_config/settings → providers → $provider → model.',
    );
  }

  /// Get the default provider name (e.g. 'gemini' or 'openai').
  static Future<String> getProvider() async {
    final config = await _getConfig();
    final provider = config['defaultProvider'] as String?;
    if (provider == null || provider.isEmpty) {
      throw Exception(
        'No AI provider configured. Set defaultProvider in Firestore ai_config/settings.',
      );
    }
    return provider;
  }

  /// Force refresh config from Firestore (useful after admin changes settings).
  static Future<void> refreshConfig() async {
    final data = await _fetchFromFirestore();
    if (data != null) {
      final box = await Hive.openBox(AppConfig.cacheBoxName);
      // Convert Firestore Timestamps to DateTime before caching
      final sanitizedData = _sanitizeForHive(data);
      await box.put(_cacheKey, sanitizedData);
      debugPrint('AiConfigService: Config refreshed from Firestore.');
    }
  }

  /// Clear cached config (forces a fresh Firestore fetch on next call).
  static Future<void> clearCache() async {
    try {
      final box = await Hive.openBox(AppConfig.cacheBoxName);
      await box.delete(_cacheKey);
      debugPrint('AiConfigService: Cache cleared.');
    } catch (_) {}
  }

  /// Get the full configuration map.
  /// Strategy: Firestore first → Hive cache fallback → throw error.
  static Future<Map<String, dynamic>> _getConfig() async {
    // 1. Try Firestore (source of truth)
    final firestoreData = await _fetchFromFirestore();
    if (firestoreData != null) {
      debugPrint(
        'AiConfigService: Loaded from Firestore. '
        'Provider: ${firestoreData['defaultProvider']}',
      );
      // Update Hive cache for next offline use
      try {
        final box = await Hive.openBox(AppConfig.cacheBoxName);
        // Convert Firestore Timestamps to DateTime before caching
        final sanitizedData = _sanitizeForHive(firestoreData);
        await box.put(_cacheKey, sanitizedData);
      } catch (_) {}
      return firestoreData;
    }

    // 2. Offline fallback: use Hive cache
    try {
      final box = await Hive.openBox(AppConfig.cacheBoxName);
      final cached = box.get(_cacheKey);
      if (cached is Map && cached.isNotEmpty) {
        debugPrint(
          'AiConfigService: Using cached config. '
          'Provider: ${cached['defaultProvider']}',
        );
        return Map<String, dynamic>.from(cached);
      }
    } catch (_) {}

    // 3. No config available at all — throw clear error
    debugPrint('AiConfigService: No config found in Firestore or cache.');
    throw Exception(
      'AI configuration not available. '
      'Ensure Firestore ai_config/settings is properly configured and the device is online.',
    );
  }

  static Future<Map<String, dynamic>?> _fetchFromFirestore() async {
    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('AiConfigService: Firebase not initialized.');
        return null;
      }
      final doc = await FirebaseFirestore.instance
          .collection('ai_config')
          .doc('settings')
          .get();
      if (!doc.exists) {
        debugPrint('AiConfigService: ai_config/settings doc does not exist.');
        return null;
      }
      return doc.data();
    } catch (e) {
      debugPrint('AiConfigService: Firestore fetch failed: $e');
      return null;
    }
  }

  /// Safely deep-cast a value to Map<String, dynamic>.
  /// Hive and Firestore can return different internal Map implementations.
  static Map<String, dynamic> _deepCastMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

  /// Sanitize Firestore data for Hive storage by converting Timestamps to DateTime
  static Map<String, dynamic> _sanitizeForHive(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    
    for (final entry in data.entries) {
      final value = entry.value;
      
      if (value is Timestamp) {
        // Convert Firestore Timestamp to DateTime
        sanitized[entry.key] = value.toDate();
      } else if (value is Map) {
        // Recursively sanitize nested maps
        sanitized[entry.key] = _sanitizeForHive(Map<String, dynamic>.from(value));
      } else if (value is List) {
        // Recursively sanitize lists
        sanitized[entry.key] = value.map((item) {
          if (item is Timestamp) {
            return item.toDate();
          } else if (item is Map) {
            return _sanitizeForHive(Map<String, dynamic>.from(item));
          }
          return item;
        }).toList();
      } else {
        sanitized[entry.key] = value;
      }
    }
    
    return sanitized;
  }
}
