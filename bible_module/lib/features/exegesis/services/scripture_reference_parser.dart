/// Service for parsing scripture references from text
/// Supports formats: (Romans 8:1), (John 3:16), (Genesis 12:1–3), (cf. Psalm 22:1; Matthew 27:46)
class ScriptureReferenceParser {
  /// Parse scripture references from text and return list of matches
  /// Returns list of maps with 'reference' and 'start'/'end' positions
  static List<ScriptureReference> parse(String text) {
    final references = <ScriptureReference>[];
    
    // Regex pattern for scripture references in parentheses
    // Matches: (Book Chapter:Verse), (Book Chapter:Verse-Verse), (cf. Book Chapter:Verse)
    // Supports multiple references separated by semicolons
    final pattern = RegExp(
      r'\((?:cf\.\s+)?([^)]+)\)',
      caseSensitive: false,
    );
    
    final matches = pattern.allMatches(text);
    
    for (final match in matches) {
      final fullMatch = match.group(0)!;
      final content = match.group(1)!;
      
      // Check if this looks like a scripture reference
      // Must contain at least one digit (chapter/verse number)
      if (!content.contains(RegExp(r'\d'))) {
        continue;
      }
      
      // Split by semicolons for multiple references
      final parts = content.split(';');
      
      for (final part in parts) {
        final trimmed = part.trim();
        
        // Check if it looks like a scripture reference
        // Should have format: Book Chapter:Verse or Book Chapter
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
    // Book Chapter:Verse (e.g., "Romans 8:1")
    // Book Chapter:Verse-Verse (e.g., "Genesis 12:1-3")
    // Book Chapter (e.g., "Psalm 23")
    final scripturePattern = RegExp(
      r'^(?:cf\.\s+)?(?:\d\s+)?[A-Za-z]+(?:\s+[A-Za-z]+)*\s+\d+(?::\d+)?(?:[-–]\d+)?$',
    );
    
    return scripturePattern.hasMatch(text.trim());
  }
  
  /// Extract book name from a scripture reference
  static String extractBook(String reference) {
    // Remove "cf." prefix if present
    var cleaned = reference.replaceFirst(RegExp(r'^cf\.\s+', caseSensitive: false), '');
    
    // Extract book name (everything before the first digit)
    final match = RegExp(r'^((?:\d\s+)?[A-Za-z]+(?:\s+[A-Za-z]+)*)\s+\d+').firstMatch(cleaned);
    
    if (match != null) {
      return match.group(1)!.trim();
    }
    
    return cleaned;
  }
  
  /// Extract chapter and verse from a scripture reference
  static Map<String, dynamic> extractChapterVerse(String reference) {
    // Remove "cf." prefix if present
    var cleaned = reference.replaceFirst(RegExp(r'^cf\.\s+', caseSensitive: false), '');
    
    // Extract chapter and verse
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
