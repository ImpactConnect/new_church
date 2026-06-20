/// Service for parsing scripture references from text
/// Supports formats: (Romans 8:1), (John 3:16), (Genesis 12:1–3), (cf. Psalm 22:1; Matthew 27:46)
/// Also supports references without parentheses: Romans 8:1, John 3:16, etc.
class ScriptureReferenceParser {
  /// Parse scripture references from text and return list of matches
  /// Returns list of maps with 'reference' and 'start'/'end' positions
  static List<ScriptureReference> parse(String text) {
    final references = <ScriptureReference>[];
    
    // Pattern 1: References in parentheses (exegesis style)
    final parenthesesPattern = RegExp(
      r'\((?:cf\.\s+)?([^)]+)\)',
      caseSensitive: false,
    );
    
    final parenthesesMatches = parenthesesPattern.allMatches(text);
    
    for (final match in parenthesesMatches) {
      final fullMatch = match.group(0)!;
      final content = match.group(1)!;
      
      // Check if this looks like a scripture reference
      if (!content.contains(RegExp(r'\d'))) {
        continue;
      }
      
      // Split by semicolons for multiple references
      final parts = content.split(';');
      
      for (final part in parts) {
        final trimmed = part.trim();
        
        if (_isScriptureReference(trimmed)) {
          references.add(ScriptureReference(
            reference: trimmed,
            start: match.start,
            end: match.end,
            fullMatch: fullMatch,
          ));
        }
      }
    }
    
    // Pattern 2: References without parentheses (bible study style)
    // Matches: Book Chapter:Verse or Book Chapter:Verse-Verse
    final plainPattern = RegExp(
      r'\b(?:\d\s+)?[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\s+\d+:\d+(?:[-–]\d+)?(?:;\s*\d+:\d+(?:[-–]\d+)?)*\b',
      caseSensitive: true,
    );
    
    final plainMatches = plainPattern.allMatches(text);
    
    for (final match in plainMatches) {
      final reference = match.group(0)!;
      
      // Skip if this reference is already inside parentheses (already captured)
      bool insideParentheses = false;
      for (final parenMatch in parenthesesMatches) {
        if (match.start >= parenMatch.start && match.end <= parenMatch.end) {
          insideParentheses = true;
          break;
        }
      }
      
      if (!insideParentheses && _isScriptureReference(reference)) {
        references.add(ScriptureReference(
          reference: reference,
          start: match.start,
          end: match.end,
          fullMatch: reference,
        ));
      }
    }
    
    // Sort by position in text
    references.sort((a, b) => a.start.compareTo(b.start));
    
    return references;
  }
  
  /// Check if a string looks like a scripture reference
  static bool _isScriptureReference(String text) {
    // Must contain at least one letter (book name) and one digit (chapter/verse)
    final hasLetter = text.contains(RegExp(r'[a-zA-Z]'));
    final hasDigit = text.contains(RegExp(r'\d'));
    
    if (!hasLetter || !hasDigit) {
      return false;
    }
    
    // Common scripture reference patterns
    final scripturePattern = RegExp(
      r'^(?:cf\.\s+)?(?:\d\s+)?[A-Za-z]+(?:\s+[A-Za-z]+)*\s+\d+(?::\d+)?(?:[-–]\d+)?$',
    );
    
    return scripturePattern.hasMatch(text.trim());
  }
  
  /// Extract book name from a scripture reference
  static String extractBook(String reference) {
    var cleaned = reference.replaceFirst(RegExp(r'^cf\.\s+', caseSensitive: false), '');
    final match = RegExp(r'^((?:\d\s+)?[A-Za-z]+(?:\s+[A-Za-z]+)*)\s+\d+').firstMatch(cleaned);
    
    if (match != null) {
      return match.group(1)!.trim();
    }
    
    return cleaned;
  }
  
  /// Extract chapter and verse from a scripture reference
  static Map<String, dynamic> extractChapterVerse(String reference) {
    var cleaned = reference.replaceFirst(RegExp(r'^cf\.\s+', caseSensitive: false), '');
    final match = RegExp(r'(\d+)(?::(\d+))?(?:[-–](\d+))?').firstMatch(cleaned);
    
    if (match != null) {
      final chapter = int.tryParse(match.group(1) ?? '');
      final verse = int.tryParse(match.group(2) ?? '');
      final endVerse = int.tryParse(match.group(3) ?? '');
      
      return {
        'chapter': chapter,
        'verse': verse,
        'endVerse': endVerse,
      };
    }
    
    return {};
  }
}

/// Represents a parsed scripture reference
class ScriptureReference {
  final String reference;
  final int start;
  final int end;
  final String fullMatch;
  
  const ScriptureReference({
    required this.reference,
    required this.start,
    required this.end,
    required this.fullMatch,
  });
  
  @override
  String toString() => reference;
}
