import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:just_audio/just_audio.dart';
import 'package:marquee/marquee.dart';
import 'package:share_plus/share_plus.dart';

import '../models/sermon.dart';
import '../services/audio_player_service.dart';
import '../services/sermon_service.dart';
import '../utils/media_utils.dart';

class SermonCard extends StatelessWidget {
  const SermonCard({
    Key? key,
    required this.sermon,
    required this.audioPlayerService,
    required this.sermonService,
    required this.onTap,
  }) : super(key: key);

  final Sermon sermon;
  final AudioPlayerService audioPlayerService;
  final SermonService sermonService;
  final VoidCallback onTap;

  String _formattedDate() =>
      DateFormat('dd MMM yyyy').format(sermon.dateCreated);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor == Colors.white
            ? const Color(0xFFF9FAFB)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // ── Thumbnail ──────────────────────────────────────────
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 75,
                        height: 75,
                        child: CachedNetworkImage(
                          imageUrl: sermon.thumbnailUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: colors.primary.withValues(alpha: 0.1),
                            child: const Icon(Icons.church, color: Colors.grey),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: colors.primary.withValues(alpha: 0.1),
                            child: const Icon(Icons.church, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    // Play/pause overlay with glassmorphism
                    Positioned.fill(
                      child: Center(
                        child: StreamBuilder<PlayerState>(
                          stream: audioPlayerService.playerStateStream,
                          builder: (context, snapshot) {
                            final isThisSermon =
                                audioPlayerService.currentSermon?.id ==
                                    sermon.id;
                            final isPlaying = snapshot.data?.playing ?? false;
                            return ClipOval(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  color: Colors.black.withValues(alpha: 0.35),
                                  child: Icon(
                                    isThisSermon && isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Duration badge
                    if (sermon.duration != null)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            MediaUtils.formatDuration(sermon.duration!),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                // ── Info ───────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 20,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final span = TextSpan(
                              text: sermon.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  height: 1.2),
                            );
                            final tp = TextPainter(
                                text: span,
                                maxLines: 1,
                                textDirection: TextDirection.ltr);
                            tp.layout(maxWidth: double.infinity);
                            if (tp.size.width > constraints.maxWidth) {
                              return Marquee(
                                text: sermon.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    height: 1.2),
                                scrollAxis: Axis.horizontal,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                blankSpace: 30.0,
                                velocity: 30.0,
                                pauseAfterRound: const Duration(seconds: 2),
                                startPadding: 0.0,
                                accelerationDuration:
                                    const Duration(milliseconds: 500),
                                accelerationCurve: Curves.linear,
                                decelerationDuration:
                                    const Duration(milliseconds: 500),
                                decelerationCurve: Curves.easeOut,
                              );
                            } else {
                              return Text(
                                sermon.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    height: 1.2),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sermon.preacherName,
                        style: TextStyle(
                            color: colors.primary.withValues(alpha: 0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          // Category chip
                          if (sermon.category.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                sermon.category,
                                style: TextStyle(
                                  color: colors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          // Date
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 10, color: Colors.grey[500]),
                              const SizedBox(width: 3),
                              Text(
                                _formattedDate(),
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 10),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.headset_rounded,
                                  size: 10, color: Colors.grey[500]),
                              const SizedBox(width: 3),
                              Text(
                                MediaUtils.formatViews(sermon.streams,
                                    hideLabel: true),
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 10),
                              ),
                            ],
                          ),
                          // Bookmark indicator
                          if (sermon.isBookmarked)
                            Icon(Icons.bookmark_rounded,
                                size: 14, color: colors.primary),
                          // Downloaded indicator
                          if (sermon.isDownloaded)
                            Icon(Icons.download_done_rounded,
                                size: 14, color: Colors.green[600]),
                        ],
                      ),
                      if (sermon.scriptureReference != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          sermon.scriptureReference!,
                          style: TextStyle(
                              color: colors.primary.withValues(alpha: 0.8),
                              fontSize: 11,
                              fontStyle: FontStyle.italic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // ── Menu ───────────────────────────────────────────────
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) async {
                    switch (value) {
                      case 'download':
                        if (sermon.isDownloaded) {
                          await sermonService.deleteDownloadedSermon(sermon);
                        } else {
                          await sermonService.downloadSermon(sermon);
                        }
                        break;
                      case 'bookmark':
                        await sermonService.toggleBookmark(sermon);
                        break;
                      case 'share':
                        await SharePlus.instance.share(
                          ShareParams(
                            text:
                                '🎙️ "${sermon.title}" by ${sermon.preacherName}'
                                '${sermon.scriptureReference != null ? '\n📖 ${sermon.scriptureReference}' : ''}'
                                '\n\n${sermon.audioUrl}',
                            subject: sermon.title,
                          ),
                        );
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'download',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          sermon.isDownloaded
                              ? Icons.delete_outline
                              : Icons.download_outlined,
                          color:
                              sermon.isDownloaded ? Colors.red : colors.primary,
                        ),
                        title: Text(sermon.isDownloaded
                            ? 'Delete Download'
                            : 'Download'),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'bookmark',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          sermon.isBookmarked
                              ? Icons.bookmark_remove
                              : Icons.bookmark_add_outlined,
                          color: Colors.amber,
                        ),
                        title: Text(sermon.isBookmarked
                            ? 'Remove Bookmark'
                            : 'Bookmark'),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'share',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.share_outlined),
                        title: Text('Share'),
                      ),
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
