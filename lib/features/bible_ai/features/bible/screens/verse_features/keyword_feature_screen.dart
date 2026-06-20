import 'package:flutter/material.dart';
import '../../../../data/models/ai/ai_models.dart';
import '../../widgets/ai_markdown_body.dart';

class KeywordFeatureScreen extends StatelessWidget {
  final KeyWordAnalysis analysis;

  const KeywordFeatureScreen({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (analysis.keywords.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No key words identified for this verse.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          )
        else
          ...analysis.keywords.map(
            (wordDetail) => _buildKeywordSection(context, wordDetail),
          ),
      ],
    );
  }

  Widget _buildKeywordSection(BuildContext context, WordDetail word) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Word Header Card
          Card(
            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (word.word.isNotEmpty)
                    Text(
                      word.word,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  if (word.original.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      word.original,
                      style: TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                  if (word.transliteration.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Transliteration: ${word.transliteration}',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer.withOpacity(
                          0.7,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Definition
          if (word.definition.isNotEmpty) ...[
            _sectionHeader(context, 'Definition', Icons.book),
            _contentCard(context, word.definition),
            const SizedBox(height: 16),
          ],

          // Usage in Verse
          if (word.usageInVerse.isNotEmpty) ...[
            _sectionHeader(context, 'Usage in This Verse', Icons.text_snippet),
            _contentCard(context, word.usageInVerse),
            const SizedBox(height: 16),
          ],

          // Usage Elsewhere
          if (word.usageElsewhere.isNotEmpty) ...[
            _sectionHeader(
              context,
              'Usage Elsewhere in Scripture',
              Icons.library_books,
            ),
            _contentCard(context, word.usageElsewhere),
            const SizedBox(height: 16),
          ],

          // Theological Significance
          if (word.theologicalSignificance.isNotEmpty) ...[
            _sectionHeader(context, 'Theological Significance', Icons.church),
            _contentCard(context, word.theologicalSignificance),
            const SizedBox(height: 16),
          ],

          // Cross Reference
          if (word.crossReference.isNotEmpty) ...[
            _sectionHeader(context, 'Cross Reference', Icons.format_quote),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.secondary.withOpacity(0.3),
                ),
              ),
              child: AiMarkdownBody(
                data: word.crossReference,
                baseStyle: const TextStyle(
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contentCard(BuildContext context, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: AiMarkdownBody(data: content),
    );
  }
}
