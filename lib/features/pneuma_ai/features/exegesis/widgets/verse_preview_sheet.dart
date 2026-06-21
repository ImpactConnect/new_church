import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_mobile/features/bible_ai/features/bible/providers/bible_providers.dart';

class VersePreviewSheet extends ConsumerStatefulWidget {
  final String reference;
  
  const VersePreviewSheet({
    super.key,
    required this.reference,
  });

  @override
  ConsumerState<VersePreviewSheet> createState() => _VersePreviewSheetState();
}

class _VersePreviewSheetState extends ConsumerState<VersePreviewSheet> {
  bool _isLoading = true;
  String? _verseText;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchVerse();
  }

  Future<void> _fetchVerse() async {
    try {
      final repo = ref.read(bibleRepositoryProvider);
      final version = ref.read(bibleVersionNotifierProvider);
      
      final parsed = _parseReference(widget.reference);
      
      if (parsed == null) {
        setState(() {
          _error = 'Could not parse reference layout format.';
          _isLoading = false;
        });
        return;
      }

      final book = await repo.getBook(parsed.book, version);
      if (book != null) {
        final chapterData = book.chapters.firstWhere(
          (c) => c.number == parsed.chapter,
          orElse: () => throw Exception('Chapter not found'),
        );
        
        final verse = chapterData.verses.firstWhere(
          (v) => v.number == parsed.verseStart,
          orElse: () => throw Exception('Verse not found in chapter'),
        );
        
        setState(() {
          _verseText = verse.text;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load chapter content.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Simplified parser for typical "Book C:V" formats
  _ParsedReference? _parseReference(String refStr) {
    try {
      final parts = refStr.trim().split(' ');
      if (parts.length < 2) return null;
      
      String bookName;
      String chapterVerse;
      
      if (int.tryParse(parts[0]) != null && parts.length >= 3) {
        // Handles "1 John 3:16"
        bookName = '${parts[0]} ${parts[1]}';
        chapterVerse = parts[2];
      } else {
        // Handles "John 3:16"
        bookName = parts[0];
        chapterVerse = parts[1];
      }
      
      final cvParts = chapterVerse.split(':');
      if (cvParts.length != 2) return null;
      
      final chapter = int.parse(cvParts[0]);
      
      final verseParts = cvParts[1].split('-');
      final startVerse = int.parse(verseParts[0]);
      final endVerse = verseParts.length > 1 ? int.parse(verseParts[1]) : startVerse;
      
      return _ParsedReference(bookName, chapter, startVerse, endVerse);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.reference,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ))
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Could not load verse: $_error\nOpen Bible reader to view instead.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            )
          else
            Text(
              _verseText ?? '',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                // Navigate to Bible reader
                Navigator.of(context).pop();
                // TODO: Route to Bible screen with specific coordinates
              },
              icon: const Icon(Icons.menu_book),
              label: const Text('Read Full Chapter'),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _ParsedReference {
  final String book;
  final int chapter;
  final int verseStart;
  final int verseEnd;
  
  _ParsedReference(this.book, this.chapter, this.verseStart, this.verseEnd);
}
