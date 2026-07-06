import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/voice_preferences_provider.dart';
import '../services/tts_service.dart';
import 'package:church_mobile/features/bible_ai/services/ai_config_service.dart';

class VoicePreferencesScreen extends ConsumerWidget {
  const VoicePreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(voicePreferencesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Preferences'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text(
            'ScriptTalk Audio Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Customize how the AI voices sound when speaking to you.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),

          // Voice Selection
          const Text('Nigerian Voice Profile', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: prefs.voiceId,
                items: const [
                  DropdownMenuItem(value: 'en-NG-1', child: Text('Nigerian Female (Standard)')),
                  DropdownMenuItem(value: 'en-NG-2', child: Text('Nigerian Female (Neural)')),
                  DropdownMenuItem(value: 'en-NG-3', child: Text('Nigerian Male (Standard)')),
                  DropdownMenuItem(value: 'en-NG-4', child: Text('Nigerian Male (Neural)')),
                  DropdownMenuItem(value: 'en-US-1', child: Text('American Female')),
                  DropdownMenuItem(value: 'en-US-2', child: Text('American Male')),
                  DropdownMenuItem(value: 'en-GB-1', child: Text('British Female')),
                  DropdownMenuItem(value: 'en-GB-2', child: Text('British Male')),
                  DropdownMenuItem(value: 'en-ZA-1', child: Text('South African Female')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref.read(voicePreferencesProvider.notifier).setVoiceId(val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Speech Speed
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Speech Speed', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${prefs.speechSpeed.toStringAsFixed(1)}x', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: prefs.speechSpeed,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            label: '${prefs.speechSpeed.toStringAsFixed(1)}x',
            onChanged: (val) {
              ref.read(voicePreferencesProvider.notifier).setSpeechSpeed(val);
            },
          ),
          const SizedBox(height: 24),

          // Speech Pitch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Speech Pitch', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(prefs.speechPitch.toStringAsFixed(1), style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: prefs.speechPitch,
            min: 0.5,
            max: 1.5,
            divisions: 10,
            label: prefs.speechPitch.toStringAsFixed(1),
            onChanged: (val) {
              ref.read(voicePreferencesProvider.notifier).setSpeechPitch(val);
            },
          ),
          
          const SizedBox(height: 48),
          
          // Test button
          Center(
            child: ElevatedButton.icon(
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Testing voice profile...')),
                );
                try {
                  final ttsProvider = await AiConfigService.getDefaultTtsProvider();
                  await ref.read(ttsServiceProvider).speak(
                        'This is a sample of what I will sound like when speaking to you.',
                        ttsProvider,
                        speed: prefs.speechSpeed,
                        pitch: prefs.speechPitch,
                        voiceId: prefs.voiceId,
                      );
                } catch (e) {
                  debugPrint('Test voice failed: $e');
                }
              },
              icon: const Icon(Icons.volume_up),
              label: const Text('Test Voice'),
            ),
          ),
        ],
      ),
    );
  }
}
