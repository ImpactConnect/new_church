import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../../data/models/ai/ai_models.dart';
import '../../../data/models/bookmarks/ai_content_bookmark_model.dart';

import '../providers/bible_providers.dart';
import '../../bookmarks/providers/ai_content_bookmarks_providers.dart';
import 'ai_chat_screen.dart';
import 'verse_features/explain_feature_screen.dart';
import 'verse_features/context_feature_screen.dart';
import 'verse_features/keyword_feature_screen.dart';
import 'verse_features/crossrefs_feature_screen.dart';
import 'verse_features/application_feature_screen.dart';

// Import standalone notes feature
import '../../notes/presentation/widgets/add_to_note_dialog.dart';
import '../../notes/data/models/linked_content_reference.dart';

class AiExplanationScreen extends ConsumerStatefulWidget {
  final String bookName;
  final int chapterNumber;
  final int verseNumber;
  final String verseText;
  final VerseFeature feature;
  final dynamic cachedAnalysis; // Pre-loaded analysis data from bookmark

  const AiExplanationScreen({
    super.key,
    required this.bookName,
    required this.chapterNumber,
    required this.verseNumber,
    required this.verseText,
    this.feature = VerseFeature.explain,
    this.cachedAnalysis,
  });

  @override
  ConsumerState<AiExplanationScreen> createState() =>
      _AiExplanationScreenState();
}

class _AiExplanationScreenState extends ConsumerState<AiExplanationScreen> {
  late Future<dynamic> _analysisFuture;
  dynamic _lastLoadedData;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  void _loadAnalysis() {
    setState(() {
      _lastLoadedData = null;
      
      // If cached analysis is provided, deserialize and use it
      if (widget.cachedAnalysis != null) {
        final deserialized = _deserializeAnalysis(widget.cachedAnalysis);
        _lastLoadedData = deserialized;
        _analysisFuture = Future.value(deserialized);
      } else {
        // Otherwise, fetch from API
        final mode = ref.read(aiModeNotifierProvider);
        final version = ref.read(bibleVersionNotifierProvider);
        final service = ref.read(aiServiceProvider);

        _analysisFuture = service
            .explainVerse(
              bookName: widget.bookName,
              chapterNumber: widget.chapterNumber,
              verseNumber: widget.verseNumber,
              verseText: widget.verseText,
              version: version,
              mode: mode,
              feature: widget.feature,
            )
            .then((data) {
              _lastLoadedData = data;
              return data;
            });
      }
    });
  }

  /// Deserialize analysis JSON to the appropriate model type
  dynamic _deserializeAnalysis(dynamic analysisJson) {
    if (analysisJson is Map<String, dynamic>) {
      try {
        switch (widget.feature) {
          case VerseFeature.explain:
            return ExplainAnalysis.fromJson(analysisJson);
          case VerseFeature.context:
            return ContextAnalysis.fromJson(analysisJson);
          case VerseFeature.keyWord:
            return KeyWordAnalysis.fromJson(analysisJson);
          case VerseFeature.crossRefs:
            return CrossReferencesAnalysis.fromJson(analysisJson);
          case VerseFeature.application:
            return ApplicationAnalysis.fromJson(analysisJson);
        }
      } catch (e) {
        // If deserialization fails, return the raw JSON
        return analysisJson;
      }
    }
    return analysisJson;
  }

  String _featureTitle(VerseFeature feature) {
    switch (feature) {
      case VerseFeature.explain:
        return 'Verse Explanation';
      case VerseFeature.context:
        return 'Verse in Context';
      case VerseFeature.keyWord:
        return 'Keywords Insight';
      case VerseFeature.crossRefs:
        return 'Verse Crossrefs';
      case VerseFeature.application:
        return 'Verse Applications';
    }
  }

