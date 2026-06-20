import 'package:flutter/material.dart';
import '../models/bible_study_models.dart';

class BibleStudyLoadingScreen extends StatelessWidget {
  final StudyType studyType;
  final String subject;

  const BibleStudyLoadingScreen({
    super.key,
    required this.studyType,
    required this.subject,
  });

  static const _messages = [
    'Consulting the scriptures...',
    'Tracing the biblical narrative...',
    'Weaving the original languages...',
    'Gathering theological threads...',
    'Preparing your study...',
    'Connecting both testaments...',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF09090F), Color(0xFF131428)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Background gradient orbs
            Positioned(
              top: -80,
              left: -80,
              child: _GlowOrb(color: const Color(0xFF4F63D2), size: 300),
            ),
            Positioned(
              bottom: 0,
              right: -60,
              child: _GlowOrb(color: const Color(0xFF8B3FC0), size: 240),
            ),
            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated emoji icon
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(seconds: 2),
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Text(
                      studyType.emoji,
                      style: const TextStyle(fontSize: 64),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Generating ${studyType.label} Study',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subject,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  // Pulsing loader
                  Container(
                    width: 200,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: const _AnimatedLoadingBar(),
                  ),
                  const SizedBox(height: 24),
                  _CyclingText(messages: _messages),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.05),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 60,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _AnimatedLoadingBar extends StatefulWidget {
  const _AnimatedLoadingBar();

  @override
  State<_AnimatedLoadingBar> createState() => _AnimatedLoadingBarState();
}

class _AnimatedLoadingBarState extends State<_AnimatedLoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _anim = Tween<double>(begin: 0.0, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return FractionallySizedBox(
          widthFactor: _anim.value,
          alignment: Alignment.centerLeft,
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                colors: [Color(0xFF4F63D2), Color(0xFF8B3FC0)],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CyclingText extends StatefulWidget {
  final List<String> messages;
  const _CyclingText({required this.messages});

  @override
  State<_CyclingText> createState() => _CyclingTextState();
}

class _CyclingTextState extends State<_CyclingText> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _cycle();
  }

  Future<void> _cycle() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) break;
      setState(() {
        _index = (_index + 1) % widget.messages.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Text(
        widget.messages[_index],
        key: ValueKey(_index),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
