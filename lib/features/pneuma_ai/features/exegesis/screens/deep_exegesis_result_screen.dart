import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/gestures.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';



import 'package:church_mobile/features/pneuma_ai/features/notes/data/models/linked_content_reference.dart';
import 'package:church_mobile/features/pneuma_ai/features/notes/presentation/widgets/add_to_note_dialog.dart';
import '../models/exegesis_final_model.dart';
import '../widgets/inline_scripture_chip.dart';
import 'package:church_mobile/features/pneuma_ai/shared/widgets/bible_passage_bottom_sheet.dart';
import '../services/exegesis_pdf_service_final.dart';
import '../../bible/screens/ai_chat_screen.dart';

/// The main deep exegesis results screen — Final Edition.
/// Renders either a [VerseExegesis] or [TopicExegesis] as a
/// single continuous-scroll experience (no accordions).
/// Shows all 14 analysis layers in order.
class DeepExegesisResultScreen extends ConsumerStatefulWidget {
  final String id;
  final dynamic result; // VerseExegesis | TopicExegesis passed via route extra

  const DeepExegesisResultScreen({
    super.key,
    required this.id,
    required this.result,
  });

  @override
  ConsumerState<DeepExegesisResultScreen> createState() =>
      _DeepExegesisResultScreenState();
}

