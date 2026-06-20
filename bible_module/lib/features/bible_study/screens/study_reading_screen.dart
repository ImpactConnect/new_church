import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../config/routes.dart';
import '../models/bible_study_models.dart';
import '../providers/bible_study_providers.dart';
import '../repository/bible_study_repository.dart';
import '../services/bible_study_pdf_service.dart';
import '../widgets/previous_session_bridge_card.dart';
import '../../bible/widgets/ai_markdown_body.dart';
import '../../../shared/widgets/bible_passage_bottom_sheet.dart';
import '../../notes/data/models/linked_content_reference.dart';
import '../../notes/presentation/widgets/add_to_note_dialog.dart';

class StudyReadingScreen extends ConsumerStatefulWidget {
  final String studyId;
  final int sessionNumber;

  const StudyReadingScreen({
    super.key,
    required this.studyId,
    required this.sessionNumber,
  });

  @override
  ConsumerState<StudyReadingScreen> createState() => _StudyReadingScreenState();
}

class _StudyReadingScreenState extends ConsumerState<StudyReadingScreen> {
  final _scrollCtrl = ScrollController();
  double _readProgress = 0.0;

  DateTime? _resolveSessionDate(BibleStudy study, StudySession session) {
    if (study.studyType != StudyType.devotional) return null;
    if (session.unlocksAt != null) return session.unlocksAt;
    if (study.startDate == null) return null;
    return study.startDate!.add(Duration(days: session.sessionNumber - 1));
  }

