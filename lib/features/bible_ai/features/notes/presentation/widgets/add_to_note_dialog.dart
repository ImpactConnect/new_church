import 'package:flutter/material.dart';
import '../data/models/linked_content_reference.dart';

/// Dialog for adding formatted content (e.g., a Bible verse) to an existing standalone note.
/// This is a stub implementation — shows a snackbar confirmation.
class AddToNoteDialog extends StatelessWidget {
  final String formattedContent;
  final LinkedContentReference linkedContentReference;
  final String suggestedTitle;

  const AddToNoteDialog({
    super.key,
    required this.formattedContent,
    required this.linkedContentReference,
    required this.suggestedTitle,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save to Note'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            suggestedTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            formattedContent,
            style: const TextStyle(fontStyle: FontStyle.italic),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Saved to note')),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
