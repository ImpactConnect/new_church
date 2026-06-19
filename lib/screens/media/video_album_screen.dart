import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/video_item.dart';

class VideoAlbumScreen extends StatelessWidget {
  final String albumName;
  final List<VideoItem> videos;
  final Function(VideoItem) onVideoTap;
  final String? coverImageUrl;
  final String? description;

  const VideoAlbumScreen({
    Key? key,
    required this.albumName,
    required this.videos,
    required this.onVideoTap,
    this.coverImageUrl,
    this.description,
  }) : super(key: key);

  String? _extractYouTubeId(String url) {
    if (url.isEmpty) return null;
    final regex = RegExp(
        r'(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  String _youtubeThumbnail(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }

  Widget _buildVideoCard(BuildContext context, VideoItem video) {
    final videoId = _extractYouTubeId(video.videoUrl);
    final thumb =
        videoId != null ? _youtubeThumbnail(videoId) : video.thumbnailUrl;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onVideoTap(video),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            SizedBox(
              width: 140,
              height: 100,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: thumb,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey[200]),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.video_library,
                          color: Colors.grey, size: 32),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.remove_red_eye_rounded,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('${video.views} views',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                        const SizedBox(width: 12),
                        Icon(Icons.access_time_rounded,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                            '${video.postedDate.day}/${video.postedDate.month}/${video.postedDate.year}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final firstVideoId =
        videos.isNotEmpty ? _extractYouTubeId(videos.first.videoUrl) : null;
    final displayImageUrl = (coverImageUrl != null && coverImageUrl!.isNotEmpty)
        ? coverImageUrl!
        : (firstVideoId != null
            ? _youtubeThumbnail(firstVideoId)
            : (videos.isNotEmpty ? videos.first.thumbnailUrl : ''));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                albumName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
              background: displayImageUrl.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: displayImageUrl,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          color: Colors.black.withValues(alpha: 0.4),
                        ),
                      ],
                    )
                  : Container(
                      color: colors.primary,
                      child: const Icon(Icons.video_library,
                          size: 80, color: Colors.white54),
                    ),
            ),
          ),
          if (description != null && description!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  description!,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Text(
                '${videos.length} Videos',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildVideoCard(context, videos[index]),
              childCount: videos.length,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }
}
