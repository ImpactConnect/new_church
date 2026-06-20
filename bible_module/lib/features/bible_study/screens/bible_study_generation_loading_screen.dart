import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../../services/ad_service.dart';
import '../../monetization/providers/monetization_providers.dart';
import '../models/bible_study_models.dart';
import '../models/series_map_item.dart';
import '../providers/bible_study_providers.dart';

class BibleStudyGenerationLoadingScreen extends ConsumerStatefulWidget {
  final String studyId;
  final StudyBreakdownState breakdownState;
  final BibleStudyInput input;

  const BibleStudyGenerationLoadingScreen({
    super.key,
    required this.studyId,
    required this.breakdownState,
    required this.input,
  });

  @override
  ConsumerState<BibleStudyGenerationLoadingScreen> createState() =>
      _BibleStudyGenerationLoadingScreenState();
}

class _BibleStudyGenerationLoadingScreenState
    extends ConsumerState<BibleStudyGenerationLoadingScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _escapeDelay = Duration(seconds: 45);

  late AnimationController _animController;
  late Animation<double> _pulseAnimation;
  Timer? _escapeTimer;

  int _totalSessions = 0;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isComplete = false;
  bool _hasNavigated = false;
  bool _timedOutToSeriesMap = false;
  bool _isCancelled = false;
  bool _isRewardFlowInProgress = false;

  @override
  void initState() {
    super.initState();
    _totalSessions = widget.breakdownState.totalSessions;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // Start generation after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGeneration();
    });
    _escapeTimer = Timer(_escapeDelay, () {
      if (!mounted || _isComplete || _hasNavigated) return;
      setState(() {
        _timedOutToSeriesMap = true;
      });
      _navigateToSeriesMap();
    });
  }

  Future<void> _startGeneration() async {
    try {
      final notifier = ref.read(bibleStudyNotifierProvider.notifier);

      await notifier.approveBreakdownAndGenerate(
        widget.breakdownState,
        widget.input,
      );

      if (_isCancelled || !mounted) return;

      setState(() {
        _isComplete = true;
      });
      _animController.stop();

      // Navigate to series map after a brief delay
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted && !_isCancelled) {
        _navigateToSeriesMap();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
        _animController.stop();
      }
    }
  }

  Future<void> _runWithRewardGate({
    required Future<void> Function() onRewardedAction,
  }) async {
    if (_isRewardFlowInProgress) return;
    final isPremiumUser = ref.read(isPremiumUserProvider);
    final shouldShowAds = AdService.shouldShowAds(isPremiumUser: isPremiumUser);

    if (!shouldShowAds) {
      await onRewardedAction();
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
        await onRewardedAction();
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
        await onRewardedAction();
        return;
      }

      if (didEarnReward) {
        await onRewardedAction();
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

  void _navigateToSeriesMap() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    _escapeTimer?.cancel();
    context.go('/bible-study/map/${widget.studyId}');
  }

  Color get _accentColor {
    final studyType = _parseStudyType(widget.breakdownState.studyType);
    return Color(studyType.accentValue);
  }

  StudyType _parseStudyType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'character':
        return StudyType.character;
      case 'book':
        return StudyType.book;
      case 'verse':
        return StudyType.verse;
      case 'theme':
        return StudyType.theme;
      case 'topical':
        return StudyType.topical;
      case 'devotional':
        return StudyType.devotional;
      default:
        return StudyType.character;
    }
  }

  double get _progressPercentage {
    if (_isComplete) return 1.0;
    if (_timedOutToSeriesMap) return 0.9;
    return 0.65;
  }

  String get _statusMessage {
    if (_isComplete) {
      return 'Generation complete!';
    }

    if (_timedOutToSeriesMap) return 'Opening your series map...';
    return 'Preparing Session 1';
  }

  String get _subStatusMessage {
    if (_isComplete) {
      return 'Taking you to your study...';
    }

    if (_timedOutToSeriesMap) {
      return 'You can keep using the app while the remaining content generates';
    }

    return 'The rest of the sessions will continue generating in the background';
  }

  @override
  void dispose() {
    _escapeTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<bool> _showCancelDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Generation?'),
        content: const Text(
          'Leaving now will cancel the Bible Study generation. '
          'The content will not be saved. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Generation'),
          ),
        ],
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Generation Error'),
          backgroundColor: isDark ? const Color(0xFF09090F) : Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 24),
                Text(
                  'Generation Failed',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _isRewardFlowInProgress
                      ? null
                      : () {
                    setState(() {
                      _hasError = false;
                      _isComplete = false;
                      _hasNavigated = false;
                      _timedOutToSeriesMap = false;
                    });
                    _animController.repeat(reverse: true);
                    _escapeTimer?.cancel();
                    _escapeTimer = Timer(_escapeDelay, () {
                      if (!mounted || _isComplete || _hasNavigated) return;
                      setState(() {
                        _timedOutToSeriesMap = true;
                      });
                      _navigateToSeriesMap();
                    });
                    _runWithRewardGate(onRewardedAction: _startGeneration);
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    _isRewardFlowInProgress ? 'Loading Ad...' : 'Try Again',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accentColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: _hasError || _isComplete,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final router = GoRouter.of(context);
          final confirmed = await _showCancelDialog();
          if (!mounted || !context.mounted || !confirmed) return;
          _isCancelled = true;
          _escapeTimer?.cancel();
          _animController.stop();
          router.go('/bible-study');
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Warning Banner ──────────────────────────────────────────
                        if (!_isComplete && !_timedOutToSeriesMap)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Please stay on this screen while content is being created.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.amber.shade800,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Text(
                          widget.breakdownState.studyTitle,
                          style: const TextStyle(
                            fontFamily: 'Spectral',
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _accentColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '$_totalSessions ${_totalSessions == 1 ? 'Session' : 'Sessions'}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _accentColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),

                        SizedBox(
                          width: 200,
                          height: 200,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 200,
                                height: 200,
                                child: CircularProgressIndicator(
                                  value: _isComplete ? 1.0 : null,
                                  strokeWidth: 6,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _accentColor,
                                  ),
                                  backgroundColor: _accentColor.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _pulseAnimation.value,
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: _accentColor.withValues(
                                              alpha: 0.08,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            _isComplete
                                                ? Icons.check_circle_outline
                                                : Icons.auto_stories_rounded,
                                            size: 32,
                                            color: _accentColor,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${(_progressPercentage * 100).toInt()}%',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: _accentColor,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isComplete ? 'Complete' : 'Generating',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),

                        Text(
                          _statusMessage,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        Text(
                          _subStatusMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        if (!_isComplete && _totalSessions > 1) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _accentColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _accentColor.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: _accentColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Session 1 is being prepared now',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _accentColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 16,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${_totalSessions - 1} sessions will continue in background',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
