import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../../data/models/standalone_note_model.dart';
import '../../services/rich_text_serializer.dart';
import '../providers/standalone_notes_providers.dart';

/// Modern note editor screen with enhanced UI
class NoteEditorScreen extends ConsumerStatefulWidget {
  final String? noteId;

  const NoteEditorScreen({super.key, this.noteId});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _titleController;
  late final quill.QuillController _quillController;
  late final TextEditingController _tagInputController;
  final FocusNode _editorFocusNode = FocusNode();
  
  List<String> _tags = [];
  List<String> _availableTags = [];
  bool _isLoading = true;
  bool _isSaving = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _tagInputController = TextEditingController();
    _quillController = quill.QuillController.basic();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _loadNote();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagInputController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    if (widget.noteId != null) {
      StandaloneNote? noteToEdit = ref.read(currentNoteProvider);
      
      if (noteToEdit == null || noteToEdit.id != widget.noteId) {
        final notesAsync = ref.read(notesProvider);
        await notesAsync.whenData((notes) {
          noteToEdit = notes.firstWhere(
            (n) => n.id == widget.noteId,
            orElse: () => throw Exception('Note not found'),
          );
        });
      }
      
      if (noteToEdit != null) {
        _titleController.text = noteToEdit!.title;
        _tags = List.from(noteToEdit!.tags);
        
        try {
          final document = RichTextSerializer.deserialize(noteToEdit!.richTextContent);
          _quillController.document = document;
        } catch (e) {
          _quillController.document = quill.Document();
        }
      }
    }
    
    final notesAsync = ref.read(notesProvider);
    notesAsync.whenData((notes) {
      final allTags = <String>{};
      for (final note in notes) {
        allTags.addAll(note.tags);
      }
      setState(() {
        _availableTags = allTags.toList()..sort();
        _isLoading = false;
      });
    });
    
    if (mounted) {
      setState(() => _isLoading = false);
      _animationController.forward();
    }
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isEmpty || _tags.contains(trimmedTag)) {
      return;
    }
    
    setState(() {
      _tags.add(trimmedTag);
      _tagInputController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 12),
              Text('Please enter a title for your note'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final richTextContent = RichTextSerializer.serialize(_quillController.document);
      final notesNotifier = ref.read(notesProvider.notifier);
      
      if (widget.noteId != null) {
        StandaloneNote? currentNote = ref.read(currentNoteProvider);
        
        if (currentNote == null || currentNote.id != widget.noteId) {
          final notesAsync = ref.read(notesProvider);
          await notesAsync.whenData((notes) {
            currentNote = notes.firstWhere(
              (n) => n.id == widget.noteId,
              orElse: () => throw Exception('Note not found'),
            );
          });
        }
        
        if (currentNote != null) {
          final updatedNote = currentNote!.copyWith(
            title: title,
            richTextContent: richTextContent,
            tags: _tags,
            lastModifiedAt: DateTime.now(),
          );
          await notesNotifier.updateNote(updatedNote);
        }
      } else {
        final newNote = StandaloneNote(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          richTextContent: richTextContent,
          tags: _tags,
          isPinned: false,
          createdAt: DateTime.now(),
          lastModifiedAt: DateTime.now(),
          linkedContent: [],
        );
        await notesNotifier.createNote(newNote);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(widget.noteId != null ? 'Note updated' : 'Note created'),
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
            content: Text('Failed to save note: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surfaceContainerLowest,
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerLowest,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildAppBar(context, colorScheme),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context, colorScheme),
                          const SizedBox(height: 24),
                          _buildTitleField(context, colorScheme),
                          const SizedBox(height: 20),
                          _buildTagSection(context, colorScheme),
                          const SizedBox(height: 24),
                          _buildEditorSection(context, colorScheme),
                        ],
                      ),
                    ),
                  ),
                  _buildToolbar(context, colorScheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            ),
            onPressed: _isSaving ? null : _cancel,
          ),
          Expanded(
            child: Text(
              widget.noteId != null ? 'Edit Note' : 'New Note',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          _isSaving
              ? Container(
                  padding: const EdgeInsets.all(12),
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(Icons.check, color: colorScheme.onPrimary),
                  ),
                  onPressed: _saveNote,
                ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withOpacity(0.5),
            colorScheme.secondaryContainer.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.edit_note,
              size: 28,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.noteId != null ? 'Edit your note' : 'Create a new note',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField(BuildContext context, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _titleController,
        decoration: InputDecoration(
          hintText: 'Note Title',
          prefixIcon: Icon(Icons.title, color: colorScheme.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTagSection(BuildContext context, ColorScheme colorScheme) {
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
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.secondaryContainer,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.label, size: 14, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      tag,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _removeTag(tag),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return _availableTags.where((tag) {
                      return tag.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      );
                    });
                  },
                  onSelected: (String selection) {
                    _addTag(selection);
                  },
                  fieldViewBuilder: (
                    context,
                    controller,
                    focusNode,
                    onFieldSubmitted,
                  ) {
                    _tagInputController.text = controller.text;
                    _tagInputController.selection = controller.selection;
                    
                    return TextField(
                      controller: _tagInputController,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Add tags...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                      onSubmitted: (value) {
                        _addTag(value);
                        onFieldSubmitted();
                      },
                    );
                  },
                ),
              ),
              IconButton(
                onPressed: () {
                  _addTag(_tagInputController.text);
                },
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add, size: 18, color: colorScheme.primary),
                ),
                tooltip: 'Add tag',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditorSection(BuildContext context, ColorScheme colorScheme) {
    return Container(
      constraints: const BoxConstraints(minHeight: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: quill.QuillEditor.basic(
        controller: _quillController,
        focusNode: _editorFocusNode,
        config: const quill.QuillEditorConfig(
          placeholder: 'Start writing your note...',
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: quill.QuillSimpleToolbar(
          controller: _quillController,
          config: const quill.QuillSimpleToolbarConfig(
            showAlignmentButtons: false,
            showBackgroundColorButton: true,
            showCenterAlignment: false,
            showCodeBlock: true,
            showColorButton: true,
            showDirection: false,
            showDividers: true,
            showFontFamily: false,
            showFontSize: false,
            showHeaderStyle: true,
            showIndent: false,
            showInlineCode: true,
            showJustifyAlignment: false,
            showLeftAlignment: false,
            showLink: true,
            showListBullets: true,
            showListCheck: false,
            showListNumbers: true,
            showQuote: true,
            showRedo: true,
            showRightAlignment: false,
            showSearchButton: false,
            showSmallButton: false,
            showStrikeThrough: true,
            showSubscript: false,
            showSuperscript: false,
            showUnderLineButton: true,
            showUndo: true,
          ),
        ),
      ),
    );
  }
}
