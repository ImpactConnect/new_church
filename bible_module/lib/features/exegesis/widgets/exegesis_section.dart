import 'package:flutter/material.dart';

/// Generic section widget for narrative sections in Exegesis v2
/// Used for: Historical Moment, What Was Being Said, In The Whole Story, 
/// What This Means For You, Grammatical Highlights
class ExegesisSection extends StatelessWidget {
  final String emoji;
  final String label;
  final String content;
  final Color? accentColor;
  final bool showDivider;

  const ExegesisSection({
    super.key,
    required this.emoji,
    required this.label,
    required this.content,
    this.accentColor,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveAccentColor = accentColor ?? theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDivider) ...[
          const SizedBox(height: 24),
          Divider(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
            height: 1,
          ),
        ],
        const SizedBox(height: 24),
        
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: effectiveAccentColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Section content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            content,
            style: const TextStyle(
              fontFamily: 'Spectral',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.75,
            ),
          ),
        ),
      ],
    );
  }
}

/// Historical Moment section (🕰️)
class HistoricalMomentSection extends StatelessWidget {
  final String content;

  const HistoricalMomentSection({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return ExegesisSection(
      emoji: '🕰️',
      label: 'Historical Moment',
      content: content,
      accentColor: const Color(0xFFD4826A), // momentEmber
      showDivider: false,
    );
  }
}

/// What Was Being Said section (💬)
class WhatWasBeingSaidSection extends StatelessWidget {
  final String content;

  const WhatWasBeingSaidSection({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return ExegesisSection(
      emoji: '💬',
      label: 'What Was Being Said',
      content: content,
    );
  }
}

/// In The Whole Story section (🌐)
class InTheWholeStorySection extends StatelessWidget {
  final String content;

  const InTheWholeStorySection({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return ExegesisSection(
      emoji: '🌐',
      label: 'In The Whole Story',
      content: content,
      accentColor: const Color(0xFF6898D4), // storyBlue
    );
  }
}

/// What This Means For You section (💡)
class WhatThisMeansForYouSection extends StatelessWidget {
  final String content;

  const WhatThisMeansForYouSection({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return ExegesisSection(
      emoji: '💡',
      label: 'What This Means For You',
      content: content,
      accentColor: const Color(0xFF82B882), // lifeSage
    );
  }
}

/// Grammatical Highlights section (📝) - Go Deep only
class GrammaticalHighlightsSection extends StatelessWidget {
  final String content;

  const GrammaticalHighlightsSection({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return ExegesisSection(
      emoji: '📝',
      label: 'Grammatical Highlights',
      content: content,
      accentColor: const Color(0xFF9878C8), // wordPurple
    );
  }
}