  String _getFeatureName(VerseFeature feature) {
    switch (feature) {
      case VerseFeature.explain:
        return 'Verse Explained';
      case VerseFeature.context:
        return 'Verse Context';
      case VerseFeature.keyWord:
        return 'Keywords Insight';
      case VerseFeature.crossRefs:
        return 'Verse Crossrefs';
      case VerseFeature.application:
        return 'Verse Applications';
    }
  }

  /// Formats the analysis data into markdown for export to notes
  String _formatAnalysisForExport(dynamic analysis) {
    final buffer = StringBuffer();
    
    // Add verse header
    buffer.writeln('**${widget.bookName} ${widget.chapterNumber}:${widget.verseNumber}**');
    buffer.writeln();
    buffer.writeln('*${widget.verseText}*');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
    
    // Add feature title
    buffer.writeln('## ${_featureTitle(widget.feature)}');
    buffer.writeln();

    if (analysis is ExplainAnalysis) {
      if (analysis.explanation.isNotEmpty) {
        buffer.writeln('**Explanation:**');
        buffer.writeln(analysis.explanation);
        buffer.writeln();
      }
      if (analysis.speaker.isNotEmpty) {
        buffer.writeln('**Speaker:** ${analysis.speaker}');
        buffer.writeln();
      }
      if (analysis.audience.isNotEmpty) {
        buffer.writeln('**Audience:** ${analysis.audience}');
        buffer.writeln();
      }
      if (analysis.historicalContext.isNotEmpty) {
        buffer.writeln('**Historical Context:**');
        buffer.writeln(analysis.historicalContext);
        buffer.writeln();
      }
      if (analysis.literaryContext.isNotEmpty) {
        buffer.writeln('**Literary Context:**');
        buffer.writeln(analysis.literaryContext);
        buffer.writeln();
      }
      if (analysis.ambiguousTerms.isNotEmpty) {
        buffer.writeln('**Key Terms:**');
        for (final term in analysis.ambiguousTerms) {
          buffer.writeln('- **${term.term}** (${term.originalWord}): ${term.definition}');
        }
        buffer.writeln();
      }
    } else if (analysis is ContextAnalysis) {
      if (analysis.chapterTheme.isNotEmpty) {
        buffer.writeln('**Chapter Theme:**');
        buffer.writeln(analysis.chapterTheme);
        buffer.writeln();
      }
      if (analysis.immediateContextBefore.isNotEmpty) {
        buffer.writeln('**Context Before:**');
        buffer.writeln(analysis.immediateContextBefore);
        buffer.writeln();
      }
      if (analysis.immediateContextAfter.isNotEmpty) {
        buffer.writeln('**Context After:**');
        buffer.writeln(analysis.immediateContextAfter);
        buffer.writeln();
      }
      if (analysis.culturalBackgroundInsight.isNotEmpty) {
        buffer.writeln('**Cultural Background:**');
        buffer.writeln(analysis.culturalBackgroundInsight);
        buffer.writeln();
      }
    } else if (analysis is KeyWordAnalysis) {
      for (final word in analysis.keywords) {
        buffer.writeln('### ${word.word}');
        buffer.writeln('**Original:** ${word.original} (${word.transliteration})');
        buffer.writeln();
        buffer.writeln('**Definition:** ${word.definition}');
        buffer.writeln();
        if (word.usageInVerse.isNotEmpty) {
          buffer.writeln('**Usage in Verse:** ${word.usageInVerse}');
          buffer.writeln();
        }
        if (word.theologicalSignificance.isNotEmpty) {
          buffer.writeln('**Theological Significance:** ${word.theologicalSignificance}');
          buffer.writeln();
        }
      }
    } else if (analysis is CrossReferencesAnalysis) {
      if (analysis.theme.isNotEmpty) {
        buffer.writeln('**Theme:** ${analysis.theme}');
        buffer.writeln();
      }
      buffer.writeln('**Cross References:**');
      for (final ref in analysis.references) {
        buffer.writeln('- **${ref.reference}**: ${ref.connection}');
      }
      buffer.writeln();
    } else if (analysis is ApplicationAnalysis) {
      if (analysis.centralTruth.isNotEmpty) {
        buffer.writeln('**Central Truth:**');
        buffer.writeln(analysis.centralTruth);
        buffer.writeln();
      }
      if (analysis.applications.isNotEmpty) {
        buffer.writeln('**Applications:**');
        buffer.writeln(analysis.applications);
        buffer.writeln();
      }
      buffer.writeln('**Application Areas:**');
      if (analysis.applicationsAreas.personal.isNotEmpty) {
        buffer.writeln('- **Personal:** ${analysis.applicationsAreas.personal}');
      }
      if (analysis.applicationsAreas.family.isNotEmpty) {
        buffer.writeln('- **Family:** ${analysis.applicationsAreas.family}');
      }
      if (analysis.applicationsAreas.church.isNotEmpty) {
        buffer.writeln('- **Church:** ${analysis.applicationsAreas.church}');
      }
      if (analysis.applicationsAreas.workplace.isNotEmpty) {
        buffer.writeln('- **Workplace:** ${analysis.applicationsAreas.workplace}');
      }
      if (analysis.applicationsAreas.society.isNotEmpty) {
        buffer.writeln('- **Society:** ${analysis.applicationsAreas.society}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final currentMode = ref.watch(aiModeNotifierProvider);

    return FutureBuilder<dynamic>(
      future: _analysisFuture,
      builder: (context, snapshot) {
        // Determine if data is loaded
        final bool isDataLoaded = snapshot.hasData && _lastLoadedData != null;

        return Scaffold(
          appBar: AppBar(
            title: Text(_featureTitle(widget.feature)),
            actions: [
              IconButton(
                icon: const Icon(Icons.note_add_outlined),
                tooltip: 'Add to Note',
                onPressed: !isDataLoaded ? null : () {
                  // Create linked content reference for the verse
                  final linkedContentRef = LinkedContentReference(
                    id: '${widget.bookName}_${widget.chapterNumber}_${widget.verseNumber}_${DateTime.now().millisecondsSinceEpoch}',
                    type: LinkedContentType.verse,
                    sourceId: '${widget.bookName}_${widget.chapterNumber}_${widget.verseNumber}',
                    sourceReference: '${widget.bookName} ${widget.chapterNumber}:${widget.verseNumber}',
                    linkedAt: DateTime.now(),
                    metadata: {
                      'book': widget.bookName,
                      'chapter': widget.chapterNumber.toString(),
                      'verse': widget.verseNumber.toString(),
                      'feature': widget.feature.toString(),
                    },
                  );

                  // Format the full analysis content
                  final formattedContent = _formatAnalysisForExport(_lastLoadedData!);

                  // Show add to note dialog with the full analysis
                  showDialog(
                    context: context,
                    builder: (context) => AddToNoteDialog(
                      formattedContent: formattedContent,
                      linkedContentReference: linkedContentRef,
                      suggestedTitle: '${widget.bookName} ${widget.chapterNumber}:${widget.verseNumber} - ${_featureTitle(widget.feature)}',
                    ),
                  );
                },
              ),
              Consumer(
                builder: (context, ref, child) {
                  final aiBookmarksAsync = ref.watch(aiContentBookmarksNotifierProvider);
                  
                  // Find if this content is bookmarked
                  bool isBookmarked = false;
                  if (aiBookmarksAsync.hasValue) {
                    final featureName = _getFeatureName(widget.feature);
                    isBookmarked = aiBookmarksAsync.value!.any(
                      (b) =>
                          b.bookName == widget.bookName &&
                          b.chapterNumber == widget.chapterNumber &&
                          b.verseNumber == widget.verseNumber &&
                          b.feature == widget.feature.name,
                    );
                  }

                  return IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    ),
                    tooltip: isBookmarked ? 'Remove Bookmark' : 'Add Bookmark',
                    onPressed: () async {
                      if (_lastLoadedData == null) return;

                      if (isBookmarked) {
                        // Remove bookmark
                        final bookmark = aiBookmarksAsync.value!.firstWhere(
                          (b) =>
                              b.bookName == widget.bookName &&
                              b.chapterNumber == widget.chapterNumber &&
                              b.verseNumber == widget.verseNumber &&
                              b.feature == widget.feature.name,
                        );
                        await ref
                            .read(aiContentBookmarksNotifierProvider.notifier)
                            .deleteBookmark(bookmark.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Bookmark removed')),
                          );
                        }
                      } else {
                        // Add bookmark - save the full analysis data
                        final analysisJson = jsonEncode(_lastLoadedData!.toJson());
                        final bookmark = AiContentBookmarkModel(
                          id: const Uuid().v4(),
                          bookName: widget.bookName,
                          chapterNumber: widget.chapterNumber,
                          verseNumber: widget.verseNumber,
                          verseText: widget.verseText,
                          feature: widget.feature.name,
                          analysisJson: analysisJson,
                          createdAt: DateTime.now(),
                        );
                        await ref
                            .read(aiContentBookmarksNotifierProvider.notifier)
                            .addBookmark(bookmark);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Bookmark added')),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              String? contextData;
              if (_lastLoadedData != null) {
                try {
                  contextData = jsonEncode(_lastLoadedData!.toJson());
                } catch (e) {
                  // Ignore serialization errors
                }
              }

              final hiddenPrompt = contextData != null
                  ? 'I am studying **${widget.bookName} ${widget.chapterNumber}:${widget.verseNumber}**. Here is the AI analysis data for this verse:\n\n$contextData\n\nPlease provide a very concise summary. '
                        'Start by highlighting my query in bold. Then, give only the bottom-line submission or conclusion in 1 short paragraph. '
                        'End by asking me to ask further questions for clarification.'
                  : null;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AiChatScreen(
                    bookName: widget.bookName,
                    chapterNumber: widget.chapterNumber,
                    verseNumber: widget.verseNumber,
                    verseText: widget.verseText,
                    hiddenAutoPrompt: hiddenPrompt,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Ask GSW'),
          ),
          body: _buildBody(snapshot),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<dynamic> snapshot) {
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVerseHeader(context),
          const SizedBox(height: 24),
          _buildFeatureContent(analysis),
          const SizedBox(height: 80), // Padding for FAB
        ],
      ),
    );
  }

  Widget _buildVerseHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.bookName} ${widget.chapterNumber}:${widget.verseNumber}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.verseText,
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Routes to the correct dedicated feature widget based on the analysis type.
  Widget _buildFeatureContent(dynamic analysis) {
    if (analysis is ExplainAnalysis) {
      return ExplainFeatureScreen(analysis: analysis);
    }
    if (analysis is ContextAnalysis) {
      return ContextFeatureScreen(analysis: analysis);
    }
    if (analysis is KeyWordAnalysis) {
      return KeywordFeatureScreen(analysis: analysis);
    }
    if (analysis is CrossReferencesAnalysis) {
      return CrossrefsFeatureScreen(analysis: analysis);
    }
    if (analysis is ApplicationAnalysis) {
      return ApplicationFeatureScreen(analysis: analysis);
    }

    return Center(
      child: Text(
        'Unsupported feature type: ${analysis.runtimeType}',
        style: const TextStyle(color: Colors.red),
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
            Container(height: 20, width: 150, color: Colors.white),
            const SizedBox(height: 12),
            Container(height: 14, width: double.infinity, color: Colors.white),
            const SizedBox(height: 6),
            Container(height: 14, width: double.infinity, color: Colors.white),
            const SizedBox(height: 6),
            Container(height: 14, width: 200, color: Colors.white),
            const SizedBox(height: 32),
            Container(height: 20, width: 120, color: Colors.white),
            const SizedBox(height: 12),
            Container(height: 80, width: double.infinity, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
