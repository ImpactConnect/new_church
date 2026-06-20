import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes.dart';
import '../../monetization/widgets/banner_ad_widget.dart';
import '../models/bible_study_models.dart';
import '../providers/bible_study_providers.dart';

class BibleStudyHomeScreen extends ConsumerWidget {
  const BibleStudyHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(bibleStudyNotifierProvider.notifier);
    final allStudies = notifier.getAllStudies();

    // Get recent studies (sorted by last accessed or created date)
    final recentStudies = allStudies.take(10).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Bible Study'),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_books_rounded),
            tooltip: 'Study Library',
            onPressed: () => context.push(Routes.bibleStudyLibrary),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero Section Card ────────────────────────────────────
                  _HeroSectionCard(),
                  const SizedBox(height: 16),
                  const BannerAdWidget(),
                  const SizedBox(height: 16),

                  // ── Recent Studies ───────────────────────────────────────
                  if (recentStudies.isNotEmpty) ...[
                    _SectionTitle(
                      title: 'Recent Studies',
                      count: recentStudies.length,
                    ),
                    const SizedBox(height: 12),
                    ...recentStudies.map(
                      (s) => _RecentStudyCard(
                        study: s,
                        onTap: () => _openStudy(context, s),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // ── Empty State ──────────────────────────────────────────
                  if (allStudies.isEmpty) const _EmptyState(),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      // ── FAB Button ─────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.bibleStudyNew),
        backgroundColor: const Color(0xFF4F63D2),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Study',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        elevation: 6,
      ),
    );
  }

  void _openStudy(BuildContext context, BibleStudy study) {
    if (study.format == StudyFormat.single) {
      // Go directly to the session
      context.push('/bible-study/session/${study.id}/1', extra: study);
    } else {
      // Go to series map
      context.push('/bible-study/map/${study.id}', extra: study);
    }
  }
}

// ─── Hero Section Card ────────────────────────────────────────────────────────
class _HeroSectionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
              Icons.auto_stories_rounded,
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
                  'Deep Bible Study',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Scripture-dense studies with original language insights, designed to help you understand God\'s Word deeply.',
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
    );
  }
}

// ─── Section Title ────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final int? count;
  const _SectionTitle({required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF4F63D2).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4F63D2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Recent Study Card ────────────────────────────────────────────────────────
class _RecentStudyCard extends ConsumerWidget {
  final BibleStudy study;
  final VoidCallback onTap;

  const _RecentStudyCard({required this.study, required this.onTap});

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Study'),
        content: Text(
          'Are you sure you want to delete "${study.studyTitle}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(bibleStudyNotifierProvider.notifier).deleteStudy(study.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${study.studyTitle} deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Color(study.studyType.accentValue);
    final tint = Color(study.studyType.tintValue);
    final lastDate = study.lastAccessedAt ?? study.createdAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E0F1C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Type Icon Container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      study.studyType.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        study.studyTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Metadata row
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Date
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(lastDate),
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          // Type badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              study.studyType.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: accent,
                              ),
                            ),
                          ),
                          // Format indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              study.format == StudyFormat.single
                                  ? 'Single'
                                  : 'Series',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          // Offline indicator
                          Icon(
                            Icons.offline_pin_rounded,
                            size: 14,
                            color: Colors.green.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Delete button
                    IconButton(
                      onPressed: () => _confirmDelete(context, ref),
                      icon: const Icon(Icons.delete_outline_rounded),
                      iconSize: 20,
                      color: Colors.red.withOpacity(0.7),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      tooltip: 'Delete study',
                    ),
                    const SizedBox(width: 4),
                    // Status indicator
                    if (study.status == StudyStatus.completed)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                          size: 20,
                        ),
                      )
                    else
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0x1A4F63D2), Color(0x1A8B3FC0)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Text('📚', style: TextStyle(fontSize: 48)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Start Your First Bible Study',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose from 6 study types — Character, Book,\nVerse, Theme, Topical, or Devotional.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}
