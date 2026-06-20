import 'package:flutter/material.dart';
import '../../../../data/models/ai/ai_models.dart';
import '../../widgets/ai_markdown_body.dart';

class ExplainFeatureScreen extends StatelessWidget {
  final ExplainAnalysis analysis;

  const ExplainFeatureScreen({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Deep Exposition',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        // Speaker & Audience
        if (analysis.speaker.isNotEmpty || analysis.audience.isNotEmpty)
          _buildInfoCard(context, [
            if (analysis.speaker.isNotEmpty)
              _labelValue('Speaker', analysis.speaker),
            if (analysis.audience.isNotEmpty)
              _labelValue('Audience', analysis.audience),
          ]),
        const SizedBox(height: 16),

        // Connected Thought Range / Passage Flow
        if (analysis.connectedThoughtRange.isNotEmpty) ...[
          _sectionHeader(context, 'Passage Flow', Icons.route),
          _contentCard(context, analysis.connectedThoughtRange),
          const SizedBox(height: 16),
        ],

        // Historical Context
        if (analysis.historicalContext.isNotEmpty) ...[
          _sectionHeader(context, 'Historical Context', Icons.history_edu),
          _contentCard(context, analysis.historicalContext),
          const SizedBox(height: 16),
        ],

        // Literary Context
        if (analysis.literaryContext.isNotEmpty) ...[
          _sectionHeader(context, 'Literary Context', Icons.menu_book),
          _contentCard(context, analysis.literaryContext),
          const SizedBox(height: 16),
        ],

        // Explanation
        if (analysis.explanation.isNotEmpty) ...[
          _sectionHeader(context, 'Explanation', Icons.lightbulb_outline),
          _contentCard(context, analysis.explanation),
          const SizedBox(height: 16),
        ],

        // Ambiguous Terms
        _sectionHeader(
          context,
          'Key Terms (${analysis.ambiguousTerms.length})',
          Icons.translate,
        ),
        if (analysis.ambiguousTerms.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'No ambiguous or key terms identified for this verse.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          )
        else
          ...analysis.ambiguousTerms.map(
            (term) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          term.term,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        if (term.originalWord.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(${term.originalWord})',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (term.transliteration.isNotEmpty)
                      Text(
                        'Transliteration: ${term.transliteration}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (term.definition.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        term.definition,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                    ],
                    if (term.whyItMatters.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Why it matters: ${term.whyItMatters}',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        if (analysis.ambiguousTerms.isNotEmpty) const SizedBox(height: 16),

        // Supporting Verse
        if (analysis.supportingVerse.isNotEmpty) ...[
          _sectionHeader(context, 'Supporting Verse', Icons.format_quote),
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
              data: analysis.supportingVerse,
              baseStyle: const TextStyle(
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Covenant Framework
        if (analysis.covenant.isNotEmpty) ...[
          _sectionHeader(context, 'Covenant Framework', Icons.account_balance),
          ...analysis.covenant.map(
            (c) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.covenant,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (c.applicability.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(
                          c.applicability,
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: theme.colorScheme.tertiaryContainer,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                    if (c.explanation.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      AiMarkdownBody(data: c.explanation),
                    ],
                  ],
                ),
              ),
            ),
          ),
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

  Widget _buildInfoCard(BuildContext context, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _labelValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
