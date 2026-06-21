import 'package:flutter/material.dart';
import '../models/exegesis_result_v3_model.dart';

/// Life event narrative card for character studies
/// Uses italic body font with fine-grain texture overlay
class LifeEventNarrativeCard extends StatelessWidget {
  final LifeEvent event;
  final Color accentColor;

  const LifeEventNarrativeCard({
    super.key,
    required this.event,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0f1020) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: accentColor,
            width: 3,
          ),
          top: BorderSide(
            color: accentColor.withOpacity(0.2),
          ),
          right: BorderSide(
            color: accentColor.withOpacity(0.2),
          ),
          bottom: BorderSide(
            color: accentColor.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reference
          Text(
            event.reference,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 8),
          
          // Title
          Text(
            event.title,
            style: const TextStyle(
              fontFamily: 'Spectral',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          
          // Narrative (italic)
          Text(
            event.narrative,
            style: const TextStyle(
              fontFamily: 'Spectral',
              fontSize: 14,
              fontStyle: FontStyle.italic,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 12),
          
          // Theological Significance
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.theologicalSignificance,
                    style: const TextStyle(
                      fontFamily: 'Spectral',
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
