import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../data/models/standalone_note_model.dart';
import 'export_service.dart';
import 'rich_text_serializer.dart';

/// Implementation of ExportService for exporting notes to various formats
class NoteExportService implements ExportService {
  @override
  Future<String> exportToPdf(StandaloneNote note) async {
    try {
      final pdf = pw.Document();
      final plainText = RichTextSerializer.toPlainText(
        RichTextSerializer.deserialize(note.richTextContent),
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Title
                pw.Text(
                  note.title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),

                // Metadata
                pw.Text(
                  'Created: ${note.createdAt.toString().split('.')[0]}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
                pw.Text(
                  'Modified: ${note.lastModifiedAt.toString().split('.')[0]}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
                pw.SizedBox(height: 16),

                // Tags
                if (note.tags.isNotEmpty) ...[
                  pw.Text(
                    'Tags: ${note.tags.join(', ')}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.SizedBox(height: 16),
                ],

                pw.Divider(),
                pw.SizedBox(height: 16),

                // Content
                pw.Text(
                  plainText,
                  style: const pw.TextStyle(fontSize: 12),
                ),

                // Linked content
                if (note.linkedContent.isNotEmpty) ...[
                  pw.SizedBox(height: 24),
                  pw.Divider(),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'Linked Content',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  ...note.linkedContent.map((ref) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Text(
                        '• ${ref.type.name.toUpperCase()}: ${ref.sourceReference}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    );
                  }),
                ],
              ],
            );
          },
        ),
      );

      // Save PDF to Downloads folder
      Directory dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!dir.existsSync()) {
          dir = await getApplicationDocumentsDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final fileName = '${note.title.replaceAll(RegExp(r'[^\w\s-]'), '')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e) {
      throw Exception('Failed to export to PDF: $e');
    }
  }

  @override
  Future<String> exportToMarkdown(StandaloneNote note) async {
    try {
      final markdown = RichTextSerializer.toMarkdown(
        RichTextSerializer.deserialize(note.richTextContent),
      );

      final buffer = StringBuffer();
      buffer.writeln('# ${note.title}');
      buffer.writeln();
      buffer.writeln('**Created:** ${note.createdAt.toString().split('.')[0]}');
      buffer.writeln('**Modified:** ${note.lastModifiedAt.toString().split('.')[0]}');
      buffer.writeln();

      if (note.tags.isNotEmpty) {
        buffer.writeln('**Tags:** ${note.tags.join(', ')}');
        buffer.writeln();
      }

      buffer.writeln('---');
      buffer.writeln();
      buffer.writeln(markdown);

      if (note.linkedContent.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('---');
        buffer.writeln();
        buffer.writeln('## Linked Content');
        buffer.writeln();
        for (final ref in note.linkedContent) {
          buffer.writeln('- **${ref.type.name.toUpperCase()}**: ${ref.sourceReference}');
        }
      }

      // Save to Downloads folder
      Directory dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!dir.existsSync()) {
          dir = await getApplicationDocumentsDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final fileName = '${note.title.replaceAll(RegExp(r'[^\w\s-]'), '')}_${DateTime.now().millisecondsSinceEpoch}.md';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(buffer.toString());

      return file.path;
    } catch (e) {
      throw Exception('Failed to export to Markdown: $e');
    }
  }

  @override
  Future<String> exportToPlainText(StandaloneNote note) async {
    try {
      final plainText = RichTextSerializer.toPlainText(
        RichTextSerializer.deserialize(note.richTextContent),
      );

      final buffer = StringBuffer();
      buffer.writeln(note.title);
      buffer.writeln('=' * note.title.length);
      buffer.writeln();
      buffer.writeln('Created: ${note.createdAt.toString().split('.')[0]}');
      buffer.writeln('Modified: ${note.lastModifiedAt.toString().split('.')[0]}');
      buffer.writeln();

      if (note.tags.isNotEmpty) {
        buffer.writeln('Tags: ${note.tags.join(', ')}');
        buffer.writeln();
      }

      buffer.writeln('-' * 50);
      buffer.writeln();
      buffer.writeln(plainText);

      if (note.linkedContent.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('-' * 50);
        buffer.writeln();
        buffer.writeln('Linked Content:');
        buffer.writeln();
        for (final ref in note.linkedContent) {
          buffer.writeln('- ${ref.type.name.toUpperCase()}: ${ref.sourceReference}');
        }
      }

      // Save to Downloads folder
      Directory dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!dir.existsSync()) {
          dir = await getApplicationDocumentsDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final fileName = '${note.title.replaceAll(RegExp(r'[^\w\s-]'), '')}_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(buffer.toString());

      return file.path;
    } catch (e) {
      throw Exception('Failed to export to plain text: $e');
    }
  }

  @override
  Future<String> exportToJson(StandaloneNote note) async {
    try {
      final jsonData = note.toJson();
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

      // Save to Downloads folder
      Directory dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!dir.existsSync()) {
          dir = await getApplicationDocumentsDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final fileName = '${note.title.replaceAll(RegExp(r'[^\w\s-]'), '')}_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      throw Exception('Failed to export to JSON: $e');
    }
  }

  @override
  Future<String> exportMultiple(
    List<StandaloneNote> notes,
    ExportFormat format,
  ) async {
    try {
      switch (format) {
        case ExportFormat.pdf:
          return await _exportMultipleToPdf(notes);
        case ExportFormat.markdown:
          return await _exportMultipleToMarkdown(notes);
        case ExportFormat.plainText:
          return await _exportMultipleToPlainText(notes);
        case ExportFormat.json:
          return await _exportMultipleToJson(notes);
      }
    } catch (e) {
      throw Exception('Failed to export multiple notes: $e');
    }
  }

  Future<String> _exportMultipleToPdf(List<StandaloneNote> notes) async {
    final pdf = pw.Document();

    for (var i = 0; i < notes.length; i++) {
      final note = notes[i];
      final plainText = RichTextSerializer.toPlainText(
        RichTextSerializer.deserialize(note.richTextContent),
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  note.title,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Created: ${note.createdAt.toString().split('.')[0]}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
                ),
                pw.SizedBox(height: 12),
                pw.Text(plainText, style: const pw.TextStyle(fontSize: 11)),
                if (i < notes.length - 1) ...[
                  pw.SizedBox(height: 24),
                  pw.Divider(),
                ],
              ],
            );
          },
        ),
      );
    }

    // Save to Downloads folder
    Directory dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download');
      if (!dir.existsSync()) {
        dir = await getApplicationDocumentsDirectory();
      }
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final fileName = 'notes_export_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  Future<String> _exportMultipleToMarkdown(List<StandaloneNote> notes) async {
    final buffer = StringBuffer();
    buffer.writeln('# Notes Export');
    buffer.writeln();
    buffer.writeln('Exported: ${DateTime.now().toString().split('.')[0]}');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    for (var i = 0; i < notes.length; i++) {
      final note = notes[i];
      final markdown = RichTextSerializer.toMarkdown(
        RichTextSerializer.deserialize(note.richTextContent),
      );

      buffer.writeln('## ${note.title}');
      buffer.writeln();
      buffer.writeln('**Created:** ${note.createdAt.toString().split('.')[0]}');
      if (note.tags.isNotEmpty) {
        buffer.writeln('**Tags:** ${note.tags.join(', ')}');
      }
      buffer.writeln();
      buffer.writeln(markdown);
      
      if (i < notes.length - 1) {
        buffer.writeln();
        buffer.writeln('---');
        buffer.writeln();
      }
    }

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'notes_export_${DateTime.now().millisecondsSinceEpoch}.md';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(buffer.toString());

    return file.path;
  }

  Future<String> _exportMultipleToPlainText(List<StandaloneNote> notes) async {
    final buffer = StringBuffer();
    buffer.writeln('NOTES EXPORT');
    buffer.writeln('=' * 50);
    buffer.writeln();
    buffer.writeln('Exported: ${DateTime.now().toString().split('.')[0]}');
    buffer.writeln();

    for (var i = 0; i < notes.length; i++) {
      final note = notes[i];
      final plainText = RichTextSerializer.toPlainText(
        RichTextSerializer.deserialize(note.richTextContent),
      );

      buffer.writeln('-' * 50);
      buffer.writeln(note.title);
      buffer.writeln('-' * 50);
      buffer.writeln();
      buffer.writeln('Created: ${note.createdAt.toString().split('.')[0]}');
      if (note.tags.isNotEmpty) {
        buffer.writeln('Tags: ${note.tags.join(', ')}');
      }
      buffer.writeln();
      buffer.writeln(plainText);
      
      if (i < notes.length - 1) {
        buffer.writeln();
        buffer.writeln();
      }
    }

    // Save to Downloads folder
    Directory dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download');
      if (!dir.existsSync()) {
        dir = await getApplicationDocumentsDirectory();
      }
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final fileName = 'notes_export_${DateTime.now().millisecondsSinceEpoch}.txt';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(buffer.toString());

    return file.path;
  }

  Future<String> _exportMultipleToJson(List<StandaloneNote> notes) async {
    final jsonData = {
      'exportedAt': DateTime.now().toIso8601String(),
      'notesCount': notes.length,
      'notes': notes.map((note) => note.toJson()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

    // Save to Downloads folder
    Directory dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download');
      if (!dir.existsSync()) {
        dir = await getApplicationDocumentsDirectory();
      }
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final fileName = 'notes_export_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(jsonString);

    return file.path;
  }
}
