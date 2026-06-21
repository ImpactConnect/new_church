import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:go_router/go_router.dart';

import '../../../services/ad_service.dart';
import '../../monetization/providers/monetization_providers.dart';
import '../models/exegesis_final_model.dart';
import '../providers/exegesis_providers_final.dart';

/// New Exegesis Input Screen — ILLUMINE Final Edition
/// Two tabs: Verse/Range and Topic/Subject.
class NewExegesisScreen extends ConsumerStatefulWidget {
  final List<VerseRef>? prefilledRefs;
  final Map<String, String>? prefilledTexts;
  final String? prefilledTranslation;

  const NewExegesisScreen({
    super.key,
    this.prefilledRefs,
    this.prefilledTexts,
    this.prefilledTranslation,
  });

  @override
  ConsumerState<NewExegesisScreen> createState() => _NewExegesisScreenState();
}

class _NewExegesisScreenState extends ConsumerState<NewExegesisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // ── Verse form ─────────────────────────────────────────────────────
  // Each verse entry: { book, chapter, verse, endVerse }
  final List<_VerseEntry> _verses = [_VerseEntry()];

  String _translation = 'ESV';
  final _questionCtrl = TextEditingController();

  // ── Topic form ─────────────────────────────────────────────────────
  final _topicCtrl = TextEditingController();
  final _specificAngleCtrl = TextEditingController();
  bool _isRewardFlowInProgress = false;

  static const _verseColor = Color(0xFF2962FF); // striking blue
  static const _topicColor = Color(0xFFAA00FF); // striking purple
  static const _translations = ['ESV', 'NIV', 'KJV', 'NASB', 'NLT'];
  static const _topicSuggestions = [
    'Grace',
    'Faith',
    'Gospel',
    'Redemption',
    'Covenant',
    'Kingdom of God',
    'Atonement',
    'Holy Spirit',
    'Prayer',
    'Resurrection',
    'Forgiveness',
    'Election',
    'Sanctification',
    'Hope',
    'Love',
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);

    // Pre-fill from Bible Reader
    if (widget.prefilledRefs != null && widget.prefilledRefs!.isNotEmpty) {
      _verses.clear();
      for (final r in widget.prefilledRefs!) {
        _verses.add(_VerseEntry.fromRef(r));
      }
      if (widget.prefilledTranslation != null) {
        _translation = widget.prefilledTranslation!;
      }
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _questionCtrl.dispose();
    _topicCtrl.dispose();
    _specificAngleCtrl.dispose();
    for (final v in _verses) {
      v.dispose();
    }
    super.dispose();
  }

  bool get _verseFormValid {
    final first = _verses.first;
    return first.book != null &&
        first.chapterCtrl.text.trim().isNotEmpty &&
        first.verseCtrl.text.trim().isNotEmpty &&
        int.tryParse(first.chapterCtrl.text.trim()) != null &&
        int.tryParse(first.verseCtrl.text.trim()) != null;
  }

  bool get _topicFormValid => _topicCtrl.text.trim().length >= 2;

  void _addVerse() {
    setState(() => _verses.add(_VerseEntry()));
  }

  void _removeVerse(int index) {
    final v = _verses.removeAt(index);
    v.dispose();
    setState(() {});
  }

  void _onGenerateVerse() {
    if (!_verseFormValid) return;
    if (_isRewardFlowInProgress) return;

    final refs = <VerseRef>[];
    for (final e in _verses) {
      final book = e.book;
      if (book == null) continue;
      final chapter = int.tryParse(e.chapterCtrl.text.trim());
      final verse = int.tryParse(e.verseCtrl.text.trim());
      if (chapter == null || verse == null) continue;
      final endVerse = int.tryParse(e.endVerseCtrl.text.trim());
      refs.add(
        VerseRef(
          book: book,
          chapter: chapter,
          verse: verse,
          endVerse: endVerse,
        ),
      );
    }

    if (refs.isEmpty) return;

    _runWithRewardGate(
      onRewardedAction: () {
        final subject = refs.map((r) => r.referenceString).join(', ');
        final question = _questionCtrl.text.trim().isEmpty
            ? null
            : _questionCtrl.text.trim();

        ref
            .read(verseExegesisNotifierProvider.notifier)
            .generate(
              verseRefs: refs,
              verseTexts: widget.prefilledTexts ?? {},
              translation: _translation,
              isRange: refs.any((r) => r.endVerse != null),
              userQuestion: question,
              source: widget.prefilledRefs != null
                  ? ExegesisSource.bibleReader
                  : ExegesisSource.newForm,
            );

        context.push(
          '/exegesis/final/loading?type=verse&subject=${Uri.encodeComponent(subject)}',
        );
      },
    );
  }

  void _onGenerateTopic() {
    if (!_topicFormValid) return;
    if (_isRewardFlowInProgress) return;
    final topicName = _topicCtrl.text.trim();
    final angle = _specificAngleCtrl.text.trim().isEmpty
        ? null
        : _specificAngleCtrl.text.trim();

    _runWithRewardGate(
      onRewardedAction: () {
        ref
            .read(topicExegesisNotifierProvider.notifier)
            .generate(
              topicName: topicName,
              specificAngle: angle,
              source: ExegesisSource.newForm,
            );

        context.push(
          '/exegesis/final/loading?type=topic&subject=${Uri.encodeComponent(topicName)}',
        );
      },
    );
  }

  Future<void> _runWithRewardGate({
    required VoidCallback onRewardedAction,
  }) async {
    if (_isRewardFlowInProgress) return;
    final isPremiumUser = ref.read(isPremiumUserProvider);
    final shouldShowAds = AdService.shouldShowAds(isPremiumUser: isPremiumUser);

    if (!shouldShowAds) {
      onRewardedAction();
      return;
    }

    setState(() => _isRewardFlowInProgress = true);

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
        onRewardedAction();
        return;
      }

      final adClosedCompleter = Completer<void>();
      var didEarnReward = false;
      var failedToShow = false;

      rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          if (!adClosedCompleter.isCompleted) adClosedCompleter.complete();
        },
        onAdFailedToShowFullScreenContent: (ad, _) {
          failedToShow = true;
          ad.dispose();
          if (!adClosedCompleter.isCompleted) adClosedCompleter.complete();
        },
      );

      rewardedAd!.show(
        onUserEarnedReward: (_, rewardItem) {
          didEarnReward = true;
        },
      );

      await adClosedCompleter.future;
      if (!mounted) return;

      if (failedToShow) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not show ad. Continuing...')),
        );
        onRewardedAction();
        return;
      }

      if (didEarnReward) {
        onRewardedAction();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete the ad to continue.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isRewardFlowInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _tabs,
      builder: (context, _) {
        final isVerse = _tabs.index == 0;
        final accent = isVerse ? _verseColor : _topicColor;

        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF08091A)
              : const Color(0xFFFAFAFA),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF0D0F22) : Colors.white,
            elevation: 0,
            leading: BackButton(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.auto_awesome, color: accent, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  'ILLUMINE',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            bottom: TabBar(
              controller: _tabs,
              indicatorColor: accent,
              indicatorWeight: 3,
              labelColor: accent,
              unselectedLabelColor: isDark ? Colors.white38 : Colors.grey[500],
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.format_quote_rounded, size: 18),
                  text: 'Verse / Range',
                ),
                Tab(
                  icon: Icon(Icons.lightbulb_outline_rounded, size: 18),
                  text: 'Topic / Concept',
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabs,
            children: [_buildVerseTab(isDark), _buildTopicTab(isDark)],
          ),
          bottomNavigationBar: _buildBottomBar(isDark, accent, isVerse),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  HERO CARD
  // ══════════════════════════════════════════════════════════════════
  Widget _buildHeroCard(bool isDark, Color accent, String title, String body) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withOpacity(isDark ? 0.25 : 0.95),
            accent.withOpacity(isDark ? 0.10 : 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? accent.withOpacity(0.25) : Colors.transparent,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: accent.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? accent : Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 17,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  VERSE TAB
  // ══════════════════════════════════════════════════════════════════
  Widget _buildVerseTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero card ──────────────────────────────────────────
          _buildHeroCard(
            isDark,
            _verseColor,
            'Verse or Passage Exegesis',
            'Select one or more scripture references and ILLUMINE will conduct a complete 14-layer textual study — from original language words to theological claims — giving you the depth scholars train for years to reach.',
          ),
          const SizedBox(height: 20),

          // ── Verse rows ─────────────────────────────────────────
          ..._verses.asMap().entries.map((entry) {
            final i = entry.key;
            final v = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildVerseRow(isDark, v, i, _verses.length),
            );
          }),

          // ── Add verse button ───────────────────────────────────
          if (_verses.length < 6)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 16),
              child: OutlinedButton.icon(
                onPressed: _addVerse,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Add Another Verse'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _verseColor,
                  side: BorderSide(color: _verseColor.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),

          // ── Translation ───────────────────────────────────────
          _card(
            isDark,
            _verseColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('Bible Translation', isDark),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _translations
                      .map((t) => _translationChip(t, isDark))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Optional question ─────────────────────────────────
          _card(
            isDark,
            _verseColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('Your question (optional)', isDark),
                const SizedBox(height: 8),
                TextField(
                  controller: _questionCtrl,
                  maxLines: 2,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                  decoration: _textFieldDeco(
                    isDark,
                    _verseColor,
                    'e.g. What does "love" mean here?',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _buildVerseRow(bool isDark, _VerseEntry entry, int index, int total) {
    return _card(
      isDark,
      _verseColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with remove button
          Row(
            children: [
              Expanded(
                child: Text(
                  total > 1 ? 'Verse ${index + 1}' : 'Select Verse',
                  style: TextStyle(
                    color: _verseColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              if (total > 1)
                GestureDetector(
                  onTap: () => _removeVerse(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Book picker
          StatefulBuilder(
            builder: (ctx, setSt) {
              return DropdownButtonFormField<String>(
                value: entry.book,
                dropdownColor: isDark ? const Color(0xFF14162A) : Colors.white,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
                decoration: _dropdownDeco(
                  isDark,
                  _verseColor,
                ).copyWith(hintText: 'Select book'),
                hint: Text(
                  'Select book',
                  style: TextStyle(color: Colors.grey[500]),
                ),
                items: bibleBooksInOrder
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (val) {
                  setState(() => entry.book = val);
                },
              );
            },
          ),
          const SizedBox(height: 10),

          // Chapter + Start verse + End verse (always shown)
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _numField(
                  entry.chapterCtrl,
                  isDark,
                  _verseColor,
                  'Chapter',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _numField(entry.verseCtrl, isDark, _verseColor, 'Verse'),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _numField(
                  entry.endVerseCtrl,
                  isDark,
                  _verseColor,
                  'End (opt.)',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numField(
    TextEditingController ctrl,
    bool isDark,
    Color accent,
    String hint,
  ) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 14,
      ),
      decoration: _textFieldDeco(isDark, accent, hint),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _translationChip(String t, bool isDark) {
    final selected = _translation == t;
    return GestureDetector(
      onTap: () => setState(() => _translation = t),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? _verseColor
              : (isDark ? const Color(0xFF14162A) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? _verseColor
                : (isDark ? _verseColor.withOpacity(0.2) : Colors.grey[300]!),
          ),
        ),
        child: Text(
          t,
          style: TextStyle(
            color: selected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  TOPIC TAB
  // ══════════════════════════════════════════════════════════════════
  Widget _buildTopicTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero card ──────────────────────────────────────────
          _buildHeroCard(
            isDark,
            _topicColor,
            'Topic or Concept Study',
            'Enter any biblical concept — Grace, Covenant, Kingdom of God — and ILLUMINE will trace it through the whole canon: original language roots, first mention, defining passages, common distortions, and its deepest theological claim.',
          ),
          const SizedBox(height: 20),

          // ── Topic input ───────────────────────────────────────
          _card(
            isDark,
            _topicColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('Topic or Biblical Concept', isDark),
                const SizedBox(height: 8),
                TextField(
                  controller: _topicCtrl,
                  autocorrect: false,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _textFieldDeco(
                    isDark,
                    _topicColor,
                    'e.g. Grace, Kingdom of God',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Suggestions ───────────────────────────────────────
          Text(
            'QUICK PICKS',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white30 : Colors.black38,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _topicSuggestions.map((s) {
              final selected = _topicCtrl.text == s;
              return GestureDetector(
                onTap: () {
                  _topicCtrl.text = s;
                  setState(() {});
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? _topicColor.withOpacity(0.18)
                        : (isDark ? const Color(0xFF13141F) : Colors.white),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? _topicColor.withOpacity(0.6)
                          : (isDark ? Colors.transparent : Colors.grey[300]!),
                    ),
                  ),
                  child: Text(
                    s,
                    style: TextStyle(
                      color: selected
                          ? _topicColor
                          : (isDark ? Colors.white60 : Colors.black54),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── Specific angle ────────────────────────────────────
          _card(
            isDark,
            _topicColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('Specific angle (optional)', isDark),
                const SizedBox(height: 8),
                TextField(
                  controller: _specificAngleCtrl,
                  maxLines: 2,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                  decoration: _textFieldDeco(
                    isDark,
                    _topicColor,
                    'e.g. How grace applies in suffering',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  BOTTOM BAR
  // ══════════════════════════════════════════════════════════════════
  Widget _buildBottomBar(bool isDark, Color accent, bool isVerse) {
    final isValid = isVerse ? _verseFormValid : _topicFormValid;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0F22) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: (isValid && !_isRewardFlowInProgress)
                ? (isVerse ? _onGenerateVerse : _onGenerateTopic)
                : null,
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: Text(
              _isRewardFlowInProgress ? 'Loading Ad...' : 'Begin Deep Study',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: isDark
                  ? const Color(0xFF14162A)
                  : Colors.grey[200],
              disabledForegroundColor: isDark
                  ? Colors.white24
                  : Colors.grey[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: isValid ? 6 : 0,
              shadowColor: accent.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  SHARED HELPERS
  // ══════════════════════════════════════════════════════════════════
  Widget _fieldLabel(String text, bool isDark) => Text(
    text,
    style: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 13,
      color: isDark ? Colors.white70 : Colors.black87,
    ),
  );

  Widget _card(bool isDark, Color accent, {required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF0F1124) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark ? accent.withOpacity(0.18) : Colors.grey[200]!,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.2)
              : Colors.black.withOpacity(0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );

  InputDecoration _textFieldDeco(bool isDark, Color accent, String hint) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.white30 : Colors.black38,
          fontSize: 13,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF181A2E) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.transparent : Colors.grey[300]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.transparent : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      );

  InputDecoration _dropdownDeco(bool isDark, Color accent) => InputDecoration(
    filled: true,
    fillColor: isDark ? const Color(0xFF181A2E) : Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: isDark ? Colors.transparent : Colors.grey[300]!,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: isDark ? Colors.transparent : Colors.grey[300]!,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: accent, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}

// ── Verse row data ─────────────────────────────────────────────────────

class _VerseEntry {
  String? book;
  final TextEditingController chapterCtrl = TextEditingController();
  final TextEditingController verseCtrl = TextEditingController();
  final TextEditingController endVerseCtrl = TextEditingController();

  _VerseEntry();

  _VerseEntry.fromRef(VerseRef r) {
    book = r.book;
    chapterCtrl.text = r.chapter.toString();
    verseCtrl.text = r.verse.toString();
    if (r.endVerse != null && r.endVerse != r.verse) {
      endVerseCtrl.text = r.endVerse.toString();
    }
  }

  void dispose() {
    chapterCtrl.dispose();
    verseCtrl.dispose();
    endVerseCtrl.dispose();
  }
}

// ── Bible books ────────────────────────────────────────────────────────
const List<String> bibleBooksInOrder = [
  'Genesis',
  'Exodus',
  'Leviticus',
  'Numbers',
  'Deuteronomy',
  'Joshua',
  'Judges',
  'Ruth',
  '1 Samuel',
  '2 Samuel',
  '1 Kings',
  '2 Kings',
  '1 Chronicles',
  '2 Chronicles',
  'Ezra',
  'Nehemiah',
  'Esther',
  'Job',
  'Psalms',
  'Proverbs',
  'Ecclesiastes',
  'Song of Solomon',
  'Isaiah',
  'Jeremiah',
  'Lamentations',
  'Ezekiel',
  'Daniel',
  'Hosea',
  'Joel',
  'Amos',
  'Obadiah',
  'Jonah',
  'Micah',
  'Nahum',
  'Habakkuk',
  'Zephaniah',
  'Haggai',
  'Zechariah',
  'Malachi',
  'Matthew',
  'Mark',
  'Luke',
  'John',
  'Acts',
  'Romans',
  '1 Corinthians',
  '2 Corinthians',
  'Galatians',
  'Ephesians',
  'Philippians',
  'Colossians',
  '1 Thessalonians',
  '2 Thessalonians',
  '1 Timothy',
  '2 Timothy',
  'Titus',
  'Philemon',
  'Hebrews',
  'James',
  '1 Peter',
  '2 Peter',
  '1 John',
  '2 John',
  '3 John',
  'Jude',
  'Revelation',
];
