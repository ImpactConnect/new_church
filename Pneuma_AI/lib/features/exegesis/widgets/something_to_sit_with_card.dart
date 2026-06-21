import 'package:flutter/material.dart';

/// Card displaying the final meditation prompt
/// 
/// Design specs:
/// - Sage green tint (#82b882 at 9% opacity)
/// - 15sp italic Spectral
/// - Generous padding (20px)
/// - "Journal This" button below
/// - 🤔 icon header
class SomethingToSitWithCard extends StatelessWidget {
  final String prompt;
  final VoidCallback? onJournal;

  const SomethingToSitWithCard({
    super.key,
    required this.prompt,
    this.onJournal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    const lifeSage = Color(0xFF82B882);
    final backgroundColor = isDark
        ? lifeSage.withOpacity(0.09)
        : lifeSage.withOpacity(0.05);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: lifeSage.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            '🤔 SOMETHING TO SIT WITH',
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: lifeSage,
            ),
          ),
          const SizedBox(height: 16),
          
          // Meditation prompt
          Text(
            prompt,
            style: const TextStyle(
              fontFamily: 'Spectral',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              height: 1.75,
            ),
          ),
          
          // Journal button
          if (onJournal != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onJournal,
                icon: const Icon(Icons.edit_note_outlined, size: 18),
                label: const Text('Journal This'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: lifeSage,
                  side: BorderSide(color: lifeSage.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
