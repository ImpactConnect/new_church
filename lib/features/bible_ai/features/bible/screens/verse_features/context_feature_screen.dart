import 'package:flutter/material.dart';
import '../../../../data/models/ai/ai_models.dart';
import '../../widgets/ai_markdown_body.dart';

class ContextFeatureScreen extends StatelessWidget {
  final ContextAnalysis analysis;

  const ContextFeatureScreen({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chapter Theme
        if (analysis.chapterTheme.isNotEmpty) ...[
          _sectionHeader(context, 'Chapter Theme', Icons.auto_awesome),
          _contentCard(context, analysis.chapterTheme),
          const SizedBox(height: 16),
        ],

        // Speaker & Audience
        if (analysis.speaker.isNotEmpty || analysis.audience.isNotEmpty)
          _buildInfoCard(context, [
            if (analysis.speaker.isNotEmpty)
              _labelValue(context, 'Speaker', analysis.speaker),
            if (analysis.audience.isNotEmpty)
              _labelValue(context, 'Audience', analysis.audience),
            if (analysis.literaryType.isNotEmpty)
              _labelValue(context, 'Literary Type', analysis.literaryType),
          ]),
        const SizedBox(height: 16),

        // Immediate Context Before
        if (analysis.immediateContextBefore.isNotEmpty) ...[
          _sectionHeader(context, 'What Comes Before', Icons.arrow_upward),
          _contentCard(context, analysis.immediateContextBefore),
          const SizedBox(height: 16),
        ],

        // Immediate Context After
        if (analysis.immediateContextAfter.isNotEmpty) ...[
          _sectionHeader(context, 'What Comes After', Icons.arrow_downward),
          _contentCard(context, analysis.immediateContextAfter),
          const SizedBox(height: 16),
        ],

        // Cultural Background
        if (analysis.culturalBackgroundInsight.isNotEmpty) ...[
          _sectionHeader(context, 'Cultural Background', Icons.public),
          _contentCard(context, analysis.culturalBackgroundInsight),
          const SizedBox(height: 16),
        ],

        // Interpretive Impact
        if (analysis.culturalInterpretiveImpact.isNotEmpty) ...[
          _sectionHeader(context, 'Impact on Interpretation', Icons.psychology),
          _contentCard(context, analysis.culturalInterpretiveImpact),
          const SizedBox(height: 16),
        ],

        // Common Misunderstandings
        if (analysis.commonMisunderstandings.isNotEmpty) ...[
          _sectionHeader(
            context,
            'Common Misunderstandings',
            Icons.warning_amber_rounded,
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.error.withOpacity(0.3),
              ),
            ),
            child: AiMarkdownBody(data: analysis.commonMisunderstandings),
          ),
          const SizedBox(height: 16),
        ],

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

  Widget _labelValue(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
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
