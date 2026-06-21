import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfFormatter {
  static String cleanText(String text) {
    return text
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'")
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('…', '...');
  }

  static pw.Widget buildRichText(String text, pw.TextStyle style, PdfColor verseColor) {
    return pw.Text(text, style: style);
  }

  static List<pw.Widget> formatMarkdown(
    String text, {
    required pw.TextStyle titleStyle,
    required pw.TextStyle headingStyle,
    required pw.TextStyle bodyStyle,
    required pw.TextStyle bulletStyle,
    required PdfColor verseColor,
  }) {
    final lines = text.split('\n');
    final List<pw.Widget> widgets = [];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('#')) {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          child: pw.Text(trimmed.replaceFirst(RegExp(r'#+\s*'), ''), style: headingStyle),
        ));
      } else if (trimmed.startsWith('-') || trimmed.startsWith('*')) {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(left: 12, bottom: 4),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('• ', style: bulletStyle),
              pw.Expanded(child: pw.Text(trimmed.substring(1).trim(), style: bodyStyle)),
            ],
          ),
        ));
      } else {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Text(trimmed, style: bodyStyle),
        ));
      }
    }
    return widgets;
  }
}
