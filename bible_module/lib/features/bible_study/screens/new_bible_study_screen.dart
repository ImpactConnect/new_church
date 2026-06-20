import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/bible_study_models.dart';
import '../providers/bible_study_providers.dart';
import '../../auth/widgets/feature_gate.dart';
import '../../../services/ad_service.dart';
import '../../monetization/providers/monetization_providers.dart';
import 'bible_study_loading_screen.dart';

class NewBibleStudyScreen extends ConsumerStatefulWidget {
  const NewBibleStudyScreen({super.key});

  @override
  ConsumerState<NewBibleStudyScreen> createState() => _NewBibleStudyScreenState();
}

class _NewBibleStudyScreenState extends ConsumerState<NewBibleStudyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  StudyType _selectedType = StudyType.character;
  bool _isGenerating = false;
  bool _isRewardFlowInProgress = false;

  // ── Form Fields ──────────────────────────────────────────────────────────
  final _charNameCtrl = TextEditingController();
  final _bookNameCtrl = TextEditingController();
  final _verseRefCtrl = TextEditingController();
  final _verseQuestionCtrl = TextEditingController();
  final _themeCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();
  final _topicContextCtrl = TextEditingController();
  final _devoThemeCtrl = TextEditingController();
  final _devoContextCtrl = TextEditingController();

  StudyFormat _format = StudyFormat.series;
  int _charSessionCount = 6;
  int _bookSessionCount = 6;
  int _themeSessionCount = 6;
  int _topicSessionCount = 3;
  String _translation = 'ESV';
  DateTime _devStartDate = DateTime.now().add(const Duration(days: 1));
  int _devDays = 7;

  final List<String> _charFocusChips = [];
  static const _focusChipOptions = [
    'Faith 🙏', 'Failure & Redemption 🔄', 'Leadership 👑',
    'Obedience ⚖️', 'Prayer 🌿', 'Calling ✨',
    'Suffering 💧', 'Witness 🕊️',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      final next = StudyType.values[_tabController.index];
      if (_selectedType != next && mounted) {
        setState(() => _selectedType = next);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _charNameCtrl.dispose();
    _bookNameCtrl.dispose();
    _verseRefCtrl.dispose();
    _verseQuestionCtrl.dispose();
    _themeCtrl.dispose();
    _topicCtrl.dispose();
    _topicContextCtrl.dispose();
    _devoThemeCtrl.dispose();
    _devoContextCtrl.dispose();
    super.dispose();
  }

  bool get _canGenerate {
    switch (_selectedType) {
      case StudyType.character: return _charNameCtrl.text.trim().isNotEmpty;
      case StudyType.book: return _bookNameCtrl.text.trim().isNotEmpty;
      case StudyType.verse: return _verseRefCtrl.text.trim().isNotEmpty;
      case StudyType.theme: return _themeCtrl.text.trim().isNotEmpty;
      case StudyType.topical: return _topicCtrl.text.trim().isNotEmpty;
      case StudyType.devotional: return _devoThemeCtrl.text.trim().isNotEmpty;
    }
  }

  BibleStudyInput get _buildInput {
    switch (_selectedType) {
      case StudyType.character:
        return BibleStudyInput(
          studyType: StudyType.character,
          format: StudyFormat.series,
          sessionCount: _charSessionCount,
          characterName: _charNameCtrl.text.trim(),
          focusChips: _charFocusChips,
        );
      case StudyType.book:
        return BibleStudyInput(
          studyType: StudyType.book,
          format: StudyFormat.series,
          sessionCount: _bookSessionCount,
          bookName: _bookNameCtrl.text.trim(),
          translation: _translation,
        );
      case StudyType.verse:
        return BibleStudyInput(
          studyType: StudyType.verse,
          format: StudyFormat.single,
          sessionCount: 1,
          verseRefs: [_verseRefCtrl.text.trim()],
          verseQuestion: _verseQuestionCtrl.text.trim().isEmpty
              ? null
              : _verseQuestionCtrl.text.trim(),
          translation: _translation,
        );
      case StudyType.theme:
        return BibleStudyInput(
          studyType: StudyType.theme,
          format: StudyFormat.series,
          sessionCount: _themeSessionCount,
          themeName: _themeCtrl.text.trim(),
        );
      case StudyType.topical:
        return BibleStudyInput(
          studyType: StudyType.topical,
          format: StudyFormat.series,
          sessionCount: _topicSessionCount,
          lifeQuestion: _topicCtrl.text.trim(),
          userContext: _topicContextCtrl.text.trim().isEmpty
              ? null
              : _topicContextCtrl.text.trim(),
        );
      case StudyType.devotional:
        return BibleStudyInput(
          studyType: StudyType.devotional,
          format: StudyFormat.series,
          sessionCount: _devDays,
          devotionalTheme: _devoThemeCtrl.text.trim(),
          startDate: _devStartDate,
          personalContext: _devoContextCtrl.text.trim().isEmpty
              ? null
              : _devoContextCtrl.text.trim(),
        );
    }
  }

  Future<void> _generateStudy() async {
    if (!_canGenerate || _isGenerating) return;

    // Require authentication before generating any AI content
    FeatureGate.execute(
      context: context,
      ref: ref,
      featureName: '${_selectedType.label} Study',
      onAuthenticated: _startGenerationWithMonetization,
    );
  }

  void _startGenerationWithMonetization() {
    final isPremiumUser = ref.read(isPremiumUserProvider);
    final shouldShowAds = AdService.shouldShowAds(isPremiumUser: isPremiumUser);

    if (!shouldShowAds) {
      _doGenerate();
      return;
    }

    _showRewardedAdBeforeGeneration();
  }

  Future<void> _showRewardedAdBeforeGeneration() async {
    if (_isRewardFlowInProgress) return;
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
        _doGenerate();
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
        _doGenerate();
        return;
      }

      if (didEarnReward) {
        _doGenerate();
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

  Future<void> _doGenerate() async {
    if (!mounted) return;
    setState(() => _isGenerating = true);

    try {
      final input = _buildInput;
      final notifier = ref.read(bibleStudyNotifierProvider.notifier);

      // For single session studies (verse), generate directly
      if (input.format == StudyFormat.single || input.studyType == StudyType.verse) {
        final study = await notifier.createAndGenerateStudy(input);
        if (!mounted) return;
        context.go('/bible-study/session/${study.id}/1', extra: study);
        return;
      }

      // For series studies, generate breakdown first
      final breakdown = await notifier.createStudyBreakdown(input);

      if (!mounted) return;
      // Navigate to breakdown preview
      context.go('/bible-study/breakdown/${breakdown.studyId}', extra: {
        'breakdownState': breakdown,
        'input': input,
      });
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();
        final truncatedMsg = errorMsg.length > 80
            ? errorMsg.substring(0, 80)
            : errorMsg;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generation failed: $truncatedMsg'),
            backgroundColor: Colors.red.shade700,
          ),
        );
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isGenerating) {
      return BibleStudyLoadingScreen(
        studyType: _selectedType,
        subject: _buildInput.subject,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Bible Study'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.8,
              children: StudyType.values
                  .map((t) => _TypePill(
                        type: t,
                        isSelected: _selectedType == t,
                        onTap: () {
                          setState(() => _selectedType = t);
                          _tabController.animateTo(t.index);
                        },
                      ))
                  .toList(),
            ),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4F63D2), Color(0xFF8B3FC0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CharacterTab(
            nameCtrl: _charNameCtrl,
            format: _format,
            sessionCount: _charSessionCount,
            selectedChips: _charFocusChips,
            chipOptions: _focusChipOptions,
            onFormatChanged: (f) => setState(() => _format = f),
            onCountChanged: (c) => setState(() => _charSessionCount = c),
            onChipToggled: (chip) => setState(() {
              if (_charFocusChips.contains(chip)) {
                _charFocusChips.remove(chip);
              } else {
                _charFocusChips.add(chip);
              }
            }),
          ),
          _BookTab(
            nameCtrl: _bookNameCtrl,
            format: _format,
            sessionCount: _bookSessionCount,
            translation: _translation,
            onFormatChanged: (f) => setState(() => _format = f),
            onCountChanged: (c) => setState(() => _bookSessionCount = c),
            onTranslationChanged: (t) => setState(() => _translation = t),
          ),
          _VerseTab(
            verseCtrl: _verseRefCtrl,
            questionCtrl: _verseQuestionCtrl,
            translation: _translation,
            onTranslationChanged: (t) => setState(() => _translation = t),
          ),
          _ThemeTab(
            themeCtrl: _themeCtrl,
            format: _format,
            sessionCount: _themeSessionCount,
            onFormatChanged: (f) => setState(() => _format = f),
            onCountChanged: (c) => setState(() => _themeSessionCount = c),
          ),
          _TopicalTab(
            questionCtrl: _topicCtrl,
            contextCtrl: _topicContextCtrl,
            sessionCount: _topicSessionCount,
            onCountChanged: (c) => setState(() => _topicSessionCount = c),
          ),
          _DevotionalTab(
            themeCtrl: _devoThemeCtrl,
            contextCtrl: _devoContextCtrl,
            days: _devDays,
            startDate: _devStartDate,
            onDaysChanged: (d) => setState(() => _devDays = d),
            onStartDateChanged: (d) => setState(() => _devStartDate = d),
          ),
        ],
      ),
      bottomNavigationBar: _GenerateBar(
        canGenerate: _canGenerate && !_isRewardFlowInProgress,
        onGenerate: _generateStudy,
        selectedType: _selectedType,
        isRewardFlowInProgress: _isRewardFlowInProgress,
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  final StudyType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypePill({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = const Color(0xFF6B4FC8);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? active.withOpacity(0.12)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? active
                : Theme.of(context).dividerColor.withOpacity(0.35),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(type.emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                type.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? active
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Generate Bar ─────────────────────────────────────────────────────────────
class _GenerateBar extends StatelessWidget {
  final bool canGenerate;
  final VoidCallback onGenerate;
  final StudyType selectedType;
  final bool isRewardFlowInProgress;

  const _GenerateBar({
    required this.canGenerate,
    required this.onGenerate,
    required this.selectedType,
    required this.isRewardFlowInProgress,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: AnimatedOpacity(
          opacity: canGenerate ? 1.0 : 0.5,
          duration: const Duration(milliseconds: 200),
          child: GestureDetector(
            onTap: canGenerate ? onGenerate : null,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: canGenerate
                    ? const LinearGradient(
                        colors: [Color(0xFF4F63D2), Color(0xFF8B3FC0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: canGenerate ? null : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                boxShadow: canGenerate
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6B4FC8).withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    selectedType.emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isRewardFlowInProgress
                        ? 'Loading Ad...'
                        : 'Generate ${selectedType.label} Study',
                    style: TextStyle(
                      color: canGenerate ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shared form components ───────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F63D2).withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF4F63D2).withOpacity(0.12),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: Color(0xFF8B3FC0),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _IntroTextCard extends StatelessWidget {
  final String text;
  const _IntroTextCard(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4F63D2).withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4F63D2).withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B3FC0), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF4F63D2)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        filled: true,
        fillColor: isDark
            ? const Color(0xFF0E0F1C)
            : const Color(0xFFF5F4FF).withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: const Color(0xFF4F63D2).withOpacity(0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: const Color(0xFF4F63D2).withOpacity(0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF4F63D2),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _FormatPicker extends StatelessWidget {
  final StudyFormat value;
  final int sessionCount;
  final ValueChanged<StudyFormat> onFormatChanged;
  final ValueChanged<int> onCountChanged;

  const _FormatPicker({
    required this.value,
    required this.sessionCount,
    required this.onFormatChanged,
    required this.onCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _FormatChip(
              label: 'Single',
              selected: value == StudyFormat.single,
              onTap: () => onFormatChanged(StudyFormat.single),
            ),
            const SizedBox(width: 12),
            _FormatChip(
              label: 'Series',
              selected: value == StudyFormat.series,
              onTap: () => onFormatChanged(StudyFormat.series),
            ),
          ],
        ),
        if (value == StudyFormat.series) ...[
          const SizedBox(height: 16),
          Slider(
            value: sessionCount.toDouble(),
            min: 2,
            max: 10,
            divisions: 8,
            activeColor: const Color(0xFF4F63D2),
            label: '$sessionCount sessions',
            onChanged: (v) => onCountChanged(v.round()),
          ),
        ],
      ],
    );
  }
}

class _FormatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FormatChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF4F63D2)
              : const Color(0xFF4F63D2).withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFF4F63D2)
                : const Color(0xFF4F63D2).withOpacity(0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : const Color(0xFF4F63D2),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _TranslationPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _TranslationPicker({required this.value, required this.onChanged});

  static const _translations = ['ESV', 'NIV', 'KJV', 'NKJV', 'NLT', 'NASB'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _translations
          .map((t) => _FormatChip(
                label: t,
                selected: t == value,
                onTap: () => onChanged(t),
              ))
          .toList(),
    );
  }
}

// ─── Session Count Stepper ────────────────────────────────────────────────────
class _SessionCountStepper extends StatelessWidget {
  final int sessionCount;
  final int minSessions;
  final int maxSessions;
  final ValueChanged<int> onCountChanged;
  final String helpText;

  const _SessionCountStepper({
    required this.sessionCount,
    required this.minSessions,
    required this.maxSessions,
    required this.onCountChanged,
    required this.helpText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF4F63D2).withOpacity(0.08),
                const Color(0xFF8B3FC0).withOpacity(0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF4F63D2).withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$sessionCount Sessions',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F63D2),
                    ),
                  ),
                  Row(
                    children: [
                      _StepperButton(
                        icon: Icons.remove_rounded,
                        onTap: sessionCount > minSessions
                            ? () => onCountChanged(sessionCount - 1)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      _StepperButton(
                        icon: Icons.add_rounded,
                        onTap: sessionCount < maxSessions
                            ? () => onCountChanged(sessionCount + 1)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (sessionCount - minSessions) / (maxSessions - minSessions),
                  backgroundColor: const Color(0xFF4F63D2).withOpacity(0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F63D2)),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Min: $minSessions',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Max: $maxSessions',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF5BB8F6).withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF5BB8F6).withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Color(0xFF5BB8F6),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  helpText,
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFF4F63D2)
              : const Color(0xFF4F63D2).withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF4F63D2).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.grey,
          size: 24,
        ),
      ),
    );
  }
}

