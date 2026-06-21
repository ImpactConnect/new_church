import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../data/models/ai/ai_models.dart';
import '../../../services/ad_service.dart';
import '../../monetization/providers/monetization_providers.dart';
import '../providers/bible_providers.dart';
import 'ai_chat_screen.dart';

class AiBookExegesisScreen extends ConsumerStatefulWidget {
  final String bookName;

  const AiBookExegesisScreen({super.key, required this.bookName});

  @override
  ConsumerState<AiBookExegesisScreen> createState() =>
      _AiBookExegesisScreenState();
}

class _AiBookExegesisScreenState extends ConsumerState<AiBookExegesisScreen> {
  late Future<BookExegesis> _analysisFuture;
  bool _isRewardFlowInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadAnalysisWithMonetization();
  }

  void _loadAnalysis() {
    final mode = ref.read(aiModeNotifierProvider);
    final service = ref.read(aiServiceProvider);

    setState(() {
      final depth = mode == AiMode.deep ? 'comprehensive' : 'standard';
      _analysisFuture = service.generateBookExegesis(
        widget.bookName,
        depth: depth,
      );
    });
  }

  Future<void> _loadAnalysisWithMonetization() async {
    if (_isRewardFlowInProgress) return;
    final isPremiumUser = ref.read(isPremiumUserProvider);
    final shouldShowAds = AdService.shouldShowAds(isPremiumUser: isPremiumUser);

    if (!shouldShowAds) {
      _loadAnalysis();
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
        _loadAnalysis();
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
        _loadAnalysis();
        return;
      }

      if (didEarnReward) {
        _loadAnalysis();
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
    final currentMode = ref.watch(aiModeNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.bookName} Exposition'),
        actions: [
          PopupMenuButton<AiMode>(
            initialValue: currentMode,
            onSelected: (mode) {
              ref.read(aiModeNotifierProvider.notifier).setMode(mode);
              _loadAnalysisWithMonetization();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: AiMode.simple,
                child: Text('Simple Mode (New Believer)'),
              ),
              const PopupMenuItem(
                value: AiMode.study,
                child: Text('Study Mode (Balanced)'),
              ),
              const PopupMenuItem(
                value: AiMode.deep,
                child: Text('Deep Mode (Theological)'),
              ),
            ],
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final autoPrompt =
              'I am studying the book of **${widget.bookName}**.\\n\\nPlease provide a very concise introductory summary of this book. '
              'Start by highlighting my query in bold. Then, give a 1-paragraph bottom-line submission. '
              'End by asking me to ask further questions for clarification.';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AiChatScreen(
                bookName: widget.bookName,
                chapterNumber: 1, // Defaulting to 1 for Book level chat
                verseNumber: 1,
                verseText: 'The entire book of ${widget.bookName}',
                hiddenAutoPrompt: autoPrompt,
              ),
            ),
          );
        },
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Ask Rabbi'),
      ),
      body: FutureBuilder<BookExegesis>(
        future: _analysisFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(context);
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'AI Connection Error',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _loadAnalysisWithMonetization,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) return const SizedBox();

          final analysis = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(context, analysis),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'Historical Background',
                  analysis.historicalBackground,
                ),
                _buildListSection(
                  context,
                  'Major Themes',
                  analysis.majorThemes,
                ),
                _buildSection(
                  context,
                  'Literary Structure',
                  analysis.literaryStructure,
                ),
                _buildSection(
                  context,
                  'Theological Emphases',
                  analysis.theologicalEmphases,
                ),
                _buildSection(
                  context,
                  'Covenantal Context',
                  analysis.covenantalContext,
                ),
                _buildSection(
                  context,
                  'Christological Trajectory',
                  analysis.christologicalOrRedemptiveTrajectory,
                ),
                _buildListSection(
                  context,
                  'Key Passages',
                  analysis.keyPassages,
                ),
                if (analysis.interpretiveChallenges.isNotEmpty)
                  _buildSection(
                    context,
                    'Interpretive Challenges',
                    analysis.interpretiveChallenges,
                  ),
                _buildSection(
                  context,
                  'Canonical Role',
                  analysis.canonicalRole,
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, BookExegesis analysis) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Book Overview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(context, 'Authorship', analysis.authorship),
          _buildDetailRow(context, 'Date & Setting', analysis.dateAndSetting),
          _buildDetailRow(
            context,
            'Original Audience',
            analysis.originalAudience,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    if (content.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(
    BuildContext context,
    String title,
    List<String> items,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.withValues(alpha: 0.1),
      highlightColor: Colors.grey.withValues(alpha: 0.05),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        itemBuilder: (_, _) => Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 24, width: 150, color: Colors.white),
              const SizedBox(height: 12),
              Container(
                height: 80,
                width: double.infinity,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
