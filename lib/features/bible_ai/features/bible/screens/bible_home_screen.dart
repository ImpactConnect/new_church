import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_mobile/widgets/bottom_nav_bar.dart';

import '../../../config/routes.dart';
import 'chapter_screen.dart';
import '../../../../search/screens/search_screen.dart';
import '../../../config/app_colors.dart';
import '../../../data/models/bible/bible_book.dart';
import '../../../data/repositories/user_settings_repository.dart';
import '../../bookmarks/providers/bookmarks_providers.dart';
import '../../bookmarks/providers/ai_content_bookmarks_providers.dart';
import '../../notes/providers/notes_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../providers/bible_providers.dart';
import '../../../data/models/ai/ai_models.dart';
import '../widgets/bible_version_sheet.dart';
import '../widgets/bible_selector_sheet.dart';
import '../../../data/repositories/reading_plan_repository.dart';
import '../../reading_plans/screens/reading_plans_screen.dart';
import '../../../data/models/bookmarks/ai_content_bookmark_model.dart';
import '../screens/verse_ai_results_screen.dart';
import 'dart:convert';
import '../../monetization/widgets/banner_ad_widget.dart';

/// Bible home screen — dashboard with bookmarks, notes, search, browse
class BibleHomeScreen extends ConsumerWidget {
  const BibleHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar / Hero Section ──
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF1A0A3C),
            actions: [const _BibleVersionChip(), const SizedBox(width: 8)],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1A0A3C), Color(0xFF3D1A7A), Color(0xFF6B2FC8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -30, right: -30,
                    child: Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text('📖', style: TextStyle(fontSize: 28)),
                            ),
                            const SizedBox(width: 14),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Bible',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  'Read, Study & Grow',
                                  style: TextStyle(
                                    color: Color(0xFFD4BBFF),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Search Bar ──
                const SizedBox(height: 16),
                _SearchBar(),
                const SizedBox(height: 20),

                // ── Continue Reading ──
                const ContinueReadingCard(),
                const SizedBox(height: 28),

                // ── Browse Books (Inline Selector) ──
                const _SectionHeader(
                  title: 'Browse Books',
                  icon: Icons.menu_book_rounded,
                  onViewMore: null,
                ),
                const SizedBox(height: 8),
                const _InlineBookChapterSelector(),
                const SizedBox(height: 28),

                // ── Bookmarks Section ──
                _SectionHeader(
                  title: 'Bookmarks',
                  icon: Icons.bookmark_rounded,
                  onViewMore: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const _AllBookmarksSheet(),
                    );
                  },
                ),
                const SizedBox(height: 8),
                const _BookmarksSection(),
                const SizedBox(height: 28),

                // ── Notes / Annotations Section ──
                _SectionHeader(
                  title: 'Annotations',
                  icon: Icons.edit_note_rounded,
                  onViewMore: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const _AllNotesSheet(),
                    );
                  },
                ),
                const SizedBox(height: 8),
                const _NotesSection(),
                const SizedBox(height: 24),

                const Center(child: BannerAdWidget()),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 1),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SEARCH BAR
// ═══════════════════════════════════════════════════════════════════

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search the Bible...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  CONTINUE READING
// ═══════════════════════════════════════════════════════════════════

class ContinueReadingCard extends ConsumerWidget {
  const ContinueReadingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(userSettingsRepositoryProvider);
    final booksAsync = ref.watch(bibleBooksProvider);

