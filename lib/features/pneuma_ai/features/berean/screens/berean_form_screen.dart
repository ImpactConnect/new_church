import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';

import '../models/berean_evaluation_model.dart';
import '../repositories/berean_repository.dart';
import '../services/berean_ai_service.dart';
import '../services/berean_pdf_service.dart';
import 'package:church_mobile/features/bible_ai/features/bible/widgets/ai_markdown_body.dart';
import 'package:church_mobile/features/pneuma_ai/shared/widgets/bible_passage_bottom_sheet.dart';
import '../../bible/screens/ai_chat_screen.dart';
import 'package:church_mobile/features/pneuma_ai/features/auth/widgets/feature_gate.dart';
import 'package:church_mobile/features/pneuma_ai/services/ad_service.dart';
import 'package:church_mobile/features/pneuma_ai/features/monetization/providers/monetization_providers.dart';
import 'package:church_mobile/features/pneuma_ai/features/notes/presentation/widgets/add_to_note_dialog.dart';
import 'package:church_mobile/features/pneuma_ai/features/notes/data/models/linked_content_reference.dart';

// ═══════════════════════════════════════════════════════════════════
//  INPUT SCREEN
// ═══════════════════════════════════════════════════════════════════

class BereanFormScreen extends ConsumerStatefulWidget {
  const BereanFormScreen({super.key});

  @override
  ConsumerState<BereanFormScreen> createState() => _BereanFormScreenState();
}

class _BereanFormScreenState extends ConsumerState<BereanFormScreen> {
  final _textController = TextEditingController();
  String _statementTypeHint = '';
  bool _isLoading = false;
  bool _isRewardFlowInProgress = false;

