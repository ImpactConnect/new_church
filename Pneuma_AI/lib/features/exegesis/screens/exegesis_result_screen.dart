import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exegesis_result_model.dart';
import '../widgets/word_detail_sheet.dart';
import '../widgets/verse_preview_sheet.dart';

class ExegesisResultScreen extends ConsumerStatefulWidget {
  final ExegesisResult result;

  const ExegesisResultScreen({
    super.key,
    required this.result,
  });

  @override
  ConsumerState<ExegesisResultScreen> createState() => _ExegesisResultScreenState();
}

class _ExegesisResultScreenState extends ConsumerState<ExegesisResultScreen> {
  // Expand first layer by default
  final Map<String, bool> _expandedState = {
    'Historical Context': true,
    'Literary Structure': false,
    'Grammatical Notes': false,
    'Theological Meaning': false,
    'Interpretive Traditions': false,
    'Application Bridge': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exegesis Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () {
              // TODO: Implement PDF Export
            },
          ),
          IconButton(
            icon: const Icon(Icons.note_add_outlined),
            onPressed: () {
              // TODO: Implement Add to Note
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeaderStrip(context),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildExecutiveSummary(context),
                if (widget.result.languageStudy.isNotEmpty) _buildLanguageStudyPills(context),
                if (widget.result.biographyTimeline != null) _buildCharacterSpecifics(context), // Example
                if (widget.result.canonicalDevelopment != null) _buildThemeSpecifics(context), // Example
                _buildAccordionLayer(context, 'Historical Context', Icons.history_edu, _buildHistoricalContext(context)),
                _buildAccordionLayer(context, 'Literary Structure', Icons.account_tree_outlined, _buildLiteraryStructure(context)),
                _buildAccordionLayer(context, 'Grammatical Notes', Icons.text_snippet_outlined, _buildGrammaticalNotes(context)),
                _buildAccordionLayer(context, 'Theological Meaning', Icons.account_balance_outlined, _buildTheologicalMeaning(context)),
                _buildAccordionLayer(context, 'Interpretive Traditions', Icons.group_work_outlined, _buildInterpretiveTraditions(context)),
                _buildAccordionLayer(context, 'Application Bridge', Icons.linear_scale, _buildApplicationBridge(context)),
                if (widget.result.scholarlyDebates.isNotEmpty) _buildScholarlyDebates(context),
                if (widget.result.crossReferences.isNotEmpty) _buildCrossReferences(context),
                if (widget.result.comprehensionQuiz.isNotEmpty) _buildComprehensionQuiz(context),
                _buildNextSteps(context),
                const SizedBox(height: 48), // Bottom padding
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  HEADER & SUMMARY
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildHeaderStrip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.result.subject,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildMetaChip(context, widget.result.entryType, Icons.category_outlined),
                    _buildMetaChip(context, widget.result.depthLevel, Icons.layers_outlined),
                    _buildMetaChip(context, widget.result.originalLanguage, Icons.language_outlined),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveSummary(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF9F2), // Light parchment background for summary
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8B87A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC8B87A).withValues(alpha: 0.2),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: Color(0xFFB59A45)),
              const SizedBox(width: 8),
              Text(
                'Executive Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8C7335),
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.result.executiveSummary,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.6,
              color: Colors.black87,
              fontFamily: 'Cormorant Garamond',
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageStudyPills(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Word Studies',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.result.languageStudy.map((wordStudy) {
              return ActionChip(
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                side: BorderSide(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3)),
                labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                avatar: const Icon(Icons.translate, size: 16),
                label: Text(
                  wordStudy.word.isNotEmpty ? wordStudy.word : wordStudy.transliteration,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (context) => WordDetailSheet(wordStudy: wordStudy),
                  );
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  ACCORDION SYSTEM
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildAccordionLayer(BuildContext context, String title, IconData icon, Widget content) {
    final isExpanded = _expandedState[title] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _expandedState[title] = expanded;
            });
          },
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isExpanded ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isExpanded ? Theme.of(context).colorScheme.primary : Theme.of(context).iconTheme.color,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: isExpanded ? FontWeight.bold : FontWeight.w600,
              fontSize: 16,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: content,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  LAYER BUILDERS
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildHistoricalContext(BuildContext context) {
    final hc = widget.result.historicalContext;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hc.author.isNotEmpty) _buildBulletPoint('Author', hc.author),
        if (hc.audience.isNotEmpty) _buildBulletPoint('Audience', hc.audience),
        if (hc.date.isNotEmpty) _buildBulletPoint('Date', hc.date),
        if (hc.occasion != null && hc.occasion!.isNotEmpty) _buildBulletPoint('Occasion', hc.occasion!),
        if (hc.politicalSetting.isNotEmpty) _buildBulletPoint('Political Setting', hc.politicalSetting),
        if (hc.geographicContext.isNotEmpty) _buildBulletPoint('Geographic Context', hc.geographicContext),
        if (hc.culturalNotes.isNotEmpty) _buildBulletPoint('Cultural Context', hc.culturalNotes),
      ],
    );
  }

  Widget _buildLiteraryStructure(BuildContext context) {
    final ls = widget.result.literaryStructure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ls.genre.isNotEmpty) _buildBulletPoint('Genre', ls.genre),
        if (ls.structure.isNotEmpty) _buildBulletPoint('Structure', ls.structure),
        if (ls.argumentFlow != null && ls.argumentFlow!.isNotEmpty) _buildBulletPoint('Argument Flow', ls.argumentFlow!),
        if (ls.bookOutline != null && ls.bookOutline!.isNotEmpty) _buildBulletPoint('Outline', ls.bookOutline!),
        if (ls.positionInBook.isNotEmpty) _buildBulletPoint('Canonical Position', ls.positionInBook),
        if (ls.literaryDevices.isNotEmpty) _buildBulletPoint('Literary Devices', ls.literaryDevices.join(', ')),
      ],
    );
  }

  Widget _buildGrammaticalNotes(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.result.grammaticalNotes,
          style: const TextStyle(height: 1.6),
        ),
      ],
    );
  }

  Widget _buildTheologicalMeaning(BuildContext context) {
    final tm = widget.result.theologicalMeaning;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tm.centralThesis != null && tm.centralThesis!.isNotEmpty) _buildBulletPoint('Central Thesis', tm.centralThesis!),
        if (tm.doctrineEstablished != null && tm.doctrineEstablished!.isNotEmpty) _buildBulletPoint('Doctrine', tm.doctrineEstablished!),
        if (tm.christologicalConnection.isNotEmpty) _buildBulletPoint('Christological Connection', tm.christologicalConnection),
        if (tm.metaNarrativePlacement.isNotEmpty) _buildBulletPoint('Meta-Narrative Placement', tm.metaNarrativePlacement),
      ],
    );
  }

  Widget _buildInterpretiveTraditions(BuildContext context) {
    final traditions = widget.result.interpretiveTraditions;
    if (traditions.isEmpty) return const Text('No major interpretive disagreements found.', style: TextStyle(fontStyle: FontStyle.italic));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: traditions.map((t) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.traditionName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(t.interpretation, style: const TextStyle(height: 1.5)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildApplicationBridge(BuildContext context) {
    final ab = widget.result.applicationBridge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBulletPoint('Original Intent', ab.originalIntent),
        _buildBulletPoint('Timeless Principle', ab.timelessPrinciple),
        _buildBulletPoint('Modern Application', ab.modernApplication),
        if (ab.misapplicationWarnings.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text('Misapplication Warnings', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 4),
          ...ab.misapplicationWarnings.map((w) => Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 4),
            child: Text('• $w', style: const TextStyle(height: 1.5)),
          )),
        ]
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  EXTRA SECTIONS
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildScholarlyDebates(BuildContext context) {
    return _buildAccordionLayer(
      context,
      'Scholarly Debates',
      Icons.people_alt_outlined,
      Column(
        children: widget.result.scholarlyDebates.map((d) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.topic, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                _buildBulletPoint('Position A', d.positionA),
                _buildBulletPoint('Position B', d.positionB),
                if (d.commonGround.isNotEmpty) _buildBulletPoint('Common Ground', d.commonGround),
                const Divider(),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCrossReferences(BuildContext context) {
    return _buildAccordionLayer(
      context,
      'Cross-References',
      Icons.link,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: widget.result.crossReferences.map((cr) {
          return InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (context) => VersePreviewSheet(reference: cr.reference),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      cr.reference,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cr.connectionType, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(cr.explanation, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildComprehensionQuiz(BuildContext context) {
    return _buildAccordionLayer(
      context,
      'Comprehension Quiz',
      Icons.quiz_outlined,
      Column(
        children: widget.result.comprehensionQuiz.map((q) {
          return ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(q.question, style: const TextStyle(fontWeight: FontWeight.w600)),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Answer:', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    Text(q.answer),
                    const SizedBox(height: 8),
                    Text('Explanation:', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    Text(q.explanation),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNextSteps(BuildContext context) {
    if (widget.result.studyNextSteps.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_walk_rounded, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text('Study Next Steps', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.result.studyNextSteps.map((step) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.arrow_right, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 4),
                Expanded(child: Text(step, style: const TextStyle(height: 1.4))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCharacterSpecifics(BuildContext context) {
    final arc = widget.result.transformationArc;
    final timeline = widget.result.biographyTimeline ?? [];
    return Column(
      children: [
        if (arc != null && arc.isNotEmpty) _buildAccordionLayer(
          context,
          'Transformation Arc',
          Icons.trending_up,
          Text(arc, style: const TextStyle(height: 1.6)),
        ),
        if (timeline.isNotEmpty) _buildAccordionLayer(
          context,
          'Biography Timeline',
          Icons.timeline,
          Column(
            children: timeline.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.primary)),
                        Container(width: 2, height: 40, color: Theme.of(context).dividerColor), // Simple line
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${e.event} (${e.reference})', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(e.significance, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          )
        ),
      ],
    );
  }

  Widget _buildThemeSpecifics(BuildContext context) {
    final dev = widget.result.canonicalDevelopment;
    if (dev == null) return const SizedBox.shrink();
    return _buildAccordionLayer(
      context,
      'Canonical Development',
      Icons.menu_book,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBulletPoint('First Mention', '${dev.firstMention.reference}\n${dev.firstMention.form}: ${dev.firstMention.significance}'),
          _buildBulletPoint('OT Development', dev.otDevelopment),
          _buildBulletPoint('Fulfillment in Christ', dev.fulfillmentInChrist),
          _buildBulletPoint('NT Development', dev.ntDevelopment),
          _buildBulletPoint('Eschatological Completion', dev.eschatologicalCompletion),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildBulletPoint(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }
}
