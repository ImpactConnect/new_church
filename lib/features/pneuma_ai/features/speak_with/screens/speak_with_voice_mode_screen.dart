import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import '../providers/speak_with_providers.dart';
import '../providers/voice_preferences_provider.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';
import '../models/speak_with_models.dart';
import 'package:church_mobile/features/bible_ai/services/ai_config_service.dart';

class SpeakWithVoiceModeScreen extends ConsumerStatefulWidget {
  final BiblicalFigure figure;

  const SpeakWithVoiceModeScreen({super.key, required this.figure});

  @override
  ConsumerState<SpeakWithVoiceModeScreen> createState() =>
      _SpeakWithVoiceModeScreenState();
}

class _SpeakWithVoiceModeScreenState extends ConsumerState<SpeakWithVoiceModeScreen>
    with SingleTickerProviderStateMixin {
  late RecorderController _recorderController;
  final _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isAiSpeaking = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _recorderController = RecorderController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    try {
      ref.read(ttsServiceProvider).stop();
    } catch (_) {}
    _recorderController.dispose();
    _audioRecorder.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        setState(() => _isRecording = true);
        await _recorderController.record();
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
    }
  }

  Future<void> _stopRecordingAndSend() async {
    setState(() {
      _isRecording = false;
      _isProcessing = true;
    });

    try {
      final path = await _recorderController.stop();
      if (path != null) {
        final sttProvider = await AiConfigService.getDefaultSttProvider();

        // Transcribe audio
        final transcribedText =
            await ref.read(sttServiceProvider).transcribeAudio(path, sttProvider);

        if (transcribedText != null && transcribedText.isNotEmpty) {
          // Send message to AI and await reply
          await ref
              .read(askSpeakWithControllerProvider.notifier)
              .sendMessage(transcribedText);

          // Get AI's latest reply and speak it
          if (mounted) {
            final state = ref.read(askSpeakWithControllerProvider);
            if (state != null && state.messages.isNotEmpty) {
              final latestReply = state.messages.last;
              if (!latestReply.isUser) {
                _speakAiReply(latestReply.message);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error stopping record: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _speakAiReply(String text) async {
    if (!mounted) return;
    setState(() => _isAiSpeaking = true);

    try {
      final prefs = ref.read(voicePreferencesProvider);
      final ttsProvider = await AiConfigService.getDefaultTtsProvider();

      await ref.read(ttsServiceProvider).speak(
            text,
            ttsProvider,
            speed: prefs.speechSpeed,
            pitch: prefs.speechPitch,
            voiceId: prefs.voiceId,
          );
    } catch (e) {
      debugPrint('TTS error: $e');
    } finally {
      if (mounted) setState(() => _isAiSpeaking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Status text and color based on state
    final String statusText = _isProcessing
        ? 'Thinking...'
        : _isAiSpeaking
            ? 'Speaking...'
            : _isRecording
                ? 'Listening...'
                : 'Hold to Speak';
    final Color statusColor = _isRecording
        ? Colors.red
        : _isAiSpeaking
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor:
          isDark ? Colors.black : colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Switch to Text Mode',
        ),
        centerTitle: true,
        title: Text(
          'Voice Mode',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

            // Central Figure Avatar with pulse animation
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: (_isRecording || _isAiSpeaking)
                      ? _pulseAnimation.value
                      : 1.0,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primaryContainer,
                      boxShadow: [
                        if (_isRecording || _isAiSpeaking)
                          BoxShadow(
                            color: _isRecording
                                ? Colors.red.withValues(alpha: 0.3)
                                : colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.figure.avatarEmoji,
                        style: const TextStyle(fontSize: 72),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            Text(
              widget.figure.name,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                statusText,
                key: ValueKey(statusText),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),

            const Spacer(),

            // Waveform area — recording waveform or speaking bars
            SizedBox(
              height: 80,
              child: _isRecording
                  ? AudioWaveforms(
                      size: Size(MediaQuery.of(context).size.width, 80),
                      recorderController: _recorderController,
                      enableGesture: false,
                      waveStyle: const WaveStyle(
                        waveColor: Colors.red,
                        extendWaveform: true,
                        showMiddleLine: false,
                      ),
                    )
                  : _isAiSpeaking
                      ? _buildSpeakingBars(colorScheme)
                      : const SizedBox(),
            ),

            const SizedBox(height: 40),

            // Push-to-Talk button
            GestureDetector(
              onLongPressStart: (_) => _startRecording(),
              onLongPressEnd: (_) => _stopRecordingAndSend(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isRecording ? 100 : 80,
                height: _isRecording ? 100 : 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording ? Colors.red : colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? Colors.red : colorScheme.primary)
                          .withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      )),
    );
  }

  /// Animated speaking indicator — 5 bars that animate up/down
  Widget _buildSpeakingBars(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(7, (i) {
        final delay = i * 0.15;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _AnimatedBar(
            color: colorScheme.primary,
            delay: delay,
            controller: _pulseController,
          ),
        );
      }),
    );
  }
}

class _AnimatedBar extends StatelessWidget {
  final Color color;
  final double delay;
  final AnimationController controller;

  const _AnimatedBar({
    required this.color,
    required this.delay,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // Offset the animation cycle by delay to create wave effect
        final value = (controller.value + delay) % 1.0;
        final barHeight = 12.0 + (Curves.easeInOut.transform(value) * 44.0);
        return Container(
          width: 6,
          height: barHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      },
    );
  }
}
