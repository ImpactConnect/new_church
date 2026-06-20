import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

import '../../../data/models/ai/chat_session_model.dart';
import '../../../data/models/ai/ai_models.dart';
import '../../../shared/services/pdf_formatter.dart';

class ChatPdfService {
  static Future<String> exportChatSession(
    ChatSessionModel session,
    List<ChatMessage> messages,
  ) async {
    final pdf = pw.Document();

    final verseColor = PdfColor.fromHex('#1E88E5');

    final headerStyle = pw.TextStyle(
      fontSize: 22,
      fontWeight: pw.FontWeight.bold,
      color: PdfColor.fromHex('#6B4EE6'),
    );
    final sectionTitleStyle = pw.TextStyle(
      fontSize: 16,
      fontWeight: pw.FontWeight.bold,
      color: PdfColor.fromHex('#6B4EE6'),
    );
    final userStyle = pw.TextStyle(
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.black,
    );
    final aiStyle = const pw.TextStyle(fontSize: 12, color: PdfColors.grey800);
    final bulletStyle = const pw.TextStyle(
      fontSize: 12,
      color: PdfColors.grey800,
    );

    List<pw.Widget> buildAiMessage(String text) {
      if (text.isEmpty) return [];
      return PdfFormatter.formatMarkdown(
        PdfFormatter.cleanText(text),
        titleStyle: headerStyle,
        headingStyle: sectionTitleStyle,
        bodyStyle: aiStyle,
        bulletStyle: bulletStyle,
        verseColor: verseColor,
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        footer: (context) => pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Divider(color: PdfColors.grey300, thickness: 1),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated from the illuminare App',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
                ),
              ],
            ),
          ],
        ),
        build: (context) => [
          // Title Section
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Ask Rabbi Conversation',
                style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 4),
              pw.Text(session.title, style: headerStyle),
              pw.SizedBox(height: 12),
              pw.Divider(color: PdfColor.fromHex('#6B4EE6'), thickness: 1),
              pw.SizedBox(height: 16),
            ],
          ),

          // Messages
          ...messages.where((m) => !m.isHidden).map((msg) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    msg.isUser ? 'You:' : 'Rabbi:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: msg.isUser
                          ? PdfColors.blue600
                          : PdfColor.fromHex('#6B4EE6'),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  if (msg.isUser)
                    pw.Text(
                      PdfFormatter.cleanText(msg.message.trim()),
                      style: userStyle,
                    )
                  else
                    ...buildAiMessage(msg.message.trim()),
                ],
              ),
            );
          }),
        ],
      ),
    );

    final sanitized = session.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();

    final fileName = 'ask_rabbi_$sanitized.pdf';

    Directory? dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download');
    } else {
      dir = await getDownloadsDirectory();
    }
    if (dir == null || !dir.existsSync()) {
      dir = await getApplicationDocumentsDirectory();
    }

    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }
}
