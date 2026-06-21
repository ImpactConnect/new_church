import 'package:flutter/material.dart';
import '../models/exegesis_result_v2_model.dart';

/// Full technical word study card (Go Deep mode only)
/// Displays original script, transliteration, Strong's number, definition, usage, and variance
class WordStudyCard extends StatelessWidget {
  final WordStudyItem wordStudy;
  final bool isExpanded;
  final VoidCallback onToggle;

  const WordStudyCard({
    super.key,
    required this.wordStudy,
    this.isExpanded = true,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isDark ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with original script and toggle
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Original script
                        Text(
                          wordStudy.word,
                          style: const TextStyle(
                            fontFamily: 'Spectral',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Transliteration + Strong's
                        Row(
                          children: [
                            Text(
                              wordStudy.transliteration,
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            if (wordStudy.strongsNumber != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9878C8).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  wordStudy.strongsNumber!,
                                  style: const TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF9878C8),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Definition
                  Text(
                    wordStudy.definition,
                    style: const TextStyle(
                      fontFamily: 'Spectral',
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),

                  // Usage
                  if (wordStudy.usageExamples.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'SEMANTIC RANGE',
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
                      wordStudy.semanticRange,
                      style: const TextStyle(
                        fontFamily: 'Spectral',
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'USAGE EXAMPLES',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...wordStudy.usageExamples.map((example) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $example',
                        style: const TextStyle(
                          fontFamily: 'Spectral',
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    )),
                  ],

                  // Translation Variance
                  if (wordStudy.translationVariance != null && wordStudy.translationVariance!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'TRANSLATION VARIANCE',
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
                      wordStudy.translationVariance!,
                      style: const TextStyle(
                        fontFamily: 'Spectral',
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ],

                  // Why It Matters (sage green tint)
                  if (wordStudy.whyItMatters.isNotEmpty) ...[
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
                            '💡 WHY IT MATTERS',
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
                            wordStudy.whyItMatters,
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
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
