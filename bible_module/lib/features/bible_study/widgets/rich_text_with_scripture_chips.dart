import 'package:flutter/material.dart';
import '../services/scripture_reference_parser.dart';
import 'inline_scripture_chip.dart';

/// Widget that renders text with inline tappable scripture chips
/// Parses scripture references and replaces them with InlineScriptureChip widgets
class RichTextWithScriptureChips extends StatelessWidget {
  final String text;
  final Color accentColor;
  final TextStyle? textStyle;
  final Function(String reference)? onChipTap;

  const RichTextWithScriptureChips({
    super.key,
    required this.text,
    required this.accentColor,
    this.textStyle,
    this.onChipTap,
  });

  @override
  Widget build(BuildContext context) {
    final references = ScriptureReferenceParser.parse(text);
    
    // If no references found, return plain text
    if (references.isEmpty) {
      return Text(
        text,
        style: textStyle ?? const TextStyle(
          fontFamily: 'Spectral',
          fontSize: 15,
          height: 1.75,
        ),
      );
    }
    
    // Build text spans with scripture chips
    final spans = <InlineSpan>[];
    int currentIndex = 0;
    
    for (final ref in references) {
      // Add text before the reference
      if (ref.start > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, ref.start),
        ));
      }
      
      // Add scripture chip
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: InlineScriptureChip(
            reference: ref.reference,
            accentColor: accentColor,
            onTap: onChipTap != null ? () => onChipTap!(ref.reference) : () {},
          ),
        ),
      ));
      
      currentIndex = ref.end;
    }
    
    // Add remaining text
    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
      ));
    }
    
    return Text.rich(
      TextSpan(
        children: spans,
        style: textStyle ?? const TextStyle(
          fontFamily: 'Spectral',
          fontSize: 15,
          height: 1.75,
        ),
      ),
    );
  }
}
