import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../data/models/ai/ai_models.dart';
import '../../../data/models/bookmarks/ai_content_bookmark_model.dart';
import '../../../services/verse_ai_service.dart';
import '../../bible/widgets/ai_markdown_body.dart';

import '../../bookmarks/providers/ai_content_bookmarks_providers.dart';
import '../../monetization/providers/monetization_providers.dart';
import '../../notes/presentation/widgets/add_to_note_dialog.dart';
import '../../notes/data/models/linked_content_reference.dart';
import '../providers/bible_providers.dart';
import '../../../services/ad_service.dart';

// ═══════════════════════════════════════════════════════════════
//  COLOUR TOKENS
// ═══════════════════════════════════════════════════════════════

class _ModeColors {
  static const explain = Color(0xFF6A9FD8);
  static const context = Color(0xFFD4A86A);
  static const crossRef = Color(0xFF7AB87C);
  static const keywords = Color(0xFFC87AD4);
  static const application = Color(0xFFD4786A);

  static Color forMode(VerseFeature mode) {
    switch (mode) {
      case VerseFeature.explain:
        return explain;
      case VerseFeature.context:
        return context;
      case VerseFeature.crossRefs:
        return crossRef;
      case VerseFeature.keyWord:
        return keywords;
      case VerseFeature.application:
        return application;
    }
  }

  static String label(VerseFeature mode) {
    switch (mode) {
      case VerseFeature.explain:
        return 'Explain';
      case VerseFeature.context:
        return 'Context';
      case VerseFeature.crossRefs:
        return 'CrossRef';
      case VerseFeature.keyWord:
        return 'Keywords';
      case VerseFeature.application:
        return 'Apply';
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════════

class VerseAiResultsScreen extends ConsumerStatefulWidget {
  final String bookName;
  final int chapterNumber;
  final int verseNumber;
  final String verseText;
  final VerseFeature initialMode;
  final dynamic cachedAnalysis;

  const VerseAiResultsScreen({
    super.key,
    required this.bookName,
    required this.chapterNumber,
    required this.verseNumber,
    required this.verseText,
    this.initialMode = VerseFeature.explain,
    this.cachedAnalysis,
  });

  @override
  ConsumerState<VerseAiResultsScreen> createState() =>
      _VerseAiResultsScreenState();
}

class _VerseAiResultsScreenState extends ConsumerState<VerseAiResultsScreen> {
  late VerseFeature _activeMode;
  final Map<VerseFeature, dynamic> _cache = {};
  final Map<VerseFeature, bool> _loading = {};
  String? _error;
  bool _isRewardFlowInProgress = false;

  String get _verseRef =>
      '${widget.bookName} ${widget.chapterNumber}:${widget.verseNumber}';

  @override
  void initState() {
    super.initState();
    _activeMode = widget.initialMode;

    if (widget.cachedAnalysis != null) {
      try {
        final deserialized = _deserializeCachedAnalysis(
          widget.cachedAnalysis,
          _activeMode,
        );
        _cache[_activeMode] = deserialized;
      } catch (e) {
        debugPrint('Failed to deserialize cached analysis: $e');
      }
    }

    _loadModeWithMonetization(_activeMode);
  }

  dynamic _deserializeCachedAnalysis(dynamic json, VerseFeature mode) {
    if (json is Map<String, dynamic>) {
      switch (mode) {
        case VerseFeature.explain:
          return ExplainResultV2.fromJson(json);
        case VerseFeature.context:
          return ContextResultV2.fromJson(json);
        case VerseFeature.crossRefs:
          return CrossRefResultV2.fromJson(json);
        case VerseFeature.keyWord:
          return KeywordsResultV2.fromJson(json);
        case VerseFeature.application:
          return ApplicationResultV2.fromJson(json);
      }
    }
    return json;
  }

  Future<void> _fetchMode(VerseFeature mode) async {
    if (_cache.containsKey(mode)) return;
    setState(() {
      _loading[mode] = true;
      _error = null;
    });

    try {
      final version = ref.read(bibleVersionNotifierProvider);
      final service = VerseAiService();
      final result = await service.analyse(
        mode: mode,
        verseRef: _verseRef,
        verseText: widget.verseText,
        translation: version,
      );
      if (mounted) {
        setState(() {
          _cache[mode] = result;
          _loading[mode] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading[mode] = false;
        });
      }
    }
  }

  Future<void> _loadModeWithMonetization(
    VerseFeature mode, {
    VerseFeature? fallbackMode,
  }) async {
    if (_cache.containsKey(mode)) return;

    final isPremiumUser = ref.read(isPremiumUserProvider);
    final shouldShowAds = AdService.shouldShowAds(isPremiumUser: isPremiumUser);

    if (!shouldShowAds) {
      await _fetchMode(mode);
      return;
    }

    if (_isRewardFlowInProgress) return;

    setState(() {
      _isRewardFlowInProgress = true;
      _loading[mode] = true;
      _error = null;
    });

    RewardedAd? rewardedAd;
    try {
      await AdService.loadRewarded(
        onLoaded: (ad) => rewardedAd = ad,
        onFailedToLoad: (_) => rewardedAd = null,
      );

      if (rewardedAd == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ad is unavailable right now. Continuing...'),
            ),
          );
        }
        await _fetchMode(mode);
        return;
      }

      final adClosedCompleter = Completer<void>();
      var didEarnReward = false;
      var failedToShow = false;

      rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          if (!adClosedCompleter.isCompleted) {
            adClosedCompleter.complete();
          }
        },
        onAdFailedToShowFullScreenContent: (ad, _) {
          failedToShow = true;
          ad.dispose();
          if (!adClosedCompleter.isCompleted) {
            adClosedCompleter.complete();
          }
        },
      );

