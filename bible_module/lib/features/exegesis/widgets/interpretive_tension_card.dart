import 'package:flutter/material.dart';
import '../models/exegesis_result_v2_model.dart';

/// Presents scholarly disagreements warmly (Go Deep mode only)
/// Two-column layout on desktop, stacked on mobile
class InterpretiveTensionCard extends StatelessWidget {
  final InterpretiveTension tension;

  const InterpretiveTensionCard({
    super.key,
    required this.tension,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 600;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isDark ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header with icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚖️',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tension.question,
                    style: const TextStyle(
                      fontFamily: 'Spectral',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Positions (two-column or stacked)
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildPosition(context, 'A', tension.positionA)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildPosition(context, 'B', tension.positionB)),
                ],
              )
            else
              Column(
                children: [
                  _buildPosition(context, 'A', tension.positionA),
                  const SizedBox(height: 12),
                  _buildPosition(context, 'B', tension.positionB),
                ],
              ),

            // Common ground footer (green tint band)
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF82B882).withOpacity(0.09),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COMMON GROUND',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tension.commonGround,
                    style: const TextStyle(
                      fontFamily: 'Spectral',
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosition(BuildContext context, String label, TensionPosition position) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.1),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Position label
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF6898D4).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6898D4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  position.label,
                  style: const TextStyle(
                    fontFamily: 'Spectral',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Reasoning
          Text(
            position.explanation,
            style: const TextStyle(
              fontFamily: 'Spectral',
              fontSize: 13,
              height: 1.6,
            ),
          ),

          // Supporting verses
          if (position.supportingVerses.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: position.supportingVerses.map((verse) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  verse,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
