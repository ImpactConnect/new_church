import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provides the shared preferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize this in main.dart');
});

class VoicePreferences {
  final String voiceId;
  final double speechSpeed;
  final double speechPitch;

  const VoicePreferences({
    this.voiceId = 'en-NG-1', // Default to first option
    this.speechSpeed = 1.0,
    this.speechPitch = 1.0,
  });

  VoicePreferences copyWith({
    String? voiceId,
    double? speechSpeed,
    double? speechPitch,
  }) {
    return VoicePreferences(
      voiceId: voiceId ?? this.voiceId,
      speechSpeed: speechSpeed ?? this.speechSpeed,
      speechPitch: speechPitch ?? this.speechPitch,
    );
  }
}

class VoicePreferencesNotifier extends Notifier<VoicePreferences> {
  static const _keyVoiceId = 'speak_with_voice_id';
  static const _keySpeechSpeed = 'speak_with_speech_speed';
  static const _keySpeechPitch = 'speak_with_speech_pitch';

  late SharedPreferences _prefs;

  @override
  VoicePreferences build() {
    // Note: To use this notifier synchronously, make sure SharedPreferences
    // is already initialized and provided correctly or use an async approach.
    // For simplicity, we assume we load it and watch `sharedPreferencesProvider` 
    // or handle loading asynchronously.
    
    // Attempting to read synchronously if possible, or we return a default 
    // and let an async load override it.
    
    _prefs = ref.watch(sharedPreferencesProvider);
    
    final voiceId = _prefs.getString(_keyVoiceId) ?? 'en-NG-1';
    final speed = _prefs.getDouble(_keySpeechSpeed) ?? 1.0;
    final pitch = _prefs.getDouble(_keySpeechPitch) ?? 1.0;

    return VoicePreferences(
      voiceId: voiceId,
      speechSpeed: speed,
      speechPitch: pitch,
    );
  }

  Future<void> setVoiceId(String id) async {
    await _prefs.setString(_keyVoiceId, id);
    state = state.copyWith(voiceId: id);
  }

  Future<void> setSpeechSpeed(double speed) async {
    await _prefs.setDouble(_keySpeechSpeed, speed);
    state = state.copyWith(speechSpeed: speed);
  }

  Future<void> setSpeechPitch(double pitch) async {
    await _prefs.setDouble(_keySpeechPitch, pitch);
    state = state.copyWith(speechPitch: pitch);
  }
}

final voicePreferencesProvider =
    NotifierProvider<VoicePreferencesNotifier, VoicePreferences>(() {
  return VoicePreferencesNotifier();
});
