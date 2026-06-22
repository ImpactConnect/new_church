import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/linked_content_reference.dart';
import '../../data/models/standalone_note_model.dart';
import '../providers/standalone_notes_providers.dart';

/// Widget that displays linked content references in a note
/// Shows content type icon, source reference, timestamp, and provides
/// navigation to original source and removal functionality
class LinkedContentWidget extends ConsumerWidget {
  final StandaloneNote note;
  final VoidCallback? onContentRemoved;

  const LinkedContentWidget({
    super.key,
    required this.note,
    this.onContentRemoved,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (note.linkedContent.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Linked Content',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        ...note.linkedContent.map((reference) {
          return _LinkedContentItem(
            reference: reference,
            noteId: note.id,
            onRemove: () async {
              await _removeLinkedContent(context, ref, note.id, reference.id);
              onContentRemoved?.call();
            },
            onTap: () => _navigateToSource(context, reference),
          );
        }),
      ],
    );
  }

  Future<void> _removeLinkedContent(
    BuildContext context,
    WidgetRef ref,
    String noteId,
    String referenceId,
  ) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Linked Content'),
        content: const Text(
          'Are you sure you want to remove this linked content reference? '
          'The content in the note text will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(notesProvider.notifier)
            .removeLinkedContent(noteId, referenceId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Linked content removed'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove linked content: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToSource(BuildContext context, LinkedContentReference reference) {
    // TODO: Implement navigation to original source based on content type
    // This will be implemented when integration points are added in later tasks
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigate to ${reference.type.name} - Coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

/// Individual linked content item widget
class _LinkedContentItem extends StatelessWidget {
  final LinkedContentReference reference;
  final String noteId;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _LinkedContentItem({
    required this.reference,
    required this.noteId,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Content type icon
              _buildContentTypeIcon(context),
              const SizedBox(width: 12),

              // Content details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Content type label
                    Text(
                      _getContentTypeLabel(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _getContentTypeColor(context),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                    ),
                    const SizedBox(height: 4),

                    // Source reference
                    Text(
                      reference.sourceReference,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Timestamp
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Linked ${DateFormat.yMMMd().add_jm().format(reference.linkedAt)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Remove button
              IconButton(
                onPressed: onRemove,
                icon: Icon(
                  Icons.close,
                  size: 20,
                  color: Theme.of(context).colorScheme.error,
                ),
                tooltip: 'Remove linked content',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentTypeIcon(BuildContext context) {
    final icon = _getContentTypeIconData();
    final color = _getContentTypeColor(context);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 24,
        color: color,
      ),
    );
  }

  IconData _getContentTypeIconData() {
    switch (reference.type) {
      case LinkedContentType.verse:
        return Icons.menu_book;
      case LinkedContentType.chat:
        return Icons.chat_bubble_outline;
      case LinkedContentType.study:
        return Icons.school;
      case LinkedContentType.exegesis:
        return Icons.analytics;
      case LinkedContentType.prayer:
        return Icons.volunteer_activism;
    }
  }

  String _getContentTypeLabel() {
    switch (reference.type) {
      case LinkedContentType.verse:
        return 'BIBLE VERSE';
      case LinkedContentType.chat:
        return 'AI CHAT';
      case LinkedContentType.study:
        return 'BIBLE STUDY';
      case LinkedContentType.exegesis:
        return 'EXEGESIS';
      case LinkedContentType.prayer:
        return 'PRAYER GUIDE';
    }
  }

  Color _getContentTypeColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (reference.type) {
      case LinkedContentType.verse:
        return colorScheme.primary;
      case LinkedContentType.chat:
        return colorScheme.secondary;
      case LinkedContentType.study:
        return colorScheme.tertiary;
      case LinkedContentType.exegesis:
        return Colors.deepPurple;
      case LinkedContentType.prayer:
        return Colors.pink;
    }
  }
}
