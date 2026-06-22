import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'note_editor_screen.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/standalone_note_model.dart';
import '../../services/rich_text_serializer.dart';
import '../../services/export_service.dart';
import '../providers/standalone_notes_providers.dart';
import '../widgets/linked_content_widget.dart';

/// Modern note detail screen with enhanced UI
class NoteDetailScreen extends ConsumerStatefulWidget {
  final String noteId;

  const NoteDetailScreen({super.key, required this.noteId});

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  late final quill.QuillController _quillController;
  StandaloneNote? _note;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _quillController = quill.QuillController.basic();
    _loadNote();
  }

  @override
  void dispose() {
    _quillController.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    final notesAsync = ref.read(notesProvider);
    notesAsync.whenData((notes) {
      final note = notes.firstWhere(
        (n) => n.id == widget.noteId,
        orElse: () => throw Exception('Note not found'),
      );
      
      setState(() {
        _note = note;
      });

      try {
        final document = RichTextSerializer.deserialize(note.richTextContent);
        _quillController.document = document;
      } catch (e) {
        _quillController.document = quill.Document();
      }

      setState(() {
        _isLoading = false;
      });
    });
  }

  void _editNote() async {
    if (_note != null) {
      ref.read(currentNoteProvider.notifier).state = _note;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NoteEditorScreen(noteId: _note!.id),
        ),
      );
      // Reload note after returning from editor to reflect changes
      _loadNote();
    }
  }

  Future<void> _deleteNote() async {
    if (_note == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 12),
            const Text('Delete Note'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${_note!.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(notesProvider.notifier).deleteNote(_note!.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Note deleted'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete note: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Export Note',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            _ExportOption(
              icon: Icons.picture_as_pdf,
              title: 'Export as PDF',
              subtitle: 'Portable document format',
              onTap: () {
                Navigator.pop(context);
                _exportNote(ExportFormat.pdf);
              },
            ),
            _ExportOption(
              icon: Icons.text_fields,
              title: 'Export as Plain Text',
              subtitle: 'Simple text file',
              onTap: () {
                Navigator.pop(context);
                _exportNote(ExportFormat.plainText);
              },
            ),
            _ExportOption(
              icon: Icons.code,
              title: 'Export as Markdown',
              subtitle: 'Markdown formatted text',
              onTap: () {
                Navigator.pop(context);
                _exportNote(ExportFormat.markdown);
              },
            ),
            _ExportOption(
              icon: Icons.data_object,
              title: 'Export as JSON',
              subtitle: 'Structured data format',
              onTap: () {
                Navigator.pop(context);
                _exportNote(ExportFormat.json);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportNote(ExportFormat format) async {
    if (_note == null) return;

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('Exporting note...'),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }

      final exportService = ref.read(exportServiceProvider);
      String filePath;

      switch (format) {
        case ExportFormat.pdf:
          filePath = await exportService.exportToPdf(_note!);
          break;
        case ExportFormat.markdown:
          filePath = await exportService.exportToMarkdown(_note!);
          break;
        case ExportFormat.plainText:
          filePath = await exportService.exportToPlainText(_note!);
          break;
        case ExportFormat.json:
          filePath = await exportService.exportToJson(_note!);
          break;
      }

      if (mounted) {
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'Note: ${_note!.title}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('Exported as ${format.name}'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _note == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, colorScheme),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, colorScheme),
                  const SizedBox(height: 24),
                  _buildMetadata(context, colorScheme),
                  const SizedBox(height: 24),
                  _buildTags(context, colorScheme),
                  const SizedBox(height: 32),
                  _buildContent(context, colorScheme),
                  if (_note!.linkedContent.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    _buildLinkedContent(context, colorScheme),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ColorScheme colorScheme) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: colorScheme.surface,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: _editNote,
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _showExportOptions,
        ),
        IconButton(
          icon: const Icon(Icons.picture_as_pdf),
          onPressed: () => _exportNote(ExportFormat.pdf),
          tooltip: 'Export as PDF',
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Text(
        _note!.title,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMetadata(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MetadataItem(
              icon: Icons.calendar_today,
              label: 'Created',
              value: DateFormat.yMMMd().format(_note!.createdAt),
              colorScheme: colorScheme,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.outline.withOpacity(0.3),
          ),
          Expanded(
            child: _MetadataItem(
              icon: Icons.update,
              label: 'Modified',
              value: DateFormat.yMMMd().format(_note!.lastModifiedAt),
              colorScheme: colorScheme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTags(BuildContext context, ColorScheme colorScheme) {
    if (_note!.tags.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.label, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Tags',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _note!.tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.secondaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.label,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tag,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      constraints: const BoxConstraints(minHeight: 200),
      child: AbsorbPointer(
        child: quill.QuillEditor.basic(
          controller: _quillController,
        ),
      ),
    );
  }

  Widget _buildLinkedContent(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.link, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Linked Content',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: LinkedContentWidget(
            note: _note!,
            onContentRemoved: () => _loadNote(),
          ),
        ),
      ],
    );
  }
}

class _MetadataItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;

  const _MetadataItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primaryContainer,
              colorScheme.secondaryContainer,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colorScheme.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
