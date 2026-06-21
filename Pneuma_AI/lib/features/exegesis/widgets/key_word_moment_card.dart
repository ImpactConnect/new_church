import 'package:flutter/material.dart';
import '../models/exegesis_result_v2_model.dart';

/// Card displaying the key word discovery moment with original language insight
/// 
/// Design specs:
/// - Original script: 22sp Spectral, centered
/// - Transliteration: 12sp JetBrains Mono, below script
/// - Strong's number: Hidden in Understand, tappable chip in Go Deep
/// - Discovery text: 15sp Spectral body
/// - Purple accent tint (#9878c8)
/// 
/// Interaction:
/// - Understand mode: Tap shows minimal "What this word means" card
/// - Go Deep mode: Tap opens full word study bottom sheet
class KeyWordMomentCard extends StatelessWidget {
  final KeyWordMoment keyWord;
  final ExegesisMode mode;
  final VoidCallback? onTapWord;

  const KeyWordMomentCard({
    super.key,
    required this.keyWord,
    required this.mode,
    this.onTapWord,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    const wordPurple = Color(0xFF9878C8);
    final backgroundColor = isDark
        ? wordPurple.withOpacity(0.09)
        : wordPurple.withOpacity(0.05);

    return GestureDetector(
      onTap: onTapWord,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: wordPurple.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Label
            Text(
              '🔑 KEY WORD',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: wordPurple,
              ),
            ),
            const SizedBox(height: 16),
            
            // Original Script
            Text(
              keyWord.originalScript,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Spectral',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            
            // Transliteration
            Text(
              keyWord.transliteration,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            
            // Strong's Number (Go Deep only)
            if (mode == ExegesisMode.goDeep && keyWord.strongsNumber != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: wordPurple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  keyWord.strongsNumber!,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: wordPurple,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            
            // Meaning
            Text(
              keyWord.meaning,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Spectral',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Why It Matters (Discovery text)
            Text(
              keyWord.whyItMatters,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Spectral',
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.75,
              ),
            ),
            
            // Tap hint
            if (onTapWord != null) ...[
              const SizedBox(height: 12),
              Text(
                mode == ExegesisMode.goDeep 
                    ? 'Tap for full word study'
                    : 'Tap to learn more',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10,
                  color: wordPurple.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
