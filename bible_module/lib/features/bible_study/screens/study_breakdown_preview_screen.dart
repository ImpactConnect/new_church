import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:go_router/go_router.dart';

import '../../../services/ad_service.dart';
import '../../monetization/providers/monetization_providers.dart';
import '../models/bible_study_models.dart';
import '../models/series_map_item.dart';
import '../widgets/session_role_badge.dart';
import '../providers/bible_study_providers.dart';

/// Screen for previewing and editing the study breakdown before generation
class StudyBreakdownPreviewScreen extends ConsumerStatefulWidget {
  final String studyId;
  final StudyBreakdownState breakdownState;
  final BibleStudyInput input;

  const StudyBreakdownPreviewScreen({
    super.key,
    required this.studyId,
    required this.breakdownState,
    required this.input,
  });

  @override
  ConsumerState<StudyBreakdownPreviewScreen> createState() =>
      _StudyBreakdownPreviewScreenState();
}

class _StudyBreakdownPreviewScreenState
    extends ConsumerState<StudyBreakdownPreviewScreen> {
  late List<SeriesMapItem> _editableSessions;
  late BibleStudyInput _originalInput;
  bool _isRegenerating = false;
  bool _isApproving = false;
  bool _isRewardFlowInProgress = false;

  @override
  void initState() {
    super.initState();
    _editableSessions = List.from(widget.breakdownState.sessions);
    _originalInput = widget.input;
  }

  Future<void> _regenerateBreakdown() async {
    setState(() => _isRegenerating = true);

    try {
      final notifier = ref.read(bibleStudyNotifierProvider.notifier);
      final newBreakdown = await notifier.regenerateBreakdown(
        widget.studyId,
        _originalInput,
      );

      if (mounted) {
        setState(() {
          _editableSessions = List.from(newBreakdown.sessions);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Breakdown regenerated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to regenerate: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRegenerating = false);
    }
  }

  Future<void> _approveAndGenerate() async {
    setState(() => _isApproving = true);

    try {
      // Create updated breakdown with edited sessions
      final updatedBreakdown = widget.breakdownState.copyWith(
        sessions: _editableSessions,
      );

      // Navigate to loading screen which will handle generation
      if (mounted) {
        context.go(
          '/bible-study/generation-loading/${widget.studyId}',
          extra: {'breakdownState': updatedBreakdown, 'input': _originalInput},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start generation: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isApproving = false);
      }
    }
  }

  Future<void> _runWithRewardGate({
    required Future<void> Function() onRewardedAction,
  }) async {
    if (_isRewardFlowInProgress) return;

    final isPremiumUser = ref.read(isPremiumUserProvider);
    final shouldShowAds = AdService.shouldShowAds(isPremiumUser: isPremiumUser);

    if (!shouldShowAds) {
      await onRewardedAction();
      return;
    }

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
        await onRewardedAction();
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
        await onRewardedAction();
        return;
      }

      if (didEarnReward) {
        await onRewardedAction();
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

  void _editSession(int index) {
    final session = _editableSessions[index];

    showDialog(
      context: context,
      builder: (context) => _EditSessionDialog(
        session: session,
        onSave: (updated) {
          setState(() {
            _editableSessions[index] = updated;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studyType = _parseStudyType(widget.breakdownState.studyType);
    final accent = Color(studyType.accentValue);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 224,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF09090F) : Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4F63D2), Color(0xFF8B3FC0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 88, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'PREVIEW & EDIT',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.breakdownState.studyTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${widget.breakdownState.totalSessions} Sessions',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Series Overview ──────────────────────────────────────────────
          if (widget.breakdownState.seriesOverview != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.08),
                        accent.withValues(alpha: 0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accent.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_stories_rounded,
                            size: 16,
                            color: accent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SERIES OVERVIEW',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.breakdownState.seriesOverview!,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.65,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Info Card ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF5BB8F6).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF5BB8F6).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: Color(0xFF5BB8F6),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Review the session breakdown below. Tap any session to edit its title or focus. When ready, approve to begin generation.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Sessions Header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SESSIONS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: accent,
                    ),
                  ),
                  if (!_isRegenerating)
                    TextButton.icon(
                      onPressed: _isRewardFlowInProgress
                          ? null
                          : () {
                              _runWithRewardGate(
                                onRewardedAction: _regenerateBreakdown,
                              );
                            },
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Regenerate'),
                      style: TextButton.styleFrom(
                        foregroundColor: accent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                    )
                  else
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ),

          // ── Session Cards ────────────────────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final session = _editableSessions[index];
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _SessionBreakdownCard(
                  session: session,
                  accent: accent,
                  onEdit: () => _editSession(index),
                ),
              );
            }, childCount: _editableSessions.length),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // ── Bottom Action Bar ────────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0E0F1C) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showStackedActions = constraints.maxWidth < 420;
              final cancelButton = OutlinedButton(
                onPressed: _isApproving ? null : () => context.pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: accent.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              );
              final approveButton = ElevatedButton(
                onPressed: (_isApproving || _isRewardFlowInProgress)
                    ? null
                    : () {
                        _runWithRewardGate(
                          onRewardedAction: _approveAndGenerate,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: _isApproving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, size: 20),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Approve & Generate',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
              );

              if (showStackedActions) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: double.infinity, child: cancelButton),
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: approveButton),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: cancelButton),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: approveButton),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  StudyType _parseStudyType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'character':
        return StudyType.character;
      case 'book':
        return StudyType.book;
      case 'verse':
        return StudyType.verse;
      case 'theme':
        return StudyType.theme;
      case 'topical':
        return StudyType.topical;
      case 'devotional':
        return StudyType.devotional;
      default:
        return StudyType.character;
    }
  }
}

