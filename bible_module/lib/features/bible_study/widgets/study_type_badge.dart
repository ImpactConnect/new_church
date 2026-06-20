import 'package:flutter/material.dart';
import '../models/bible_study_models.dart';

// ── Study Type Badge ──────────────────────────────────────────────────────────
class StudyTypeBadge extends StatelessWidget {
  final StudyType type;
  final bool small;

  const StudyTypeBadge({super.key, required this.type, this.small = true});

  @override
  Widget build(BuildContext context) {
    final accent = Color(type.accentValue);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 10,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(type.emoji, style: TextStyle(fontSize: small ? 10 : 13)),
          const SizedBox(width: 4),
          Text(
            type.label.toUpperCase(),
            style: TextStyle(
              fontSize: small ? 9 : 11,
              fontWeight: FontWeight.w800,
              color: accent,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scripture Chip ────────────────────────────────────────────────────────────
class ScriptureChip extends StatelessWidget {
  final String reference;
  final VoidCallback? onTap;
  final Color? color;

  const ScriptureChip({
    super.key,
    required this.reference,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF4F63D2);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: c.withOpacity(0.25), width: 1),
        ),
        child: Text(
          reference,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: c,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

// ── Word Insight Card ─────────────────────────────────────────────────────────
class WordInsightCard extends StatelessWidget {
  final WordInsight insight;
  final Color? accentColor;

  const WordInsightCard({super.key, required this.insight, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = accentColor ?? const Color(0xFF4F63D2);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0E0F1C)
            : const Color(0xFFF8F7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Text(
                  insight.isHebrew ? '🇮🇱' : '🇬🇷',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  insight.original,
                  style: TextStyle(
                    fontSize: 20,
                    color: accent,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.transliteration,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          insight.strongsNumber,
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"${insight.englishWord.toUpperCase()}"',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: accent,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  insight.insight,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (insight.disambiguationNote != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.amber.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      insight.disambiguationNote!,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Narrative Event Card ──────────────────────────────────────────────────────
class NarrativeEventCard extends StatelessWidget {
  final NarrativeEvent event;
  final int eventIndex;
  final Color? accentColor;

  const NarrativeEventCard({
    super.key,
    required this.event,
    required this.eventIndex,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = accentColor ?? const Color(0xFF4F63D2);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0E0F1C)
            : const Color(0xFFFAF9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Event number badge
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F63D2), Color(0xFF8B3FC0)],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$eventIndex',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScriptureChip(reference: event.primaryReference, color: accent),
                const SizedBox(height: 8),
                Text(
                  event.eventTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  event.narrative,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accent.withOpacity(0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WHAT GOD REVEALS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: accent,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event.whatGodReveals,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                if (event.keyWordInsight != null) ...[
                  const SizedBox(height: 10),
                  WordInsightCard(
                    insight: event.keyWordInsight!,
                    accentColor: accent,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Study Progress Ring (stub) ─────────────────────────────────────────────────
class StudyProgressRing extends StatelessWidget {
  final double value;
  final Color color;
  final double size;

  const StudyProgressRing({
    super.key,
    required this.value,
    required this.color,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        value: value,
        backgroundColor: color.withOpacity(0.15),
        valueColor: AlwaysStoppedAnimation<Color>(color),
        strokeWidth: 4,
      ),
    );
  }
}
