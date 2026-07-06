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
    with TickerProviderStateMixin {
  late RecorderController _recorderController;
  final _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isAiSpeaking = false;

  // Pulse animation for avatar (always running, but only applied when active)
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Waveform animation controller for AI speaking bars — only starts when AI speaks
  late AnimationController _waveController;

  // 2-second delay timer before recording actually starts
  Timer? _recordDelayTimer;
  bool _isWaitingToRecord = false; // holding but not yet recording

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

    // Separate controller just for the speaking bars — stopped by default
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _recordDelayTimer?.cancel();
    try {
      ref.read(ttsServiceProvider).stop();
    } catch (_) {}
    _recorderController.dispose();
    _audioRecorder.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  // ── Recording ────────────────────────────────────────────────────────────

  void _onHoldStart() {
    if (_isProcessing || _isAiSpeaking) return;

    // Wait 2 seconds before actually starting to record
    setState(() => _isWaitingToRecord = true);

    _recordDelayTimer = Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;
      await _startRecording();
    });
  }

  void _onHoldEnd() {
    // If the 2-second window hasn't elapsed yet, cancel — nothing was said
    if (_isWaitingToRecord && !_isRecording) {
      _recordDelayTimer?.cancel();
      setState(() => _isWaitingToRecord = false);
      return;
    }
    _stopRecordingAndSend();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        setState(() {
          _isWaitingToRecord = false;
          _isRecording = true;
        });
        await _recorderController.record();
      } else {
        setState(() => _isWaitingToRecord = false);
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
      if (mounted) setState(() { _isWaitingToRecord = false; _isRecording = false; });
    }
  }

  Future<void> _stopRecordingAndSend() async {
    setState(() {
      _isRecording = false;
      _isWaitingToRecord = false;
      _isProcessing = true;
    });

    try {
      final path = await _recorderController.stop();
      if (path == null) {
        if (mounted) setState(() => _isProcessing = false);
        return;
      }

      final sttProvider = await AiConfigService.getDefaultSttProvider();
      final transcribedText =
          await ref.read(sttServiceProvider).transcribeAudio(path, sttProvider);

      // Ignore empty / noise-only transcriptions
      final cleaned = transcribedText?.trim() ?? '';
      if (cleaned.isEmpty || cleaned.length < 3) {
        debugPrint('STT: nothing meaningful detected, ignoring.');
        if (mounted) setState(() => _isProcessing = false);
        return;
      }

      await ref
          .read(askSpeakWithControllerProvider.notifier)
          .sendMessage(cleaned, isVoiceMode: true);

      if (mounted) {
        final state = ref.read(askSpeakWithControllerProvider);
        if (state != null && state.messages.isNotEmpty) {
          final latestReply = state.messages.last;
          if (!latestReply.isUser) {
            // Hand off state management to _speakAiReply
            _speakAiReply(latestReply.message);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Error stopping record: $e');
    }
    // If we reach here without returning, we need to manually clear the processing state
    if (mounted) setState(() => _isProcessing = false);
  }

  // ── AI Speaking ──────────────────────────────────────────────────────────

  Future<void> _speakAiReply(String text) async {
    if (!mounted) return;

    try {
      final prefs = ref.read(voicePreferencesProvider);
      final ttsProvider = await AiConfigService.getDefaultTtsProvider();

      await ref.read(ttsServiceProvider).speak(
            text,
            ttsProvider,
            speed: prefs.speechSpeed,
            pitch: prefs.speechPitch,
            voiceId: prefs.voiceId,
            gender: widget.figure.gender,
            onStart: () {
              if (!mounted) return;
              setState(() {
                _isProcessing = false;
                _isAiSpeaking = true;
              });
              _waveController.repeat(reverse: true);
            },
          );
    } catch (e) {
      debugPrint('TTS error: $e');
    } finally {
      if (mounted) {
        _waveController.stop();
        _waveController.reset();
        setState(() {
          _isProcessing = false;
          _isAiSpeaking = false;
        });
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String statusText = _isProcessing
        ? 'Thinking...'
        : _isAiSpeaking
            ? 'Speaking...'
            : _isRecording
                ? 'Listening...'
                : _isWaitingToRecord
                    ? 'Get ready...'
                    : 'Hold to Speak';

    final Color statusColor = _isRecording
        ? Colors.red
        : _isAiSpeaking
            ? colorScheme.primary
            : _isWaitingToRecord
                ? Colors.orange
                : colorScheme.onSurfaceVariant;

    final bool buttonActive = _isRecording || _isWaitingToRecord;

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
                    scale: (buttonActive || _isAiSpeaking)
                        ? _pulseAnimation.value
                        : 1.0,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primaryContainer,
                        boxShadow: [
                          if (buttonActive || _isAiSpeaking)
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

              // ── Waveform area ──
              // Recording waveform: shown while user speaks
              // AI speaking bars: shown ONLY when _isAiSpeaking
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: SizedBox(
                  key: ValueKey(_isRecording
                      ? 'recording'
                      : _isAiSpeaking
                          ? 'speaking'
                          : 'idle'),
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
              ),

              const SizedBox(height: 40),

              // Push-to-Talk button
              GestureDetector(
                onLongPressStart: (_) => _onHoldStart(),
                onLongPressEnd: (_) => _onHoldEnd(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: buttonActive ? 100 : 80,
                  height: buttonActive ? 100 : 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording
                        ? Colors.red
                        : _isWaitingToRecord
                            ? Colors.orange
                            : colorScheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording
                                ? Colors.red
                                : _isWaitingToRecord
                                    ? Colors.orange
                                    : colorScheme.primary)
                            .withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording
                        ? Icons.mic
                        : _isWaitingToRecord
                            ? Icons.hourglass_top
                            : Icons.mic_none,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  /// Animated speaking indicator bars — only animates via _waveController
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
            controller: _waveController,
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
