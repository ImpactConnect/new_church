import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';

import '../../../services/ad_service.dart';
import '../../monetization/providers/monetization_providers.dart';
import '../models/exegesis_result_v2_model.dart';
import '../providers/exegesis_providers_v2.dart';

class ExegesisLoadingScreen extends ConsumerStatefulWidget {
  final String subject;
  final String entryType;
  final String mode; // v2: mode instead of depthLevel

  const ExegesisLoadingScreen({
    super.key,
    required this.subject,
    required this.entryType,
    required this.mode,
  });

  @override
  ConsumerState<ExegesisLoadingScreen> createState() => _ExegesisLoadingScreenState();
}

class _ExegesisLoadingScreenState extends ConsumerState<ExegesisLoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isRewardFlowInProgress = false;

  // v2: Simplified - no phase labels, just quiet expectation
  
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // Schedule generation after the build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGeneration();
    });
  }

  // Get mode-specific color
  Color get _modeColor {
    final mode = ExegesisMode.values.firstWhere(
      (m) => m.name == widget.mode,
      orElse: () => ExegesisMode.understand,
    );
    return mode == ExegesisMode.understand
        ? const Color(0xFFD4A86A) // Amber
        : const Color(0xFF6898D4); // Blue
  }

  Future<void> _startGeneration() async {
    try {
      final notifier = ref.read(exegesisNotifierProvider.notifier);
      
      // Parse entry type
      final entryType = _parseEntryType(widget.entryType);
      final mode = ExegesisMode.values.firstWhere(
        (m) => m.name == widget.mode,
        orElse: () => ExegesisMode.understand,
      );

      await notifier.generateExegesis(
        subject: widget.subject,
        entryType: entryType,
        mode: mode,
      );

      if (mounted) {
        final result = ref.read(exegesisNotifierProvider).result;
        if (result != null) {
          context.go('/exegesis/result/${result.id}');
        }
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

  ExegesisEntryType _parseEntryType(String type) {
    switch (type.toLowerCase()) {
      case 'single verse':
        return ExegesisEntryType.singleVerse;
      case 'passage':
        return ExegesisEntryType.passage;
      case 'bible book':
        return ExegesisEntryType.bibleBook;
      case 'bible character':
        return ExegesisEntryType.bibleCharacter;
      case 'theme':
        return ExegesisEntryType.theme;
      default:
        return ExegesisEntryType.singleVerse;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                const SizedBox(height: 24),
                Text(
                  'Generation Failed',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
                    });
                    _animController.repeat(reverse: true);
                    _runWithRewardGate(onRewardedAction: _startGeneration);
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    _isRewardFlowInProgress ? 'Loading Ad...' : 'Try Again',
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go Back'),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mode-colored pulse animation
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: _modeColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _modeColor.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.wb_sunny_outlined,
                              size: 64,
                              color: _modeColor,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 48),
                    
                    // Subject title (quiet expectation)
                    Text(
                      widget.subject,
                      style: const TextStyle(
                        fontFamily: 'Spectral',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    
                    // Simple progress indicator
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_modeColor),
                      strokeWidth: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
