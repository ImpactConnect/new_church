import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import '../providers/speak_with_providers.dart';
import '../models/speak_with_models.dart';

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
    _initRecorder();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initRecorder() async {
    _recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 16000;
  }

  @override
  void dispose() {
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
        // In a full implementation, you'd save to a path and send to Whisper API.
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
        // Placeholder: Here you would send `path` to Whisper STT API
        // For demonstration, we simulate transcription:
        await Future.delayed(const Duration(seconds: 1));
        final transcribedText = "This is a simulated transcription from voice.";
        
        // Add to standard conversation state
        await ref.read(askSpeakWithControllerProvider.notifier).sendMessage(transcribedText);
        
        // After AI replies, trigger TTS playback
        _simulateAiSpeech();
      }
    } catch (e) {
      debugPrint('Error stopping record: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _simulateAiSpeech() async {
    setState(() => _isAiSpeaking = true);
    // Placeholder: Trigger flutter_tts or Google Cloud TTS here
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _isAiSpeaking = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(askSpeakWithControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : colorScheme.surfaceContainerLowest,
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
        child: Column(
          children: [
            const Spacer(),
            
            // Central Figure Avatar
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: (_isRecording || _isAiSpeaking) ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primaryContainer,
                      boxShadow: [
                        if (_isRecording || _isAiSpeaking)
                          BoxShadow(
                            color: _isRecording ? Colors.red.withValues(alpha: 0.3) : colorScheme.primary.withValues(alpha: 0.3),
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
            const SizedBox(height: 32),
            Text(
              widget.figure.name,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _isProcessing 
                ? 'Processing...' 
                : _isAiSpeaking 
                  ? 'Speaking...' 
                  : _isRecording 
                    ? 'Listening...' 
                    : 'Hold to Speak',
              style: TextStyle(
                color: _isRecording ? Colors.red : colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            
            // Audio Waveforms
            SizedBox(
              height: 100,
              child: _isRecording
                  ? AudioWaveforms(
                      size: Size(MediaQuery.of(context).size.width, 100),
                      recorderController: _recorderController,
                      enableGesture: false,
                      waveStyle: WaveStyle(
                        waveColor: Colors.red,
                        extendWaveform: true,
                        showMiddleLine: false,
                      ),
                    )
                  : _isAiSpeaking
                      ? Center(child: Text("🔊 Waveform Placeholder", style: TextStyle(color: colorScheme.primary)))
                      : const SizedBox(),
            ),
            
            const SizedBox(height: 48),

            // Push-to-Talk Button
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
                      color: (_isRecording ? Colors.red : colorScheme.primary).withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
