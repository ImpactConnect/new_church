import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shimmer/shimmer.dart';
import '../../../data/models/ai/ai_models.dart';


import '../providers/bible_providers.dart';
import 'ai_chat_screen.dart';

class AiChapterExegesisScreen extends ConsumerStatefulWidget {
  final String bookName;
  final int chapterNumber;

  const AiChapterExegesisScreen({
    super.key,
    required this.bookName,
    required this.chapterNumber,
  });

  @override
  ConsumerState<AiChapterExegesisScreen> createState() =>
      _AiChapterExegesisScreenState();
}

class _AiChapterExegesisScreenState
    extends ConsumerState<AiChapterExegesisScreen> {
  late Future<ChapterExegesis> _analysisFuture;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  void _loadAnalysis() {
    final mode = ref.read(aiModeNotifierProvider);
    final service = ref.read(aiServiceProvider);

    setState(() {
      final depth = mode == AiMode.deep ? 'comprehensive' : 'standard';
      _analysisFuture = service.generateChapterExegesis(
        widget.bookName,
        widget.chapterNumber,
        depth: depth,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentMode = ref.watch(aiModeNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.bookName} ${widget.chapterNumber} Exposition'),
        actions: [
          PopupMenuButton<AiMode>(
            initialValue: currentMode,
            onSelected: (mode) {
              ref.read(aiModeNotifierProvider.notifier).setMode(mode);
              _loadAnalysis();
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
              'I am studying **${widget.bookName} ${widget.chapterNumber}**.\\n\\nPlease provide a very concise introductory summary of this chapter. '
              'Start by highlighting my query in bold. Then, give a 1-paragraph bottom-line submission. '
              'End by asking me to ask further questions for clarification.';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AiChatScreen(
                bookName: widget.bookName,
                chapterNumber: widget.chapterNumber,
                verseNumber: 1, // Defaulting to verse 1 for chapter level chat
                verseText:
                    'The entire chapter of ${widget.bookName} ${widget.chapterNumber}',
                hiddenAutoPrompt: autoPrompt,
              ),
            ),
          );
        },
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Ask Rabbi'),
      ),
      body: FutureBuilder<ChapterExegesis>(
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  context,
                  'Historical Context',
                  analysis.historicalContext,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'Literary Flow',
                  analysis.literaryFlowSummary,
                ),
                _buildListSection(
                  context,
                  'Section Breakdown',
                  analysis.sectionBreakdown,
                ),
                _buildListSection(
                  context,
                  'Major Themes',
                  analysis.majorThemes,
                ),
                _buildListSection(context, 'Key Terms', analysis.keyTerms),
                if (analysis.interpretiveIssues.isNotEmpty)
                  _buildSection(
                    context,
                    'Interpretive Issues',
                    analysis.interpretiveIssues,
                  ),
                _buildSection(
                  context,
                  'Canonical Connection',
                  analysis.canonicalConnection,
                ),
                _buildListSection(
                  context,
                  'Application Principles',
                  analysis.applicationPrinciples,
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content, {
    Color? backgroundColor,
    Color? borderColor,
  }) {
    if (content.isEmpty) return const SizedBox.shrink();

    Widget child = Column(
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
        ),
      ],
    );

    if (backgroundColor != null || borderColor != null) {
      child = Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: borderColor != null ? Border.all(color: borderColor) : null,
        ),
        child: child,
      );
    } else {
      child = Padding(padding: const EdgeInsets.only(bottom: 24), child: child);
    }

    return child;
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
        itemBuilder: (context, index) => Padding(
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
