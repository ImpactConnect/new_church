import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// Service for serializing and deserializing rich text content from flutter_quill
/// 
/// This service handles conversion between flutter_quill Document objects and
/// various formats (JSON, markdown, plain text) for storage and export.
class RichTextSerializer {
  /// Serializes a flutter_quill Document to a JSON string for storage
  /// 
  /// The Document is converted to Delta format and then encoded as JSON.
  /// Returns an empty JSON array string if the document is null or empty.
  /// 
  /// Example:
  /// ```dart
  /// final document = quill.Document()..insert(0, 'Hello World');
  /// final json = RichTextSerializer.serialize(document);
  /// // Returns: '[{"insert":"Hello World\\n"}]'
  /// ```
  static String serialize(quill.Document document) {
    try {
      final delta = document.toDelta();
      return jsonEncode(delta.toJson());
    } catch (e) {
      // Return empty delta if serialization fails
      return jsonEncode([]);
    }
  }

  /// Deserializes a JSON string back to a flutter_quill Document
  /// 
  /// Converts a JSON string (Delta format) back into a Document object
  /// that can be used with QuillEditor. Returns an empty Document if
  /// the JSON is invalid or empty.
  /// 
  /// Example:
  /// ```dart
  /// final json = '[{"insert":"Hello World\\n"}]';
  /// final document = RichTextSerializer.deserialize(json);
  /// ```
  static quill.Document deserialize(String json) {
    try {
      if (json.isEmpty) {
        return quill.Document();
      }
      
      final List<dynamic> deltaJson = jsonDecode(json) as List<dynamic>;
      return quill.Document.fromJson(deltaJson);
    } catch (e) {
      // Return empty document if deserialization fails
      return quill.Document();
    }
  }

  /// Converts markdown-formatted text to a flutter_quill Document
  /// 
  /// Parses markdown syntax and converts it to proper Quill Delta format with
  /// formatting attributes. Supports:
  /// - Bold: **text** or __text__
  /// - Italic: *text* or _text_
  /// - Headings: # H1, ## H2, ### H3
  /// - Code blocks: ```code```
  /// - Inline code: `code`
  /// - Lists: - item or * item or 1. item
  /// 
  /// Example:
  /// ```dart
  /// final markdown = '**Bold** and *italic* text';
  /// final document = RichTextSerializer.fromMarkdown(markdown);
  /// ```
  static quill.Document fromMarkdown(String markdown) {
    final document = quill.Document();
    
    if (markdown.isEmpty) {
      return document;
    }
    
    final lines = markdown.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      final int startPosition = document.length - 1; // Position before the trailing newline
      
      // Handle headings
      if (line.startsWith('###')) {
        final text = line.substring(3).trim();
        if (text.isNotEmpty) {
          document.insert(startPosition, text);
          document.format(startPosition, text.length, quill.Attribute.h3);
        }
        document.insert(document.length - 1, '\n');
        continue;
      } else if (line.startsWith('##')) {
        final text = line.substring(2).trim();
        if (text.isNotEmpty) {
          document.insert(startPosition, text);
          document.format(startPosition, text.length, quill.Attribute.h2);
        }
        document.insert(document.length - 1, '\n');
        continue;
      } else if (line.startsWith('#')) {
        final text = line.substring(1).trim();
        if (text.isNotEmpty) {
          document.insert(startPosition, text);
          document.format(startPosition, text.length, quill.Attribute.h1);
        }
        document.insert(document.length - 1, '\n');
        continue;
      }

      // Handle bullet lists
      if (line.trim().startsWith('- ') || line.trim().startsWith('* ')) {
        final text = line.trim().substring(2);
        if (text.isNotEmpty) {
          final textStartPos = document.length - 1;
          _processInlineFormatting(document, text);
          final textLength = (document.length - 1) - textStartPos;
          if (textLength > 0) {
            document.format(textStartPos, textLength, quill.Attribute.ul);
          }
        }
        document.insert(document.length - 1, '\n');
        continue;
      }

      // Handle numbered lists
      final numberedListMatch = RegExp(r'^\d+\.\s+').firstMatch(line.trim());
      if (numberedListMatch != null) {
        final text = line.trim().substring(numberedListMatch.group(0)!.length);
        if (text.isNotEmpty) {
          final textStartPos = document.length - 1;
          _processInlineFormatting(document, text);
          final textLength = (document.length - 1) - textStartPos;
          if (textLength > 0) {
            document.format(textStartPos, textLength, quill.Attribute.ol);
          }
        }
        document.insert(document.length - 1, '\n');
        continue;
      }

      // Process inline formatting for regular text
      if (line.isNotEmpty) {
        _processInlineFormatting(document, line);
      }
      
      // Add newline after each line
      document.insert(document.length - 1, '\n');
    }

