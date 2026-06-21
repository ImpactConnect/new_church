import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/bible_books.dart';

/// Form widget for Verse entry type
/// Allows up to 7 independent verse units with translation selection
class VerseFormWidget extends StatefulWidget {
  final ValueChanged<bool> onValidityChanged;

  const VerseFormWidget({
    super.key,
    required this.onValidityChanged,
  });

  @override
  State<VerseFormWidget> createState() => VerseFormWidgetState();
}

// Make the state class public so it can be accessed via GlobalKey
class VerseFormWidgetState extends State<VerseFormWidget> {
  final List<_VerseUnit> _verseUnits = [_VerseUnit()];
  String _selectedTranslation = 'ESV';
  String? _userQuestion;

  static const List<String> _translations = ['ESV', 'NIV', 'KJV', 'NASB', 'NLT'];
  static const int _maxVerseUnits = 7;

  /// Public method to get form data
  Map<String, dynamic> getFormData() {
    return {
      'verses': _verseUnits
          .where((unit) => unit.isComplete)
          .map((unit) => {
                'book': unit.book,
                'chapter': unit.chapter,
                'verse': unit.verse,
              })
          .toList(),
      'translation': _selectedTranslation,
      'userQuestion': _userQuestion,
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
    // Form is valid if at least one verse unit is complete
    final isValid = _verseUnits.any((unit) => unit.isComplete);
    widget.onValidityChanged(isValid);
  }

  void _addVerseUnit() {
    if (_verseUnits.length < _maxVerseUnits) {
      setState(() {
        _verseUnits.add(_VerseUnit());
      });
    }
  }

  void _removeVerseUnit(int index) {
    if (_verseUnits.length > 1) {
      setState(() {
        _verseUnits.removeAt(index);
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
        // Verse units
        ...List.generate(_verseUnits.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _VerseUnitWidget(
              unit: _verseUnits[index],
              index: index,
              canRemove: _verseUnits.length > 1,
              onChanged: () {
                setState(() {
                  _validateForm();
                });
              },
              onRemove: () => _removeVerseUnit(index),
            ),
          );
        }),

        // Add verse button
        if (_verseUnits.length < _maxVerseUnits)
          OutlinedButton.icon(
            onPressed: _addVerseUnit,
            icon: const Icon(Icons.add, size: 18),
            label: Text('Add Verse (${_verseUnits.length}/$_maxVerseUnits)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF5a9fd4),
              side: const BorderSide(color: Color(0xFF5a9fd4)),
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

        // Optional question field
        Text(
          'What\'s your question? (Optional)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          maxLength: 120,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'e.g., What does this verse mean in context?',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: (value) {
            setState(() {
              _userQuestion = value.isEmpty ? null : value;
            });
          },
        ),
      ],
    );
  }
}

/// Individual verse unit widget
class _VerseUnitWidget extends StatefulWidget {
  final _VerseUnit unit;
  final int index;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _VerseUnitWidget({
    required this.unit,
    required this.index,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_VerseUnitWidget> createState() => _VerseUnitWidgetState();
}

class _VerseUnitWidgetState extends State<_VerseUnitWidget> {
  late final TextEditingController _bookController;
  late final TextEditingController _chapterController;
  late final TextEditingController _verseController;

  @override
  void initState() {
    super.initState();
    _bookController = TextEditingController(text: widget.unit.book);
    _chapterController = TextEditingController(
      text: widget.unit.chapter?.toString() ?? '',
    );
    _verseController = TextEditingController(
      text: widget.unit.verse?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _bookController.dispose();
    _chapterController.dispose();
    _verseController.dispose();
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
                'Verse ${widget.index + 1}',
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
          
          // Book autocomplete field
          Autocomplete<String>(
            initialValue: TextEditingValue(text: widget.unit.book ?? ''),
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
              widget.unit.book = selection;
              widget.onChanged();
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              _bookController.text = controller.text;
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
                  widget.unit.book = value.isEmpty ? null : value;
                  widget.onChanged();
                },
              );
            },
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              // Chapter field - number only
              Expanded(
                child: TextField(
                  controller: _chapterController,
                  decoration: InputDecoration(
                    labelText: 'Chapter',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) {
                    widget.unit.chapter = int.tryParse(value);
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Verse field - number only
              Expanded(
                child: TextField(
                  controller: _verseController,
                  decoration: InputDecoration(
                    labelText: 'Verse',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) {
                    widget.unit.verse = int.tryParse(value);
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

/// Data class for a single verse unit
class _VerseUnit {
  String? book;
  int? chapter;
  int? verse;

  bool get isComplete => book != null && chapter != null && verse != null;
}
