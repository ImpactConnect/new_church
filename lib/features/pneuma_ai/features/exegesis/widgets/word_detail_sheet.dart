import 'package:flutter/material.dart';
import '../models/exegesis_result_model.dart';
import 'package:go_router/go_router.dart';

class WordDetailSheet extends StatelessWidget {
  final ExegesisWordStudy wordStudy;

  const WordDetailSheet({super.key, required this.wordStudy});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wordStudy.word,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (wordStudy.strongsNumber.isNotEmpty)
                              _buildPill(context, wordStudy.strongsNumber),
                            if (wordStudy.strongsNumber.isNotEmpty)
                              const SizedBox(width: 8),
                            if (wordStudy.partOfSpeech != null && wordStudy.partOfSpeech!.isNotEmpty)
                              _buildPill(context, wordStudy.partOfSpeech!),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Transliteration: ${wordStudy.transliteration}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Core Definition
              _buildSectionTitle(context, 'Definition'),
              Text(
                wordStudy.definition,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
              
              const SizedBox(height: 24),
              
              // Semantic Range
              if (wordStudy.semanticRange.isNotEmpty) ...[
                _buildSectionTitle(context, 'Semantic Range'),
                Text(
                  wordStudy.semanticRange,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 24),
              ],
              
              // Usage Note
              if (wordStudy.usageNote.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('Exegetical Significance', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(wordStudy.usageNote, style: const TextStyle(height: 1.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Translation Comparison
              if (wordStudy.translationComparison != null && wordStudy.translationComparison!.isNotEmpty) ...[
                _buildSectionTitle(context, 'Translation Comparison'),
                Text(
                  wordStudy.translationComparison!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 24),
              ],
              
              // Type-specifics
              if (wordStudy.meaning != null && wordStudy.meaning!.isNotEmpty) ...[
                _buildSectionTitle(context, 'Name Meaning'),
                Text(wordStudy.meaning!, style: const TextStyle(height: 1.5)),
                const SizedBox(height: 24),
              ],
              if (wordStudy.interTestamentalShift != null && wordStudy.interTestamentalShift!.isNotEmpty) ...[
                _buildSectionTitle(context, 'Intertestamental Shift'),
                Text(wordStudy.interTestamentalShift!, style: const TextStyle(height: 1.5)),
                const SizedBox(height: 24),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildPill(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
