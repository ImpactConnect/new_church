import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../auth/widgets/feature_gate.dart';
import '../../../services/ad_service.dart';
import '../../monetization/providers/monetization_providers.dart';
import '../models/exegesis_result_v2_model.dart';

class ExegesisFormScreen extends ConsumerStatefulWidget {
  final String? initialEntryType;

  const ExegesisFormScreen({super.key, this.initialEntryType});

  @override
  ConsumerState<ExegesisFormScreen> createState() => _ExegesisFormScreenState();
}

class _ExegesisFormScreenState extends ConsumerState<ExegesisFormScreen> {
  final _inputController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isRewardFlowInProgress = false;

  String _selectedType = 'Single Verse';
  ExegesisMode _selectedMode = ExegesisMode.understand; // v2 mode

  final List<String> _entryTypes = [
    'Single Verse',
    'Passage',
    'Bible Book',
    'Bible Character',
    'Theme'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialEntryType != null && _entryTypes.contains(widget.initialEntryType)) {
      _selectedType = widget.initialEntryType!;
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      FeatureGate.execute(
        context: context,
        ref: ref,
        featureName: 'Exegesis',
        onAuthenticated: _startExegesisWithMonetization,
      );
    }
  }

  void _startExegesisWithMonetization() {
    final isPremiumUser = ref.read(isPremiumUserProvider);
    final shouldShowAds = AdService.shouldShowAds(isPremiumUser: isPremiumUser);

    if (!shouldShowAds) {
      _openExegesisLoading();
      return;
    }

    _showRewardedAdBeforeExegesis();
  }

  Future<void> _showRewardedAdBeforeExegesis() async {
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
        _openExegesisLoading();
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
        _openExegesisLoading();
        return;
      }

      if (didEarnReward) {
        _openExegesisLoading();
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

  void _openExegesisLoading() {
    final uri = Uri(
      path: '/exegesis/loading',
      queryParameters: {
        'subject': _inputController.text.trim(),
        'entryType': _selectedType,
        'mode': _selectedMode.name, // v2 mode parameter
      },
    );
    context.push(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Exegesis'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                const SizedBox(height: 32),

                // Main Input
                Text(
                  'What would you like to study?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _inputController,
                  autofocus: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a subject to analyze.';
                    }
                    return null;
                  },
                  maxLines: 2,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'e.g. John 3:16, Romans 8:1-4, Apostle Paul, Covenant',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  style: const TextStyle(fontSize: 18),
                ),
                
                const SizedBox(height: 32),

                // Entry Type Chips
                Text(
                  'Detected Type',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select the entry type that best matches your subject.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 12,
                  children: _entryTypes.map((type) {
                    final isSelected = _selectedType == type;
                    return ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedType = type;
                          });
                        }
                      },
                      selectedColor: const Color(0xFFC8B87A).withValues(alpha: 0.2), // Parchment
                      labelStyle: TextStyle(
                        color: isSelected 
                          ? const Color(0xFFC8B87A) // Parchment
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected 
                            ? const Color(0xFFC8B87A) 
                            : Theme.of(context).dividerColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),

                // Mode Toggle (v2)
                Text(
                  'Choose Your Approach',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildModeButton(
                        context,
                        mode: ExegesisMode.understand,
                        emoji: '🌅',
                        title: 'Help Me Understand',
                        description: 'Narrative-first, warm, accessible',
                        color: const Color(0xFFD4A86A), // Amber
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModeButton(
                        context,
                        mode: ExegesisMode.goDeep,
                        emoji: '🔬',
                        title: 'Go Deep',
                        description: 'Technical layers, word studies',
                        color: const Color(0xFF6898D4), // Blue
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // Submit Button
                FilledButton.icon(
                  onPressed: _isRewardFlowInProgress ? null : _submit,
                  icon: const Icon(Icons.lightbulb_outline),
                  label: Text(
                    _isRewardFlowInProgress
                        ? 'Loading Ad...'
                        : 'Open My Understanding',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: const Color(0xFFD4A86A), // Amber
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wb_sunny_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ILLUMINE',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scripture opens up. Choose how deep you want to go.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context, {
    required ExegesisMode mode,
    required String emoji,
    required String title,
    required String description,
    required Color color,
  }) {
    final isSelected = _selectedMode == mode;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
            ? color.withOpacity(0.15)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: color,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
