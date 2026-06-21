import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

import '../models/exegesis_final_model.dart';
import '../../../shared/services/pdf_formatter.dart';

class ExegesisPdfServiceFinal {
  static Future<String> exportPdf(dynamic result) async {
    final pdf = pw.Document();

    final primaryColor = PdfColor.fromHex('#6B4EE6');
    final accentColor = PdfColor.fromHex('#9C88FF');
    final textColor = PdfColors.grey900;
    final lightGrey = PdfColor.fromHex('#F5F3FF');
    final verseColor = PdfColor.fromHex('#1E88E5');

    final titleStyle = pw.TextStyle(
      fontSize: 22,
      fontWeight: pw.FontWeight.bold,
      color: primaryColor,
    );
    final sectionStyle = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
      color: primaryColor,
    );
    final subStyle = pw.TextStyle(
      fontSize: 11,
      fontWeight: pw.FontWeight.bold,
      color: accentColor,
    );
    final bodyStyle = pw.TextStyle(
      fontSize: 11,
      color: textColor,
      lineSpacing: 5,
    );
    final smallStyle = pw.TextStyle(
      fontSize: 10,
      color: PdfColors.grey600,
      lineSpacing: 4,
    );

    String clean(String text) {
      return PdfFormatter.cleanText(text);
    }