    return settingsAsync.when(
      data: (repo) {
        final lastRead = repo.getLastRead();
        final defaultBookId = booksAsync.maybeWhen(
          data: (books) => books.isNotEmpty ? books.first.id : 'GEN',
          orElse: () => 'GEN',
        );
        String bookId = defaultBookId;
        int chapter = 1;
        String bookName = booksAsync.maybeWhen(
          data: (books) => books.isNotEmpty ? books.first.name : 'Genesis',
          orElse: () => 'Genesis',
        );

        if (lastRead != null) {
          bookId = lastRead.$1;
          chapter = lastRead.$2;
        }

        if (booksAsync.hasValue) {
          final book = booksAsync.value!
              .where((b) => b.id == bookId)
              .firstOrNull;
          if (book != null) bookName = book.name;
        }

        return Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChapterScreen(bookId: bookId, chapterNumber: chapter),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: AppColors.primaryGradient),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Continue Reading',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$bookName $chapter',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lastRead != null
                              ? 'Resume where you left off'
                              : 'Start reading',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  READING PLAN BANNER
// ═══════════════════════════════════════════════════════════════════

class _ReadingPlanSection extends ConsumerWidget {
  const _ReadingPlanSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePlanAsync = ref.watch(activePlanProvider);

    return activePlanAsync.when(
      data: (activePlan) {
        if (activePlan != null) {
          final now = DateTime.now();
          final daysSinceStart = now
              .difference(
                DateTime(
                  activePlan.startDate.year,
                  activePlan.startDate.month,
                  activePlan.startDate.day,
                ),
              )
              .inDays;
          final safeIndex = daysSinceStart < 0
              ? 0
              : daysSinceStart.clamp(0, activePlan.days.length - 1);
          final todayDay = activePlan.days[safeIndex];

          final int total = activePlan.days.length;
          final int done = activePlan.completedDays;

          return Column(
            children: [
              Card(
                elevation: 0,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ReadingPlansScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade700, Colors.teal.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                activePlan.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Day ${todayDay.dayNumber}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          todayDay.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: todayDay.readings
                              .take(3)
                              .map(
                                (r) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.16),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    r,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        _PlanDayProgressStrip(
                          completedDays: done,
                          totalDays: total,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$done of $total days completed',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Option to create a new plan
              OutlinedButton.icon(
                onPressed: () {
                    context.mounted ? Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ReadingPlansScreen()),
                    ) : null;
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Start Today\'s Reading'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  foregroundColor: Colors.teal.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          );
        }

        // ── No active plan — show create CTA ──
        return Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReadingPlansScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade700, Colors.teal.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'AI-Powered',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Create a Reading Plan',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Personalized by topic, duration and schedule',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white60),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: const [
                            _PlanTopicChip(label: 'Anxiety'),
                            _PlanTopicChip(label: 'Faith'),
                            _PlanTopicChip(label: 'Leadership'),
                            _PlanTopicChip(label: 'Forgiveness'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white54,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _PlanDayProgressStrip extends StatelessWidget {
  final int completedDays;
  final int totalDays;

  const _PlanDayProgressStrip({
    required this.completedDays,
    required this.totalDays,
  });

  @override
  Widget build(BuildContext context) {
    final capped = totalDays.clamp(1, 14);
    return Row(
      children: List.generate(capped, (index) {
        final done = index < completedDays;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == capped - 1 ? 0 : 4),
            height: 6,
            decoration: BoxDecoration(
              color: done ? Colors.white : Colors.white.withOpacity(0.24),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }),
    );
  }
}

class _PlanTopicChip extends StatelessWidget {
  final String label;

  const _PlanTopicChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SECTION HEADER
// ═══════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onViewMore;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.onViewMore,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (onViewMore != null)
          TextButton(
            onPressed: onViewMore,
            child: Text(
              'View All',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  BOOKMARKS SECTION (vertical list, max 4)
// ═══════════════════════════════════════════════════════════════════

class _BookmarksSection extends ConsumerWidget {
  const _BookmarksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarksNotifierProvider);
    final aiBookmarksAsync = ref.watch(aiContentBookmarksNotifierProvider);

    return bookmarksAsync.when(
      data: (bookmarks) {
        return aiBookmarksAsync.when(
          data: (aiBookmarks) {
            // Combine both lists
            final allBookmarks = [...bookmarks, ...aiBookmarks];

            if (allBookmarks.isEmpty) {
              return _EmptyCard(
                icon: Icons.bookmark_border_rounded,
                message: 'No bookmarks yet',
                subMessage:
                    'Tap the bookmark icon on any verse to save it here.',
                actionLabel: 'Browse Bible',
                onAction: () {
                  // Scroll to browse section or just let user browse
                  // For now, we'll just scroll down or do nothing as browse is below
                },
              );
            }

            // Sort by most recent
            final sorted = [...allBookmarks]
              ..sort((a, b) {
                DateTime dateA = DateTime.now();
                DateTime dateB = DateTime.now();

                if (a is AiContentBookmarkModel) {
                  dateA = a.createdAt;
                } else {
                  dateA = (a as dynamic).createdAt;
                }

                if (b is AiContentBookmarkModel) {
                  dateB = b.createdAt;
                } else {
                  dateB = (b as dynamic).createdAt;
                }

                return dateB.compareTo(dateA);
              });

            final display = sorted.take(3).toList();

            return Column(
              children: display.map((bm) {
                // Check if it's an AI content bookmark
                if (bm is AiContentBookmarkModel) {
                  return _ItemTile(
                    leading: Icons.auto_awesome,
                    leadingColor: Colors.blue,
                    title: bm.displayTitle,
                    subtitle: bm.verseText.length > 80
                        ? '${bm.verseText.substring(0, 80)}...'
                        : bm.verseText,
                    onTap: () {
                      // Parse and navigate to AI explanation screen with cached data
                      try {
                        final analysisJson = jsonDecode(bm.analysisJson);
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (context) => VerseAiResultsScreen(
                              bookName: bm.bookName,
                              chapterNumber: bm.chapterNumber,
                              verseNumber: bm.verseNumber,
                              verseText: bm.verseText,
                              initialMode: VerseFeature.values.firstWhere(
                                (e) => e.name == bm.feature,
                                orElse: () => VerseFeature.explain,
                              ),
                              cachedAnalysis: analysisJson,
                            ),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error loading bookmark: $e')),
                        );
                      }
                    },
                  );
                }

                // Regular bookmark
                return _ItemTile(
                  leading: Icons.bookmark_rounded,
                  leadingColor: Colors.amber,
                  title: (bm as dynamic).reference,
                  subtitle: (bm as dynamic).verseText.length > 80
                      ? '${(bm as dynamic).verseText.substring(0, 80)}...'
                      : (bm as dynamic).verseText,
                   onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (_) => ChapterScreen(
                            bookId: (bm as dynamic).bookId,
                            chapterNumber: (bm as dynamic).chapterNumber,
                            initialVerseNumber: (bm as dynamic).verseNumber,
                          ),
                        ),
                      );
                    },
                );
              }).toList(),
            );
          },
          loading: () => const _LoadingShimmer(),
          error: (err, stack) => _EmptyCard(
            icon: Icons.error_outline_rounded,
            message: 'Error loading bookmarks',
            subMessage: err.toString(),
          ),
        );
      },
      loading: () => const _LoadingShimmer(),
      error: (err, stack) => _EmptyCard(
        icon: Icons.error_outline_rounded,
        message: 'Error loading bookmarks',
        subMessage: err.toString(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  NOTES SECTION (vertical list, max 4)
// ═══════════════════════════════════════════════════════════════════

class _NotesSection extends ConsumerWidget {
  const _NotesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesNotifierProvider);

    return notesAsync.when(
      data: (notes) {
        if (notes.isEmpty) {
          return _EmptyCard(
            icon: Icons.edit_note_rounded,
            message: 'No annotations yet',
            subMessage:
                'Add notes to verses as you study to keep track of your thoughts.',
          );
        }

        final sorted = [...notes]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final display = sorted.take(3).toList();

        return Column(
          children: display.map((note) {
            return _ItemTile(
              leading: Icons.sticky_note_2_rounded,
              leadingColor: Colors.blue,
              title: note.reference,
              subtitle: note.content.length > 80
                  ? '${note.content.substring(0, 80)}...'
                  : note.content,
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChapterScreen(
                      bookId: note.bookId,
                      chapterNumber: note.chapterNumber,
                      initialVerseNumber: note.verseNumber,
                    ),
                  ),
                ),
            );
          }).toList(),
        );
      },
      loading: () => const _LoadingShimmer(),
      error: (err, stack) => _EmptyCard(
        icon: Icons.error_outline_rounded,
        message: 'Error loading notes',
        subMessage: err.toString(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  INLINE BOOK / CHAPTER SELECTOR
// ═══════════════════════════════════════════════════════════════════

class _InlineBookChapterSelector extends ConsumerStatefulWidget {
  const _InlineBookChapterSelector();

  @override
  ConsumerState<_InlineBookChapterSelector> createState() =>
      _InlineBookChapterSelectorState();
}

class _InlineBookChapterSelectorState
    extends ConsumerState<_InlineBookChapterSelector> {
  String? _selectedBookId;

  void _openVerseSelector(
    BuildContext context,
    BibleBook book,
    int chapterNumber,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VerseSelectorSheet(
        book: book,
        chapterNumber: chapterNumber,
        onVerseSelected: (verseNumber) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChapterScreen(
                bookId: book.id,
                chapterNumber: chapterNumber,
                initialVerseNumber: verseNumber,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(bibleBooksProvider);

    return booksAsync.when(
      data: (books) {
        if (books.isEmpty) return const Center(child: Text('No Bible data'));

        // Default to first book if nothing selected
        final selectedBook = _selectedBookId != null
            ? books.firstWhere(
                (b) => b.id == _selectedBookId,
                orElse: () => books.first,
              )
            : books.first;

        return Container(
          height: 400,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              // ── LEFT: Books List ──
              SizedBox(
                width: 140,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Theme.of(context).dividerColor.withOpacity(0.3),
                      ),
                    ),
                  ),
                  child: ListView.builder(
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];
                      final isSelected = book.id == selectedBook.id;

                      return InkWell(
                        onTap: () => setState(() => _selectedBookId = book.id),
                        child: Container(
                          color: isSelected
                              ? Theme.of(
                                  context,
                                ).colorScheme.primaryContainer.withOpacity(0.4)
                              : null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Text(
                            book.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ── RIGHT: Chapters Grid ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedBook.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: selectedBook.chapters.length,
                          itemBuilder: (context, index) {
                            final chapter = selectedBook.chapters[index];
                            return InkWell(
                              onTap: () => _openVerseSelector(
                                context,
                                selectedBook,
                                chapter.number,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${chapter.number}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  BIBLE VERSION CHIP
// ═══════════════════════════════════════════════════════════════════

class _BibleVersionChip extends ConsumerWidget {
  const _BibleVersionChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(bibleVersionNotifierProvider);
    return ActionChip(
      avatar: const Icon(Icons.translate, size: 16),
      label: Text(version.abbreviation),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const BibleVersionSheet(),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════

class _ItemTile extends StatelessWidget {
  final IconData leading;
  final Color leadingColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ItemTile({
    required this.leading,
    required this.leadingColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: leadingColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(leading, color: leadingColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subMessage;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyCard({
    required this.icon,
    required this.message,
    this.subMessage,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (subMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              subMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withOpacity(0.8),
                height: 1.4,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          height: 64,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ALL BOOKMARKS SHEET
// ═══════════════════════════════════════════════════════════════════

class _AllBookmarksSheet extends ConsumerWidget {
  const _AllBookmarksSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarksNotifierProvider);
    final aiBookmarksAsync = ref.watch(aiContentBookmarksNotifierProvider);
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'All Bookmarks',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: bookmarksAsync.when(
              data: (bookmarks) {
                return aiBookmarksAsync.when(
                  data: (aiBookmarks) {
                    final allBookmarks = [...bookmarks, ...aiBookmarks];
                    if (allBookmarks.isEmpty) {
                      return const Center(child: Text('No bookmarks saved.'));
                    }
                    final sorted = [...allBookmarks]
                      ..sort((a, b) {
                        DateTime dateA = DateTime.now();
                        DateTime dateB = DateTime.now();

                        if (a is AiContentBookmarkModel) {
                          dateA = a.createdAt;
                        } else {
                          dateA = (a as dynamic).createdAt;
                        }

                        if (b is AiContentBookmarkModel) {
                          dateB = b.createdAt;
                        } else {
                          dateB = (b as dynamic).createdAt;
                        }

                        return dateB.compareTo(dateA);
                      });

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: sorted.length,
                      itemBuilder: (context, index) {
                        final bm = sorted[index];
                        final navigator = Navigator.of(context);
                        if (bm is AiContentBookmarkModel) {
                          return _ItemTile(
                            leading: Icons.auto_awesome,
                            leadingColor: Theme.of(context).primaryColor,
                            title: bm.displayTitle,
                            subtitle: bm.verseText.isNotEmpty
                                ? bm.verseText
                                : bm.feature,
                            onTap: () {
                              navigator.pop(); // Close sheet
                              try {
                                final dataJson = jsonDecode(bm.analysisJson);
                                VerseFeature feature;
                                try {
                                  feature = VerseFeature.values.byName(bm.feature);
                                } catch (_) {
                                  feature = VerseFeature.explain;
                                }
                                navigator.push(
                                  MaterialPageRoute(
                                    builder: (_) => VerseAiResultsScreen(
                                      bookName: bm.bookName,
                                      chapterNumber: bm.chapterNumber,
                                      verseNumber: bm.verseNumber,
                                      verseText: bm.verseText,
                                      initialMode: feature,
                                      cachedAnalysis: dataJson,
                                    ),
                                  ),
                                );
                              } catch (e) {
                                // Ignore
                              }
                            },
                          );
                        }

                        // Regular bookmark
                        final regularBm = bm as dynamic;
                        return _ItemTile(
                          leading: Icons.bookmark_rounded,
                          leadingColor: Colors.amber,
                          title: regularBm.reference,
                          subtitle: regularBm.verseText,
                          onTap: () {
                            navigator.pop(); // Close sheet
                            navigator.push(
                              MaterialPageRoute(
                                builder: (_) => ChapterScreen(
                                  bookId: regularBm.bookId,
                                  chapterNumber: regularBm.chapterNumber,
                                  initialVerseNumber: regularBm.verseNumber,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text(err.toString())),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text(err.toString())),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ALL NOTES SHEET
// ═══════════════════════════════════════════════════════════════════

class _AllNotesSheet extends ConsumerWidget {
  const _AllNotesSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesNotifierProvider);
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'All Annotations',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: notesAsync.when(
              data: (notes) {
                if (notes.isEmpty) {
                  return const Center(child: Text('No annotations saved.'));
                }
                final sorted = [...notes]
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final note = sorted[index];
                    return _ItemTile(
                      leading: Icons.sticky_note_2_rounded,
                      leadingColor: Colors.blue,
                      title: note.reference,
                      subtitle: note.content.length > 80
                          ? '${note.content.substring(0, 80)}...'
                          : note.content,
                      onTap: () {
                        final navigator = Navigator.of(context);
                        navigator.pop(); // Close sheet
                        navigator.push(
                          MaterialPageRoute(
                            builder: (_) => ChapterScreen(
                              bookId: note.bookId,
                              chapterNumber: note.chapterNumber,
                              initialVerseNumber: note.verseNumber,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text(err.toString())),
            ),
          ),
        ],
      ),
    );
  }
}
