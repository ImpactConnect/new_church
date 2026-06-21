import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/exegesis_result_v2_model.dart';

/// Hero card displaying the big picture insight - the first content user sees
/// 
/// Design specs:
/// - Large padding (24px all sides)
/// - Serif font (Spectral) 17sp italic
/// - Mode-specific tint: Amber (Understand) / Blue (Go Deep)
/// - Label: "✨ THE BIG PICTURE" (9sp uppercase mono)
/// - Tappable for share sheet
/// - Long-press for add to notes
class BigPictureHeroCard extends StatelessWidget {
  final String bigPicture;
  final ExegesisMode mode;
  final VoidCallback? onShare;
  final VoidCallback? onAddToNotes;

  const BigPictureHeroCard({
    super.key,
    required this.bigPicture,
    required this.mode,
    this.onShare,
    this.onAddToNotes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Mode-specific colors
    final tintColor = mode == ExegesisMode.understand
        ? const Color(0xFFD4A86A) // Amber
        : const Color(0xFF6898D4); // Blue
    
    final backgroundColor = isDark
        ? tintColor.withOpacity(0.10)
        : tintColor.withOpacity(0.05);

    return GestureDetector(
      onTap: onShare,
      onLongPress: () {
        if (onAddToNotes != null) {
          HapticFeedback.mediumImpact();
          onAddToNotes!();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: tintColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Row(
              children: [
                Text(
                  '✨ THE BIG PICTURE',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: tintColor,
                  ),
                ),
                const Spacer(),
                if (onShare != null)
                  Icon(
                    Icons.share_outlined,
                    size: 16,
                    color: tintColor.withOpacity(0.6),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Big Picture Content
            Text(
              bigPicture,
              style: const TextStyle(
                fontFamily: 'Spectral',
                fontSize: 17,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
