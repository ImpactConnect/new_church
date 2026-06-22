import '../data/models/standalone_note_model.dart';

/// Export format options
enum ExportFormat {
  pdf,
  markdown,
  plainText,
  json,
}

/// Abstract interface for note export service
abstract class ExportService {
  /// Exports a note to PDF format
  /// Returns the file path of the exported PDF
  Future<String> exportToPdf(StandaloneNote note);

  /// Exports a note to Markdown format
  /// Returns the file path of the exported markdown file
  Future<String> exportToMarkdown(StandaloneNote note);

  /// Exports a note to plain text format
  /// Returns the file path of the exported text file
  Future<String> exportToPlainText(StandaloneNote note);

  /// Exports a note to JSON format
  /// Returns the file path of the exported JSON file
  Future<String> exportToJson(StandaloneNote note);

  /// Exports multiple notes in a single file
  /// Returns the file path of the exported file
  Future<String> exportMultiple(
    List<StandaloneNote> notes,
    ExportFormat format,
  );
}