// ─── Character Tab ────────────────────────────────────────────────────────────
class _CharacterTab extends StatelessWidget {
  final TextEditingController nameCtrl;
  final StudyFormat format;
  final int sessionCount;
  final List<String> selectedChips;
  final List<String> chipOptions;
  final ValueChanged<StudyFormat> onFormatChanged;
  final ValueChanged<int> onCountChanged;
  final ValueChanged<String> onChipToggled;

  const _CharacterTab({
    required this.nameCtrl,
    required this.format,
    required this.sessionCount,
    required this.selectedChips,
    required this.chipOptions,
    required this.onFormatChanged,
    required this.onCountChanged,
    required this.onChipToggled,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const _IntroTextCard(
              'A deep narrative-theological portrait of a biblical figure. Their calling, failures, faith, legacy, and Christological significance.'),
          _SectionCard(
            title: 'Biblical Character',
            child: _StyledTextField(
              controller: nameCtrl,
              hint: 'e.g. Elijah, Mary Magdalene, Paul, David...',
            ),
          ),
          _SectionCard(
            title: 'Study Focus (Optional)',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: chipOptions
                  .map((chip) => FilterChip(
                        label: Text(chip, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        selected: selectedChips.contains(chip),
                        onSelected: (_) => onChipToggled(chip),
                        selectedColor: const Color(0xFF4F63D2).withOpacity(0.15),
                        backgroundColor: Theme.of(context).cardColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: selectedChips.contains(chip)
                                ? const Color(0xFF4F63D2)
                                : const Color(0xFF4F63D2).withOpacity(0.1),
                            width: selectedChips.contains(chip) ? 1.5 : 1.0,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          _SectionCard(
            title: 'Number of Sessions',
            child: _SessionCountStepper(
              sessionCount: sessionCount,
              minSessions: 2,
              maxSessions: 14,
              onCountChanged: onCountChanged,
              helpText: 'Character studies require 2-14 sessions to trace their life story chronologically.',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Book Tab ─────────────────────────────────────────────────────────────────
class _BookTab extends StatelessWidget {
  final TextEditingController nameCtrl;
  final StudyFormat format;
  final int sessionCount;
  final String translation;
  final ValueChanged<StudyFormat> onFormatChanged;
  final ValueChanged<int> onCountChanged;
  final ValueChanged<String> onTranslationChanged;

  const _BookTab({
    required this.nameCtrl, required this.format, required this.sessionCount,
    required this.translation, required this.onFormatChanged,
    required this.onCountChanged, required this.onTranslationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const _IntroTextCard(
              'A systematic journey through an entire Bible book — context, structure, theology, and meaning for today.'),
          _SectionCard(
            title: 'Bible Book',
            child: _StyledTextField(controller: nameCtrl, hint: 'e.g. Romans, Genesis, Psalms, Revelation...'),
          ),
          _SectionCard(
            title: 'Translation',
            child: _TranslationPicker(value: translation, onChanged: onTranslationChanged),
          ),
          _SectionCard(
            title: 'Number of Sessions',
            child: _SessionCountStepper(
              sessionCount: sessionCount,
              minSessions: 2,
              maxSessions: 14,
              onCountChanged: onCountChanged,
              helpText: 'Book studies require 2-14 sessions to cover the book comprehensively.',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Verse Tab ────────────────────────────────────────────────────────────────
class _VerseTab extends StatelessWidget {
  final TextEditingController verseCtrl;
  final TextEditingController questionCtrl;
  final String translation;
  final ValueChanged<String> onTranslationChanged;

  const _VerseTab({
    required this.verseCtrl, required this.questionCtrl,
    required this.translation, required this.onTranslationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const _IntroTextCard(
              'A personal study session on a specific verse or passage. Original language, connections across scripture, and what it means for life today.'),
          _SectionCard(
            title: 'Verse Reference',
            child: _StyledTextField(
              controller: verseCtrl,
              hint: 'e.g. Romans 8:1, John 3:16, Psalm 23:1–6',
            ),
          ),
          _SectionCard(
            title: 'Your Question (Optional)',
            child: _StyledTextField(
              controller: questionCtrl,
              hint: 'What does this verse mean for my life?',
              maxLines: 2,
            ),
          ),
          _SectionCard(
            title: 'Translation',
            child: _TranslationPicker(value: translation, onChanged: onTranslationChanged),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF5BB8F6).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF5BB8F6).withOpacity(0.2)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.push_pin_rounded, size: 18, color: Color(0xFF5BB8F6)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Verse Study is always Single Session — depth achieved in one sitting. For multiple passages, list them separated by commas.',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ─── Theme Tab ────────────────────────────────────────────────────────────────
class _ThemeTab extends StatelessWidget {
  final TextEditingController themeCtrl;
  final StudyFormat format;
  final int sessionCount;
  final ValueChanged<StudyFormat> onFormatChanged;
  final ValueChanged<int> onCountChanged;

  const _ThemeTab({
    required this.themeCtrl, required this.format, required this.sessionCount,
    required this.onFormatChanged, required this.onCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const _IntroTextCard(
              'A canonical thread study tracing how the Bible develops a theological concept from Genesis to Revelation.'),
          _SectionCard(
            title: 'Theme or Concept',
            child: _StyledTextField(controller: themeCtrl, hint: 'e.g. Covenant, Redemption, Faith, Kingdom of God...'),
          ),
          _SectionCard(
            title: 'Number of Sessions',
            child: _SessionCountStepper(
              sessionCount: sessionCount,
              minSessions: 2,
              maxSessions: 14,
              onCountChanged: onCountChanged,
              helpText: 'Theme studies require 2-14 sessions to trace the concept across scripture.',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Topical Tab ──────────────────────────────────────────────────────────────
class _TopicalTab extends StatelessWidget {
  final TextEditingController questionCtrl;
  final TextEditingController contextCtrl;
  final int sessionCount;
  final ValueChanged<int> onCountChanged;

  const _TopicalTab({
    required this.questionCtrl,
    required this.contextCtrl,
    required this.sessionCount,
    required this.onCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const _IntroTextCard(
              'A practical life question answered from scripture. Pastoral, warm, and comprehensively grounded in the Bible.'),
          _SectionCard(
            title: 'Your Question',
            child: _StyledTextField(controller: questionCtrl, hint: 'e.g. What does the Bible say about anxiety? How do I forgive someone who hurt me?', maxLines: 3, keyboardType: TextInputType.multiline),
          ),
          _SectionCard(
            title: 'Personal Context (Optional)',
            child: _StyledTextField(controller: contextCtrl, hint: 'Share what you\'re going through...', maxLines: 3),
          ),
          _SectionCard(
            title: 'Number of Sessions',
            child: _SessionCountStepper(
              sessionCount: sessionCount,
              minSessions: 3,
              maxSessions: 7,
              onCountChanged: onCountChanged,
              helpText: 'Topical studies require 3-7 sessions: Session 1 (What Bible says), Session 2 (Stories/personalities), Session 3+ (Application).',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Devotional Tab ───────────────────────────────────────────────────────────
class _DevotionalTab extends StatefulWidget {
  final TextEditingController themeCtrl;
  final TextEditingController contextCtrl;
  final int days;
  final DateTime startDate;
  final ValueChanged<int> onDaysChanged;
  final ValueChanged<DateTime> onStartDateChanged;

  const _DevotionalTab({
    required this.themeCtrl, required this.contextCtrl, required this.days,
    required this.startDate, required this.onDaysChanged, required this.onStartDateChanged,
  });

  @override
  State<_DevotionalTab> createState() => _DevotionalTabState();
}

class _DevotionalTabState extends State<_DevotionalTab> {
  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: widget.startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) widget.onStartDateChanged(d);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const _IntroTextCard(
              'A daily spiritual journey anchored to a theme or scripture. Delivered one session per day starting from a user-selected date.'),
          _SectionCard(
            title: 'Devotional Theme or Scripture',
            child: _StyledTextField(controller: widget.themeCtrl, hint: 'e.g. Peace in the storm, Walking by faith, Psalm 23...'),
          ),
          _SectionCard(
            title: 'Personal Context (Optional)',
            child: _StyledTextField(controller: widget.contextCtrl, hint: 'What season of life are you in right now?', maxLines: 2),
          ),
          _SectionCard(
            title: 'Number of Days (3–10)',
            child: Slider(
              value: widget.days.toDouble(),
              min: 3,
              max: 10,
              divisions: 7,
              activeColor: const Color(0xFF9B7DF6),
              label: '${widget.days} days',
              onChanged: (v) => widget.onDaysChanged(v.round()),
            ),
          ),
          _SectionCard(
            title: 'Start Date',
            child: GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF0E0F1C)
                      : const Color(0xFFF5F4FF).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF9B7DF6).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF9B7DF6)),
                    const SizedBox(width: 16),
                    Text(
                      DateFormat('EEEE, MMMM d, y').format(widget.startDate),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
