import 'package:flutter/material.dart';
import '../../../../data/models/ai/ai_models.dart';
import '../../widgets/ai_markdown_body.dart';

class CrossrefsFeatureScreen extends StatelessWidget {
  final CrossReferencesAnalysis analysis;

  const CrossrefsFeatureScreen({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Theme
        if (analysis.theme.isNotEmpty) ...[
          _sectionHeader(context, 'Connecting Theme', Icons.hub),
          _contentCard(context, analysis.theme),
          const SizedBox(height: 20),
        ],

        // References
        if (analysis.references.isNotEmpty) ...[
          _sectionHeader(
            context,
            'Cross References (${analysis.references.length})',
            Icons.bookmark_border,
          ),
          ...analysis.references.asMap().entries.map((entry) {
            final idx = entry.key;
            final ref = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        '${idx + 1}',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (ref.reference.isNotEmpty)
                            Text(
                              ref.reference,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          if (ref.connection.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            AiMarkdownBody(data: ref.connection),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
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
