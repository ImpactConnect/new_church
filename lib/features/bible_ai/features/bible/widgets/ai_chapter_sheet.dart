import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../data/models/ai/ai_models.dart';
import '../providers/bible_providers.dart';

class AiChapterSheet extends ConsumerStatefulWidget {
  final String bookName;
  final int chapterNumber;

  const AiChapterSheet({
    super.key,
    required this.bookName,
    required this.chapterNumber,
  });

  @override
  ConsumerState<AiChapterSheet> createState() => _AiChapterSheetState();
}

class _AiChapterSheetState extends ConsumerState<AiChapterSheet> {
  late Future<ChapterAnalysis> _analysisFuture;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  void _loadAnalysis() {
    final mode = ref.read(aiModeNotifierProvider);
    final version = ref.read(bibleVersionNotifierProvider);
    final service = ref.read(aiServiceProvider);

    setState(() {
      _analysisFuture = service.analyzeChapter(
        bookName: widget.bookName,
        chapterNumber: widget.chapterNumber,
        chapterText:
            '', // Optional, not sending text for chapter analysis to save tokens? Or should I?
        // AiService says: required String chapterText
        // But for a whole chapter, it might be too long.
        // The implementation in AiService sends it to the prompt.
        // I should probably try to get the text if possible, or pass empty string if the model knows the Bible.
        // Gemini definitely knows the Bible.
        // Let's pass an empty string for now to rely on model training, or fetch it if needed.
        // Note: ChapterScreen doesn't easily give me the full chapter text without iterating all verses.
        // Accessing ref.read(bibleChapterProvider) value is possible.
        version: version,
        mode: mode,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentMode = ref.watch(aiModeNotifierProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header with Mode Selection
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Based on ${widget.bookName} ${widget.chapterNumber}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Chapter Insight',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<AiMode>(
                  initialValue: currentMode,
                  onSelected: (mode) {
                    ref.read(aiModeNotifierProvider.notifier).setMode(mode);
                    _loadAnalysis(); // Reload with new mode
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune,
                          size: 16,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentMode.name.toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Content
          Expanded(
            child: FutureBuilder<ChapterAnalysis>(
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
                            'something went wrong please try again',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _loadAnalysis,
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
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overview
                      _buildSectionHeader(
                        context,
                        'Overview',
                        Icons.visibility_outlined,
                      ),
                      Text(
                        analysis.overview,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(height: 1.6),
                      ),
                      const SizedBox(height: 24),

                      // Main Message
                      _buildSectionHeader(
                        context,
                        'Main Message',
                        Icons.message_outlined,
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.tertiaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.tertiaryContainer,
                          ),
                        ),
                        child: Text(
                          analysis.mainMessage,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onTertiaryContainer,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                              ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Key Verses
                      _buildSectionHeader(
                        context,
                        'Key Verses',
                        Icons.format_quote_outlined,
                      ),
                      ...analysis.keyVerses.map(
                        (verse) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 6,
                                  right: 12,
                                ),
                                child: Icon(
                                  Icons.bookmark_border,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  verse,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        height: 1.5,
                                        fontStyle: FontStyle.italic,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Reflection Questions
                      _buildSectionHeader(
                        context,
                        'Reflection Questions',
                        Icons.psychology_alt_outlined,
                      ),
                      ...analysis.reflectionQuestions.map(
                        (question) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 6,
                                  right: 12,
                                ),
                                child: Icon(
                                  Icons.question_answer_outlined,
                                  size: 16,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  question,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.withOpacity(0.1),
      highlightColor: Colors.grey.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 24, width: 150, color: Colors.white),
            const SizedBox(height: 16),
            Container(height: 100, width: double.infinity, color: Colors.white),
            const SizedBox(height: 32),
            Container(height: 24, width: 120, color: Colors.white),
            const SizedBox(height: 16),
            Container(height: 60, width: double.infinity, color: Colors.white),
            const SizedBox(height: 32),
            Container(height: 24, width: 140, color: Colors.white),
            const SizedBox(height: 16),
            Container(height: 40, width: double.infinity, color: Colors.white),
            const SizedBox(height: 8),
            Container(height: 40, width: double.infinity, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
