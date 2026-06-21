import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/bible_books.dart';

/// Form widget for Passage entry type
/// Book, Chapter, Start Verse, End Verse with translation selection
/// Supports up to 5 passages
class PassageFormWidget extends StatefulWidget {
  final ValueChanged<bool> onValidityChanged;

  const PassageFormWidget({
    super.key,
    required this.onValidityChanged,
  });

  @override
  State<PassageFormWidget> createState() => PassageFormWidgetState();
}

// Make the state class public so it can be accessed via GlobalKey
class PassageFormWidgetState extends State<PassageFormWidget> {
  final List<_PassageUnit> _passages = [_PassageUnit()];
  String _selectedTranslation = 'ESV';
  String? _context;

  static const List<String> _translations = ['ESV', 'NIV', 'KJV', 'NASB', 'NLT'];
  static const int _maxPassages = 5;

  /// Public method to get form data
  Map<String, dynamic> getFormData() {
    return {
      'passages': _passages
          .where((passage) => passage.isComplete)
          .map((passage) => {
                'book': passage.book,
                'chapter': passage.chapter,
                'startVerse': passage.startVerse,
                'endVerse': passage.endVerse,
              })
          .toList(),
      'translation': _selectedTranslation,
      'context': _context,
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateForm();
    });
  }

  void _validateForm() {
    final isValid = _passages.any((passage) => passage.isComplete);
    widget.onValidityChanged(isValid);
  }

  void _addPassage() {
    if (_passages.length < _maxPassages) {
      setState(() {
        _passages.add(_PassageUnit());
      });
    }
  }

  void _removePassage(int index) {
    if (_passages.length > 1) {
      setState(() {
        _passages.removeAt(index);
        _validateForm();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Passage units
        ...List.generate(_passages.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _PassageUnitWidget(
              passage: _passages[index],
              index: index,
              canRemove: _passages.length > 1,
              onChanged: () {
                setState(() {
                  _validateForm();
                });
              },
              onRemove: () => _removePassage(index),
            ),
          );
        }),

        // Add passage button
        if (_passages.length < _maxPassages)
          OutlinedButton.icon(
            onPressed: _addPassage,
            icon: const Icon(Icons.add, size: 18),
            label: Text('Add Passage (${_passages.length}/$_maxPassages)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6b4fc8),
              side: const BorderSide(color: Color(0xFF6b4fc8)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

        const SizedBox(height: 24),

        // Translation selector
        Text(
          'Translation',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedTranslation,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: _translations.map((translation) {
            return DropdownMenuItem(
              value: translation,
              child: Text(translation),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedTranslation = value!;
            });
          },
        ),

        const SizedBox(height: 24),

        // Optional context field
        Text(
          'Context (Optional)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Any specific context or question about this passage?',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: (value) {
            setState(() {
              _context = value.isEmpty ? null : value;
            });
          },
        ),
      ],
    );
  }
}

/// Individual passage unit widget
class _PassageUnitWidget extends StatefulWidget {
  final _PassageUnit passage;
  final int index;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _PassageUnitWidget({
    required this.passage,
    required this.index,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_PassageUnitWidget> createState() => _PassageUnitWidgetState();
}

class _PassageUnitWidgetState extends State<_PassageUnitWidget> {
  late final TextEditingController _chapterController;
  late final TextEditingController _startVerseController;
  late final TextEditingController _endVerseController;

  @override
  void initState() {
    super.initState();
    _chapterController = TextEditingController(
      text: widget.passage.chapter?.toString() ?? '',
    );
    _startVerseController = TextEditingController(
      text: widget.passage.startVerse?.toString() ?? '',
    );
    _endVerseController = TextEditingController(
      text: widget.passage.endVerse?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _chapterController.dispose();
    _startVerseController.dispose();
    _endVerseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0f1020) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF14162a) : const Color(0xFFeeecff),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Passage ${widget.index + 1}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (widget.canRemove)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: widget.onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Book autocomplete
          Autocomplete<String>(
            initialValue: TextEditingValue(text: widget.passage.book ?? ''),
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return BibleBooks.allBooks;
              }
              return BibleBooks.allBooks.where((String book) {
                return book.toLowerCase().contains(
                  textEditingValue.text.toLowerCase(),
                );
              });
            },
            onSelected: (String selection) {
              widget.passage.book = selection;
              widget.onChanged();
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: 'Book',
                  hintText: 'Type to search...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onChanged: (value) {
                  widget.passage.book = value.isEmpty ? null : value;
                  widget.onChanged();
                },
              );
            },
          ),

          const SizedBox(height: 12),

          // Chapter and verse range
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chapterController,
                  decoration: InputDecoration(
                    labelText: 'Chapter',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) {
                    widget.passage.chapter = int.tryParse(value);
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _startVerseController,
                  decoration: InputDecoration(
                    labelText: 'Start Verse',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) {
                    widget.passage.startVerse = int.tryParse(value);
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _endVerseController,
                  decoration: InputDecoration(
                    labelText: 'End Verse',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) {
                    widget.passage.endVerse = int.tryParse(value);
                    widget.onChanged();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Data class for a single passage unit
class _PassageUnit {
  String? book;
  int? chapter;
  int? startVerse;
  int? endVerse;

  bool get isComplete =>
      book != null &&
      chapter != null &&
      startVerse != null &&
      endVerse != null &&
      endVerse! >= startVerse!;
}