  String? _sessionDateLabel(BibleStudy study, StudySession session) {
    final date = _resolveSessionDate(study, session);
    if (date == null) return null;
    return DateFormat('EEE, MMM d').format(date);
  }

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    // Mark as accessed
    Future.microtask(() {
      ref.read(bibleStudyRepositoryProvider).updateLastAccessed(widget.studyId);
    });
  }

  void _onScroll() {
    final max = _scrollCtrl.position.maxScrollExtent;
    if (max <= 0) return;
    final progress = (_scrollCtrl.offset / max).clamp(0.0, 1.0);
    if ((progress - _readProgress).abs() >= 0.02) {
      setState(() => _readProgress = progress);
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  Widget _buildLoadingView(String message, {Color? accent}) {
    final theme = Theme.of(context);
    final themeAccent = accent ?? theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Bible Study'), elevation: 0),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: themeAccent.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: themeAccent.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(themeAccent),
              ),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildExportText(
    BibleStudy study,
    StudySession session,
    Map<String, dynamic>? content,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('**${study.studyTitle}**');
    buffer.writeln('*${session.sessionTitle}*');
    if (session.primaryScripture != null &&
        session.primaryScripture!.isNotEmpty) {
      buffer.writeln('Primary Scripture: ${session.primaryScripture}');
      buffer.writeln();
    }

    final previousSessionBridge = content?['previousSessionBridge'];
    if (previousSessionBridge is Map<String, dynamic>) {
      final bridgeText = previousSessionBridge['bridgeText'] as String?;
      if (bridgeText != null && bridgeText.trim().isNotEmpty) {
        buffer.writeln('## Connection to Previous Session');
        buffer.writeln(bridgeText.trim());
        buffer.writeln();
      }
    }

    final sections =
        (content?['sections'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        const <Map<String, dynamic>>[];
    for (final section in sections) {
      final title = (section['sectionTitle'] as String?)?.trim();
      final body = (section['content'] as String?)?.trim();
      final scriptures =
          (section['scriptures'] as List<dynamic>?)
              ?.map((s) {
                if (s is Map<String, dynamic>) {
                  return (s['reference'] as String?)?.trim() ?? '';
                }
                return s.toString().trim();
              })
              .where((s) => s.isNotEmpty)
              .toList() ??
          const <String>[];

      if (title != null && title.isNotEmpty) {
        buffer.writeln('## $title');
      }
      if (scriptures.isNotEmpty) {
        buffer.writeln('Scriptures: ${scriptures.join(', ')}');
      }
      if (body != null && body.isNotEmpty) {
        buffer.writeln(body);
      }

      final keyWordInsight = section['keyWordInsight'];
      if (keyWordInsight is Map<String, dynamic>) {
        final word = (keyWordInsight['englishWord'] as String?)?.trim() ?? '';
        final insight = (keyWordInsight['insight'] as String?)?.trim() ?? '';
        if (word.isNotEmpty || insight.isNotEmpty) {
          buffer.writeln();
          buffer.writeln(
            'Word Insight: ${[word, insight].where((v) => v.isNotEmpty).join(' - ')}',
          );
        }
      }

      buffer.writeln();
    }

    final studyQuestions =
        (content?['studyQuestions'] as List<dynamic>?)
            ?.map((q) => q.toString().trim())
            .where((q) => q.isNotEmpty)
            .toList() ??
        const <String>[];
    if (studyQuestions.isNotEmpty) {
      buffer.writeln('## Reflection Questions');
      for (var i = 0; i < studyQuestions.length; i++) {
        buffer.writeln('${i + 1}. ${studyQuestions[i]}');
      }
      buffer.writeln();
    }

    final prayerFocus = (content?['prayerFocus'] as String?)?.trim();
    if (prayerFocus != null && prayerFocus.isNotEmpty) {
      buffer.writeln('## Prayer Focus');
      buffer.writeln(prayerFocus);
      buffer.writeln();
    }

    final sessionClosing = (content?['sessionClosing'] as String?)?.trim();
    if (sessionClosing != null && sessionClosing.isNotEmpty) {
      buffer.writeln('## Closing Thought');
      buffer.writeln(sessionClosing);
    }

    return buffer.toString().trim();
  }

  Future<void> _shareSession(
    BibleStudy study,
    StudySession session,
    Map<String, dynamic>? content,
  ) async {
    await SharePlus.instance.share(
      ShareParams(text: _buildExportText(study, session, content)),
    );
  }

  Future<void> _addSessionToNote(
    BibleStudy study,
    StudySession session,
    Map<String, dynamic>? content,
  ) async {
    final linkedContentRef = LinkedContentReference(
      id: const Uuid().v4(),
      type: LinkedContentType.study,
      sourceId: '${study.id}_${session.sessionNumber}',
      sourceReference: session.sessionTitle,
      linkedAt: DateTime.now(),
      metadata: {
        'studyId': study.id,
        'studyTitle': study.studyTitle,
        'sessionNumber': session.sessionNumber.toString(),
        'primaryScripture': session.primaryScripture ?? '',
      },
    );

    await showDialog(
      context: context,
      builder: (_) => AddToNoteDialog(
        formattedContent: _buildExportText(study, session, content),
        linkedContentReference: linkedContentRef,
        suggestedTitle: session.sessionTitle,
      ),
    );
  }

  Future<void> _exportSessionPdf(
    BibleStudy study,
    StudySession session,
    Map<String, dynamic>? content,
  ) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Generating PDF...')));

    final path = await BibleStudyPdfService.exportSession(
      studyTitle: study.studyTitle,
      sessionTitle: session.sessionTitle,
      content: _buildExportText(study, session, content),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved to Downloads folder:\n$path'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final study = ref.watch(singleBibleStudyProvider(widget.studyId));

    if (study == null) {
      return _buildLoadingView('Loading study insights...');
    }

    final session = study.sessions.firstWhere(
      (s) => s.sessionNumber == widget.sessionNumber,
      orElse: () => StudySession(
        sessionNumber: widget.sessionNumber,
        sessionTitle: study.studyTitle,
      ),
    );

    if (!session.isGenerated) {
      return _buildLoadingView(
        'Generating session content...',
        accent: Color(study.studyType.accentValue),
      );
    }

    final content = session.parsedContent;
    final accent = Color(study.studyType.accentValue);
    final isCompleted = study.completedSessions.contains(widget.sessionNumber);
    final sessionDateLabel = _sessionDateLabel(study, session);

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollCtrl,
            slivers: [
              // ── App Bar ──────────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                expandedHeight: 0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else if (study.format == StudyFormat.series) {
                      context.go('/bible-study/map/${study.id}');
                    } else {
                      context.go(Routes.bibleStudy);
                    }
                  },
                ),
                title: Text(
                  study.studyType == StudyType.devotional
                      ? 'Day ${widget.sessionNumber}${sessionDateLabel != null ? ' • $sessionDateLabel' : ''}'
                      : study.format == StudyFormat.series
                      ? 'Session ${widget.sessionNumber}'
                      : session.sessionTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (value) async {
                      switch (value) {
                        case 'share':
                          await _shareSession(study, session, content);
                          break;
                        case 'note':
                          await _addSessionToNote(study, session, content);
                          break;
                        case 'pdf':
                          await _exportSessionPdf(study, session, content);
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: 'share',
                        child: ListTile(
                          leading: Icon(Icons.share_outlined),
                          title: Text('Share'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'note',
                        child: ListTile(
                          leading: Icon(Icons.note_add_outlined),
                          title: Text('Add to Note'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'pdf',
                        child: ListTile(
                          leading: Icon(Icons.picture_as_pdf_outlined),
                          title: Text('Print PDF'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: LinearProgressIndicator(
                    value: _readProgress,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                    minHeight: 3,
                  ),
                ),
              ),

              // ── Content ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Previous Session Bridge (Sessions 2+)
                      if (widget.sessionNumber > 1 &&
                          session.parsedContent?['previousSessionBridge'] !=
                              null)
                        PreviousSessionBridgeCard(
                          bridgeText:
                              session.parsedContent!['previousSessionBridge']['bridgeText']
                                  as String,
                          sessionsReferenced:
                              (session.parsedContent!['previousSessionBridge']['sessionsReferenced']
                                      as List<dynamic>?)
                                  ?.map((e) => e as int)
                                  .toList() ??
                              [],
                          accent: accent,
                        ),
                      // Main content
                      RepaintBoundary(
                        child: content != null
                            ? _ContentRenderer(
                                content: content,
                                studyType: study.studyType,
                                accent: accent,
                                sessionDateLabel: sessionDateLabel,
                              )
                            : _RawTextFallback(session: session),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Mark Complete / Navigation ────────────────────────────────
              SliverToBoxAdapter(
                child: _SessionFooter(
                  study: study,
                  sessionNumber: widget.sessionNumber,
                  isCompleted: isCompleted,
                  accent: accent,
                  onMarkComplete: () async {
                    final notifier = ref.read(
                      bibleStudyNotifierProvider.notifier,
                    );
                    await notifier.markSessionComplete(
                      widget.studyId,
                      widget.sessionNumber,
                      BibleStudyInput(studyType: study.studyType),
                    );
                    if (mounted) setState(() {});
                  },
                  onNextSession: () {
                    final next = widget.sessionNumber + 1;
                    if (next <= study.totalSessions) {
                      context.go(
                        '/bible-study/session/${study.id}/$next',
                        extra: study,
                      );
                    } else {
                      context.go('/bible-study/map/${study.id}', extra: study);
                    }
                  },
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Content Renderer ─────────────────────────────────────────────────────────
class _ContentRenderer extends StatelessWidget {
  final Map<String, dynamic> content;
  final StudyType studyType;
  final Color accent;
  final String? sessionDateLabel;

  const _ContentRenderer({
    required this.content,
    required this.studyType,
    required this.accent,
    this.sessionDateLabel,
  });

  @override
  Widget build(BuildContext context) {
    switch (studyType) {
      case StudyType.character:
        return _CharacterContentRenderer(content: content, accent: accent);
      case StudyType.book:
        return _BookContentRenderer(content: content, accent: accent);
      case StudyType.verse:
        return _VerseContentRenderer(content: content, accent: accent);
      case StudyType.theme:
        return _ThemeContentRenderer(content: content, accent: accent);
      case StudyType.topical:
        return _TopicalContentRenderer(content: content, accent: accent);
      case StudyType.devotional:
        return _DevotionalContentRenderer(
          content: content,
          accent: accent,
          sessionDateLabel: sessionDateLabel,
        );
    }
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class _SectionHdr extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color accent;

  const _SectionHdr({required this.label, required this.accent, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: accent,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Session Title Card ───────────────────────────────────────────────────────
class _SessionTitleCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color accent;

  const _SessionTitleCard({
    required this.title,
    this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: accent,
              height: 1.3,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: accent.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Card Inner Header ────────────────────────────────────────────────────────
class _CardInnerHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color accent;

  const _CardInnerHeader({
    required this.title,
    required this.accent,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accent),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(color: accent.withOpacity(0.1), height: 1),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── Rich Paragraph ───────────────────────────────────────────────────────────
class _RichPara extends ConsumerWidget {
  final String text;
  final bool italic;
  final Color? accentColor;

  const _RichPara(this.text, {this.italic = false, this.accentColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AiMarkdownBody(
      data: text,
      baseStyle: TextStyle(
        fontSize: 15,
        height: 1.75,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

// ─── Word Insight Inline ──────────────────────────────────────────────────────
Widget _wordInsightFromMap(Map<String, dynamic>? map, Color accent) {
  if (map == null) return const SizedBox.shrink();
  final insight = WordInsight.fromJson(map);
  return _WordInsightInline(insight: insight, accent: accent);
}

class _WordInsightInline extends StatelessWidget {
  final WordInsight insight;
  final Color accent;

  const _WordInsightInline({required this.insight, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E0F1C) : const Color(0xFFF8F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  insight.isHebrew ? '🇮🇱' : '🇬🇷',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  insight.original,
                  style: TextStyle(
                    fontSize: 18,
                    color: accent,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  insight.transliteration,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    insight.strongsNumber,
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '"${insight.englishWord.toUpperCase()}"',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: accent,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              insight.insight,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Study Question Card ──────────────────────────────────────────────────────
class _StudyQuestionsCard extends StatelessWidget {
  final List<dynamic> questions;
  final Color accent;

  const _StudyQuestionsCard({required this.questions, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: accent.withOpacity(0.12), width: 1.5),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.quiz_rounded, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(
                'REFLECTION QUESTIONS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: accent,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...questions.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${e.key + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.value.toString(),
                      style: const TextStyle(fontSize: 14, height: 1.55),
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
}

// ─── Prayer Box ───────────────────────────────────────────────────────────────
class _PrayerBox extends StatelessWidget {
  final String prayer;
  final Color accent;
  const _PrayerBox({required this.prayer, required this.accent});

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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4FC8).withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🙏', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Text(
                'PRAYER',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            prayer,
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: Colors.white.withOpacity(0.9),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Character Content Renderer ───────────────────────────────────────────────
class _CharacterContentRenderer extends StatelessWidget {
  final Map<String, dynamic> content;
  final Color accent;
  const _CharacterContentRenderer({
    required this.content,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    // Check if this is the new dynamic sections format
    final sections = content['sections'] as List<dynamic>?;

    if (sections != null && sections.isNotEmpty) {
      // New dynamic sections format
      return _DynamicSectionsRenderer(
        content: content,
        sections: sections,
        accent: accent,
      );
    }

    // Legacy format - keep for backward compatibility
    return _LegacyCharacterRenderer(content: content, accent: accent);
  }
}

// ─── Dynamic Sections Renderer (New Format) ───────────────────────────────────
class _DynamicSectionsRenderer extends StatelessWidget {
  final Map<String, dynamic> content;
  final List<dynamic> sections;
  final Color accent;

  const _DynamicSectionsRenderer({
    required this.content,
    required this.sections,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final questions = content['studyQuestions'] as List<dynamic>? ?? [];
    final anchorPassage = content['anchorPassage'] as Map<String, dynamic>?;
    final bibleStory = content['bibleStory'] as Map<String, dynamic>?;
    final keywordAnalysis = content['keywordAnalysis'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Session title
        _SessionTitleCard(
          title: content['sessionTitle'] ?? '',
          subtitle:
              content['characterName'] ??
              content['themeName'] ??
              content['question'] ??
              '',
          accent: accent,
        ),

        // Anchor Passage (v2.1)
        if (anchorPassage != null) ...[
          const SizedBox(height: 16),
          _AnchorPassageCard(anchorPassage: anchorPassage, accent: accent),
        ],

        // Bible Story (v2.1 - Devotionals)
        if (bibleStory != null) ...[
          const SizedBox(height: 16),
          _BibleStoryCard(bibleStory: bibleStory, accent: accent),
        ],

        // Keyword Analysis (v2.1 - Session 1)
        if (keywordAnalysis != null) ...[
          const SizedBox(height: 16),
          _KeywordAnalysisCard(
            keywordAnalysis: keywordAnalysis,
            accent: accent,
          ),
        ],

        // Render each dynamic section
        ...sections.map((sectionData) {
          final section = sectionData as Map<String, dynamic>;
          return _DynamicSectionCard(section: section, accent: accent);
        }),

        const SizedBox(height: 20),
        if (questions.isNotEmpty)
          _StudyQuestionsCard(questions: questions, accent: accent),
        const SizedBox(height: 16),
        if (content['prayerFocus'] != null)
          _PrayerBox(prayer: content['prayerFocus'], accent: accent),
        const SizedBox(height: 12),
        if (content['sessionClosing'] != null)
          Text(
            content['sessionClosing'],
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
      ],
    );
  }
}

// ─── Anchor Passage Card (v2.1) ───────────────────────────────────────────────
class _AnchorPassageCard extends StatelessWidget {
  final Map<String, dynamic> anchorPassage;
  final Color accent;

  const _AnchorPassageCard({required this.anchorPassage, required this.accent});

  @override
  Widget build(BuildContext context) {
    final reference = anchorPassage['reference'] as String? ?? '';
    final verseText = anchorPassage['verseText'] as String? ?? '';
    final whyThisPassage = anchorPassage['whyThisPassage'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: accent.withOpacity(0.12), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.anchor_rounded, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(
                'ANCHOR PASSAGE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: accent,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => BiblePassageBottomSheet.show(context, reference),
            child: Text(
              reference,
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: accent,
                fontSize: 13,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '"$verseText"',
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 16,
              height: 1.7,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (whyThisPassage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                whyThisPassage,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.9),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Bible Story Card (v2.1 - Devotionals) ────────────────────────────────────
class _BibleStoryCard extends StatelessWidget {
  final Map<String, dynamic> bibleStory;
  final Color accent;

  const _BibleStoryCard({required this.bibleStory, required this.accent});

  @override
  Widget build(BuildContext context) {
    final title = bibleStory['title'] as String? ?? '';
    final reference = bibleStory['reference'] as String? ?? '';
    final summary = bibleStory['summary'] as String? ?? '';
    final connection = bibleStory['connection'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: accent.withOpacity(0.12), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories_rounded, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(
                'BIBLE STORY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: accent,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => BiblePassageBottomSheet.show(context, reference),
            child: Text(
              reference,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: accent.withOpacity(0.7),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            summary,
            style: const TextStyle(
              fontSize: 15,
              height: 1.75,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (connection.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONNECTION',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: accent,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    connection,
                    style: const TextStyle(fontSize: 13, height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Keyword Analysis Card (v2.1 - Session 1) ─────────────────────────────────
class _KeywordAnalysisCard extends StatelessWidget {
  final Map<String, dynamic> keywordAnalysis;
  final Color accent;

  const _KeywordAnalysisCard({
    required this.keywordAnalysis,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final keywords = keywordAnalysis['keywords'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: accent.withOpacity(0.12), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.translate_rounded, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(
                'KEYWORD ANALYSIS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: accent,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...keywords.map((keywordData) {
            final keyword = keywordData as Map<String, dynamic>;
            return _KeywordItem(keyword: keyword, accent: accent);
          }),
        ],
      ),
    );
  }
}

// ─── Keyword Item ─────────────────────────────────────────────────────────────
class _KeywordItem extends StatelessWidget {
  final Map<String, dynamic> keyword;
  final Color accent;

  const _KeywordItem({required this.keyword, required this.accent});

  @override
  Widget build(BuildContext context) {
    final word = keyword['word'] as String? ?? '';
    final hebrewWord = keyword['hebrewWord'] as Map<String, dynamic>?;
    final greekWord = keyword['greekWord'] as Map<String, dynamic>?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${word.toUpperCase()}"',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: accent,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          if (hebrewWord != null)
            _LanguageWordCard(
              wordData: hebrewWord,
              isHebrew: true,
              accent: accent,
            ),
          if (hebrewWord != null && greekWord != null)
            const SizedBox(height: 12),
          if (greekWord != null)
            _LanguageWordCard(
              wordData: greekWord,
              isHebrew: false,
              accent: accent,
            ),
        ],
      ),
    );
  }
}

// ─── Language Word Card ───────────────────────────────────────────────────────
class _LanguageWordCard extends StatelessWidget {
  final Map<String, dynamic> wordData;
  final bool isHebrew;
  final Color accent;

  const _LanguageWordCard({
    required this.wordData,
    required this.isHebrew,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final script = wordData['script'] as String? ?? '';
    final transliteration = wordData['transliteration'] as String? ?? '';
    final strongsNumber = wordData['strongsNumber'] as String? ?? '';
    final definition = wordData['definition'] as String? ?? '';
    final insight = wordData['insight'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isHebrew ? '🇮🇱' : '🇬🇷',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 8),
              Text(
                script,
                style: TextStyle(
                  fontSize: 20,
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                transliteration,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  strongsNumber,
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (definition.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              definition,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
          if (insight.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              insight,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Dynamic Section Card ─────────────────────────────────────────────────────
class _DynamicSectionCard extends ConsumerWidget {
  final Map<String, dynamic> section;
  final Color accent;

  const _DynamicSectionCard({required this.section, required this.accent});

  IconData? _getIconForSectionType(String? type) {
    switch (type?.toLowerCase()) {
      case 'introduction':
        return Icons.person_outline;
      case 'narrative':
        return Icons.auto_stories_rounded;
      case 'teaching':
        return Icons.school_rounded;
      case 'word_study':
        return Icons.translate_rounded;
      case 'application':
        return Icons.favorite_rounded;
      case 'bridge':
        return Icons.link_rounded;
      case 'reflection':
        return Icons.psychology_rounded;
      case 'legacy':
        return Icons.history_edu;
      default:
        return Icons.article_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionTitle = section['sectionTitle'] as String? ?? '';
    final sectionType = section['sectionType'] as String?;
    final content = section['content'] as String? ?? '';
    final scriptures = section['scriptures'] as List<dynamic>? ?? [];
    final keyWordInsight = section['keyWordInsight'] as Map<String, dynamic>?;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: accent.withOpacity(0.12), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with icon
          _CardInnerHeader(
            title: sectionTitle,
            icon: _getIconForSectionType(sectionType),
            accent: accent,
          ),
          const SizedBox(height: 12),

          // Main content with clickable scripture references
          AiMarkdownBody(
            data: content,
            baseStyle: TextStyle(
              fontSize: 15,
              height: 1.75,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

          // Scripture references
          if (scriptures.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...scriptures.map((scriptureData) {
              final scripture = scriptureData as Map<String, dynamic>;
              return _ScriptureReferenceCard(
                scripture: scripture,
                accent: accent,
              );
            }),
          ],

          // Word insight
          if (keyWordInsight != null) ...[
            const SizedBox(height: 12),
            _DynamicWordInsightCard(insight: keyWordInsight, accent: accent),
          ],
        ],
      ),
    );
  }
}

// ─── Scripture Reference Card ─────────────────────────────────────────────────
class _ScriptureReferenceCard extends StatelessWidget {
  final Map<String, dynamic> scripture;
  final Color accent;

  const _ScriptureReferenceCard({
    required this.scripture,
    required this.accent,
  });

  void _showScripturePreview(BuildContext context) {
    final reference = scripture['reference'] as String? ?? '';
    if (reference.isEmpty) return;

    BiblePassageBottomSheet.show(context, reference);
  }

  @override
  Widget build(BuildContext context) {
    final reference = scripture['reference'] as String? ?? '';
    final relevance = scripture['relevance'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clickable reference
          InkWell(
            onTap: () => _showScripturePreview(context),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_rounded, size: 14, color: accent),
                  const SizedBox(width: 6),
                  Text(
                    reference,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.touch_app_rounded,
                    size: 12,
                    color: accent.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ),

          // Full relevance text (not clickable)
          if (relevance.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              relevance,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Dynamic Word Insight Card ────────────────────────────────────────────────
class _DynamicWordInsightCard extends StatelessWidget {
  final Map<String, dynamic> insight;
  final Color accent;

  const _DynamicWordInsightCard({required this.insight, required this.accent});

  @override
  Widget build(BuildContext context) {
    final englishWord = insight['englishWord'] as String? ?? '';
    final original = insight['original'] as String? ?? '...';
    final transliteration = insight['transliteration'] as String? ?? '...';
    final strongsNumber = insight['strongsNumber'] as String? ?? '';
    final insightText = insight['insight'] as String? ?? '';
    final isHebrew = strongsNumber.startsWith('H');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isHebrew ? '🇮🇱' : '🇬🇷',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  original,
                  style: TextStyle(
                    fontSize: 18,
                    color: accent,
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  transliteration,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  strongsNumber,
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '"${englishWord.toUpperCase()}"',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: accent,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            insightText,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Legacy Character Renderer (Backward Compatibility) ───────────────────────
class _LegacyCharacterRenderer extends StatelessWidget {
  final Map<String, dynamic> content;
  final Color accent;
  const _LegacyCharacterRenderer({required this.content, required this.accent});

  @override
  Widget build(BuildContext context) {
    final who = content['whoTheyWere'] as Map<String, dynamic>?;
    final keyEvents = content['keyEvents'] as List<dynamic>? ?? [];
    final questions = content['studyQuestions'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Opening Hook
        if (content['openingHook'] != null) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF09090F), Color(0xFF131428)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              content['openingHook'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.75,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Session title
        _SessionTitleCard(
          title: content['sessionTitle'] ?? '',
          subtitle: content['characterName'] ?? '',
          accent: accent,
        ),

        // Who They Were
        if (who != null) ...[
          _SectionHdr(
            label: 'Who They Were',
            accent: accent,
            icon: Icons.person_outline,
          ),
          if (who['world'] != null)
            _RichPara(who['world'], accentColor: accent),
          if (who['nameAndOrigin'] != null) ...[
            const SizedBox(height: 12),
            _RichPara(who['nameAndOrigin'], accentColor: accent),
          ],
          if (who['background'] != null) ...[
            const SizedBox(height: 12),
            _RichPara(who['background'], accentColor: accent),
          ],
        ],

        // Key Events
        if (keyEvents.isNotEmpty) ...[
          _SectionHdr(
            label: 'Key Events',
            accent: accent,
            icon: Icons.timeline,
          ),
          ...keyEvents.asMap().entries.map((e) {
            final ev = e.value as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: NarrativeEventContainer(
                event: ev,
                index: e.key + 1,
                accent: accent,
              ),
            );
          }),
        ],

        // Faith & Failure
        if (content['faithAndFailure'] != null) ...[
          _SectionHdr(
            label: 'Faith & Failure',
            accent: accent,
            icon: Icons.flash_on_rounded,
          ),
          _RichPara(
            content['faithAndFailure'],
            italic: true,
            accentColor: accent,
          ),
        ],

        // Points to Christ
        if (content['howTheyPointToChrist'] != null) ...[
          _SectionHdr(
            label: 'How They Point to Christ',
            accent: accent,
            icon: Icons.brightness_5_rounded,
          ),
          _RichPara(content['howTheyPointToChrist'], accentColor: accent),
        ],

        // Their Legacy
        if (content['theirLegacyInScripture'] != null) ...[
          _SectionHdr(
            label: 'Their Legacy in Scripture',
            accent: accent,
            icon: Icons.history_edu,
          ),
          _RichPara(content['theirLegacyInScripture'], accentColor: accent),
        ],

        // What This Life Says to You
        if (content['whatThisLifeSaysToYou'] != null) ...[
          _SectionHdr(
            label: 'What This Life Says to You',
            accent: accent,
            icon: Icons.favorite_rounded,
          ),
          _RichPara(content['whatThisLifeSaysToYou'], accentColor: accent),
        ],

        const SizedBox(height: 20),
        if (questions.isNotEmpty)
          _StudyQuestionsCard(questions: questions, accent: accent),
        const SizedBox(height: 16),
        if (content['prayerFocus'] != null)
          _PrayerBox(prayer: content['prayerFocus'], accent: accent),
        const SizedBox(height: 12),
        if (content['sessionClosing'] != null)
          Text(
            content['sessionClosing'],
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
      ],
    );
  }
}

// ─── Shared Event Card (used by character renderer) ───────────────────────────
class NarrativeEventContainer extends StatelessWidget {
  final Map<String, dynamic> event;
  final int index;
  final Color accent;

  const NarrativeEventContainer({
    super.key,
    required this.event,
    required this.index,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E0F1C) : const Color(0xFFFAF9FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reference badge
          InkWell(
            onTap: () => BiblePassageBottomSheet.show(
              context,
              event['primaryReference'] ?? '',
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                event['primaryReference'] ?? '',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            event['eventTitle'] ?? '',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            event['narrative'] ?? '',
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 14,
              height: 1.65,
            ),
          ),
          if (event['whatGodReveals'] != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WHAT GOD REVEALS',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: accent,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event['whatGodReveals'] ?? '',
                    style: const TextStyle(fontSize: 13, height: 1.6),
                  ),
                ],
              ),
            ),
          ],
          if (event['keyWordInsight'] != null)
            _wordInsightFromMap(
              event['keyWordInsight'] as Map<String, dynamic>?,
              accent,
            ),
        ],
      ),
    );
  }
}

// ─── Book Content Renderer ────────────────────────────────────────────────────
class _BookContentRenderer extends StatelessWidget {
  final Map<String, dynamic> content;
  final Color accent;
  const _BookContentRenderer({required this.content, required this.accent});

  @override
  Widget build(BuildContext context) {
    // Check if this is the new dynamic sections format
    final sections = content['sections'] as List<dynamic>?;

    if (sections != null && sections.isNotEmpty) {
      // New dynamic sections format
      return _DynamicSectionsRenderer(
        content: content,
        sections: sections,
        accent: accent,
      );
    }

    // Legacy format - keep for backward compatibility
    return _LegacyBookRenderer(content: content, accent: accent);
  }
}

// ─── Legacy Book Renderer (Backward Compatibility) ────────────────────────────
class _LegacyBookRenderer extends StatelessWidget {
  final Map<String, dynamic> content;
  final Color accent;
  const _LegacyBookRenderer({required this.content, required this.accent});

  @override
  Widget build(BuildContext context) {
    final keyPassages = content['keyPassages'] as List<dynamic>? ?? [];
    final questions = content['studyQuestions'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SessionTitleCard(
          title: content['sessionTitle'] ?? '',
          subtitle: content['bookName'] ?? '',
          accent: accent,
        ),

        if (content['sessionOverview'] != null) ...[
          _SectionHdr(
            label: 'Session Overview',
            accent: accent,
            icon: Icons.info_outline,
          ),
          _RichPara(content['sessionOverview'], accentColor: accent),
        ],
        if (content['whyThisBookExists'] != null) ...[
          _SectionHdr(
            label: 'Why This Book Exists',
            accent: accent,
            icon: Icons.auto_stories_rounded,
          ),
          _RichPara(
            content['whyThisBookExists'],
            italic: true,
            accentColor: accent,
          ),
        ],
        if (content['bigTheme'] != null) ...[
          _SectionHdr(
            label: 'The Big Theme',
            accent: accent,
            icon: Icons.hub_outlined,
          ),
          _RichPara(content['bigTheme'], accentColor: accent),
        ],
        if (keyPassages.isNotEmpty) ...[
          _SectionHdr(
            label: 'Key Passages',
            accent: accent,
            icon: Icons.menu_book_rounded,
          ),
          ...keyPassages.map((p) {
            final pm = p as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      pm['reference'] ?? '',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ),
                  if (pm['verseText'] != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accent.withOpacity(0.15)),
                      ),
                      child: Text(
                        '"${pm['verseText']}"',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                  if (pm['exposition'] != null) ...[
                    const SizedBox(height: 8),
                    _RichPara(pm['exposition'], accentColor: accent),
                  ],
                  if (pm['keyWordInsight'] != null)
                    _wordInsightFromMap(
                      pm['keyWordInsight'] as Map<String, dynamic>?,
                      accent,
                    ),
                ],
              ),
            );
          }),
        ],
        if (content['forYourLife'] != null) ...[
          _SectionHdr(
            label: 'For Your Life',
            accent: accent,
            icon: Icons.favorite_rounded,
          ),
          _RichPara(content['forYourLife']),
        ],
        const SizedBox(height: 20),
        if (questions.isNotEmpty)
          _StudyQuestionsCard(questions: questions, accent: accent),
        const SizedBox(height: 16),
        if (content['prayerFocus'] != null)
          _PrayerBox(prayer: content['prayerFocus'], accent: accent),
      ],
    );
  }
}

// ─── Verse Content Renderer ───────────────────────────────────────────────────
class _VerseContentRenderer extends StatelessWidget {
  final Map<String, dynamic> content;
  final Color accent;
  const _VerseContentRenderer({required this.content, required this.accent});

  @override
  Widget build(BuildContext context) {
    // Check if this is the new dynamic sections format
    final sections = content['sections'] as List<dynamic>?;

    if (sections != null && sections.isNotEmpty) {
      // New dynamic sections format
      return _DynamicSectionsRenderer(
        content: content,
        sections: sections,
        accent: accent,
      );
    }

    final wordByWord = content['wordByWord'] as List<dynamic>? ?? [];
    final echoes = content['echoesAcrossScripture'] as List<dynamic>? ?? [];
    final questions = content['studyQuestions'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            content['verseRef'] ?? '',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
        ),

        if (content['theHeartOfThisVerse'] != null) ...[
          _SectionHdr(
            label: 'The Heart of This Verse',
            accent: accent,
            icon: Icons.favorite_rounded,
          ),
          _RichPara(content['theHeartOfThisVerse'], accentColor: accent),
        ],
        if (content['theWorld'] != null) ...[
          _SectionHdr(
            label: 'The World of This Verse',
            accent: accent,
            icon: Icons.language_rounded,
          ),
          _RichPara(content['theWorld'], accentColor: accent),
        ],
        if (wordByWord.isNotEmpty) ...[
          _SectionHdr(
            label: 'Word by Word',
            accent: accent,
            icon: Icons.translate_rounded,
          ),
          ...wordByWord.map((w) {
            if (w is Map<String, dynamic>) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _wordInsightFromMap(w, accent),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
        if (content['whatItMeans'] != null) ...[
          _SectionHdr(
            label: 'What It Means',
            accent: accent,
            icon: Icons.lightbulb_rounded,
          ),
          _RichPara(content['whatItMeans'], accentColor: accent),
        ],
        if (content['inItsPassage'] != null) ...[
          _SectionHdr(
            label: 'In Its Passage',
            accent: accent,
            icon: Icons.format_align_center_rounded,
          ),
          _RichPara(content['inItsPassage'], accentColor: accent),
        ],
        if (echoes.isNotEmpty) ...[
          _SectionHdr(
            label: 'Echoes Across Scripture',
            accent: accent,
            icon: Icons.all_inclusive_rounded,
          ),
          ...echoes.map((e) {
            final em = e as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      em['reference'] ?? '',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: accent,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (em['verseText'] != null)
                      Text(
                        '"${em['verseText']}"',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    if (em['connection'] != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        em['connection'] ?? '',
                        style: const TextStyle(fontSize: 13, height: 1.6),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
        if (content['forYourLife'] != null) ...[
          _SectionHdr(
            label: 'For Your Life',
            accent: accent,
            icon: Icons.directions_walk_rounded,
          ),
          _RichPara(content['forYourLife'], accentColor: accent),
        ],
        const SizedBox(height: 20),
        if (questions.isNotEmpty)
          _StudyQuestionsCard(questions: questions, accent: accent),
        const SizedBox(height: 16),
        if (content['prayerFocus'] != null)
          _PrayerBox(prayer: content['prayerFocus'], accent: accent),
      ],
    );
  }
}

// ─── Theme Content Renderer ───────────────────────────────────────────────────
class _ThemeContentRenderer extends StatelessWidget {
  final Map<String, dynamic> content;
  final Color accent;
  const _ThemeContentRenderer({required this.content, required this.accent});

  @override
  Widget build(BuildContext context) {
    // Check if this is the new dynamic sections format
    final sections = content['sections'] as List<dynamic>?;

    if (sections != null && sections.isNotEmpty) {
      // New dynamic sections format
      return _DynamicSectionsRenderer(
        content: content,
        sections: sections,
        accent: accent,
      );
    }

    // Legacy format - keep for backward compatibility
    return _LegacyThemeRenderer(content: content, accent: accent);
  }
}

// ─── Legacy Theme Renderer (Backward Compatibility) ───────────────────────────
class _LegacyThemeRenderer extends StatelessWidget {
  final Map<String, dynamic> content;
  final Color accent;
  const _LegacyThemeRenderer({required this.content, required this.accent});

  @override
  Widget build(BuildContext context) {
    final conceptDef = content['conceptDefinition'] as Map<String, dynamic>?;
    final stories = content['biblicalStories'] as List<dynamic>? ?? [];
    final questions = content['studyQuestions'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SessionTitleCard(
          title: content['sessionTitle'] ?? '',
          subtitle: content['themeName'] ?? '',
          accent: accent,
        ),

        if (conceptDef != null) ...[
          _SectionHdr(
            label: 'The Concept Defined',
            accent: accent,
            icon: Icons.book_outlined,
          ),
          if (conceptDef['whatItReallyMeans'] != null)
            _RichPara(
              conceptDef['whatItReallyMeans'],
              italic: true,
              accentColor: accent,
            ),
          if (conceptDef['hebrewWord'] != null)
            _wordInsightFromMap({
              'englishWord': content['themeName'] ?? '',
              'original': conceptDef['hebrewWord']?['script'] ?? '',
              'transliteration':
                  conceptDef['hebrewWord']?['transliteration'] ?? '',
              'strongsNumber': conceptDef['hebrewWord']?['strongsNumber'] ?? '',
              'insight': conceptDef['hebrewWord']?['semanticRange'] ?? '',
            }, accent),
          if (conceptDef['greekWord'] != null)
            _wordInsightFromMap({
              'englishWord': content['themeName'] ?? '',
              'original': conceptDef['greekWord']?['script'] ?? '',
              'transliteration':
                  conceptDef['greekWord']?['transliteration'] ?? '',
              'strongsNumber': conceptDef['greekWord']?['strongsNumber'] ?? '',
              'insight': conceptDef['greekWord']?['semanticRange'] ?? '',
            }, accent),
        ],

        if (content['canonicalJourney'] != null) ...[
          _SectionHdr(
            label: 'Canonical Journey',
            accent: accent,
            icon: Icons.alt_route_rounded,
          ),
          _RichPara(content['canonicalJourney'], accentColor: accent),
        ],

        if (stories.isNotEmpty) ...[
          _SectionHdr(
            label: 'Biblical Stories',
            accent: accent,
            icon: Icons.book,
          ),
          ...stories.asMap().entries.map((e) {
            final s = e.value as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: NarrativeEventContainer(
                event: {
                  'primaryReference': s['reference'],
                  'eventTitle': s['title'],
                  'narrative': s['narrative'],
                  'whatGodReveals': s['themeConnection'],
                },
                index: e.key + 1,
                accent: accent,
              ),
            );
          }),
        ],

        if (content['howItPointsToChrist'] != null) ...[
          _SectionHdr(
            label: 'How It Points to Christ',
            accent: accent,
            icon: Icons.brightness_5_rounded,
          ),
          _RichPara(content['howItPointsToChrist'], accentColor: accent),
        ],

        if (content['forYourLife'] != null) ...[
          _SectionHdr(
            label: 'For Your Life',
            accent: accent,
            icon: Icons.favorite_rounded,
          ),
          _RichPara(content['forYourLife'], accentColor: accent),
        ],

        const SizedBox(height: 20),
        if (questions.isNotEmpty)
          _StudyQuestionsCard(questions: questions, accent: accent),
        const SizedBox(height: 16),
        if (content['prayerFocus'] != null)
          _PrayerBox(prayer: content['prayerFocus'], accent: accent),
      ],
    );
  }
}

// ─── Topical Content Renderer ─────────────────────────────────────────────────
class _TopicalContentRenderer extends StatelessWidget {
  final Map<String, dynamic> content;
  final Color accent;
  const _TopicalContentRenderer({required this.content, required this.accent});

  @override
  Widget build(BuildContext context) {
    // Check if this is the new dynamic sections format
    final sections = content['sections'] as List<dynamic>?;

    if (sections != null && sections.isNotEmpty) {
      // New dynamic sections format
      return _DynamicSectionsRenderer(
        content: content,
        sections: sections,
        accent: accent,
      );
    }

    // Legacy format - keep for backward compatibility
    return _LegacyTopicalRenderer(content: content, accent: accent);
  }
}

// ─── Legacy Topical Renderer (Backward Compatibility) ─────────────────────────
class _LegacyTopicalRenderer extends StatelessWidget {
  final Map<String, dynamic> content;
  final Color accent;
  const _LegacyTopicalRenderer({required this.content, required this.accent});

  @override
  Widget build(BuildContext context) {
    final keyScriptures = content['keyScriptures'] as List<dynamic>? ?? [];
    final personalities =
        content['biblicalPersonalities'] as List<dynamic>? ?? [];
    final questions = content['studyQuestions'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SessionTitleCard(title: content['question'] ?? '', accent: accent),

        if (content['whatScriptureSays'] != null) ...[
          _SectionHdr(
            label: 'What Scripture Says',
            accent: accent,
            icon: Icons.menu_book_rounded,
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withOpacity(0.2)),
            ),
            child: Text(
              content['whatScriptureSays'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
            ),
          ),
        ],

        if (content['godsPerspective'] != null) ...[
          _SectionHdr(
            label: "God's Perspective",
            accent: accent,
            icon: Icons.visibility_rounded,
          ),
          _RichPara(content['godsPerspective'], accentColor: accent),
        ],

        if (keyScriptures.isNotEmpty) ...[
          _SectionHdr(
            label: 'Key Scriptures',
            accent: accent,
            icon: Icons.format_quote_rounded,
          ),
          ...keyScriptures.map((s) {
            final sm = s as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sm['reference'] ?? '',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: accent,
                        fontSize: 12,
                      ),
                    ),
                    if (sm['verseText'] != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '"${sm['verseText']}"',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ],
                    if (sm['whatItSays'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        sm['whatItSays'] ?? '',
                        style: const TextStyle(fontSize: 13, height: 1.6),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],

        if (personalities.isNotEmpty) ...[
          _SectionHdr(
            label: 'Biblical Personalities',
            accent: accent,
            icon: Icons.people_rounded,
          ),
          ...personalities.asMap().entries.map((e) {
            final p = e.value as Map<String, dynamic>;
            return NarrativeEventContainer(
              event: {
                'primaryReference': '',
                'eventTitle': p['person'] ?? '',
                'narrative': p['story'] ?? '',
                'whatGodReveals': p['lesson'] ?? '',
              },
              index: e.key + 1,
              accent: accent,
            );
          }),
        ],

        if (content['whatChristShows'] != null) ...[
          _SectionHdr(
            label: 'What Christ Shows',
            accent: accent,
            icon: Icons.brightness_5_rounded,
          ),
          _RichPara(content['whatChristShows'], accentColor: accent),
        ],

        if (content['practicalWisdom'] != null) ...[
          _SectionHdr(
            label: 'Practical Wisdom',
            accent: accent,
            icon: Icons.tips_and_updates_rounded,
          ),
          _RichPara(content['practicalWisdom'], accentColor: accent),
        ],

        const SizedBox(height: 20),
        if (questions.isNotEmpty)
          _StudyQuestionsCard(questions: questions, accent: accent),
        const SizedBox(height: 16),
        if (content['prayerFocus'] != null)
          _PrayerBox(prayer: content['prayerFocus'], accent: accent),
        const SizedBox(height: 12),
        if (content['sessionClosing'] != null)
          Text(
            content['sessionClosing'],
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
      ],
    );
  }
}

// ─── Devotional Content Renderer ──────────────────────────────────────────────
class _DevotionalContentRenderer extends StatelessWidget {
  final Map<String, dynamic> content;
  final Color accent;
  final String? sessionDateLabel;
  const _DevotionalContentRenderer({
    required this.content,
    required this.accent,
    this.sessionDateLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Check if this is the new dynamic sections format
    final sections = content['sections'] as List<dynamic>?;

    if (sections != null && sections.isNotEmpty) {
      // New dynamic sections format
      return _DynamicDevotionalRenderer(
        content: content,
        sections: sections,
        accent: accent,
        sessionDateLabel: sessionDateLabel,
      );
    }

    // Legacy format - keep for backward compatibility
    return _LegacyDevotionalRenderer(
      content: content,
      accent: accent,
      sessionDateLabel: sessionDateLabel,
    );
  }
}

// ─── Dynamic Devotional Renderer (New Format) ─────────────────────────────────
class _DynamicDevotionalRenderer extends StatelessWidget {
  final Map<String, dynamic> content;
  final List<dynamic> sections;
  final Color accent;
  final String? sessionDateLabel;

  const _DynamicDevotionalRenderer({
    required this.content,
    required this.sections,
    required this.accent,
    this.sessionDateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final anchor = content['anchorScripture'] as Map<String, dynamic>?;
    final bibleStory = content['bibleStory'] as Map<String, dynamic>?;
    final questions = content['studyQuestions'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day badge
        _SessionTitleCard(
          title: content['dayTitle'] ?? '',
          subtitle:
              'DAY ${content['dayNumber'] ?? content['sessionNumber'] ?? ''}${sessionDateLabel != null ? ' • $sessionDateLabel' : ''} — ${(content['arcPhase'] ?? '').toUpperCase()}',
          accent: accent,
        ),

        // Anchor Scripture (v2.1)
        if (anchor != null) ...[
          const SizedBox(height: 16),
          _AnchorPassageCard(anchorPassage: anchor, accent: accent),
        ],

        // Bible Story (v2.1 - Day 1)
        if (bibleStory != null) ...[
          const SizedBox(height: 16),
          _BibleStoryCard(bibleStory: bibleStory, accent: accent),
        ],

        // Render each dynamic section
        ...sections.map((sectionData) {
          final section = sectionData as Map<String, dynamic>;
          return _DynamicSectionCard(section: section, accent: accent);
        }),

        if (content['prayerFocus'] != null) ...[
          const SizedBox(height: 16),
          _PrayerBox(prayer: content['prayerFocus'], accent: accent),
        ],

        if (content['journalingPrompt'] != null) ...[
          _SectionHdr(
            label: 'Journal Prompt',
            accent: accent,
            icon: Icons.edit_note_rounded,
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withOpacity(0.15)),
            ),
            child: Text(
              content['journalingPrompt'],
              style: const TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                height: 1.65,
              ),
            ),
          ),
        ],

        if (content['closingDeclaration'] != null) ...[
          const SizedBox(height: 20),
          Text(
            content['closingDeclaration'],
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: accent,
              height: 1.55,
            ),
          ),
        ],

        if (questions.isNotEmpty) ...[
          const SizedBox(height: 20),
          _StudyQuestionsCard(questions: questions, accent: accent),
        ],
      ],
    );
  }
}

// ─── Legacy Devotional Renderer (Backward Compatibility) ──────────────────────
class _LegacyDevotionalRenderer extends StatelessWidget {
  final Map<String, dynamic> content;
  final Color accent;
  final String? sessionDateLabel;
  const _LegacyDevotionalRenderer({
    required this.content,
    required this.accent,
    this.sessionDateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final anchor = content['anchorScripture'] as Map<String, dynamic>?;
    final supporting = content['supportingScriptures'] as List<dynamic>? ?? [];
    final wordInsight =
        content['aWordFromTheOriginal'] as Map<String, dynamic>?;
    final questions = content['studyQuestions'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF9B7DF6), Color(0xFF4F63D2)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'DAY ${content['dayNumber']}${sessionDateLabel != null ? ' • $sessionDateLabel' : ''} — ${(content['arcPhase'] ?? '').toUpperCase()}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content['dayTitle'] ?? '',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: accent,
          ),
        ),
        const SizedBox(height: 4),

        // Anchor Scripture
        if (anchor != null) ...[
          const SizedBox(height: 16),
          _AnchorPassageCard(
            anchorPassage: {
              'reference': anchor['reference'],
              'verseText': anchor['verseText'],
              'whyThisPassage': anchor['whyToday'],
            },
            accent: accent,
          ),
        ],

        if (content['openingReflection'] != null) ...[
          _SectionHdr(
            label: "Today's Opening",
            accent: accent,
            icon: Icons.wb_sunny_outlined,
          ),
          _RichPara(
            content['openingReflection'],
            italic: true,
            accentColor: accent,
          ),
        ],

        if (content['theDaysTruth'] != null) ...[
          _SectionHdr(
            label: "Today's Truth",
            accent: accent,
            icon: Icons.auto_stories_rounded,
          ),
          _RichPara(content['theDaysTruth'], accentColor: accent),
        ],

        if (wordInsight != null) ...[
          _SectionHdr(
            label: 'A Word from the Original',
            accent: accent,
            icon: Icons.translate_rounded,
          ),
          _wordInsightFromMap({
            'englishWord': wordInsight['englishWord'] ?? '',
            'original': wordInsight['original'] ?? '',
            'transliteration': wordInsight['transliteration'] ?? '',
            'strongsNumber': wordInsight['strongsNumber'] ?? '',
            'insight': wordInsight['discovery'] ?? '',
          }, accent),
        ],

        if (supporting.isNotEmpty) ...[
          _SectionHdr(
            label: 'Supporting Scriptures',
            accent: accent,
            icon: Icons.format_quote_rounded,
          ),
          ...supporting.map((s) {
            final sm = s as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sm['reference'] ?? '',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: accent,
                        fontSize: 12,
                      ),
                    ),
                    if (sm['verseText'] != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '"${sm['verseText']}"',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ],
                    if (sm['connection'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        sm['connection'] ?? '',
                        style: const TextStyle(fontSize: 13, height: 1.6),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],

        if (content['prayerPoint'] != null) ...[
          const SizedBox(height: 16),
          _PrayerBox(prayer: content['prayerPoint'], accent: accent),
        ],

        if (content['journalingPrompt'] != null) ...[
          _SectionHdr(
            label: 'Journal Prompt',
            accent: accent,
            icon: Icons.edit_note_rounded,
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withOpacity(0.15)),
            ),
            child: Text(
              content['journalingPrompt'],
              style: const TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                height: 1.65,
              ),
            ),
          ),
        ],

        if (content['closingDeclaration'] != null) ...[
          const SizedBox(height: 20),
          Text(
            content['closingDeclaration'],
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: accent,
              height: 1.55,
            ),
          ),
        ],

        if (questions.isNotEmpty) ...[
          const SizedBox(height: 20),
          _StudyQuestionsCard(questions: questions, accent: accent),
        ],
      ],
    );
  }
}

// ─── Raw Fallback ─────────────────────────────────────────────────────────────
class _RawTextFallback extends StatelessWidget {
  final StudySession session;
  const _RawTextFallback({required this.session});

  @override
  Widget build(BuildContext context) {
    return Text(
      session.contentJson ?? 'No content available.',
      style: TextStyle(
        fontSize: 13,
        color: Theme.of(context).colorScheme.onSurface,
        fontFamily: 'monospace',
        height: 1.6,
      ),
    );
  }
}

// ─── Session Footer ───────────────────────────────────────────────────────────
class _SessionFooter extends StatelessWidget {
  final BibleStudy study;
  final int sessionNumber;
  final bool isCompleted;
  final Color accent;
  final VoidCallback onMarkComplete;
  final VoidCallback onNextSession;

  const _SessionFooter({
    required this.study,
    required this.sessionNumber,
    required this.isCompleted,
    required this.accent,
    required this.onMarkComplete,
    required this.onNextSession,
  });

  @override
  Widget build(BuildContext context) {
    final hasNext = sessionNumber < study.totalSessions;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 16),
          if (!isCompleted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onMarkComplete,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Mark as Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Session Completed',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          if (hasNext) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onNextSession,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text('Session ${sessionNumber + 1}'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: accent.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