      rewardedAd!.show(
        onUserEarnedReward: (_, _) {
          didEarnReward = true;
        },
      );

      await adClosedCompleter.future;
      if (!mounted) return;

      if (failedToShow) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not show ad. Continuing...')),
        );
        await _fetchMode(mode);
        return;
      }

      if (didEarnReward) {
        await _fetchMode(mode);
        return;
      }

      setState(() {
        _loading[mode] = false;
        if (fallbackMode != null) {
          _activeMode = fallbackMode;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete the ad to continue.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isRewardFlowInProgress = false);
      }
    }
  }

  void _switchMode(VerseFeature mode) {
    if (_activeMode == mode) return;
    final previousMode = _activeMode;
    setState(() => _activeMode = mode);
    _loadModeWithMonetization(mode, fallbackMode: previousMode);
  }

  // ── AppBar actions ──

  void _showActionsMenu() {
    final data = _cache[_activeMode];
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.note_add_outlined),
              title: const Text('Add to Note'),
              onTap: () {
                Navigator.pop(context);
                _addToNote(data);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Export PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportPdf(data);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                _share(data);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addToNote(dynamic data) {
    if (data == null) return;
    final linkedRef = LinkedContentReference(
      id: '${widget.bookName}_${widget.chapterNumber}_${widget.verseNumber}_${DateTime.now().millisecondsSinceEpoch}',
      type: LinkedContentType.verse,
      sourceId:
          '${widget.bookName}_${widget.chapterNumber}_${widget.verseNumber}',
      sourceReference: _verseRef,
      linkedAt: DateTime.now(),
      metadata: {
        'book': widget.bookName,
        'chapter': widget.chapterNumber.toString(),
        'verse': widget.verseNumber.toString(),
        'mode': _activeMode.name,
      },
    );
    showDialog(
      context: context,
      builder: (_) => AddToNoteDialog(
        formattedContent: _formatForExport(data),
        linkedContentReference: linkedRef,
        suggestedTitle: '$_verseRef — ${_ModeColors.label(_activeMode)}',
      ),
    );
  }

  void _share(dynamic data) {
    if (data == null) return;
    Share.share(_formatForExport(data));
  }

  Future<void> _exportPdf(dynamic data) async {
    if (data == null) return;
    final pdf = pw.Document();
    final content = _formatForExport(data);
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Header(
            level: 0,
            text: '$_verseRef — ${_ModeColors.label(_activeMode)}',
          ),
          pw.Paragraph(
            text: widget.verseText,
            style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
          ),
          pw.SizedBox(height: 12),
          pw.Paragraph(text: content),
        ],
      ),
    );
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/verse_ai_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([
      XFile(file.path),
    ], subject: '$_verseRef — ${_ModeColors.label(_activeMode)}');
  }

  Future<void> _toggleBookmark() async {
    final data = _cache[_activeMode];
    if (data == null) return;
    final notifier = ref.read(aiContentBookmarksNotifierProvider.notifier);
    final bookmarks = ref.read(aiContentBookmarksNotifierProvider);
    final isBookmarked =
        bookmarks.hasValue &&
        bookmarks.value!.any(
          (b) =>
              b.bookName == widget.bookName &&
              b.chapterNumber == widget.chapterNumber &&
              b.verseNumber == widget.verseNumber &&
              b.feature == _activeMode,
        );

    if (isBookmarked) {
      final bm = bookmarks.value!.firstWhere(
        (b) =>
            b.bookName == widget.bookName &&
            b.chapterNumber == widget.chapterNumber &&
            b.verseNumber == widget.verseNumber &&
            b.feature == _activeMode,
      );
      await notifier.deleteBookmark(bm.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bookmark removed')));
      }
    } else {
      final json = jsonEncode(data.toJson());
      final bm = AiContentBookmarkModel.fromFeature(
        id: const Uuid().v4(),
        bookName: widget.bookName,
        chapterNumber: widget.chapterNumber,
        verseNumber: widget.verseNumber,
        verseText: widget.verseText,
        feature: _activeMode,
        analysisJson: json,
        createdAt: DateTime.now(),
      );
      await notifier.addBookmark(bm);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bookmark added')));
      }
    }
  }

  // ── Format export text ──

  String _formatForExport(dynamic data) {
    final buf = StringBuffer();
    buf.writeln('$_verseRef — ${_ModeColors.label(_activeMode)}');
    buf.writeln('"${widget.verseText}"');
    buf.writeln();

    if (data is ExplainResultV2) {
      buf.writeln('Key Insight: ${data.oneLineSummary}');
      buf.writeln();
      buf.writeln('Speaker: ${data.speaker}');
      buf.writeln('Audience: ${data.audience}');
      buf.writeln();
      buf.writeln('Explanation:');
      buf.writeln(data.explanation);
      buf.writeln();
      if (data.historicalContext.isNotEmpty) {
        buf.writeln('Historical Context:');
        buf.writeln(data.historicalContext);
        buf.writeln();
      }
      for (final t in data.keyTerms) {
        buf.writeln(
          '• ${t.term} (${t.originalWord} ${t.strongsNumber}): ${t.definition}',
        );
      }
      buf.writeln();
      buf.writeln('Study Prompt: ${data.studyPrompt}');
    } else if (data is ContextResultV2) {
      buf.writeln('Key Insight: ${data.oneLineSummary}');
      buf.writeln();
      buf.writeln('Before: ${data.immediateContextBefore}');
      buf.writeln('After: ${data.immediateContextAfter}');
      buf.writeln('Chapter Theme: ${data.chapterTheme}');
      buf.writeln('Cultural Background: ${data.culturalBackgroundInsight}');
      buf.writeln();
      buf.writeln('Study Prompt: ${data.studyPrompt}');
    } else if (data is CrossRefResultV2) {
      buf.writeln('Key Insight: ${data.oneLineSummary}');
      buf.writeln('Central Theme: ${data.centralTheme}');
      buf.writeln();
      for (final r in data.references) {
        buf.writeln('• ${r.reference} [${r.connectionType}]: ${r.connection}');
      }
      buf.writeln();
      buf.writeln('Canonical Thread: ${data.canonicalThread}');
      buf.writeln();
      buf.writeln('Study Prompt: ${data.studyPrompt}');
    } else if (data is KeywordsResultV2) {
      buf.writeln('Key Insight: ${data.oneLineSummary}');
      buf.writeln('Language: ${data.language}');
      buf.writeln();
      for (final kw in data.keywords) {
        buf.writeln(
          '• ${kw.word} — ${kw.originalWord} (${kw.transliteration}, ${kw.strongsNumber})',
        );
        buf.writeln('  Definition: ${kw.definition}');
        buf.writeln('  Significance: ${kw.theologicalSignificance}');
        buf.writeln();
      }
      buf.writeln('Study Prompt: ${data.studyPrompt}');
    } else if (data is ApplicationResultV2) {
      buf.writeln('Key Insight: ${data.oneLineSummary}');
      buf.writeln('Central Truth: ${data.centralTruth}');
      buf.writeln('General Application: ${data.generalApplication}');
      buf.writeln();
      if (data.applicationAreas != null) {
        buf.writeln('Personal: ${data.applicationAreas!.personal}');
        buf.writeln('Family: ${data.applicationAreas!.family}');
        buf.writeln('Church: ${data.applicationAreas!.church}');
        buf.writeln('Workplace: ${data.applicationAreas!.workplace}');
        buf.writeln('Society: ${data.applicationAreas!.society}');
      }
      buf.writeln();
      buf.writeln('Study Prompt: ${data.studyPrompt}');
    }
    return buf.toString();
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final color = _ModeColors.forMode(_activeMode);
    final isLoading = _loading[_activeMode] == true || _isRewardFlowInProgress;
    final data = _cache[_activeMode];
    final aiBookmarks = ref.watch(aiContentBookmarksNotifierProvider);
    final isBookmarked =
        aiBookmarks.hasValue &&
        aiBookmarks.value!.any(
          (b) =>
              b.bookName == widget.bookName &&
              b.chapterNumber == widget.chapterNumber &&
              b.verseNumber == widget.verseNumber &&
              b.feature == _activeMode,
        );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(_ModeColors.label(_activeMode)),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _verseRef,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
            tooltip: isBookmarked ? 'Remove Bookmark' : 'Bookmark',
            onPressed: _toggleBookmark,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: data != null ? _showActionsMenu : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode switcher tabs
          _ModeSwitcher(
            active: _activeMode,
            onTap: _switchMode,
            loadedModes: _cache.keys.toSet(),
          ),
          // Body
          Expanded(
            child: isLoading
                ? _buildLoadingState(color)
                : _error != null && data == null
                ? _buildError()
                : data != null
                ? _buildResults(data, color)
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(color: color, strokeWidth: 3),
          ),
          const SizedBox(height: 20),
          Text(
            'Analysing ${_ModeColors.label(_activeMode).toLowerCase()}…',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          const Text('Something went wrong'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              _cache.remove(_activeMode);
              _fetchMode(_activeMode);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(dynamic data, Color color) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero summary
          _heroCard(data, color),
          const SizedBox(height: 16),
          // Mode-specific sections
          if (data is ExplainResultV2) ..._explainSections(data, color),
          if (data is ContextResultV2) ..._contextSections(data, color),
          if (data is CrossRefResultV2) ..._crossRefSections(data, color),
          if (data is KeywordsResultV2) ..._keywordsSections(data, color),
          if (data is ApplicationResultV2) ..._applicationSections(data, color),
          // Study prompt footer
          _studyPromptCard(data, color),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Shared widgets ──

  Widget _heroCard(dynamic data, Color color) {
    String summary = '';
    if (data is ExplainResultV2) summary = data.oneLineSummary;
    if (data is ContextResultV2) summary = data.oneLineSummary;
    if (data is CrossRefResultV2) summary = data.oneLineSummary;
    if (data is KeywordsResultV2) summary = data.oneLineSummary;
    if (data is ApplicationResultV2) summary = data.oneLineSummary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KEY INSIGHT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            summary,
            style: const TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _studyPromptCard(dynamic data, Color color) {
    String prompt = '';
    if (data is ExplainResultV2) prompt = data.studyPrompt;
    if (data is ContextResultV2) prompt = data.studyPrompt;
    if (data is CrossRefResultV2) prompt = data.studyPrompt;
    if (data is KeywordsResultV2) prompt = data.studyPrompt;
    if (data is ApplicationResultV2) prompt = data.studyPrompt;
    if (prompt.isEmpty) return const SizedBox();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🤔 ', style: TextStyle(fontSize: 18)),
          Expanded(
            child: Text(
              prompt,
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: color,
      ),
    ),
  );

  Widget _bodyText(String text) => AiMarkdownBody(
    data: text,
    baseStyle: const TextStyle(fontSize: 14.5, height: 1.7),
  );

  Widget _metaChip(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13)),
      ],
    ),
  );

  // ── Explain sections ──

  List<Widget> _explainSections(ExplainResultV2 d, Color c) => [
    if (d.speaker.isNotEmpty || d.audience.isNotEmpty)
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (d.speaker.isNotEmpty) _metaChip('Speaker', d.speaker),
          if (d.speaker.isNotEmpty && d.audience.isNotEmpty)
            const SizedBox(height: 8),
          if (d.audience.isNotEmpty) _metaChip('Audience', d.audience),
        ],
      ),
    if (d.connectedThoughtRange.isNotEmpty) ...[
      const SizedBox(height: 8),
      _metaChip('Passage Context', d.connectedThoughtRange),
    ],
    _sectionLabel('EXPLANATION', c),
    _bodyText(d.explanation),
    if (d.historicalContext.isNotEmpty) ...[
      _sectionLabel('HISTORICAL CONTEXT', c),
      _bodyText(d.historicalContext),
    ],
    if (d.keyTerms.isNotEmpty) ...[
      _sectionLabel('KEY TERMS', c),
      ...d.keyTerms.map((t) => _keyTermCard(t, c)),
    ],
    if (d.literaryContext.isNotEmpty)
      ExpansionTile(
        title: Text(
          'Literary Context',
          style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 13),
        ),
        initiallyExpanded: false,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: _bodyText(d.literaryContext),
          ),
        ],
      ),
    if (d.supportingScriptures.isNotEmpty) ...[
      _sectionLabel('SUPPORTING SCRIPTURES', c),
      ...d.supportingScriptures.map((s) => _supportingScriptureCard(s)),
    ],
    if (d.covenant.isNotEmpty)
      ExpansionTile(
        title: Text(
          'Covenant Framework',
          style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 13),
        ),
        initiallyExpanded: false,
        children: d.covenant
            .map(
              (cv) => ListTile(
                title: Text(
                  cv.covenantName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(cv.explanation),
                trailing: _applicabilityBadge(cv.applicability),
              ),
            )
            .toList(),
      ),
  ];

  Widget _keyTermCard(KeyTermV2 t, Color c) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                t.originalWord,
                style: TextStyle(
                  fontSize: 18,
                  color: c,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${t.transliteration} · ${t.strongsNumber}',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '"${t.term}" — ${t.definition}',
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
          if (t.whyItMatters.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              t.whyItMatters,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _supportingScriptureCard(SupportingScriptureV2 s) => Card(
    margin: const EdgeInsets.only(bottom: 6),
    child: ListTile(
      title: Text(
        s.reference,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      subtitle: Text(s.connection, style: const TextStyle(fontSize: 12)),
    ),
  );

  Widget _applicabilityBadge(String a) {
    final color = a == 'Direct'
        ? Colors.green
        : a == 'Principle-Based'
        ? Colors.amber
        : a == 'Fulfilled'
        ? Colors.blue
        : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        a,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Context sections ──

  List<Widget> _contextSections(ContextResultV2 d, Color c) => [
    _contextCard('← Before', d.immediateContextBefore, c),
    const SizedBox(height: 8),
    _contextCard('After →', d.immediateContextAfter, c),
    if (d.chapterTheme.isNotEmpty) ...[
      _sectionLabel('CHAPTER THEME', c),
      _bodyText(d.chapterTheme),
    ],
    if (d.speaker.isNotEmpty || d.audience.isNotEmpty)
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (d.speaker.isNotEmpty) _metaChip('Speaker', d.speaker),
            if (d.speaker.isNotEmpty && d.audience.isNotEmpty)
              const SizedBox(height: 8),
            if (d.audience.isNotEmpty) _metaChip('Audience', d.audience),
          ],
        ),
      ),
    if (d.literaryType.isNotEmpty) ...[
      _sectionLabel('LITERARY TYPE', c),
      _bodyText(d.literaryType),
    ],
    if (d.culturalBackgroundInsight.isNotEmpty)
      ExpansionTile(
        title: Text(
          'Cultural Background',
          style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 13),
        ),
        initiallyExpanded: false,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bodyText(d.culturalBackgroundInsight),
                if (d.culturalInterpretiveImpact.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Interpretive Impact',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: c,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _bodyText(d.culturalInterpretiveImpact),
                ],
              ],
            ),
          ),
        ],
      ),
    if (d.commonMisunderstandings.isNotEmpty) ...[
      _sectionLabel('COMMON MISUNDERSTANDINGS', c),
      ...d.commonMisunderstandings.map((m) => _misunderstandingCard(m)),
    ],
    if (d.nearbyVerseQuote != null) ...[
      _sectionLabel('KEY NEARBY VERSE', c),
      _nearbyVerseCard(d.nearbyVerseQuote!),
    ],
  ];

  Widget _contextCard(String label, String text, Color c) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: c.withOpacity(0.06),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: c.withOpacity(0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c),
        ),
        const SizedBox(height: 6),
        Text(text, style: const TextStyle(fontSize: 12.5, height: 1.5)),
      ],
    ),
  );

  Widget _misunderstandingCard(MisunderstandingV2 m) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              m.misunderstanding,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),
          Text('Why: ${m.whyItHappens}', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '✓ ${m.correction}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _nearbyVerseCard(NearbyVerseV2 v) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            v.reference,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          if (v.text != null) ...[
            const SizedBox(height: 4),
            Text(
              '"${v.text}"',
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            v.relevance,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );

  // ── CrossRef sections ──

  List<Widget> _crossRefSections(CrossRefResultV2 d, Color c) => [
    if (d.centralTheme.isNotEmpty) ...[
      _sectionLabel('CENTRAL THEME', c),
      _bodyText(d.centralTheme),
    ],
    const SizedBox(height: 12),
    ...d.references.map((r) => _crossRefCard(r)),
    if (d.canonicalThread.isNotEmpty)
      ExpansionTile(
        title: Text(
          'Canonical Thread',
          style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 13),
        ),
        initiallyExpanded: false,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: _bodyText(d.canonicalThread),
          ),
        ],
      ),
  ];

  Widget _crossRefCard(CrossRefItemV2 r) {
    final typeColor = _connectionTypeColor(r.connectionType);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  r.reference,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    r.connectionType,
                    style: TextStyle(
                      fontSize: 10,
                      color: typeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    r.testament,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              r.connection,
              style: const TextStyle(fontSize: 12.5, height: 1.5),
            ),
            if (r.verseText != null) ...[
              const SizedBox(height: 6),
              Text(
                '"${r.verseText}"',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _connectionTypeColor(String type) {
    switch (type) {
      case 'Parallel':
        return Colors.blue;
      case 'Fulfillment':
        return Colors.green;
      case 'Allusion':
        return Colors.amber.shade700;
      case 'Contrast':
        return Colors.blueGrey;
      case 'Development':
        return Colors.purple;
      case 'Foundation':
        return Colors.amber.shade800;
      default:
        return Colors.grey;
    }
  }

  // ── Keywords sections ──

  List<Widget> _keywordsSections(KeywordsResultV2 d, Color c) => [
    if (d.language.isNotEmpty) _metaChip('Language', d.language),
    const SizedBox(height: 12),
    ...d.keywords.map((kw) => _fullKeywordCard(kw, c)),
  ];

  Widget _fullKeywordCard(KeywordV2 kw, Color c) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kw.originalWord,
            style: TextStyle(
              fontSize: 22,
              color: c,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${kw.transliteration} · ${kw.strongsNumber} · ${kw.partOfSpeech}',
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '"${kw.word}" — ${kw.definition}',
            style: const TextStyle(fontSize: 13.5, height: 1.5),
          ),
          if (kw.usageInVerse.isNotEmpty)
            ExpansionTile(
              title: const Text(
                'Usage in This Verse',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              initiallyExpanded: false,
              tilePadding: EdgeInsets.zero,
              children: [
                Text(kw.usageInVerse, style: const TextStyle(fontSize: 12.5)),
              ],
            ),
          if (kw.usageElsewhere.isNotEmpty)
            ExpansionTile(
              title: const Text(
                'Usage Elsewhere',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              initiallyExpanded: false,
              tilePadding: EdgeInsets.zero,
              children: [
                Text(kw.usageElsewhere, style: const TextStyle(fontSize: 12.5)),
              ],
            ),
          if (kw.theologicalSignificance.isNotEmpty)
            ExpansionTile(
              title: const Text(
                'Theological Significance',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              initiallyExpanded: false,
              tilePadding: EdgeInsets.zero,
              children: [
                Text(
                  kw.theologicalSignificance,
                  style: const TextStyle(fontSize: 12.5),
                ),
              ],
            ),
          if (kw.translationVariance != null)
            ExpansionTile(
              title: const Text(
                'Translation Comparison',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              initiallyExpanded: false,
              tilePadding: EdgeInsets.zero,
              children: [
                Text(
                  kw.translationVariance!,
                  style: const TextStyle(fontSize: 12.5),
                ),
              ],
            ),
          if (kw.crossReference.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: c.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '📖 ${kw.crossReference}',
                style: TextStyle(fontSize: 11, color: c),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  // ── Application sections ──

  List<Widget> _applicationSections(ApplicationResultV2 d, Color c) => [
    if (d.centralTruth.isNotEmpty) ...[
      _sectionLabel('CENTRAL TRUTH', c),
      _bodyText(d.centralTruth),
    ],
    if (d.applicabilityScope != null) ...[
      const SizedBox(height: 12),
      _scopeBadge(d.applicabilityScope!),
    ],
    if (d.generalApplication.isNotEmpty) ...[
      _sectionLabel('GENERAL APPLICATION', c),
      _bodyText(d.generalApplication),
    ],
    if (d.applicationAreas != null) ...[
      _sectionLabel('APPLICATION AREAS', c),
      _appAreaCard('👤', 'Personal', d.applicationAreas!.personal, c),
      _appAreaCard('🏠', 'Family', d.applicationAreas!.family, c),
      _appAreaCard('⛪', 'Church', d.applicationAreas!.church, c),
      _appAreaCard('💼', 'Workplace', d.applicationAreas!.workplace, c),
      _appAreaCard('🌍', 'Society', d.applicationAreas!.society, c),
    ],
    if (d.commonMisapplications.isNotEmpty) ...[
      _sectionLabel('COMMON MISAPPLICATIONS', c),
      ...d.commonMisapplications.map((m) => _misapplicationCard(m)),
    ],
    if (d.supportingVerse != null) ...[
      _sectionLabel('SUPPORTING VERSE', c),
      _supportingScriptureCard(d.supportingVerse!),
    ],
  ];

  Widget _scopeBadge(ApplicabilityScopeV2 s) {
    final color = s.scope == 'Universal'
        ? Colors.green
        : s.scope == 'Historical-Specific'
        ? Colors.amber
        : Colors.blue;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              s.scope,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(s.explanation, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _appAreaCard(String icon, String label, String text, Color c) {
    if (text.isEmpty) return const SizedBox();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: c.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(text, style: const TextStyle(fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _misapplicationCard(MisapplicationV2 m) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              m.misapplication,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Used by: ${m.whoUsesIt}',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Why wrong: ${m.whyItsWrong}',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '✓ ${m.correctApplication}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
//  MODE SWITCHER TABS
// ═══════════════════════════════════════════════════════════════

class _ModeSwitcher extends StatelessWidget {
  final VerseFeature active;
  final ValueChanged<VerseFeature> onTap;
  final Set<VerseFeature> loadedModes;

  const _ModeSwitcher({
    required this.active,
    required this.onTap,
    required this.loadedModes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: VerseFeature.values.map((mode) {
          final isActive = mode == active;
          final color = _ModeColors.forMode(mode);
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(mode),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: isActive
                      ? Border(bottom: BorderSide(color: color, width: 2.5))
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _iconForMode(mode),
                      size: 20,
                      color: isActive
                          ? color
                          : Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _ModeColors.label(mode),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isActive
                            ? color
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _iconForMode(VerseFeature mode) {
    switch (mode) {
      case VerseFeature.explain:
        return Icons.lightbulb_outline;
      case VerseFeature.context:
        return Icons.account_balance_outlined;
      case VerseFeature.crossRefs:
        return Icons.compare_arrows;
      case VerseFeature.keyWord:
        return Icons.abc;
      case VerseFeature.application:
        return Icons.nature_people_outlined;
    }
  }
}
