import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stub AddToNoteDialog — notes integration not yet wired in this app build.
class AddToNoteDialog extends ConsumerWidget {
  final String formattedContent;
  final dynamic linkedContentReference;
  final String? suggestedTitle;

  const AddToNoteDialog({
    super.key,
    required this.formattedContent,
    this.linkedContentReference,
    this.suggestedTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Add to Note'),
      content: const Text('Note-taking integration coming soon.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
