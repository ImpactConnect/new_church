import 'package:flutter/material.dart';
import '../models/exegesis_result_v2_model.dart';

/// Bottom sheet for displaying full word study details (Go Deep mode)
/// Shows complete word study with translation variance and usage examples
class WordStudyBottomSheet extends StatelessWidget {
  final WordStudyItem wordStudy;

  const WordStudyBottomSheet({
    super.key,
    required this.wordStudy,
  });

  static Future<void> show({
    required BuildContext context,
    required WordStudyItem wordStudy,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WordStudyBottomSheet(wordStudy: wordStudy),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Original script
                  Center(
                    child: Text(
                      wordStudy.word,
                      style: const TextStyle(
                        fontFamily: 'Spectral',
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Transliteration + Strong's
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          wordStudy.transliteration,
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        if (wordStudy.strongsNumber != null) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9878C8).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              wordStudy.strongsNumber!,
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF9878C8),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Definition
                  _buildSection(
                    context,
                    label: 'DEFINITION',
                    content: wordStudy.definition,
                  ),

                  // Semantic Range
                  const SizedBox(height: 20),
                  _buildSection(
                    context,
                    label: 'SEMANTIC RANGE',
                    content: wordStudy.semanticRange,
                  ),

                  // Usage Examples
                  if (wordStudy.usageExamples.isNotEmpty) ...[
                    const SizedBox(height: 20),
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
                      padding: const EdgeInsets.only(bottom: 8),
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
                    const SizedBox(height: 20),
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

                  // Why It Matters
                  if (wordStudy.whyItMatters.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
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
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String label, required String content}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
          content,
          style: const TextStyle(
            fontFamily: 'Spectral',
            fontSize: 13,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
