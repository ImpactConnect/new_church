import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
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

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // ── Thumbnail ──────────────────────────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: CachedNetworkImage(
                        imageUrl: sermon.thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: colors.primary.withOpacity(0.1),
                          child: const Icon(Icons.church,
                              color: Colors.grey),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: colors.primary.withOpacity(0.1),
                          child: const Icon(Icons.church,
                              color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  // Play/pause overlay
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        color: Colors.black26,
                        child: StreamBuilder<PlayerState>(
                          stream: audioPlayerService.playerStateStream,
                          builder: (context, snapshot) {
                            final isThisSermon =
                                audioPlayerService.currentSermon?.id ==
                                    sermon.id;
                            final isPlaying =
                                snapshot.data?.playing ?? false;
                            return Center(
                              child: Icon(
                                isThisSermon && isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            );
                          },
                        ),
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
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          MediaUtils.formatDuration(sermon.duration!),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 9),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // ── Info ───────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sermon.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sermon.preacherName,
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Category chip
                        if (sermon.category.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  colors.primary.withOpacity(0.1),
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
                        if (sermon.category.isNotEmpty)
                          const SizedBox(width: 6),
                        // Date
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 10, color: Colors.grey[500]),
                            const SizedBox(width: 3),
                            Text(
                              _formattedDate(),
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 10),
                            ),
                          ],
                        ),
                        // Bookmark indicator
                        if (sermon.isBookmarked) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.bookmark_rounded,
                              size: 14, color: colors.primary),
                        ],
                        // Downloaded indicator
                        if (sermon.isDownloaded) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.download_done_rounded,
                              size: 14, color: Colors.green[600]),
                        ],
                      ],
                    ),
                    if (sermon.scriptureReference != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        sermon.scriptureReference!,
                        style: TextStyle(
                            color: colors.primary.withOpacity(0.8),
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
                          text: '🎙️ "${sermon.title}" by ${sermon.preacherName}'
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
                        color: sermon.isDownloaded
                            ? Colors.red
                            : colors.primary,
                      ),
                      title: Text(
                          sermon.isDownloaded ? 'Delete Download' : 'Download'),
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
    );
  }
}
