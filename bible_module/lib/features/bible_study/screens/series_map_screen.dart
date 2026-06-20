import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../config/routes.dart';
import '../models/bible_study_models.dart';
import '../providers/bible_study_providers.dart';
import '../widgets/study_type_badge.dart';
import '../widgets/session_role_badge.dart';

class SeriesMapScreen extends ConsumerWidget {
  final String studyId;

  const SeriesMapScreen({super.key, required this.studyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final study = ref.watch(singleBibleStudyProvider(studyId));
    if (study == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bible Study')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final accent = Color(study.studyType.accentValue);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if there are sessions actively generating or pending
    final isAnySessionGeneratingOrPending = study.sessions.any(
      (s) => !s.isGenerated && s.lastGenerationError == null,
    );

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 0,
                pinned: true,
                backgroundColor: isDark
                    ? const Color(0xFF09090F)
                    : Colors.white,
                elevation: 0,
                title: const Text(
                  'Bible Study',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(Routes.bibleStudy);
                    }
                  },
                ),
              ),

              // ── Series Overview ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      StudyTypeBadge(type: study.studyType, small: true),
                      const SizedBox(height: 12),
                      Text(
                        study.studyTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Progress summary
                      Row(
                        children: [
                          Expanded(
                            child: _ProgressStat(
                              label: 'Progress',
                              value:
                                  '${study.completedSessions.length}/${study.totalSessions}',
                              accent: accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ProgressStat(
                              label: 'Completed',
                              value: study.isCompleted
                                  ? '✅ Done'
                                  : '${(study.progress * 100).round()}%',
                              accent: accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: study.progress,
                          backgroundColor: accent.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (study.seriesOverview != null) ...[
                        // Overview text
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'SERIES OVERVIEW',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: accent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          study.seriesOverview!,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.65,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'SESSIONS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // ── Session List ─────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 24), // Normal padding
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (study.sessions.isEmpty) {
                        // Show placeholder sessions
                        return _SessionTile(
                          sessionNumber: index + 1,
                          title: 'Session ${index + 1}',
                          subtitle: null,
                          dateLabel: _devotionalSessionDateLabel(
                            study,
                            index + 1,
                          ),
                          scripture: null,
                          isGenerated: false,
                          isCompleted: false,
                          isLocked: false,
                          accent: accent,
                          onTap: null,
                          sessionRole: null,
                        );
                      }
                      if (index >= study.sessions.length) return null;
                      final session = study.sessions[index];
                      final isCompleted = study.completedSessions.contains(
                        session.sessionNumber,
                      );
                      final isLocked = !(session.isAvailableToRead);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _SessionTile(
                          sessionNumber: session.sessionNumber,
                          title: session.sessionTitle,
                          subtitle: session.sessionSubtitle,
                          dateLabel: _devotionalSessionDateLabel(
                            study,
                            session.sessionNumber,
                          ),
                          scripture: session.primaryScripture,
                          isGenerated: session.isGenerated,
                          isCompleted: isCompleted,
                          isLocked: isLocked,
                          accent: accent,
                          sessionRole: session.sessionRole?.name,
                          generationStage: session.generationStage,
                          lastGenerationError: session.lastGenerationError,
                          isGenerating: session.isGenerating,
                          hasPartialContent:
                              session.parsedPartialContent != null,
                          onTap: session.isGenerated && !isLocked
                              ? () => context.push(
                                  '/bible-study/session/${study.id}/${session.sessionNumber}',
                                  extra: study,
                                )
                              : null,
                          onRetry: session.lastGenerationError != null
                              ? () async {
                                  try {
                                    await ref
                                        .read(
                                          bibleStudyNotifierProvider.notifier,
                                        )
                                        .retrySessionGeneration(
                                          study.id,
                                          session.sessionNumber,
                                        );
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Retry failed: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              : null,
                        ),
                      );
                    },
                    childCount: study.sessions.isEmpty
                        ? study.totalSessions
                        : study.sessions.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Background Generation Note ──────────────────────────────────
              if (isAnySessionGeneratingOrPending)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accent.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: accent, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Generation in progress',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Keep the app open to generate all sessions. Generation will pause if you leave, and resume when you return.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.3,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ],
      ),
    );
  }

  String? _devotionalSessionDateLabel(BibleStudy study, int sessionNumber) {
    if (study.studyType != StudyType.devotional) return null;
    final baseDate = study.sessions
            .where((s) => s.sessionNumber == sessionNumber)
            .firstOrNull
            ?.unlocksAt ??
        study.startDate;
    if (baseDate == null) return null;

    final resolvedDate =
        baseDate.isAtSameMomentAs(study.startDate ?? baseDate) &&
            study.startDate != null
        ? study.startDate!.add(Duration(days: sessionNumber - 1))
        : baseDate;
    return DateFormat('EEE, MMM d').format(resolvedDate);
  }
}

class _ProgressStat extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _ProgressStat({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E0F1C) : const Color(0xFFF5F4FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final int sessionNumber;
  final String title;
  final String? subtitle;
  final String? dateLabel;
  final String? scripture;
  final bool isGenerated;
  final bool isCompleted;
  final bool isLocked;
  final Color accent;
  final VoidCallback? onTap;
  final String? sessionRole;
  final String? generationStage;
  final String? lastGenerationError;
  final bool isGenerating;
  final bool hasPartialContent;
  final VoidCallback? onRetry;

  const _SessionTile({
    required this.sessionNumber,
    required this.title,
    this.subtitle,
    this.dateLabel,
    this.scripture,
    required this.isGenerated,
    required this.isCompleted,
    required this.isLocked,
    required this.accent,
    this.onTap,
    this.sessionRole,
    this.generationStage,
    this.lastGenerationError,
    this.isGenerating = false,
    this.hasPartialContent = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canRead = isGenerated && !isLocked;
    final hasFailure =
        lastGenerationError != null && lastGenerationError!.isNotEmpty;
    final statusLabel = _buildStatusLabel();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E0F1C) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withOpacity(0.3)
              : hasFailure
              ? Colors.red.withOpacity(0.3)
              : accent.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: isCompleted
                ? const LinearGradient(
                    colors: [Colors.green, Color(0xFF00A86B)],
                  )
                : hasFailure
                ? const LinearGradient(
                    colors: [Colors.redAccent, Colors.deepOrange],
                  )
                : isLocked || !isGenerated
                ? null
                : const LinearGradient(
                    colors: [Color(0xFF4F63D2), Color(0xFF8B3FC0)],
                  ),
            color: isLocked || !isGenerated ? accent.withOpacity(0.1) : null,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : hasFailure
                ? const Icon(Icons.error_outline, color: Colors.white, size: 18)
                : isLocked
                ? const Icon(Icons.lock_outlined, size: 16, color: Colors.grey)
                : isGenerating || !isGenerated
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.grey),
                    ),
                  )
                : Text(
                    '$sessionNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session role badge
            if (sessionRole != null) ...[
              Builder(
                builder: (context) {
                  final role = _parseSessionRole(sessionRole);
                  if (role == null) return const SizedBox.shrink();
                  return SessionRoleBadge(role: role, small: true);
                },
              ),
              const SizedBox(height: 6),
            ],
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: canRead
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dateLabel != null) ...[
              Text(
                dateLabel!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (statusLabel != null) ...[
              const SizedBox(height: 4),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: hasFailure
                      ? Colors.redAccent
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: hasFailure ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
            if (scripture != null)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  scripture!,
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: accent.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        trailing: canRead
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCompleted ? 'Read Again' : 'Read',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              )
            : hasFailure
            ? TextButton(onPressed: onRetry, child: const Text('Retry'))
            : isGenerating
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Generating',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        accent.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              )
            : !isGenerated
            ? const Text(
                'Pending',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  String? _buildStatusLabel() {
    if (lastGenerationError != null && lastGenerationError!.isNotEmpty) {
      return 'Generation failed. Tap retry to continue.';
    }
    if (generationStage != null && generationStage!.isNotEmpty) {
      return generationStage;
    }
    if (hasPartialContent) {
      return 'Partial content saved';
    }
    return null;
  }

  SessionRole? _parseSessionRole(String? roleStr) {
    if (roleStr == null) return null;
    switch (roleStr.toLowerCase()) {
      case 'foundation':
        return SessionRole.foundation;
      case 'development':
        return SessionRole.development;
      case 'depth':
        return SessionRole.depth;
      case 'turning_point':
      case 'turningpoint':
        return SessionRole.turningPoint;
      case 'integration':
        return SessionRole.integration;
      case 'application':
        return SessionRole.application;
      default:
        return SessionRole.foundation;
    }
  }
}
