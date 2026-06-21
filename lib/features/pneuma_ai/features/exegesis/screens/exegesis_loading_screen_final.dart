import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'deep_exegesis_result_screen.dart';

import '../models/exegesis_final_model.dart';
import '../providers/exegesis_providers_final.dart';

/// Branded loading screen shown while ILLUMINE generates the exegesis.
/// Shows inline error state with Retry button — no dialogs.
class ExegesisLoadingScreenFinal extends ConsumerStatefulWidget {
  final String subject;
  final String type; // 'verse' | 'topic'

  const ExegesisLoadingScreenFinal({
    super.key,
    required this.subject,
    required this.type,
  });

  @override
  ConsumerState<ExegesisLoadingScreenFinal> createState() =>
      _ExegesisLoadingScreenFinalState();
}

class _ExegesisLoadingScreenFinalState
    extends ConsumerState<ExegesisLoadingScreenFinal>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _rotateCtrl;
  late Animation<double> _pulse;

  String? _errorMessage;
  bool _hasNavigated = false;
  bool _isCancelled = false;
  int _progress = 0;
  Timer? _progressTimer;

  static const _phases = [
    'Investigating the original text…',
    'Engaging the Hebrew and Greek roots…',
    'Tracing the meaning through scripture…',
    'Mapping the theological landscape…',
    'Looking for echoes across the canon…',
    'Preparing your deep study…',
  ];

  int _phaseIndex = 0;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
    _scheduleNextPhase();

    _progressTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (mounted && _progress < 96) {
        final increment = _progress < 70 ? 2 : 1;
        setState(() => _progress += increment);
        if (_progress > 96) setState(() => _progress = 96);
      }
    });
  }

  void _scheduleNextPhase() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted || _errorMessage != null) return;
      setState(() => _phaseIndex = (_phaseIndex + 1) % _phases.length);
      _scheduleNextPhase();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _handleError(Object e) {
    if (!mounted) return;
    setState(() {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    });
    _pulseCtrl.stop();
    _rotateCtrl.stop();
  }

  void _retry() {
    Navigator.of(context).pop();
  }

  Future<bool> _showCancelDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0E1023),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Exegesis?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Leaving now will cancel the exegesis generation. '
          'The result will not be saved. Are you sure?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final isVerse = widget.type == 'verse';
    final accent = isVerse ? const Color(0xFF5B8DEF) : const Color(0xFF9B59B6);

    // Listen for completion / error
    if (isVerse) {
      ref.listen<AsyncValue<VerseExegesis?>>(
        verseExegesisNotifierProvider,
        (_, next) {
          next.whenOrNull(
            data: (result) {
              if (result != null && !_hasNavigated) {
                _hasNavigated = true;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => DeepExegesisResultScreen(id: result.id, result: result),
                  ),
                );
              }
            },
            error: (e, _) => _handleError(e),
          );
        },
      );
    } else {
      ref.listen<AsyncValue<TopicExegesis?>>(
        topicExegesisNotifierProvider,
        (_, next) {
          next.whenOrNull(
            data: (result) {
              if (result != null && !_hasNavigated && !_isCancelled) {
                _hasNavigated = true;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => DeepExegesisResultScreen(id: result.id, result: result),
                  ),
                );
              }
            },
            error: (e, _) => _handleError(e),
          );
        },
      );
    }

    if (_errorMessage != null) {
      return _buildErrorScreen(accent);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final confirmed = await _showCancelDialog();
          if (confirmed && mounted) {
            _isCancelled = true;
            _pulseCtrl.stop();
            _rotateCtrl.stop();
            Navigator.of(context).pop();
          }
        }
      },
      child: _buildLoadingScreen(accent),
    );
  }

  Widget _buildLoadingScreen(Color accent) {
    return Scaffold(
      backgroundColor: const Color(0xFF060711),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Warning Banner ─────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 32),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.amber, size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Please stay on this screen. '
                          'Leaving will cancel the exegesis.',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.amber,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Animated orb ────────────────────────────────
                AnimatedBuilder(
                  animation: Listenable.merge([_pulseCtrl, _rotateCtrl]),
                  builder: (ctx, _) {
                    return SizedBox.square(
                      dimension: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow
                          Transform.scale(
                            scale: 1 + _pulse.value * 0.15,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withOpacity(0.18),
                                    blurRadius: 60,
                                    spreadRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Rotating ring
                          Transform.rotate(
                            angle: _rotateCtrl.value * 2 * pi,
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  colors: [
                                    accent.withOpacity(0.9),
                                    accent.withOpacity(0.05),
                                    accent.withOpacity(0.9),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Inner circle with icon
                          Container(
                            width: 108,
                            height: 108,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  accent.withOpacity(0.35),
                                  const Color(0xFF060711),
                                ],
                              ),
                            ),
                            child: Center(
                              child: FadeTransition(
                                opacity: _pulse,
                                child: Icon(
                                  Icons.auto_awesome,
                                  color: accent,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 48),

                // ── ILLUMINE label ───────────────────────────────
                Text(
                  'ILLUMINE',
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 14),

                // ── Subject ──────────────────────────────────────
                Text(
                  widget.subject,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 36),

                // ── Phase label ──────────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position:
                          Tween(begin: const Offset(0, 0.1), end: Offset.zero)
                              .animate(anim),
                      child: child,
                    ),
                  ),
                  child: Text(
                    _phases[_phaseIndex],
                    key: ValueKey(_phaseIndex),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                const SizedBox(height: 12),
                Text(
                  '$_progress%',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 220,
                  child: LinearProgressIndicator(
                    value: _progress / 100.0,
                    backgroundColor: accent.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(accent),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'This may take up to a minute',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.25),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(Color accent) {
    return Scaffold(
      backgroundColor: const Color(0xFF060711),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 38,
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                'Study Generation Failed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                'ILLUMINE encountered a problem while processing your request.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 14,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Error detail box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Text(
                  _errorMessage ?? 'Unknown error',
                  style: TextStyle(
                    color: Colors.redAccent.withOpacity(0.9),
                    fontSize: 12,
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),

              // Retry button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text(
                    'Try Again',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                    shadowColor: accent.withOpacity(0.4),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Go back link
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Back to Exegesis',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
