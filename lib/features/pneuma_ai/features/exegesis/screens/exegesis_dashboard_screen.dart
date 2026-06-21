import 'package:flutter/material.dart';

import 'package:church_mobile/features/pneuma_ai/features/auth/widgets/feature_gate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:church_mobile/features/pneuma_ai/features/monetization/widgets/banner_ad_widget.dart';
import '../providers/exegesis_providers.dart';
import '../providers/exegesis_providers_v2.dart';
import '../providers/exegesis_providers_final.dart';
import '../models/exegesis_result_model.dart';
import '../models/exegesis_final_model.dart'
    hide ExegesisEntryType, ExegesisSource;
import '../models/exegesis_result_v2_model.dart';
import 'new_exegesis_screen.dart';
import 'exegesis_result_screen.dart';
import 'exegesis_result_screen_v2.dart';
import 'deep_exegesis_result_screen.dart';

class ExegesisDashboardScreen extends ConsumerWidget {
  const ExegesisDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible Exegesis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

            // Hero Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F63D2), Color(0xFF8B3FC0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B4FC8).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Deep Biblical Exegesis',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Generate historically grounded, theologically balanced, and context-aware insights for any passage, chapter, book, or character.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const BannerAdWidget(),
            const SizedBox(height: 16),
            Text(
              'Saved Exegesis History',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Final Edition Results
            ref
                .watch(exegesisLibraryStreamProvider)
                .when(
                  data: (finalResults) {
                    if (finalResults.isEmpty) {
                      // Fallback to v2 history if no final results
                      return ref
                          .watch(exegesisHistoryProvider)
                          .when(
                            data: (v2Results) {
                              if (v2Results.isEmpty) {
                                // Fallback to v1
                                return ref
                                    .watch(recentExegesisSessionsProvider)
                                    .when(
                                      data: (sessions) {
                                        if (sessions.isEmpty) {
                                          return Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                32.0,
                                              ),
                                              child: Column(
                                                children: [
                                                  Icon(
                                                    Icons.history,
                                                    size: 48,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant
                                                        .withValues(alpha: 0.5),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    'No saved exegesis yet.',
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }
                                        return ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: sessions.length,
                                          itemBuilder: (context, index) {
                                            final session = sessions[index];
                                            return ListTile(
                                              leading: const Icon(
                                                Icons.article_outlined,
                                              ),
                                              title: Text(session.title),
                                              subtitle: Text(
                                                '${session.type} • ${session.depth}',
                                              ),
                                              onTap: () {
                                                try {
                                                  if (session.contentJson !=
                                                          null &&
                                                      session
                                                          .contentJson!
                                                          .isNotEmpty) {
                                                    final data = jsonDecode(
                                                      session.contentJson!,
                                                    );
                                                    final result =
                                                        ExegesisResult.fromJson(
                                                          data,
                                                        );
                                                    Navigator.of(context).push(
                                                       MaterialPageRoute(
                                                         builder: (_) => ExegesisResultScreen(result: result),
                                                       ),
                                                     );
                                                  } else {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Legacy format: Cannot view in v2 Viewer yet.',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                } catch (e) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Failed to load saved exegesis.',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                            );
                                          },
                                        );
                                      },
                                      loading: () => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      error: (e, _) => Center(
                                        child: Text(
                                          'Error loading history: $e',
                                        ),
                                      ),
                                    );
                              }

                              // Show v2 results
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: v2Results.length,
                                itemBuilder: (context, index) {
                                  final result = v2Results[index];
                                  final modeLabel =
                                      result.mode == ExegesisMode.understand
                                      ? 'Understand'
                                      : 'Go Deep';

                                  return ListTile(
                                    leading: const Icon(Icons.article_outlined),
                                    title: Text(result.subject),
                                    subtitle: Text(
                                      '${_getEntryTypeLabel(result.entryType)} • $modeLabel',
                                    ),
                                    trailing: Text(
                                      _formatDate(result.createdAt),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    onTap: () {
                                      Navigator.of(context).push(
                                         MaterialPageRoute(
                                           builder: (_) => ExegesisResultScreenV2(resultId: result.id),
                                         ),
                                       );
                                    },
                                  );
                                },
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, _) => Center(
                              child: Text('Error loading history: $e'),
                            ),
                          );
                    }

                    // Show Final Edition Results
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: finalResults.length,
                      itemBuilder: (context, index) {
                        final result = finalResults[index];
                        // ExegesisEntryType.verse is at index 0
                        final isVerse = result.typeIndex == 0;
                        final typeString = isVerse ? 'verse' : 'topic';
                        final modeLabel = isVerse
                            ? 'Verse / Range'
                            : 'Topic / Concept';

                        return ListTile(
                          leading: const Icon(Icons.article_outlined),
                          title: Text(result.subject),
                          subtitle: Text(modeLabel),
                          trailing: Text(
                            _formatDate(result.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          onTap: () {
                            try {
                              final data = jsonDecode(result.resultJson);
                              final parsedResult = isVerse
                                  ? VerseExegesis.fromJson(data)
                                  : TopicExegesis.fromJson(data);
                              Navigator.of(context).push(
                                         MaterialPageRoute(
                                           builder: (_) => DeepExegesisResultScreen(id: result.id, result: parsedResult),
                                         ),
                                       );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to load this study: $e',
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text('Error loading history: $e')),
                ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilledButton.icon(
              onPressed: () {
                FeatureGate.execute(
                  context: context,
                  ref: ref,
                  featureName: 'Biblical Exegesis',
                  onAuthenticated: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewExegesisScreen())),
                );
              },
              icon: const Icon(Icons.flash_on),
              label: const Text('Start Exegesis Now'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
    );
  }

  String _getEntryTypeLabel(ExegesisEntryType type) {
    switch (type) {
      case ExegesisEntryType.singleVerse:
        return 'Verse';
      case ExegesisEntryType.passage:
        return 'Passage';
      case ExegesisEntryType.bibleBook:
        return 'Book';
      case ExegesisEntryType.bibleCharacter:
        return 'Character';
      case ExegesisEntryType.theme:
        return 'Theme';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
