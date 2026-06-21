import 'package:flutter/material.dart';
import '../constants/bible_books.dart';

/// Form widget for Book entry type
/// Autocomplete book selector with translation selection
class BookFormWidget extends StatefulWidget {
  final ValueChanged<bool> onValidityChanged;

  const BookFormWidget({
    super.key,
    required this.onValidityChanged,
  });

  @override
  State<BookFormWidget> createState() => BookFormWidgetState();
}

// Make the state class public so it can be accessed via GlobalKey
class BookFormWidgetState extends State<BookFormWidget> {
  String? _selectedBook;
  String _selectedTranslation = 'ESV';

  static const List<String> _translations = ['ESV', 'NIV', 'KJV', 'NASB', 'NLT'];

  /// Public method to get form data
  Map<String, dynamic> getFormData() {
    return {
      'book': _selectedBook ?? '',
      'translation': _selectedTranslation,
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
    widget.onValidityChanged(_selectedBook != null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Book autocomplete field
        Text(
          'Select a Book',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Autocomplete<String>(
          initialValue: TextEditingValue(text: _selectedBook ?? ''),
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
            setState(() {
              _selectedBook = selection;
              _validateForm();
            });
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'Type to search for a book...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (value) {
                setState(() {
                  _selectedBook = value.isEmpty ? null : value;
                  _validateForm();
                });
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 300,
                    maxWidth: 400,
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(option),
                        onTap: () {
                          onSelected(option);
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
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

        // Info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFd4a84f).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFd4a84f).withOpacity(0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: const Color(0xFFd4a84f),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This will provide a comprehensive study of the entire book, including its structure, themes, and theological significance.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
