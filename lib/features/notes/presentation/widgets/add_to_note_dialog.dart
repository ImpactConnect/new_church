import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../../data/models/standalone_note_model.dart';
import '../../data/models/linked_content_reference.dart';
import '../../services/rich_text_serializer.dart';
import '../providers/standalone_notes_providers.dart';

/// Dialog for adding formatted content to a new or existing note
/// 
/// This dialog is used across the app (Bible, Chat, Study, Exegesis screens)
/// to allow users to save content to notes. It provides two options:
/// 1. Create a new note with the content pre-filled
/// 2. Add the content to an existing note
class AddToNoteDialog extends ConsumerStatefulWidget {
  /// The formatted content to add to the note
  final String formattedContent;
  
  /// The linked content reference for tracking the source
  final LinkedContentReference linkedContentReference;
  
  /// Optional suggested title for new notes
  final String? suggestedTitle;

  const AddToNoteDialog({
    super.key,
    required this.formattedContent,
    required this.linkedContentReference,
    this.suggestedTitle,
  });

  @override
  ConsumerState<AddToNoteDialog> createState() => _AddToNoteDialogState();
}

class _AddToNoteDialogState extends ConsumerState<AddToNoteDialog> {
  bool _showExistingNotes = false;
  bool _isProcessing = false;

  /// Creates a new note with the content pre-filled
  Future<void> _createNewNote() async {
    setState(() => _isProcessing = true);

    try {
      // Convert markdown-formatted content to Quill document with proper formatting
      final document = RichTextSerializer.fromMarkdown(widget.formattedContent);
      final richTextContent = RichTextSerializer.serialize(document);

      // Create the new note
      final newNote = StandaloneNote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: widget.suggestedTitle ?? 'New Note',
        richTextContent: richTextContent,
        tags: [],
        isPinned: false,
        createdAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        linkedContent: [widget.linkedContentReference],
      );

      final notesNotifier = ref.read(notesProvider.notifier);
      await notesNotifier.createNote(newNote);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create note: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Adds the content to an existing note
  Future<void> _addToExistingNote(StandaloneNote note) async {
    setState(() => _isProcessing = true);

    try {
      // Deserialize the existing content
      final existingDocument = RichTextSerializer.deserialize(note.richTextContent);
      
      // Get the current length to insert at the end
      final length = existingDocument.length;
      
      // Add a newline separator if the document is not empty
      if (length > 1) {
        existingDocument.insert(length - 1, '\n\n');
      }
      
      // Convert markdown-formatted content to Quill document
      final newContentDocument = RichTextSerializer.fromMarkdown(widget.formattedContent);
      
      // Get the delta operations from the new content
      final newContentDelta = newContentDocument.toDelta();
      
      // Compose the existing document with the new content
      final insertPosition = existingDocument.length - 1;
      int currentPosition = insertPosition;
      
      // Process all operations from the new content
      final operations = newContentDelta.toList();
      for (int i = 0; i < operations.length; i++) {
        final op = operations[i];
        if (op.isInsert) {
          final text = op.data.toString();
          existingDocument.insert(currentPosition, text);
          
          // Apply formatting if present
          if (op.attributes != null && op.attributes!.isNotEmpty) {
            for (final entry in op.attributes!.entries) {
              final attribute = quill.Attribute.fromKeyValue(entry.key, entry.value);
              if (attribute != null) {
                existingDocument.format(currentPosition, text.length, attribute);
              }
            }
          }
          
          currentPosition += text.length;
        }
      }
      
      // Serialize the updated document
      final updatedRichTextContent = RichTextSerializer.serialize(existingDocument);

      // Update the linked content list
      final updatedLinkedContent = List<LinkedContentReference>.from(note.linkedContent)
        ..add(widget.linkedContentReference);

      // Update the note
      final updatedNote = note.copyWith(
        richTextContent: updatedRichTextContent,
        linkedContent: updatedLinkedContent,
        lastModifiedAt: DateTime.now(),
      );

      final notesNotifier = ref.read(notesProvider.notifier);
      await notesNotifier.updateNote(updatedNote);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content added to note'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add content: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.note_add,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add to Note',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : _showExistingNotes
                      ? _buildExistingNotesList(notesAsync)
                      : _buildOptionsView(),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the initial options view
  Widget _buildOptionsView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choose an option:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          // Create New Note option
          Card(
            child: InkWell(
              onTap: _createNewNote,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.note_add,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create New Note',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Start a new note with this content',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Add to Existing Note option
          Card(
            child: InkWell(
              onTap: () => setState(() => _showExistingNotes = true),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.library_add,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add to Existing Note',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Append to an existing note',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the list of existing notes
  Widget _buildExistingNotesList(AsyncValue<List<StandaloneNote>> notesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Back button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _showExistingNotes = false),
              ),
              const SizedBox(width: 8),
              Text(
                'Select a note',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),

        // Notes list
        Expanded(
          child: notesAsync.when(
            data: (notes) {
              if (notes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notes yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a new note to get started',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.note,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(
                        note.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (note.tags.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              children: note.tags.take(3).map((tag) {
                                return Chip(
                                  label: Text(
                                    tag,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                      trailing: const Icon(Icons.add),
                      onTap: () => _addToExistingNote(note),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load notes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
