import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../shared/services/pdf_formatter.dart';

class BibleStudyPdfService {
  static Future<String> exportSession({
    required String studyTitle,
    required String sessionTitle,
    required String content,
  }) async {
    final pdf = pw.Document();

    final primaryColor = PdfColor.fromHex('#6B4EE6');
    final verseColor = PdfColor.fromHex('#1E88E5'); // Blue for verse references
    final textColor = PdfColors.grey900;

    final titleStyle = pw.TextStyle(
      fontSize: 24,
      fontWeight: pw.FontWeight.bold,
      color: primaryColor,
    );
    final subtitleStyle = pw.TextStyle(
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.grey700,
    );
    final headingStyle = pw.TextStyle(
      fontSize: 16,
      fontWeight: pw.FontWeight.bold,
      color: primaryColor,
    );
    final bodyStyle = pw.TextStyle(
      fontSize: 12,
      color: textColor,
      lineSpacing: 4,
    );
    final bulletStyle = pw.TextStyle(
      fontSize: 12,
      color: textColor,
      lineSpacing: 4,
    );

    final cleanContent = PdfFormatter.cleanText(content);
    final widgets = PdfFormatter.formatMarkdown(
      cleanContent,
      titleStyle: titleStyle,
      headingStyle: headingStyle,
      bodyStyle: bodyStyle,
      bulletStyle: bulletStyle,
      verseColor: verseColor,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (_) => [
          pw.Text(studyTitle, style: titleStyle),
          pw.SizedBox(height: 4),
          pw.Text(sessionTitle, style: subtitleStyle),
          pw.SizedBox(height: 24),
          ...widgets,
        ],
      ),
    );

    Directory? output;
    if (Platform.isAndroid) {
      output = Directory('/storage/emulated/0/Download');
    } else {
      output = await getDownloadsDirectory();
    }
    if (output == null || !output.existsSync()) {
      output = await getApplicationDocumentsDirectory();
    }

    final safeSession = sessionTitle
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();

    final file = File(
      '${output.path}/bible_study_${DateTime.now().millisecondsSinceEpoch}_$safeSession.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }
}
