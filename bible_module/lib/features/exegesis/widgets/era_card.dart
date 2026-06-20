import 'package:flutter/material.dart';

/// Era card for theme canonical development
/// Displays era name as header badge with left border in theme color
class EraCard extends StatelessWidget {
  final String eraName;
  final String content;
  final Color accentColor;

  const EraCard({
    super.key,
    required this.eraName,
    required this.content,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
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
          // Era name badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              eraName.toUpperCase(),
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Era content
          Text(
            content,
            style: const TextStyle(
              fontFamily: 'Spectral',
              fontSize: 14,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
