import 'package:flutter/material.dart';
import '../../../../data/models/ai/ai_models.dart';
import '../../widgets/ai_markdown_body.dart';

class ApplicationFeatureScreen extends StatelessWidget {
  final ApplicationAnalysis analysis;

  const ApplicationFeatureScreen({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Central Truth
        if (analysis.centralTruth.isNotEmpty) ...[
          _sectionHeader(context, 'Central Truth', Icons.lightbulb),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: AiMarkdownBody(
              data: analysis.centralTruth,
              baseStyle: TextStyle(
                height: 1.6,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Common Misuse
        if (analysis.commonMisuse.isNotEmpty) ...[
          _sectionHeader(context, 'Common Misuse', Icons.warning_amber_rounded),
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
            child: AiMarkdownBody(data: analysis.commonMisuse),
          ),
          const SizedBox(height: 16),
        ],

        // General Applications
        if (analysis.applications.isNotEmpty) ...[
          _sectionHeader(context, 'General Application', Icons.handshake),
          _contentCard(context, analysis.applications),
          const SizedBox(height: 16),
        ],

        // Applications Areas
        _sectionHeader(context, 'Specific Areas', Icons.grid_view),
        _applicationTile(
          context,
          Icons.person,
          'Personal',
          analysis.applicationsAreas.personal,
        ),
        _applicationTile(
          context,
          Icons.family_restroom,
          'Family',
          analysis.applicationsAreas.family,
        ),
        _applicationTile(
          context,
          Icons.church,
          'Church',
          analysis.applicationsAreas.church,
        ),
        _applicationTile(
          context,
          Icons.work,
          'Workplace',
          analysis.applicationsAreas.workplace,
        ),
        _applicationTile(
          context,
          Icons.public,
          'Society',
          analysis.applicationsAreas.society,
        ),
        const SizedBox(height: 16),

        // Clarification
        if (analysis.clarification.isNotEmpty) ...[
          _sectionHeader(context, 'Clarification', Icons.info_outline),
          _contentCard(context, analysis.clarification),
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
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _applicationTile(
    BuildContext context,
    IconData icon,
    String title,
    String content,
  ) {
    if (content.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: AiMarkdownBody(data: content),
        ),
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
