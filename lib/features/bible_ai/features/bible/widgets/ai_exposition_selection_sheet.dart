import 'package:flutter/material.dart';

class AiExpositionSelectionSheet extends StatelessWidget {
  final String bookName;
  final int chapterNumber;
  final VoidCallback onSelectBook;
  final VoidCallback onSelectChapter;

  const AiExpositionSelectionSheet({
    super.key,
    required this.bookName,
    required this.chapterNumber,
    required this.onSelectBook,
    required this.onSelectChapter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'AI Exposition',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'What would you like to study?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          _SelectionCard(
            context: context,
            title: 'Exposition on the book of $bookName',
            icon: Icons.menu_book,
            description:
                'History, key facts, themes, and theological emphasis of the entire book.',
            onTap: () {
              Navigator.pop(context);
              onSelectBook();
            },
          ),
          const SizedBox(height: 16),
          _SelectionCard(
            context: context,
            title: 'Exposition on Chapter $chapterNumber',
            icon: Icons.library_books,
            description:
                'Context, literary flow, key terms, and application principles for this specific chapter.',
            onTap: () {
              Navigator.pop(context);
              onSelectChapter();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final BuildContext context;
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.context,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
