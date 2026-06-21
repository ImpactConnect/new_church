import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/exegesis_result_v2_model.dart';
import '../providers/exegesis_providers_v2.dart';
import '../widgets/big_picture_hero_card.dart';
import '../widgets/key_word_moment_card.dart';
import '../widgets/echo_card.dart';
import '../widgets/something_to_sit_with_card.dart';
import '../widgets/deeper_layer_divider.dart';
import '../widgets/word_study_card.dart';
import '../widgets/interpretive_tension_card.dart';
import '../widgets/exegesis_section.dart';
import '../widgets/echo_bottom_sheet.dart';

/// Main results screen for displaying Exegesis v2.0 content
class ExegesisResultScreenV2 extends ConsumerStatefulWidget {
  final String resultId;

  const ExegesisResultScreenV2({
    super.key,
    required this.resultId,
  });

  @override
  ConsumerState<ExegesisResultScreenV2> createState() => _ExegesisResultScreenV2State();
}

class _ExegesisResultScreenV2State extends ConsumerState<ExegesisResultScreenV2> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, bool> _expandedWordStudies = {};

  @override
  void initState() {
    super.initState();
    // Load the result
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exegesisNotifierProvider.notifier).loadById(widget.resultId);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Color _getModeColor(ExegesisMode mode) {
    return mode == ExegesisMode.understand
        ? const Color(0xFFD4A86A) // Amber
        : const Color(0xFF6898D4); // Blue
  }

  String _getModeBadge(ExegesisMode mode) {
    return mode == ExegesisMode.understand ? '🌅' : '🔬';
  }

  String _getModeLabel(ExegesisMode mode) {
    return mode == ExegesisMode.understand ? 'Understand' : 'Go Deep';
  }

  Future<void> _switchMode(ExegesisMode targetMode) async {
    await ref.read(exegesisNotifierProvider.notifier).switchMode(targetMode);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exegesisNotifierProvider);
    final result = state.result;

    if (state.isLoading && result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null && result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(state.error!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Not Found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Exegesis not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final modeColor = _getModeColor(result.mode);
    final isGoDeep = result.mode == ExegesisMode.goDeep;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Sticky header
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            flexibleSpace: FlexibleSpaceBar(
              title: Row(
                children: [
                  Text(
                    _getModeBadge(result.mode),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.subject,
                      style: const TextStyle(
                        fontFamily: 'Spectral',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              titlePadding: const EdgeInsets.only(left: 56, right: 16, bottom: 16),
            ),
            actions: [
              // Mode switcher
              if (!state.isSwitchingMode)
                IconButton(
                  icon: Icon(
                    result.mode == ExegesisMode.understand
                        ? Icons.science_outlined
                        : Icons.wb_sunny_outlined,
                    color: modeColor,
                  ),
                  tooltip: result.mode == ExegesisMode.understand
                      ? 'Switch to Go Deep'
                      : 'Switch to Understand',
                  onPressed: () {
                    final targetMode = result.mode == ExegesisMode.understand
                        ? ExegesisMode.goDeep
                        : ExegesisMode.understand;
                    _switchMode(targetMode);
                  },
                )
              else
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              // Bookmark button (placeholder)
              IconButton(
                icon: const Icon(Icons.bookmark_border),
                onPressed: () {
                  // TODO: Implement bookmark
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bookmark feature coming soon')),
                  );
                },
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  
                  // Entry type chip
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Chip(
                      label: Text(_getEntryTypeLabel(result.entryType)),
                      backgroundColor: modeColor.withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: modeColor,
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Big Picture Hero Card
                  BigPictureHeroCard(
                    bigPicture: result.bigPicture,
                    mode: result.mode,
                    onShare: () {
                      // TODO: Implement share
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share feature coming soon')),
                      );
                    },
                    onAddToNotes: () {
                      // TODO: Implement add to notes
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notes feature coming soon')),
                      );
                    },
                  ),

                  // Historical Moment
                  HistoricalMomentSection(content: result.historicalMoment),

                  // Key Word Moment
                  if (result.keyWord != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: KeyWordMomentCard(
                        keyWord: result.keyWord!,
                        mode: result.mode,
                        onTapWord: () {
                          // TODO: Show word details
                        },
                      ),
                    ),

                  // What Was Being Said
                  WhatWasBeingSaidSection(content: result.whatWasBeingSaid),

                  // In The Whole Story
                  InTheWholeStorySection(content: result.inTheWholeStory),

                  // Echoes Across Scripture
                  if (result.echoes.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Text('🔗', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(
                            'ECHOES ACROSS SCRIPTURE',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: modeColor.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...result.echoes.map((echo) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: EchoCard(
                        echo: echo,
                        onTap: () {
                          EchoBottomSheet.show(
                            context: context,
                            echo: echo,
                            verseText: echo.verseText ?? 'Verse text not available',
                            onOpenInBible: () {
                              // TODO: Open in Bible
                            },
                            onUnderstandThisVerse: () {
                              // TODO: Recursive exegesis
                            },
                          );
                        },
                      ),
                    )),
                  ],

                  // What This Means For You
                  WhatThisMeansForYouSection(content: result.whatThisMeansForYou),

                  // Something To Sit With
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SomethingToSitWithCard(
                      prompt: result.somethingToSitWith,
                      onJournal: () {
                        // TODO: Implement journal action
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Journal feature coming soon')),
                        );
                      },
                    ),
                  ),

                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Create study guide
                            },
                            icon: const Icon(Icons.book_outlined, size: 18),
                            label: const Text('Study Guide'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Share
                            },
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('Share'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: modeColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Go Deep content
                  if (isGoDeep) ...[
                    const SizedBox(height: 24),
                    const DeeperLayerDivider(visible: true),
                    const SizedBox(height: 24),

                    // Word Studies
                    if (result.wordStudies != null && result.wordStudies!.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Text('🔤', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              'WORD STUDIES',
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...result.wordStudies!.map((wordStudy) {
                        final key = wordStudy.word;
                        return WordStudyCard(
                          wordStudy: wordStudy,
                          isExpanded: _expandedWordStudies[key] ?? true,
                          onToggle: () {
                            setState(() {
                              _expandedWordStudies[key] = !(_expandedWordStudies[key] ?? true);
                            });
                          },
                        );
                      }),
                    ],

                    // Grammatical Highlights
                    if (result.grammaticalHighlights != null)
                      GrammaticalHighlightsSection(content: result.grammaticalHighlights!),

                    // Interpretive Tensions
                    if (result.interpretiveTensions != null && result.interpretiveTensions!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Text('⚖️', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              'INTERPRETIVE TENSIONS',
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...result.interpretiveTensions!.map((tension) => InterpretiveTensionCard(tension: tension)),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getEntryTypeLabel(ExegesisEntryType type) {
    switch (type) {
      case ExegesisEntryType.singleVerse:
        return 'VERSE';
      case ExegesisEntryType.passage:
        return 'PASSAGE';
      case ExegesisEntryType.bibleBook:
        return 'BOOK';
      case ExegesisEntryType.bibleCharacter:
        return 'CHARACTER';
      case ExegesisEntryType.theme:
        return 'THEME';
    }
  }
}
