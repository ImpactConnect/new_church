import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:church_mobile/features/bible_ai/services/ai_config_service.dart';

final ttsServiceProvider = Provider<TtsService>((ref) => TtsService());

/// OpenAI TTS voices — 6 available, clearly distinct.
/// We use gender to auto-select: female-sounding vs male-sounding voices.
/// https://platform.openai.com/docs/guides/text-to-speech
class OpenAiVoice {
  /// Nova & Shimmer: bright, clear female voices
  static const String nova = 'nova';
  static const String shimmer = 'shimmer';
  static const String alloy = 'alloy'; // neutral/female-leaning

  /// Onyx & Echo: deep male voices. Fable: warm male voice.
  static const String onyx = 'onyx';
  static const String echo = 'echo';
  static const String fable = 'fable';

  /// Resolve voice from gender + user-selected voice profile
  static String resolve({required String gender, required String voiceId}) {
    final isFemale = gender.toLowerCase() == 'female';

    // If user has set a specific profile, respect it but ensure correct gender
    switch (voiceId) {
      // ── User selected a female-profile → always use female voice ──
      case 'en-NG-1':
      case 'en-US-1':
      case 'en-GB-1':
      case 'en-ZA-1':
        return isFemale ? nova : onyx;

      case 'en-NG-2':
      case 'en-US-2':
      case 'en-GB-2':
        return isFemale ? shimmer : echo;

      case 'en-NG-3':
      case 'en-NG-4':
        return isFemale ? alloy : fable;

      default:
        return isFemale ? nova : onyx;
    }
  }
}

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _initialized = false;

  // Resolved voice map: voiceId → {name, locale}
  final Map<String, Map<String, String>?> _resolvedVoices = {};

  Future<void> _ensureInit() async {
    if (_initialized) return;
    _initialized = true;
    await _flutterTts.awaitSpeakCompletion(true);
    await _resolveVoices();
  }

  Future<void> _resolveVoices() async {
    try {
      final rawVoices = await _flutterTts.getVoices;
      if (rawVoices == null) return;

      final voices = (rawVoices as List)
          .map((v) => Map<String, String>.from(v as Map))
          .toList();

      debugPrint('TtsService: ${voices.length} voices available on device.');

      Map<String, String>? pick(String localePrefix, {String? hint}) {
        final candidates = voices.where((v) {
          final locale = (v['locale'] ?? '').toLowerCase();
          return locale.startsWith(localePrefix.toLowerCase());
        }).toList();
        if (candidates.isEmpty) {
          final en = voices
              .where((v) => (v['locale'] ?? '').toLowerCase().startsWith('en-'))
              .toList();
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

      _resolvedVoices['en-NG-1'] = pick('en-ng') ?? pick('en-', hint: 'female');
      _resolvedVoices['en-NG-2'] = pick('en-ng') ?? pick('en-US', hint: 'female');
      _resolvedVoices['en-NG-3'] =
          pick('en-ng', hint: 'male') ?? pick('en-', hint: 'male');
      _resolvedVoices['en-NG-4'] =
          pick('en-ng', hint: 'male') ?? pick('en-GB', hint: 'male');
      _resolvedVoices['en-US-1'] = pick('en-US', hint: 'female') ?? pick('en-US');
      _resolvedVoices['en-US-2'] = pick('en-US', hint: 'male') ?? pick('en-US');
      _resolvedVoices['en-GB-1'] = pick('en-GB', hint: 'female') ?? pick('en-GB');
      _resolvedVoices['en-GB-2'] = pick('en-GB', hint: 'male') ?? pick('en-GB');
      _resolvedVoices['en-ZA-1'] = pick('en-ZA') ?? pick('en-AU') ?? pick('en-');
    } catch (e) {
      debugPrint('TtsService._resolveVoices error: $e');
    }
  }

  static const Map<String, double> _pitchOffset = {
    'en-NG-1': 0.00, 'en-NG-2': 0.20, 'en-NG-3': -0.30, 'en-NG-4': -0.20,
    'en-US-1': 0.10, 'en-US-2': -0.25,
    'en-GB-1': 0.05, 'en-GB-2': -0.20,
    'en-ZA-1': 0.00,
  };

  static const Map<String, double> _rateOffset = {
    'en-NG-1': 0.00, 'en-NG-2': 0.05, 'en-NG-3': -0.05, 'en-NG-4': 0.00,
    'en-US-1': 0.05, 'en-US-2': -0.05,
    'en-GB-1': 0.00, 'en-GB-2': -0.05,
    'en-ZA-1': 0.00,
  };

  /// Speaks the given text and WAITS for it to finish.
  /// [gender] should be 'male' or 'female' — used to auto-select OpenAI voice.
  /// [onStart] is called exactly when the audio begins playing.
  Future<void> speak(
    String text,
    String provider, {
    double speed = 0.5,
    double pitch = 1.0,
    String voiceId = 'en-NG-1',
    String gender = 'male',
    void Function()? onStart,
  }) async {
    try {
      await _ensureInit();
      final cleanText = _stripMarkdown(text);

      if (provider == 'openai_tts') {
        final ok =
            await _speakWithOpenAi(cleanText, speed, voiceId, gender, onStart);
        if (!ok) await _speakWithFlutterTts(cleanText, speed, pitch, voiceId, onStart);
      } else if (provider == 'google_cloud') {
        final ok = await _speakWithGoogleCloud(cleanText, speed, pitch, voiceId, gender, onStart);
        if (!ok) await _speakWithFlutterTts(cleanText, speed, pitch, voiceId, onStart);
      } else {
        await _speakWithFlutterTts(cleanText, speed, pitch, voiceId, onStart);
      }
    } catch (e) {
      debugPrint('TtsService.speak error: $e');
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    await _flutterTts.stop();
  }

  String _stripMarkdown(String text) => text
      .replaceAll(RegExp(r'[*_~`]+'), '')
      .replaceAll(RegExp(r'#+\s'), '')
      .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1')
      // Remove any bible verse references in parentheses (e.g., (John 3:16) or (1 Corinthians 13:4-8))
      .replaceAll(RegExp(r'\([^)]*\d+:\d+[^)]*\)'), '')
      .replaceAll(RegExp(r'\(\s*\)'), '')
      .trim();

  // ── OpenAI TTS ───────────────────────────────────────────────────────────

  Future<bool> _speakWithOpenAi(
      String text, double speed, String voiceId, String gender, void Function()? onStart) async {
    final apiKey = await AiConfigService.getTtsApiKey('openai_tts');
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('OpenAI TTS: no API key configured, falling back to flutter_tts.');
      return false;
    }

    final voice = OpenAiVoice.resolve(gender: gender, voiceId: voiceId);
    // OpenAI speed: 0.25–4.0 (1.0 = normal). Map our 0.1–1.0 to 0.75–1.5.
    final openAiSpeed = 0.75 + (speed * 0.75);

    debugPrint('OpenAI TTS: voice=$voice, speed=$openAiSpeed');

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/audio/speech'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'tts-1',
          'input': text,
          'voice': voice,
          'speed': openAiSpeed,
          'response_format': 'mp3',
        }),
      );

      if (response.statusCode == 200) {
        await _playAudioBytes(response.bodyBytes, onStart);
        return true;
      } else {
        debugPrint(
            'OpenAI TTS error ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('OpenAI TTS exception: $e');
      return false;
    }
  }

  Future<void> _playAudioBytes(Uint8List bytes, void Function()? onStart) async {
    await _audioPlayer.stop();
    final source = _BytesAudioSource(bytes);
    await _audioPlayer.setAudioSource(source);
    if (onStart != null) onStart();
    await _audioPlayer.play();
    // Wait for playback to complete
    await _audioPlayer.processingStateStream
        .firstWhere((s) => s == ProcessingState.completed);
  }

  // ── Flutter TTS (device) ────────────────────────────────────────────────

  Future<void> _speakWithFlutterTts(
      String text, double speed, double pitch, String voiceId, void Function()? onStart) async {
    final pitchOff = _pitchOffset[voiceId] ?? 0.0;
    final rateOff = _rateOffset[voiceId] ?? 0.0;
    final effectivePitch = (pitch + pitchOff).clamp(0.5, 2.0);
    final effectiveRate = (speed + rateOff).clamp(0.1, 1.0);

    final voice = _resolvedVoices[voiceId];
    if (voice != null && voice['name'] != null && voice['locale'] != null) {
      try {
        await _flutterTts.setLanguage(voice['locale']!);
        await _flutterTts
            .setVoice({'name': voice['name']!, 'locale': voice['locale']!});
      } catch (e) {
        await _flutterTts.setLanguage(voice['locale'] ?? 'en-US');
      }
    } else {
      final langCode = voiceId.length >= 5 ? voiceId.substring(0, 5) : 'en-US';
      final available = await _flutterTts.isLanguageAvailable(langCode);
      await _flutterTts.setLanguage(available == true ? langCode : 'en-US');
    }

    await _flutterTts.setSpeechRate(effectiveRate);
    await _flutterTts.setPitch(effectivePitch);
    if (onStart != null) onStart();
    await _flutterTts.speak(text);
  }

  // ── Google Cloud TTS ────────────────────────────────────────────────────

  Future<bool> _speakWithGoogleCloud(
      String text, double speed, double pitch, String voiceId, String gender, void Function()? onStart) async {
    final apiKey = await AiConfigService.getTtsApiKey('google_cloud');
    if (apiKey == null || apiKey.isEmpty) return false;

    final langCode = voiceId.length >= 5 ? voiceId.substring(0, 5) : 'en-US';
    final isFemale = gender.toLowerCase() == 'female';
    final pitchOff = _pitchOffset[voiceId] ?? 0.0;
    final rateOff = _rateOffset[voiceId] ?? 0.0;

    final response = await http.post(
      Uri.parse(
          'https://texttospeech.googleapis.com/v1/text:synthesize?key=$apiKey'),
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

    if (response.statusCode == 200) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final audioContent = json['audioContent'] as String?;
        if (audioContent != null) {
          final bytes = base64Decode(audioContent);
          await _playAudioBytes(bytes, onStart);
          return true;
        }
      } catch (e) {
        debugPrint('Google Cloud TTS audio decode error: $e');
      }
    } else {
      debugPrint(
          'Google Cloud TTS error ${response.statusCode}: ${response.body}');
    }
    return false;
  }
}

// ── In-memory audio source for just_audio ─────────────────────────────────

class _BytesAudioSource extends StreamAudioSource {
  final Uint8List _bytes;

  _BytesAudioSource(this._bytes) : super(
          tag: MediaItem(
            id: 'openai-tts',
            title: 'AI Voice Response',
          ),
        );

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}