    return document;
  }

  /// Processes inline formatting (bold, italic, code) in a text line
  /// Inserts formatted text into the document at the current position
  static void _processInlineFormatting(quill.Document document, String text) {
    int textIndex = 0;

    while (textIndex < text.length) {
      final insertPos = document.length - 1; // Always insert before trailing newline
      
      // Check for bold (**text** or __text__)
      if (textIndex + 2 < text.length && 
          (text.substring(textIndex, textIndex + 2) == '**' || 
           text.substring(textIndex, textIndex + 2) == '__')) {
        final delimiter = text.substring(textIndex, textIndex + 2);
        final endIndex = text.indexOf(delimiter, textIndex + 2);
        
        if (endIndex != -1) {
          final boldText = text.substring(textIndex + 2, endIndex);
          if (boldText.isNotEmpty) {
            document.insert(insertPos, boldText);
            document.format(insertPos, boldText.length, quill.Attribute.bold);
          }
          textIndex = endIndex + 2;
          continue;
        }
      }

      // Check for italic (*text* or _text_)
      if (textIndex < text.length && 
          (text[textIndex] == '*' || text[textIndex] == '_')) {
        final delimiter = text[textIndex];
        final endIndex = text.indexOf(delimiter, textIndex + 1);
        
        if (endIndex != -1 && endIndex != textIndex + 1) {
          final italicText = text.substring(textIndex + 1, endIndex);
          if (italicText.isNotEmpty) {
            document.insert(insertPos, italicText);
            document.format(insertPos, italicText.length, quill.Attribute.italic);
          }
          textIndex = endIndex + 1;
          continue;
        }
      }

      // Check for inline code (`code`)
      if (textIndex < text.length && text[textIndex] == '`') {
        final endIndex = text.indexOf('`', textIndex + 1);
        
        if (endIndex != -1) {
          final codeText = text.substring(textIndex + 1, endIndex);
          if (codeText.isNotEmpty) {
            document.insert(insertPos, codeText);
            document.format(insertPos, codeText.length, quill.Attribute.inlineCode);
          }
          textIndex = endIndex + 1;
          continue;
        }
      }

      // Regular character
      document.insert(insertPos, text[textIndex]);
      textIndex += 1;
    }
  }

  /// Converts a flutter_quill Document to markdown format for export
  /// 
  /// Iterates through the Delta operations and converts formatting to
  /// markdown syntax. Supports:
  /// - Bold: **text**
  /// - Italic: *text*
  /// - Headings: # H1, ## H2, ### H3
  /// - Lists: - item or 1. item
  /// - Code blocks: ```code```
  /// - Links: [text](url)
  /// 
  /// Example:
  /// ```dart
  /// final document = quill.Document()..insert(0, 'Hello', {'bold': true});
  /// final markdown = RichTextSerializer.toMarkdown(document);
  /// // Returns: '**Hello**'
  /// ```
  static String toMarkdown(quill.Document document) {
    try {
      final delta = document.toDelta();
      final StringBuffer buffer = StringBuffer();
      
      for (final op in delta.toList()) {
        if (op.isInsert) {
          String text = op.data.toString();
          final attributes = op.attributes;
          
          if (attributes != null) {
            // Handle headings
            if (attributes.containsKey('header')) {
              final level = attributes['header'] as int;
              final prefix = '#' * level;
              text = '$prefix $text';
            }
            
            // Handle code blocks
            if (attributes.containsKey('code-block')) {
              text = '```\n$text```\n';
            }
            
            // Handle lists
            if (attributes.containsKey('list')) {
              final listType = attributes['list'];
              if (listType == 'bullet') {
                text = '- $text';
              } else if (listType == 'ordered') {
                text = '1. $text';
              }
            }
            
            // Handle inline formatting (bold, italic, underline)
            if (attributes.containsKey('bold')) {
              text = '**$text**';
            }
            if (attributes.containsKey('italic')) {
              text = '*$text*';
            }
            if (attributes.containsKey('underline')) {
              text = '<u>$text</u>'; // Markdown doesn't have native underline
            }
            
            // Handle links
            if (attributes.containsKey('link')) {
              final url = attributes['link'];
              text = '[$text]($url)';
            }
          }
          
          buffer.write(text);
        }
      }
      
      return buffer.toString();
    } catch (e) {
      return '';
    }
  }

  /// Extracts plain text from a flutter_quill Document (removes all formatting)
  /// 
  /// Strips all formatting attributes and returns only the text content.
  /// Useful for search indexing, character counting, and plain text export.
  /// 
  /// Example:
  /// ```dart
  /// final document = quill.Document()
  ///   ..insert(0, 'Hello', {'bold': true})
  ///   ..insert(5, ' World');
  /// final plainText = RichTextSerializer.toPlainText(document);
  /// // Returns: 'Hello World'
  /// ```
  static String toPlainText(quill.Document document) {
    try {
      final delta = document.toDelta();
      final StringBuffer buffer = StringBuffer();
      
      for (final op in delta.toList()) {
        if (op.isInsert) {
          buffer.write(op.data.toString());
        }
      }
      
      return buffer.toString().trim();
    } catch (e) {
      return '';
    }
  }
}