class _DeepExegesisResultScreenState
    extends ConsumerState<DeepExegesisResultScreen> {
  static const _verseColor = Color(0xFF5B8DEF);
  static const _topicColor = Color(0xFF9B59B6);

  @override
  Widget build(BuildContext context) {
    if (widget.result == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          leading: const BackButton(),
        ),
        body: const Center(child: Text('Study data lost due to app reload. Please return to the dashboard.')),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isVerse = widget.result is VerseExegesis;
    final accent = isVerse ? _verseColor : _topicColor;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF080912) : const Color(0xFFF6F5FF),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Ask Question'),
          onPressed: () => _openAskQuestion(context, isVerse, accent),
        ),
        body: CustomScrollView(
        slivers: [
          _buildHeader(isVerse, accent, isDark),
          SliverToBoxAdapter(
            child: isVerse
                ? _buildVerseContent(
                    widget.result as VerseExegesis, isDark, accent)
                : _buildTopicContent(
                    widget.result as TopicExegesis, isDark, accent),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      ),
    );
  }

  Widget _buildHeader(bool isVerse, Color accent, bool isDark) {
    final result = widget.result;
    final subject = isVerse
        ? (result as VerseExegesis).subject
        : (result as TopicExegesis).subject;
    final bigPicture = isVerse
        ? (result as VerseExegesis).bigPicture
        : (result as TopicExegesis).bigPicture;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 220,
      backgroundColor: isDark ? const Color(0xFF0D0E1B) : Colors.white,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
        onPressed: () {
            Navigator.of(context).pop();
        },
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.picture_as_pdf_outlined, color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
          tooltip: 'Export as PDF',
          onPressed: () async {
            try {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating PDF...')));
              final path = await ExegesisPdfServiceFinal.exportPdf(widget.result);
              if (context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to $path')));
              }
            } catch (e) {
              if (context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to export: $e')));
              }
            }
          },
        ),
        IconButton(
          icon: Icon(Icons.note_add_outlined, color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
          tooltip: 'Add to Note',
          onPressed: () => _addExegesisToNote(context, isVerse),
        ),
        IconButton(
          icon: Icon(Icons.share_outlined, color: isDark ? Colors.white : const Color(0xFF1A1A2E)),
          tooltip: 'Share',
          onPressed: () => _shareOrSave(context),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent.withOpacity(0.2), Colors.transparent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 36),
              // ILLUMINE badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: accent, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'ILLUMINE · ${isVerse ? "Verse Study" : "Topic Study"}',
                      style: TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subject,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                bigPicture,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withOpacity(0.65)
                      : Colors.black87.withOpacity(0.65),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── VERSE RESULT ─────────────────────────────────────────────────

  Widget _buildVerseContent(VerseExegesis e, bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Layer 1 — Big Picture
          _layerCard(
            isDark, accent,
            layerNumber: 1,
            title: 'The Orienting Insight',
            child: _richText(e.bigPicture, isDark),
          ),

          // Layer 2 — Historical & Cultural Setting
          _layerCard(
            isDark, accent,
            layerNumber: 2,
            title: 'Historical & Cultural Setting',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _richText(e.historicalCulturalSetting.world, isDark),
                if (e.historicalCulturalSetting.specificCulturalKeys.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...e.historicalCulturalSetting.specificCulturalKeys.map((k) =>
                      _culturalKeyCard(k, isDark, accent)),
                ],
              ],
            ),
          ),

          // Layer 3 — Literary Context
          _layerCard(
            isDark, accent,
            layerNumber: 3,
            title: 'Literary & Structural Context',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _pill(accent, e.literaryContext.genre),
                const SizedBox(height: 12),
                _subheading('Before this text', isDark),
                _richText(e.literaryContext.immediateBefore, isDark),
                const SizedBox(height: 12),
                _subheading('After this text', isDark),
                _richText(e.literaryContext.immediateAfter, isDark),
                const SizedBox(height: 12),
                _subheading('Structural role', isDark),
                _richText(e.literaryContext.structuralRole, isDark),
                const SizedBox(height: 12),
                _subheading('Passage flow', isDark),
                _richText(e.literaryContext.passageFlow, isDark),
              ],
            ),
          ),

          // Layer 4 — Word Study
          if (e.wordStudy.isNotEmpty)
            _layerCard(
              isDark, accent,
              layerNumber: 4,
              title: 'Original Language Word Study',
              child: Column(
                children: e.wordStudy
                    .map((w) => _wordStudyCard(w, isDark, accent))
                    .toList(),
              ),
            ),

          // Layer 5 — Morphological Analysis
          if (e.morphologicalAnalysis.isNotEmpty)
            _layerCard(
              isDark, accent,
              layerNumber: 5,
              title: 'Morphological Analysis',
              child: Column(
                children: e.morphologicalAnalysis
                    .map((m) => _morphCard(m, isDark, accent))
                    .toList(),
              ),
            ),

          // Layer 6 — Semantic Disambiguation
          if (e.semanticDisambiguation.isNotEmpty)
            _layerCard(
              isDark, accent,
              layerNumber: 6,
              title: 'Semantic Disambiguation',
              child: Column(
                children: e.semanticDisambiguation
                    .map((s) => _semanticCard(s, isDark, accent))
                    .toList(),
              ),
            ),

          // Layer 7 — Mention Analysis
          if (e.mentionAnalysis.isNotEmpty)
            _layerCard(
              isDark, accent,
              layerNumber: 7,
              title: 'First & Significant Mentions',
              child: Column(
                children: e.mentionAnalysis
                    .map((m) => _mentionCard(m, isDark, accent))
                    .toList(),
              ),
            ),

          // Layer 8 — Discourse Analysis
          _layerCard(
            isDark, accent,
            layerNumber: 8,
            title: 'Discourse Analysis',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _pill(accent, e.discourseAnalysis.rhetoricalFunction),
                const SizedBox(height: 12),
                if (e.discourseAnalysis.logicalConnectors.isNotEmpty) ...[
                  _subheading('Logical Connectors', isDark),
                  ...e.discourseAnalysis.logicalConnectors.map((lc) =>
                      _connectorRow(lc, isDark, accent)),
                  const SizedBox(height: 12),
                ],
                _subheading('Author intent', isDark),
                _richText(e.discourseAnalysis.authorIntent, isDark),
              ],
            ),
          ),

          // Layer 9 — Cross References
          if (e.crossReferences.isNotEmpty)
            _layerCard(
              isDark, accent,
              layerNumber: 9,
              title: 'Cross-References',
              child: Column(
                children: e.crossReferences
                    .map((cr) => _crossRefCard(cr, isDark, accent))
                    .toList(),
              ),
            ),

          // Layer 10 — Intertextual Allusions
          if (e.intertextualAllusions != null &&
              e.intertextualAllusions!.isNotEmpty)
            _layerCard(
              isDark, accent,
              layerNumber: 10,
              title: 'Intertextual Allusions',
              child: Column(
                children: e.intertextualAllusions!
                    .map((a) => _allusionCard(a, isDark, accent))
                    .toList(),
              ),
            ),

          // Layer 11 — Textual Apparatus
          if (e.textualApparatusNotes != null &&
              e.textualApparatusNotes!.include &&
              e.textualApparatusNotes!.notes != null)
            _layerCard(
              isDark, accent,
              layerNumber: 11,
              title: 'Textual Apparatus Notes',
              child: _richText(e.textualApparatusNotes!.notes!, isDark),
            ),

          // Layer 12 — Implied Theological Claim
          _layerCard(
            isDark, accent,
            layerNumber: 12,
            title: 'The Implied Theological Claim',
            child: _richText(e.impliedTheologicalClaim, isDark),
          ),

          // Layer 13 — What It Cannot Mean
          if (e.whatItCannotMean.isNotEmpty)
            _layerCard(
              isDark, accent,
              layerNumber: 13,
              title: 'What This Text Cannot Mean',
              child: Column(
                children: e.whatItCannotMean
                    .map((m) => _misreadingCard(m, isDark, accent))
                    .toList(),
              ),
            ),

          // Layer 14 — From Text to Life
          _layerCard(
            isDark, accent,
            layerNumber: 14,
            title: 'From Text to Life',
            child: _richText(e.fromTextToLife, isDark),
          ),

          // Something To Sit With
          _sitWithCard(e.somethingToSitWith, isDark, accent),
        ],
      ),
    );
  }

  // ── TOPIC RESULT ─────────────────────────────────────────────────

  Widget _buildTopicContent(TopicExegesis e, bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Big Picture
          _layerCard(isDark, accent,
              layerNumber: 1,
              title: 'The Orienting Insight',
              child: _richText(e.bigPicture, isDark)),

          // Concept Definition
          _layerCard(isDark, accent,
              title: 'Concept Definition',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _subheading('Hebrew', isDark),
                  _languageWordCard(e.conceptDefinition.hebrewWord, isDark, accent),
                  const SizedBox(height: 12),
                  _subheading('Greek', isDark),
                  _languageWordCard(e.conceptDefinition.greekWord, isDark, accent),
                  const SizedBox(height: 12),
                  _subheading('Semantic Disambiguation', isDark),
                  _richText(e.conceptDefinition.semanticDisambiguation, isDark),
                  const SizedBox(height: 12),
                  _subheading('Modern vs. Ancient', isDark),
                  _richText(e.conceptDefinition.modernVsAncient, isDark),
                ],
              )),

          // First Mention
          _layerCard(isDark, accent,
              title: 'First Mention',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InlineScriptureChip(reference: e.firstMention.reference),
                  const SizedBox(height: 8),
                  if (e.firstMention.verseText != null)
                    _quoteBlock(e.firstMention.verseText!, isDark, accent),
                  _richText(e.firstMention.whatItEstablishes, isDark),
                ],
              )),

          // Defining Passages
          if (e.definingPassages.isNotEmpty)
            _layerCard(isDark, accent,
                title: 'Defining Passages',
                child: Column(
                  children: e.definingPassages
                      .map((p) => _definingPassageCard(p, isDark, accent))
                      .toList(),
                )),

          // Canonical Progression
          _layerCard(isDark, accent,
              title: 'Canonical Progression',
              child: _richText(e.canonicalProgression, isDark)),

          // Common Distortions
          if (e.commonDistortions.isNotEmpty)
            _layerCard(isDark, accent,
                title: 'Common Distortions',
                child: Column(
                  children: e.commonDistortions
                      .map((d) => _distortionCard(d, isDark, accent))
                      .toList(),
                )),

          // Implied Theological Claim
          _layerCard(isDark, accent,
              title: 'The Implied Theological Claim',
              child: _richText(e.impliedTheologicalClaim, isDark)),

          // What It Cannot Mean
          if (e.whatItCannotMean.isNotEmpty)
            _layerCard(isDark, accent,
                title: 'What This Cannot Mean',
                child: Column(
                  children: e.whatItCannotMean
                      .map((m) => _misreadingCard(m, isDark, accent))
                      .toList(),
                )),

          // From Text to Life
          _layerCard(isDark, accent,
              title: 'From Text to Life',
              child: _richText(e.fromTextToLife, isDark)),

          // Something To Sit With
          _sitWithCard(e.somethingToSitWith, isDark, accent),
        ],
      ),
    );
  }

  // ── REUSABLE COMPONENT WIDGETS ────────────────────────────────────

  Widget _layerCard(bool isDark, Color accent,
      {int? layerNumber, required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0E1B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                if (layerNumber != null) ...[
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$layerNumber',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _wordStudyCard(WordStudyItem w, bool isDark, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF12143a).withOpacity(0.7)
            : const Color(0xFFF3F0FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                w.englishWord,
                style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 16),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  w.strongsNumber,
                  style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${w.originalWord}  ·  ${w.transliteration}',
            style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 14,
                fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 10),
          _subheading('Lexical definition', isDark),
          _richText(w.lexicalDefinition, isDark),
          const SizedBox(height: 8),
          _subheading('Meaning in this context', isDark),
          _richText(w.meaningInThisContext, isDark),
          if (w.discoveryNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.tips_and_updates, color: accent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                    w.discoveryNote,
                    style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 13,
                        height: 1.5),
                  )),
                ],
              ),
            ),
          ],
          if (w.otherOccurrences.isNotEmpty) ...[
            const SizedBox(height: 10),
            _subheading('Other occurrences', isDark),
            ...w.otherOccurrences.map((o) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InlineScriptureChip(reference: o.reference),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(o.context,
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                  fontSize: 12,
                                  height: 1.4))),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _morphCard(MorphItem m, bool isDark, Color accent) {
    final attrs = <String>[
      if (m.tense != null) m.tense!,
      if (m.voice != null) m.voice!,
      if (m.mood != null) m.mood!,
      if (m.personNumber != null) m.personNumber!,
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF12182A).withOpacity(0.7)
            : const Color(0xFFFAF8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(m.word,
                style: TextStyle(
                    color: accent, fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(width: 8),
            Text(m.originalWord,
                style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 13,
                    fontStyle: FontStyle.italic)),
          ]),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: [
              _pill(accent, m.partOfSpeech, small: true),
              ...attrs.map((a) => _pill(accent, a, small: true)),
            ],
          ),
          const SizedBox(height: 10),
          _richText(m.plainEnglishExplanation, isDark),
        ],
      ),
    );
  }

  Widget _semanticCard(SemanticItem s, bool isDark, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12172A) : const Color(0xFFFAF8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.englishWord,
              style: TextStyle(
                  color: accent, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          _richText(s.disambiguation, isDark),
          if (s.confusedWith.isNotEmpty) ...[
            const SizedBox(height: 8),
            _subheading('Often confused with', isDark),
            ...s.confusedWith.map((c) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.orange.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${c.word} (${c.strongsNumber})',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.orange,
                                fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(c.meaningDifference,
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.black87)),
                      ],
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _mentionCard(MentionItem m, bool isDark, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12172A) : const Color(0xFFFAF8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m.concept,
              style: TextStyle(
                  color: accent, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.first_page, size: 14, color: Colors.amber),
            const SizedBox(width: 4),
            InlineScriptureChip(reference: m.firstMention.reference),
          ]),
          const SizedBox(height: 4),
          _richText(m.firstMention.whatItEstablishes, isDark),
          if (m.developmentMentions.isNotEmpty) ...[
            const SizedBox(height: 8),
            _subheading('Development', isDark),
            ...m.developmentMentions.map((d) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InlineScriptureChip(reference: d.reference),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(d.development,
                              style: TextStyle(
                                  color:
                                      isDark ? Colors.white60 : Colors.black54,
                                  fontSize: 12,
                                  height: 1.4))),
                    ],
                  ),
                )),
          ],
          if (m.emphasisPattern != null) ...[
            const SizedBox(height: 8),
            _subheading('Emphasis pattern', isDark),
            _richText(m.emphasisPattern!, isDark),
          ],
        ],
      ),
    );
  }

  Widget _connectorRow(LogicalConnector lc, bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '"${lc.word}"',
              style: TextStyle(
                  color: accent, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(lc.significance,
                  style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 13,
                      height: 1.4))),
        ],
      ),
    );
  }

  Widget _crossRefCard(CrossRef cr, bool isDark, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1423) : const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            InlineScriptureChip(reference: cr.reference),
            const SizedBox(width: 8),
            _pill(accent, cr.connectionType, small: true),
          ]),
          if (cr.verseText != null) ...[
            const SizedBox(height: 6),
            _quoteBlock(cr.verseText!, isDark, accent),
          ],
          const SizedBox(height: 6),
          Text(cr.specificContribution,
              style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 13,
                  height: 1.5)),
        ],
      ),
    );
  }

  Widget _allusionCard(Allusion a, bool isDark, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1423) : const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.link, size: 14, color: Colors.amber),
            const SizedBox(width: 4),
            InlineScriptureChip(reference: a.sourceText),
            const Icon(Icons.arrow_forward, size: 14, color: Colors.amber),
            const SizedBox(width: 4),
            InlineScriptureChip(reference: a.allusionText),
          ]),
          if (a.sourceVerseText != null) ...[
            const SizedBox(height: 6),
            _quoteBlock(a.sourceVerseText!, isDark, Colors.amber),
          ],
          const SizedBox(height: 6),
          Text(a.howToHearIt,
              style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 13,
                  height: 1.5)),
        ],
      ),
    );
  }

  Widget _misreadingCard(Misreading m, bool isDark, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(children: [
              const Icon(Icons.not_interested,
                  color: Colors.red, size: 14),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(m.commonMisreading,
                      style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 12))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _richText(m.whyItIsWrong, isDark),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.green.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: Colors.green, size: 15),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(m.whatItActuallyMeans,
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                  fontSize: 13,
                                  height: 1.5))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _languageWordCard(LanguageWord w, bool isDark, Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(w.originalScript,
                style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
            const SizedBox(width: 8),
            Text('(${w.transliteration})',
                style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontStyle: FontStyle.italic)),
            const Spacer(),
            _pill(accent, w.strongsNumber, small: true),
          ]),
          const SizedBox(height: 6),
          _richText(w.fullSemanticRange, isDark),
        ],
      ),
    );
  }

  Widget _definingPassageCard(DefiningPassage p, bool isDark, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1020) : const Color(0xFFFAF9FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            InlineScriptureChip(reference: p.reference),
          ]),
          if (p.verseText != null) ...[
            const SizedBox(height: 8),
            _quoteBlock(p.verseText!, isDark, accent),
          ],
          const SizedBox(height: 10),
          if (p.wordStudy.isNotEmpty) ...[
            _subheading('Word Study', isDark),
            ...p.wordStudy.map((w) => _wordStudyCard(w, isDark, accent)),
          ],
          _subheading('What this passage says', isDark),
          _richText(p.whatThisPassageSays, isDark),
        ],
      ),
    );
  }

  Widget _distortionCard(Distortion d, bool isDark, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A0E0E) : const Color(0xFFFFF8F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepOrange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(d.distortion,
              style: const TextStyle(
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
          const SizedBox(height: 6),
          _richText(d.linguisticCorrection, isDark),
        ],
      ),
    );
  }

  Widget _culturalKeyCard(CulturalKey k, bool isDark, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k.item,
              style: TextStyle(
                  color: accent, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 4),
          _richText(k.howItShapesReading, isDark),
        ],
      ),
    );
  }

  Widget _sitWithCard(String text, bool isDark, Color accent) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.15), accent.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.self_improvement, color: accent, size: 18),
            const SizedBox(width: 8),
            Text('Something To Sit With',
                style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.3)),
          ]),
          const SizedBox(height: 12),
          Text(text,
              style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.65,
                  fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _richText(String text, bool isDark) {
    final RegExp verseRegex = RegExp(r'\b(?:[1-4]\s+)?[A-Z][a-z]+\s+\d{1,3}:\d{1,3}(?:-\d{1,3})?\b');
    
    final List<TextSpan> spans = [];
    int start = 0;
    
    for (final match in verseRegex.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      final reference = match.group(0)!;
      spans.add(
        TextSpan(
          text: reference,
          style: TextStyle(
            color: isDark ? const Color(0xFF5B8DEF) : const Color(0xFF2962FF),
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()..onTap = () {
            showBiblePassageBottomSheet(context, reference);
          },
        ),
      );
      start = match.end;
    }
    
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: isDark ? Colors.white.withOpacity(0.85) : Colors.black87,
          fontSize: 14,
          height: 1.65,
          fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
        ),
        children: spans,
      ),
    );
  }

  void _openAskQuestion(BuildContext context, bool isVerse, Color accent) {
    final result = widget.result;
    final subject = isVerse
        ? (result as VerseExegesis).subject
        : (result as TopicExegesis).subject;
    final bigPicture = isVerse
        ? (result as VerseExegesis).bigPicture
        : (result as TopicExegesis).bigPicture;
    final fromTextToLife = isVerse
        ? (result as VerseExegesis).fromTextToLife
        : (result as TopicExegesis).fromTextToLife;
    final impliedClaim = isVerse
        ? (result as VerseExegesis).impliedTheologicalClaim
        : (result as TopicExegesis).impliedTheologicalClaim;

    // Build a rich contextual preload for the chat
    final contextSummary = '''
You are an expert biblical theologian and teacher. The user has just completed reading a deep ILLUMINE exegesis study about: "$subject"

Here is the study summary:

**The Orienting Insight (Big Picture):**
$bigPicture

**The Implied Theological Claim:**
$impliedClaim

**From Text to Life (Application):**
$fromTextToLife

The user may ask you follow-up questions about this study. Answer with depth, precision, and scholarly integrity. Cite scripture references where relevant. Stay anchored to the content of the exegesis above.
''';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiChatScreen(
          topic: 'Study: $subject',
          preloadedContext: contextSummary,
          initialAssistantMessage:
              'I\'ve reviewed your deep ILLUMINE study on **$subject**.\n\nWhat questions do you have about this study? You can ask me to elaborate on any layer, explain a word further, or explore how this connects to other scriptures.',
        ),
      ),
    );
  }

  void _addExegesisToNote(BuildContext context, bool isVerse) {
    final result = widget.result;
    final subject = isVerse
        ? (result as VerseExegesis).subject
        : (result as TopicExegesis).subject;
    final bigPicture = isVerse
        ? (result as VerseExegesis).bigPicture
        : (result as TopicExegesis).bigPicture;

    final buffer = StringBuffer();
    buffer.writeln('**ILLUMINE Deep Study: $subject**\n');
    buffer.writeln('*The Orienting Insight*');
    buffer.writeln(bigPicture);

    final linkedContentRef = LinkedContentReference(
      id: const Uuid().v4(),
      type: LinkedContentType.exegesis,
      sourceId: isVerse ? (result as VerseExegesis).id : (result as TopicExegesis).id,
      sourceReference: 'ILLUMINE Study',
      linkedAt: DateTime.now(),
      metadata: {'subject': subject},
    );

    showDialog(
      context: context,
      builder: (context) => AddToNoteDialog(
        formattedContent: buffer.toString(),
        linkedContentReference: linkedContentRef,
        suggestedTitle: 'Study: $subject',
      ),
    );
  }

  Widget _subheading(String text, bool isDark) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black45,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                textBaseline: TextBaseline.alphabetic)),
      );

  Widget _pill(Color accent, String text, {bool small = false}) => Container(
        padding: EdgeInsets.symmetric(
            horizontal: small ? 7 : 10, vertical: small ? 2 : 4),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: TextStyle(
                color: accent,
                fontSize: small ? 10 : 12,
                fontWeight: FontWeight.w600)),
      );

  Widget _quoteBlock(String text, bool isDark, Color accent) => Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: accent, width: 3)),
          color: accent.withOpacity(0.05),
        ),
        child: Text(text,
            style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.5)),
      );

  void _shareOrSave(BuildContext context) {
    final isVerse = widget.result is VerseExegesis;
    final subject = isVerse
        ? (widget.result as VerseExegesis).subject
        : (widget.result as TopicExegesis).subject;
    final bigPicture = isVerse
        ? (widget.result as VerseExegesis).bigPicture
        : (widget.result as TopicExegesis).bigPicture;
        
    final shareText = '''ILLUMINE Deep Study: $subject

The Orienting Insight:
$bigPicture

Read the full 14-layer exegesis in the illuminare app.''';

    Share.share(shareText);
  }
}
