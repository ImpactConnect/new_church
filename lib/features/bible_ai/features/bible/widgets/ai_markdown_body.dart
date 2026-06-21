import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../config/app_colors.dart';
import '../../../../pneuma_ai/shared/widgets/bible_passage_bottom_sheet.dart';

/// A reusable widget that renders text as Markdown and automatically finds and linkifies
/// Bible verse references, opening the BiblePassageBottomSheet when tapped.
class AiMarkdownBody extends StatelessWidget {
  final String data;
  final TextStyle? baseStyle;

  const AiMarkdownBody({super.key, required this.data, this.baseStyle});

  /// Pre-processes the text, finding Bible references and converting them to Markdown links
  String _preprocessText(String text) {
    if (text.isEmpty) return text;
    // Basic regex to catch patterns like "John 3:16", "1 John 2:4", "Genesis 1:1-3"
    final verseRegex = RegExp(
      r'\b(?:[123]\s)?[A-Z][a-z]+(?:\s[a-z]+\s[A-Z][a-z]+|\s[A-Z][a-z]+)?\s\d{1,3}:\d{1,3}(?:-\d{1,3})?\b',
    );
    return text.replaceAllMapped(verseRegex, (match) {
      final verse = match.group(0)!;
      final normalized = _normalizeReference(verse);
      final encoded = Uri.encodeComponent(normalized);
      return '[$verse](verse://$encoded)';
    });
  }

  /// Normalizes a reference by stripping common prepositions and fixing pluralization issues.
  String _normalizeReference(String ref) {
    String normalized = ref.trim();

    // 1. Strip common leading prepositions that AI might attach
    final prepositions = [
      'In',
      'From',
      'See',
      'Read',
      'Cf',
      'According to',
      'Quote',
      'Reference',
      'Refer to',
    ];

    bool changed = true;
    while (changed) {
      changed = false;
      for (final prep in prepositions) {
        final pattern = RegExp('^$prep\\s+', caseSensitive: false);
        if (pattern.hasMatch(normalized)) {
          normalized = normalized.replaceFirst(pattern, '').trim();
          changed = true;
        }
      }
    }

    // 2. Handle Psalm vs Psalms (App uses "Psalms")
    final psalmPattern = RegExp(r'^Psalm\b', caseSensitive: false);
    if (psalmPattern.hasMatch(normalized)) {
      if (!normalized.toLowerCase().startsWith('psalms')) {
        normalized = normalized.replaceFirst(psalmPattern, 'Psalms');
      }
    }

    return normalized;
  }

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: _preprocessText(data),
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p:
            baseStyle ??
            TextStyle(
              height: 1.6,
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface,
            ),
        a: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
        ),
        h1: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        h2: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        h3: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        h4: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        h5: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        h6: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        strong: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
      ),
      onTapLink: (text, href, title) {
        if (href != null && href.startsWith('verse://')) {
          final verse = Uri.decodeComponent(href.replaceFirst('verse://', ''));
          showBiblePassageBottomSheet(context, verse);
        }
      },
    );
  }
}