  static const _typeHints = [
    'Doctrinal',
    'Prophetic',
    'Pastoral',
    'Prosperity',
    'Motivational',
    'Cultural',
    'Ethical',
    'Apologetics',
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _evaluate() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a statement to evaluate.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Navigate to loading screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _BereanLoadingScreen(
          inputText: text,
          statementTypeHint: _statementTypeHint,
        ),
      ),
    ).then((_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _onEvaluatePressed() {
    FocusScope.of(context).unfocus();
    FeatureGate.execute(
      context: context,
      ref: ref,
      featureName: 'Berean Evaluations',
      onAuthenticated: _startEvaluationWithMonetization,
    );
  }

  void _startEvaluationWithMonetization() {
    final isPremiumUser = ref.read(isPremiumUserProvider);
    final shouldShowAds = AdService.shouldShowAds(isPremiumUser: isPremiumUser);

    if (!shouldShowAds) {
      _evaluate();
      return;
    }

    _showRewardedAdBeforeEvaluation();
  }

  Future<void> _showRewardedAdBeforeEvaluation() async {
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
        _evaluate();
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
        _evaluate();
        return;
      }

      if (didEarnReward) {
        _evaluate();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Evaluation'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // — Hero Header —
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3F51B5), Color(0xFF673AB7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.balance,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Test All Things',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Enter a statement, teaching, or quote to have it analyzed against Scripture.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // — Input —
                  Text(
                    'Statement or Quote',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _textController,
                    maxLines: 5,
                    maxLength: 500,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                    decoration: InputDecoration(
                      hintText: 'e.g. "God helps those who help themselves"',
                      hintStyle: TextStyle(
                        color: isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? theme.colorScheme.surfaceContainerHighest
                          : theme.colorScheme.surface,
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // — Type Hint Chips —
                  Text(
                    'Statement Type (optional)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _typeHints.map((hint) {
                      final isSelected = _statementTypeHint == hint;
                      return FilterChip(
                        label: Text(hint),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _statementTypeHint = isSelected ? '' : hint;
                          });
                        },
                        selectedColor: const Color(
                          0xFF673AB7,
                        ).withValues(alpha: 0.2),
                        checkmarkColor: const Color(0xFF673AB7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  // — Evaluate Button —
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed:
                          (_isLoading || _isRewardFlowInProgress)
                              ? null
                              : _onEvaluatePressed,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.balance),
                      label: Text(
                        _isLoading
                            ? 'Analyzing...'
                            : _isRewardFlowInProgress
                                ? 'Loading Ad...'
                                : 'Run Berean Check',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF673AB7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: const Color(
                          0xFF673AB7,
                        ).withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  LOADING / ANALYSIS SCREEN
// ═══════════════════════════════════════════════════════════════════

class _BereanLoadingScreen extends StatefulWidget {
  final String inputText;
  final String statementTypeHint;

  const _BereanLoadingScreen({
    required this.inputText,
    required this.statementTypeHint,
  });

  @override
  State<_BereanLoadingScreen> createState() => _BereanLoadingScreenState();
}

class _BereanLoadingScreenState extends State<_BereanLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _phaseIndex = 0;
  int _scripIndex = 0;
  Timer? _phaseTimer;
  Timer? _scripTimer;
  Timer? _progressTimer;
  int _progress = 0;
  bool _hasError = false;
  String _errorMsg = '';
  bool _isCancelled = false;

  static const _phases = [
    'Reading the statement...',
    'Searching the Scriptures...',
    'Examining context...',
    'Comparing with the Word...',
    'Checking for fallacies...',
    'Weighing both sides...',
    'Forming a verdict...',
  ];

  static const _loadingScripts = [
    '"Test all things; hold fast what is good."\n— 1 Thessalonians 5:21',
    '"Be diligent to present yourself approved to God..."\n— 2 Timothy 2:15',
    '"These were more noble... they searched the Scriptures daily."\n— Acts 17:11',
    '"Your word is a lamp to my feet and a light to my path."\n— Psalm 119:105',
    '"All Scripture is breathed out by God..."\n— 2 Timothy 3:16',
    '"The word of God is living and active..."\n— Hebrews 4:12',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _phaseTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && _phaseIndex < _phases.length - 1) {
        setState(() => _phaseIndex++);
      }
    });

    _scripTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(
          () => _scripIndex = (_scripIndex + 1) % _loadingScripts.length,
        );
      }
    });

    _progressTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (mounted && _progress < 96) {
        final increment = _progress < 70 ? 2 : 1;
        setState(() => _progress += increment);
        if (_progress > 96) setState(() => _progress = 96);
      }
    });

    _startEvaluation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _phaseTimer?.cancel();
    _scripTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_hasError) return true;
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Evaluation?'),
        content: const Text(
          'Leaving now will cancel the Berean Check. '
          'The result will not be saved. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (shouldCancel == true) _isCancelled = true;
    return shouldCancel == true;
  }

  Future<void> _startEvaluation() async {
    try {
      final service = BereanAiService();
      final evaluation = await service.evaluate(
        id: const Uuid().v4(),
        inputText: widget.inputText,
        statementTypeHint: widget.statementTypeHint,
      );

      if (_isCancelled || !mounted) return;

      // ── Save session ONLY after successful generation ──
      final repo = BereanRepository();
      await repo.save(evaluation);

      if (!mounted || _isCancelled) return;

      // Pop the loading screen (uncovers form screen)
      Navigator.of(context).pop();

      // Replace the form screen with the result screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BereanResultScreenFull(evaluation: evaluation),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMsg = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: _hasError,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final confirmed = await _onWillPop();
          if (confirmed && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analyzing...'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final confirmed = await _onWillPop();
              if (confirmed && mounted) Navigator.of(context).pop();
            },
          ),
        ),
        body: Center(
          child: _hasError ? _buildError(theme) : _buildLoading(theme),
        ),
      ),
    );
  }

  Widget _buildLoading(ThemeData theme) {
    final warningColor = theme.colorScheme.secondary;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Warning Banner ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: warningColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: warningColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: warningColor,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Please stay on this screen. '
                    'Leaving will cancel the evaluation.',
                    style: TextStyle(
                      fontSize: 13,
                      color: warningColor,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Pulsing icon
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, child) => Transform.scale(
              scale: 0.9 + (_pulseController.value * 0.2),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(
                        0xFF3F51B5,
                      ).withValues(alpha: 0.15 + _pulseController.value * 0.15),
                      const Color(
                        0xFF673AB7,
                      ).withValues(alpha: 0.1 + _pulseController.value * 0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.balance,
                  size: 48,
                  color: Color(0xFF673AB7),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Phase label
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              _phases[_phaseIndex],
              key: ValueKey(_phaseIndex),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF673AB7),
              ),
            ),
          ),

          const SizedBox(height: 12),

          const SizedBox(height: 12),

          Text(
            '$_progress%',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF673AB7),
            ),
          ),
          const SizedBox(height: 8),

          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              value: _progress / 100.0,
              backgroundColor: const Color(0x20673AB7),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF673AB7)),
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          const SizedBox(height: 40),

          // Rotating scriptue
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: Container(
              key: ValueKey(_scripIndex),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _loadingScripts[_scripIndex],
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Show the statement being analyzed
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '"${widget.inputText}"',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 56, color: Color(0xFFe05c5c)),
          const SizedBox(height: 16),
          Text(
            'Analysis Failed',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMsg,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              setState(() {
                _hasError = false;
                _phaseIndex = 0;
              });
              _startEvaluation();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF673AB7),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  RESULTS SCREEN