    pw.Widget section(String title) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 16, bottom: 6),
      child: pw.Row(
        children: [
          pw.Container(
            width: 4,
            height: 16,
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(title, style: sectionStyle),
        ],
      ),
    );

    pw.Widget sub(String title) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
      child: pw.Text(title, style: subStyle),
    );

    pw.Widget body(String text) {
      final c = clean(text);
      if (c.isEmpty) return pw.SizedBox();
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: PdfFormatter.buildRichText(c, bodyStyle, verseColor),
      );
    }

    pw.Widget chip(String text) {
      final c = clean(text);
      if (c.isEmpty) return pw.SizedBox();
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: pw.BoxDecoration(
          color: lightGrey,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Text(c, style: smallStyle),
      );
    }

    pw.Widget divider() => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Divider(color: PdfColor.fromHex('#E0DCFF'), thickness: 0.5),
    );

    // Determine if verse or topic using direct typed locals
    final VerseExegesis? verseResult = result is VerseExegesis ? result : null;
    final TopicExegesis? topicResult = result is TopicExegesis ? result : null;
    final isVerse = verseResult != null;
    final subject = isVerse ? verseResult.subject : topicResult!.subject;

    final List<pw.Widget> pageWidgets = [];

    // ── Header ──
    pageWidgets.addAll([
      pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: lightGrey,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'ILLUMINE Deep Biblical Study',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 4),
            pw.Text(clean(subject), style: titleStyle),
            pw.SizedBox(height: 4),
            pw.Text(
              isVerse ? 'Verse Analysis' : 'Topic Study',
              style: pw.TextStyle(fontSize: 11, color: accentColor),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 8),
      pw.Divider(color: primaryColor, thickness: 1),
      pw.SizedBox(height: 8),
    ]);

    if (isVerse) {
      final e = verseResult;

      // Layer 1
      pageWidgets.add(section('1. The Orienting Insight'));
      pageWidgets.add(body(e.bigPicture));

      // Layer 2
      pageWidgets.add(section('2. Historical & Cultural Setting'));
      pageWidgets.add(body(e.historicalCulturalSetting.world));
      for (final k in e.historicalCulturalSetting.specificCulturalKeys) {
        if (k.item.isNotEmpty) {
          pageWidgets.add(sub(k.item));
          pageWidgets.add(body(k.howItShapesReading));
        }
      }

      // Layer 3
      pageWidgets.add(section('3. Literary & Structural Context'));
      if (e.literaryContext.genre.isNotEmpty)
        pageWidgets.add(chip(e.literaryContext.genre));
      pageWidgets.add(sub('Before this text'));
      pageWidgets.add(body(e.literaryContext.immediateBefore));
      pageWidgets.add(sub('After this text'));
      pageWidgets.add(body(e.literaryContext.immediateAfter));
      pageWidgets.add(sub('Structural role'));
      pageWidgets.add(body(e.literaryContext.structuralRole));
      pageWidgets.add(sub('Passage flow'));
      pageWidgets.add(body(e.literaryContext.passageFlow));

      // Layer 4
      if (e.wordStudy.isNotEmpty) {
        pageWidgets.add(section('4. Original Language Word Study'));
        for (final w in e.wordStudy) {
          pageWidgets.add(
            sub(
              '${w.englishWord} — ${w.originalWord} (${w.transliteration}) ${w.strongsNumber}',
            ),
          );
          pageWidgets.add(
            body(
              '${w.lexicalDefinition}\n\nIn this context: ${w.meaningInThisContext}',
            ),
          );
          if (w.discoveryNote.isNotEmpty)
            pageWidgets.add(body('💡 ${w.discoveryNote}'));
          pageWidgets.add(divider());
        }
      }

      // Layer 5
      if (e.morphologicalAnalysis.isNotEmpty) {
        pageWidgets.add(section('5. Morphological Analysis'));
        for (final m in e.morphologicalAnalysis) {
          pageWidgets.add(
            sub('${m.word} (${m.partOfSpeech}) ${m.strongsNumber}'),
          );
          pageWidgets.add(body(m.plainEnglishExplanation));
        }
      }

      // Layer 6
      if (e.semanticDisambiguation.isNotEmpty) {
        pageWidgets.add(section('6. Semantic Disambiguation'));
        for (final s in e.semanticDisambiguation) {
          pageWidgets.add(sub(s.englishWord));
          pageWidgets.add(body(s.disambiguation));
        }
      }

      // Layer 7
      if (e.mentionAnalysis.isNotEmpty) {
        pageWidgets.add(section('7. First & Significant Mentions'));
        for (final m in e.mentionAnalysis) {
          pageWidgets.add(sub(m.concept));
          pageWidgets.add(
            body(
              'First mention (${m.firstMention.reference}): ${m.firstMention.whatItEstablishes}',
            ),
          );
        }
      }

      // Layer 8 discourse
      pageWidgets.add(section('8. Discourse Analysis'));
      if (e.discourseAnalysis.rhetoricalFunction.isNotEmpty) {
        pageWidgets.add(chip(e.discourseAnalysis.rhetoricalFunction));
      }
      for (final lc in e.discourseAnalysis.logicalConnectors) {
        pageWidgets.add(sub('"${lc.word}" — ${lc.originalWord}'));
        pageWidgets.add(body(lc.significance));
      }
      pageWidgets.add(sub('Author intent'));
      pageWidgets.add(body(e.discourseAnalysis.authorIntent));

      // Layer 9
      if (e.crossReferences.isNotEmpty) {
        pageWidgets.add(section('9. Cross-References'));
        for (final r in e.crossReferences) {
          pageWidgets.add(sub('${r.reference} — ${r.connectionType}'));
          pageWidgets.add(body(r.specificContribution));
          pageWidgets.add(divider());
        }
      }

      // Layer 10
      if (e.intertextualAllusions != null &&
          e.intertextualAllusions!.isNotEmpty) {
        pageWidgets.add(section('10. Intertextual Allusions'));
        for (final a in e.intertextualAllusions!) {
          pageWidgets.add(sub('${a.sourceText} → ${a.allusionText}'));
          pageWidgets.add(body(a.howToHearIt));
          pageWidgets.add(divider());
        }
      }

      // Layer 11
      if (e.textualApparatusNotes != null &&
          e.textualApparatusNotes!.include &&
          e.textualApparatusNotes!.notes != null &&
          e.textualApparatusNotes!.notes!.isNotEmpty) {
        pageWidgets.add(section('11. Textual Apparatus Notes'));
        pageWidgets.add(body(e.textualApparatusNotes!.notes!));
      }

      // Layer 12
      pageWidgets.add(section('12. The Implied Theological Claim'));
      pageWidgets.add(body(e.impliedTheologicalClaim));

      // Layer 13
      if (e.whatItCannotMean.isNotEmpty) {
        pageWidgets.add(section('13. What This Text Cannot Mean'));
        for (final m in e.whatItCannotMean) {
          pageWidgets.add(sub('Misreading: ${m.commonMisreading}'));
          pageWidgets.add(body('Why it\'s wrong: ${m.whyItIsWrong}'));
          pageWidgets.add(
            body('What it actually means: ${m.whatItActuallyMeans}'),
          );
          pageWidgets.add(divider());
        }
      }

      // Layer 14
      pageWidgets.add(section('14. From Text to Life'));
      pageWidgets.add(body(e.fromTextToLife));

      pageWidgets.add(divider());
      pageWidgets.add(body('Something to sit with: ${e.somethingToSitWith}'));
    } else {
      final e = topicResult!;

      pageWidgets.add(section('1. The Orienting Insight'));
      pageWidgets.add(body(e.bigPicture));

      pageWidgets.add(section('2. Concept Definition'));
      pageWidgets.add(
        sub(
          'Hebrew: ${e.conceptDefinition.hebrewWord.word} (${e.conceptDefinition.hebrewWord.transliteration}) ${e.conceptDefinition.hebrewWord.strongsNumber}',
        ),
      );
      pageWidgets.add(body(e.conceptDefinition.hebrewWord.fullSemanticRange));
      pageWidgets.add(
        sub(
          'Greek: ${e.conceptDefinition.greekWord.word} (${e.conceptDefinition.greekWord.transliteration}) ${e.conceptDefinition.greekWord.strongsNumber}',
        ),
      );
      pageWidgets.add(body(e.conceptDefinition.greekWord.fullSemanticRange));
      pageWidgets.add(sub('Semantic Disambiguation'));
      pageWidgets.add(body(e.conceptDefinition.semanticDisambiguation));
      pageWidgets.add(sub('Modern vs. Ancient'));
      pageWidgets.add(body(e.conceptDefinition.modernVsAncient));

      pageWidgets.add(section('3. First Mention'));
      pageWidgets.add(sub(e.firstMention.reference));
      if (e.firstMention.verseText != null)
        pageWidgets.add(body(e.firstMention.verseText!));
      pageWidgets.add(body(e.firstMention.whatItEstablishes));

      if (e.definingPassages.isNotEmpty) {
        pageWidgets.add(section('4. Defining Passages'));
        for (final p in e.definingPassages) {
          pageWidgets.add(sub(p.reference));
          if (p.verseText != null) pageWidgets.add(body(p.verseText!));
          pageWidgets.add(body(p.whatThisPassageSays));
          pageWidgets.add(divider());
        }
      }

      pageWidgets.add(section('5. Canonical Progression'));
      pageWidgets.add(body(e.canonicalProgression));

      if (e.commonDistortions.isNotEmpty) {
        pageWidgets.add(section('6. Common Distortions'));
        for (final d in e.commonDistortions) {
          pageWidgets.add(sub('Distortion: ${d.distortion}'));
          pageWidgets.add(body('Why it enters: ${d.howItEnters}'));
          pageWidgets.add(
            body('Linguistic correction: ${d.linguisticCorrection}'),
          );
          pageWidgets.add(divider());
        }
      }

      pageWidgets.add(section('7. The Implied Theological Claim'));
      pageWidgets.add(body(e.impliedTheologicalClaim));

      if (e.whatItCannotMean.isNotEmpty) {
        pageWidgets.add(section('8. What This Cannot Mean'));
        for (final m in e.whatItCannotMean) {
          pageWidgets.add(sub('Misreading: ${m.commonMisreading}'));
          pageWidgets.add(body(m.whyItIsWrong));
          pageWidgets.add(body('What it means: ${m.whatItActuallyMeans}'));
          pageWidgets.add(divider());
        }
      }

      pageWidgets.add(section('9. From Text to Life'));
      pageWidgets.add(body(e.fromTextToLife));

      pageWidgets.add(divider());
      pageWidgets.add(body('Something to sit with: ${e.somethingToSitWith}'));
    }

    // Footer
    pageWidgets.addAll([
      divider(),
      pw.Center(
        child: pw.Text(
          'Generated by illuminare — ILLUMINE Deep Study Engine',
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
        ),
      ),
    ]);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'ILLUMINE Study: ${clean(subject)}',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
              ),
            ],
          ),
        ),
        build: (context) => pageWidgets,
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

    final safeSubject = subject
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    final file = File(
      '${output.path}/exegesis_${DateTime.now().millisecondsSinceEpoch}_$safeSubject.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }
}