// ─── Session Breakdown Card ──────────────────────────────────────────────────
class _SessionBreakdownCard extends StatelessWidget {
  final SeriesMapItem session;
  final Color accent;
  final VoidCallback onEdit;

  const _SessionBreakdownCard({
    required this.session,
    required this.accent,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E0F1C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Session number
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F63D2), Color(0xFF8B3FC0)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${session.sessionNumber}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Role badge
                    Expanded(
                      child: SessionRoleBadge(
                        role: _parseSessionRole(session.sessionRole),
                        small: true,
                      ),
                    ),
                    // Edit icon
                    Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: accent.withValues(alpha: 0.6),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Title
                Text(
                  session.sessionTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                // Subtitle
                if (session.sessionSubtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    session.sessionSubtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                // Additional info
                if (session.primaryScripture != null ||
                    session.lifePhase != null ||
                    session.chapterRange != null ||
                    session.eraFocus != null) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (session.primaryScripture != null)
                        _InfoChip(
                          label: session.primaryScripture!,
                          icon: Icons.menu_book_rounded,
                          accent: accent,
                        ),
                      if (session.lifePhase != null)
                        _InfoChip(
                          label: session.lifePhase!,
                          icon: Icons.timeline,
                          accent: accent,
                        ),
                      if (session.chapterRange != null)
                        _InfoChip(
                          label: session.chapterRange!,
                          icon: Icons.format_list_numbered,
                          accent: accent,
                        ),
                      if (session.eraFocus != null)
                        _InfoChip(
                          label: session.eraFocus!,
                          icon: Icons.history,
                          accent: accent,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  SessionRole _parseSessionRole(String roleStr) {
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

// ─── Info Chip ───────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;

  const _InfoChip({
    required this.label,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Edit Session Dialog ─────────────────────────────────────────────────────
class _EditSessionDialog extends StatefulWidget {
  final SeriesMapItem session;
  final Function(SeriesMapItem) onSave;

  const _EditSessionDialog({required this.session, required this.onSave});

  @override
  State<_EditSessionDialog> createState() => _EditSessionDialogState();
}

class _EditSessionDialogState extends State<_EditSessionDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _subtitleCtrl;
  late final TextEditingController _focusCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.session.sessionTitle);
    _subtitleCtrl = TextEditingController(
      text: widget.session.sessionSubtitle ?? '',
    );
    _focusCtrl = TextEditingController(text: widget.session.focusArea ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _focusCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Session ${widget.session.sessionNumber}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TITLE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                hintText: 'Session title',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            const Text(
              'SUBTITLE (OPTIONAL)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _subtitleCtrl,
              decoration: const InputDecoration(
                hintText: 'Brief description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            const Text(
              'FOCUS AREA (OPTIONAL)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _focusCtrl,
              decoration: const InputDecoration(
                hintText: 'What this session focuses on',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final updated = widget.session.copyWith(
              sessionTitle: _titleCtrl.text.trim(),
              sessionSubtitle: _subtitleCtrl.text.trim().isEmpty
                  ? null
                  : _subtitleCtrl.text.trim(),
              focusArea: _focusCtrl.text.trim().isEmpty
                  ? null
                  : _focusCtrl.text.trim(),
            );
            widget.onSave(updated);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