// ═══════════════════════════════════════════════════════════════════

class BereanResultScreenFull extends StatelessWidget {
  final BereanEvaluationModel evaluation;
  const BereanResultScreenFull({super.key, required this.evaluation});

  Color _verdictColor(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (label) {
      case 'Scripturally Sound':
        return const Color(0xFF4caf82);
      case 'Partially Supported':
      case 'Context Dependent':
      case 'Misleading Without Context':
        return colorScheme.secondary;
      case 'Contradicts Scripture':
        return const Color(0xFFe05c5c);
      case 'Scripture Silent':
      case 'Scripture Silent on This':
        return const Color(0xFF5b9bd5);
      default:
        return Colors.grey;
    }
  }

  double _scoreValue(String score) {
    switch (score) {
      case 'Strong':
        return 0.95;
      case 'Moderate':
        return 0.65;
      case 'Mixed':
        return 0.45;
      case 'Weak':
        return 0.22;
      case 'None':
        return 0.05;
      default:
        return 0.5;
    }
  }

  String _formatForNote(BereanEvaluationModel eval) {
    final buffer = StringBuffer();
    buffer.writeln('**Berean Check: "${eval.statement}"**');
    buffer.writeln();
    buffer.writeln(
      '**Verdict:** ${eval.alignmentVerdict.label} (${eval.alignmentVerdict.score})',
    );
    buffer.writeln(eval.alignmentVerdict.oneLineVerdict);
    buffer.writeln();
    buffer.writeln('**Analysis:**');
    buffer.writeln(eval.statementAnalysis);
    buffer.writeln();
    buffer.writeln('**Key Scriptures:**');
    for (final s in eval.scriptures) {
      buffer.writeln(
        '- **${s.reference}** (${s.supportsOrQualifies}): ${s.explanation}',
      );
    }
    buffer.writeln();
    buffer.writeln('**Conclusion:**');
    buffer.writeln(eval.conclusion);
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verdict = evaluation.alignmentVerdict;
    final color = _verdictColor(context, verdict.label);
    final warningColor = theme.colorScheme.secondary;
    final conclusionColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluation Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add_outlined),
            tooltip: 'Add to Note',
            onPressed: () {
              final linkedContentRef = LinkedContentReference(
                id: 'berean_${evaluation.id}',
                type: LinkedContentType.berean,
                sourceId: evaluation.id,
                sourceReference: 'Berean Check',
                linkedAt: DateTime.now(),
                metadata: {'feature': 'Berean Check', 'verdict': verdict.label},
              );

              showDialog(
                context: context,
                builder: (context) => AddToNoteDialog(
                  formattedContent: _formatForNote(evaluation),
                  linkedContentReference: linkedContentRef,
                  suggestedTitle: 'Berean Check: ${evaluation.statement}',
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export PDF',
            onPressed: () async {
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Generating PDF...')),
                );
                final path = await BereanPdfService.exportEvaluation(
                  evaluation,
                );
                // ignore: deprecated_member_use
                Share.shareXFiles([XFile(path)], subject: 'Berean Evaluation');
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to generate PDF: $e')),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // ignore: deprecated_member_use
              Share.share(
                'Berean Check: "${evaluation.statement}"\n\nVerdict: ${verdict.label}\n\nConclusion: ${evaluation.conclusion}',
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final contextData =
              '''
Statement: "${evaluation.statement}"
Summary: ${evaluation.summary}
Alignment: ${verdict.label} (${verdict.score})
Analysis: ${evaluation.statementAnalysis}
''';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AiChatScreen(
                topic: 'Berean: ${evaluation.statement}',
                preloadedContext: contextData,
                hiddenAutoPrompt:
                    'Here is the evaluation data for the statement "${evaluation.statement}":\n\n$contextData\n\nPlease provide a very concise summary of the conclusion. '
                    'Start exactly with "You are trying to know the scriptural stand on **[Subject]**..." (bold the subject). '
                    'Then, give only the bottom-line submission/conclusion in 1 or 2 short paragraphs. Do not write a long essay. '
                    'End by asking the user to ask further questions for clarification.',
              ),
            ),
          );
        },
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Ask more questions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Escalation Banner ──
            if (evaluation.escalationFlag &&
                evaluation.pastoralWarning != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFe05c5c).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: const Border(
                    left: BorderSide(color: Color(0xFFe05c5c), width: 4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          color: Color(0xFFe05c5c),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'PASTORAL ALERT',
                          style: TextStyle(
                            color: Color(0xFFe05c5c),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AiMarkdownBody(data: evaluation.pastoralWarning!),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Verdict Banner ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    verdict.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _scoreValue(verdict.score),
                      minHeight: 10,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    verdict.oneLineVerdict,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Meta Strip ──
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metaChip(
                  evaluation.statementType,
                  color,
                  color.withValues(alpha: 0.1),
                ),
                _metaChip(
                  evaluation.doctrineClassification.tier,
                  theme.colorScheme.onSecondaryContainer,
                  theme.colorScheme.secondaryContainer,
                ),
                _metaChip(
                  '⚡ ${evaluation.confidenceLevel}',
                  theme.colorScheme.onTertiaryContainer,
                  theme.colorScheme.tertiaryContainer,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Statement Card ──
            _buildSection(
              context,
              'Statement Being Evaluated',
              Icons.format_quote,
              evaluation.statement,
            ),
            _buildSection(
              context,
              'Summary',
              Icons.summarize,
              evaluation.summary,
            ),

            // ── Scripture Pills ──
            _buildSectionHeader(context, 'Key Scriptures', Icons.menu_book),
            ...evaluation.scriptures.map(
              (s) => _buildScriptureCard(context, s, theme),
            ),
            const SizedBox(height: 8),

            // ── Core Analysis ──
            _buildSection(
              context,
              'Scripture Analysis',
              Icons.analytics,
              evaluation.statementAnalysis,
            ),

            // ── Rhetorical Flags ──
            if (evaluation.rhetoricalFlags.isNotEmpty) ...[
              _buildSectionHeader(
                context,
                'Rhetorical Flags',
                Icons.flag_rounded,
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: evaluation.rhetoricalFlags
                    .map(
                      (f) => ActionChip(
                        avatar: Icon(
                          Icons.warning_amber,
                          size: 16,
                          color: warningColor,
                        ),
                        label: Text(
                          f.flagType,
                          style: TextStyle(fontSize: 12, color: warningColor),
                        ),
                        backgroundColor: warningColor.withValues(alpha: 0.1),
                        side: BorderSide(
                          color: warningColor.withValues(alpha: 0.3),
                        ),
                        onPressed: () => _showFlagSheet(context, f),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
            ],

            // ── Context Warnings ──
            if (evaluation.contextWarnings.isNotEmpty) ...[
              _buildSectionHeader(
                context,
                'Context Warnings',
                Icons.shield_outlined,
              ),
              ...evaluation.contextWarnings.map(
                (w) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFe05c5c).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFe05c5c).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ ${w.misusedVerse}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFe05c5c),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'How misused: ${w.howMisused}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Correct reading: ${w.correctReading}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // ── Interpretive Tensions (Accordion) ──
            _accordionSection(
              context,
              'Interpretive Tensions',
              Icons.compare_arrows,
              false,
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evaluation.interpretiveTensions.viewA.tradition,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AiMarkdownBody(
                      data: evaluation.interpretiveTensions.viewA.argument,
                    ),
                    const Divider(height: 24),
                    Text(
                      evaluation.interpretiveTensions.viewB.tradition,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AiMarkdownBody(
                      data: evaluation.interpretiveTensions.viewB.argument,
                    ),
                    if (evaluation
                        .interpretiveTensions
                        .whereDiffer
                        .isNotEmpty) ...[
                      const Divider(height: 24),
                      Text(
                        'Where they differ',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFe05c5c),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AiMarkdownBody(
                        data: evaluation.interpretiveTensions.whereDiffer,
                      ),
                    ],
                    if (evaluation
                        .interpretiveTensions
                        .whereAgree
                        .isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Where they agree',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4caf82),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AiMarkdownBody(
                        data: evaluation.interpretiveTensions.whereAgree,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Historical Perspective (Accordion) ──
            _accordionSection(
              context,
              'Church History View',
              Icons.history_edu,
              false,
              Padding(
                padding: const EdgeInsets.all(16),
                child: AiMarkdownBody(data: evaluation.historicalPerspective),
              ),
            ),
            const SizedBox(height: 8),

            // ── Broader Context (Accordion) ──
            _accordionSection(
              context,
              'Historical & Biblical Context',
              Icons.map,
              false,
              Padding(
                padding: const EdgeInsets.all(16),
                child: AiMarkdownBody(data: evaluation.broaderContext),
              ),
            ),
            const SizedBox(height: 8),

            // ── Example Scenario (Accordion) ──
            _accordionSection(
              context,
              'Real World Application',
              Icons.lightbulb_outline,
              false,
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _exampleBox(
                      '✓ Correct Application',
                      evaluation.exampleScenario.correctUse,
                      const Color(0xFF4caf82),
                    ),
                    const SizedBox(height: 12),
                    _exampleBox(
                      '✗ Incorrect Application',
                      evaluation.exampleScenario.incorrectUse,
                      const Color(0xFFe05c5c),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Conclusion ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: conclusionColor, width: 4),
                ),
                color: conclusionColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 18,
                        color: conclusionColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Conclusion',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: conclusionColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AiMarkdownBody(
                    data: evaluation.conclusion,
                    baseStyle: const TextStyle(height: 1.5, fontSize: 15),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── User Guidance Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4caf82).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4caf82).withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Chip(
                    label: Text(
                      evaluation.userGuidance.action,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: color,
                      ),
                    ),
                    backgroundColor: color.withValues(alpha: 0.15),
                    side: BorderSide.none,
                  ),
                  const SizedBox(height: 12),
                  _guidanceRow(
                    '📖',
                    'Practical Step',
                    evaluation.userGuidance.practicalStep,
                  ),
                  const SizedBox(height: 12),
                  _guidanceRow(
                    '🙏',
                    'Prayer Focus',
                    evaluation.userGuidance.prayerFocus,
                    italic: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Disclaimer
            Text(
              'This tool provides structured Scripture comparison for study purposes and does not replace pastoral counsel.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Helper Widgets ──

  Widget _metaChip(String text, Color fg, Color bg) {
    return Chip(
      label: Text(text, style: TextStyle(fontSize: 11, color: fg)),
      backgroundColor: bg,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _guidanceRow(
    String emoji,
    String title,
    String content, {
    bool italic = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Color(0xFF4caf82),
                ),
              ),
              const SizedBox(height: 2),
              AiMarkdownBody(
                data: content,
                baseStyle: italic
                    ? const TextStyle(fontStyle: FontStyle.italic)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _exampleBox(String label, String content, Color c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: c,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          AiMarkdownBody(data: content),
        ],
      ),
    );
  }

  Widget _accordionSection(
    BuildContext context,
    String title,
    IconData icon,
    bool initiallyExpanded,
    Widget content,
  ) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      leading: Icon(icon),
      initiallyExpanded: initiallyExpanded,
      children: [content],
    );
  }

  Widget _buildScriptureCard(
    BuildContext context,
    BereanScriptureRef s,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showBiblePassageBottomSheet(context, s.reference),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    s.reference,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  _scriptureTag(context, s.supportsOrQualifies),
                ],
              ),
              if (s.text.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  s.text,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              AiMarkdownBody(data: s.explanation),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scriptureTag(BuildContext context, String tag) {
    Color tagColor;
    final warningColor = Theme.of(context).colorScheme.secondary;
    switch (tag) {
      case 'Supports':
        tagColor = const Color(0xFF4caf82);
        break;
      case 'Qualifies':
        tagColor = warningColor;
        break;
      case 'Contradicts':
        tagColor = const Color(0xFFe05c5c);
        break;
      case 'Contextualizes':
        tagColor = const Color(0xFF5b9bd5);
        break;
      default:
        tagColor = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: tagColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: tagColor,
        ),
      ),
    );
  }

  void _showFlagSheet(BuildContext context, RhetoricalFlag flag) {
    final warningColor = Theme.of(context).colorScheme.secondary;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.warning_amber, color: warningColor, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    flag.flagType,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: warningColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AiMarkdownBody(data: flag.explanation),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF4caf82).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4caf82).withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Corrective',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF4caf82),
                    ),
                  ),
                  const SizedBox(height: 6),
                  AiMarkdownBody(data: flag.corrective),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    String content,
  ) {
    if (content.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, title, icon),
          AiMarkdownBody(data: content),
        ],
      ),
    );
  }
}
