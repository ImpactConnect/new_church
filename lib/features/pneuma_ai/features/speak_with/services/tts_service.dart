import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:church_mobile/features/bible_ai/services/ai_config_service.dart';

final ttsServiceProvider = Provider<TtsService>((ref) => TtsService());

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _initialized = false;

  // Resolved voice map: voiceId → {name, locale}
  final Map<String, Map<String, String>?> _resolvedVoices = {};

  Future<void> _ensureInit() async {
    if (_initialized) return;
    _initialized = true;
    await _flutterTts.awaitSpeakCompletion(true);
    await _resolveVoices();
  }

  /// Query the device TTS engine for real voice names, then map our profile IDs
  /// to distinct voices by locale and gender hints.
  Future<void> _resolveVoices() async {
    try {
      final rawVoices = await _flutterTts.getVoices;
      if (rawVoices == null) return;

      final voices = (rawVoices as List)
          .map((v) => Map<String, String>.from(v as Map))
          .toList();

      debugPrint('TtsService: ${voices.length} voices available.');
      for (final v in voices) {
        debugPrint('  voice → ${v['name']} | ${v['locale']}');
      }

      // Helper: pick a voice matching a locale prefix (e.g. 'en-') and a
      // keyword hint, falling back to locale prefix only.
      Map<String, String>? pick(String localePrefix,
          {String? hint, bool avoidUsed = true}) {
        final candidates = voices.where((v) {
          final locale = (v['locale'] ?? '').toLowerCase();
          return locale.startsWith(localePrefix.toLowerCase());
        }).toList();

        if (candidates.isEmpty) {
          // Broader fallback to 'en-'
          final en = voices.where((v) =>
              (v['locale'] ?? '').toLowerCase().startsWith('en-')).toList();
          return en.isNotEmpty ? en.first : null;
        }

        if (hint != null) {
          final hinted = candidates.firstWhere(
            (v) => (v['name'] ?? '').toLowerCase().contains(hint.toLowerCase()),
            orElse: () => candidates.first,
          );
          return hinted;
        }
        return candidates.first;
      }

      // Map each profile ID to the best available voice
      // Nigerian female (standard) — any en-NG, or en- with 'f' hint
      _resolvedVoices['en-NG-1'] = pick('en-ng') ?? pick('en-', hint: 'female');
      // Nigerian female (neural / higher pitch)
      _resolvedVoices['en-NG-2'] = pick('en-ng') ?? pick('en-US', hint: 'female');
      // Nigerian male (standard)
      _resolvedVoices['en-NG-3'] = pick('en-ng', hint: 'male') ?? pick('en-', hint: 'male');
      // Nigerian male (neural)
      _resolvedVoices['en-NG-4'] = pick('en-ng', hint: 'male') ?? pick('en-GB', hint: 'male');

      // American English
      _resolvedVoices['en-US-1'] = pick('en-US', hint: 'female') ?? pick('en-US');
      _resolvedVoices['en-US-2'] = pick('en-US', hint: 'male') ?? pick('en-US');

      // British English
      _resolvedVoices['en-GB-1'] = pick('en-GB', hint: 'female') ?? pick('en-GB');
      _resolvedVoices['en-GB-2'] = pick('en-GB', hint: 'male') ?? pick('en-GB');

      // South African English
      _resolvedVoices['en-ZA-1'] = pick('en-ZA') ?? pick('en-AU') ?? pick('en-');

    } catch (e) {
      debugPrint('TtsService._resolveVoices error: $e');
    }
  }

  /// Pitch multipliers per profile relative to user base pitch.
  static const Map<String, double> _pitchOffset = {
    'en-NG-1': 0.00,
    'en-NG-2': 0.20,  // higher pitch = more feminine
    'en-NG-3': -0.30, // lower pitch = male
    'en-NG-4': -0.20,
    'en-US-1': 0.10,
    'en-US-2': -0.25,
    'en-GB-1': 0.05,
    'en-GB-2': -0.20,
    'en-ZA-1': 0.00,
  };

  static const Map<String, double> _rateOffset = {
    'en-NG-1': 0.00,
    'en-NG-2': 0.05,
    'en-NG-3': -0.05,
    'en-NG-4': 0.00,
    'en-US-1': 0.05,
    'en-US-2': -0.05,
    'en-GB-1': 0.00,
    'en-GB-2': -0.05,
    'en-ZA-1': 0.00,
  };

  /// Speaks the given text and WAITS for it to finish.
  Future<void> speak(String text, String provider,
      {double speed = 0.5,
      double pitch = 1.0,
      String voiceId = 'en-NG-1'}) async {
    try {
      await _ensureInit();
      final cleanText = _stripMarkdown(text);

      if (provider == 'google_cloud') {
        final ok = await _speakWithGoogleCloud(cleanText, speed, pitch, voiceId);
        if (!ok) await _speakWithFlutterTts(cleanText, speed, pitch, voiceId);
      } else {
        await _speakWithFlutterTts(cleanText, speed, pitch, voiceId);
      }
    } catch (e) {
      debugPrint('TtsService.speak error: $e');
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  String _stripMarkdown(String text) => text
      .replaceAll(RegExp(r'[*_~`]+'), '')
      .replaceAll(RegExp(r'#+\s'), '')
      .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1')
      .trim();

  Future<void> _speakWithFlutterTts(
      String text, double speed, double pitch, String voiceId) async {
    final pitchOff = _pitchOffset[voiceId] ?? 0.0;
    final rateOff = _rateOffset[voiceId] ?? 0.0;
    final effectivePitch = (pitch + pitchOff).clamp(0.5, 2.0);
    final effectiveRate = (speed + rateOff).clamp(0.1, 1.0);

    // Try to set the resolved voice for this profile
    final voice = _resolvedVoices[voiceId];
    if (voice != null && voice['name'] != null && voice['locale'] != null) {
      try {
        final locale = voice['locale']!;
        await _flutterTts.setLanguage(locale);
        await _flutterTts.setVoice({'name': voice['name']!, 'locale': locale});
        debugPrint('TtsService: using voice ${voice['name']} (${locale}) for $voiceId');
      } catch (e) {
        debugPrint('TtsService: setVoice failed, using language only: $e');
        await _flutterTts.setLanguage(voice['locale'] ?? 'en-US');
      }
    } else {
      // No resolved voice — set language from profile id prefix
      final langCode = voiceId.substring(0, 5); // e.g. 'en-US'
      final available = await _flutterTts.isLanguageAvailable(langCode);
      await _flutterTts.setLanguage(available == true ? langCode : 'en-US');
    }

    await _flutterTts.setSpeechRate(effectiveRate);
    await _flutterTts.setPitch(effectivePitch);
    await _flutterTts.speak(text);
  }

  Future<bool> _speakWithGoogleCloud(
      String text, double speed, double pitch, String voiceId) async {
    final apiKey = await AiConfigService.getTtsApiKey('google_cloud');
    if (apiKey == null || apiKey.isEmpty) return false;

    final langCode = voiceId.substring(0, 5);
    final isFemale = voiceId.endsWith('1') || voiceId.endsWith('2');
    final pitchOff = _pitchOffset[voiceId] ?? 0.0;
    final rateOff = _rateOffset[voiceId] ?? 0.0;

    final uri = Uri.parse(
        'https://texttospeech.googleapis.com/v1/text:synthesize?key=$apiKey');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'input': {'text': text},
        'voice': {
          'languageCode': langCode,
          'ssmlGender': isFemale ? 'FEMALE' : 'MALE',
        },
        'audioConfig': {
          'audioEncoding': 'MP3',
          'speakingRate': ((speed + rateOff) * 2).clamp(0.25, 4.0),
          'pitch': ((pitch + pitchOff - 1.0) * 20.0).clamp(-20.0, 20.0),
        }
      }),
    );

    if (response.statusCode != 200) {
      debugPrint('Google Cloud TTS error ${response.statusCode}: ${response.body}');
    }
    return false; // Fallback to flutter_tts until audio player for bytes is integrated
  }
}
