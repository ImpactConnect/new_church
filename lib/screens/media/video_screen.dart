import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/video_item.dart';
import '../../services/video_service.dart';
import '../../utils/media_utils.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({Key? key}) : super(key: key);

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final VideoService _videoService = VideoService();
  YoutubePlayerController? _youtubeController;

  // ── Search / Filter ──────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  List<String> _allCategories = [];

  @override
  void dispose() {
    _youtubeController?.close();
    _searchController.dispose();
    super.dispose();
  }

  // ─── YouTube Helpers ─────────────────────────────────────────────────────

  String? _extractYouTubeId(String url) {
    final regExp = RegExp(
      r'^.*(?:youtu\.be\/|v\/|vi\/|u\/\w\/|embed\/|shorts\/|(?:watch)?\?v(?:i)?=|&v(?:i)?=)([^#&?]+).*',
      caseSensitive: false,
    );
    return regExp.firstMatch(url)?.group(1);
  }

  String _youtubeThumbnail(String videoId) =>
      'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';

  // ─── Filtering ───────────────────────────────────────────────────────────

  List<VideoItem> _applyFilters(List<VideoItem> videos) {
    final q = _searchQuery.toLowerCase();
    return videos.where((v) {
      final matchesSearch = q.isEmpty ||
          v.title.toLowerCase().contains(q) ||
          (v.description?.toLowerCase().contains(q) ?? false) ||
          (v.category?.toLowerCase().contains(q) ?? false);
      final matchesCategory =
          _selectedCategory == null || v.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  // ─── Playback ────────────────────────────────────────────────────────────

  Future<void> _playVideo(VideoItem video) async {
    final videoId = _extractYouTubeId(video.videoUrl);

    if (videoId == null) {
      final uri = Uri.parse(video.videoUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError('Could not launch video');
      }
      return;
    }

    _videoService.incrementVideoViews(video.id);

    _youtubeController?.close();
    _youtubeController = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        enableCaption: true,
        showVideoAnnotations: false,
        enableJavaScript: true,
      ),
    );

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _VideoPlayerPage(
          video: video,
          controller: _youtubeController!,
          videoService: _videoService,
        ),
      ),
    );

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: CustomScrollView(
          slivers: [
            // ── Hero header ──
            SliverToBoxAdapter(child: _buildHeroSection()),

            // ── Search bar ──
            SliverToBoxAdapter(child: _buildSearchBar()),

            // ── Featured / Recommended ──
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
              sliver: SliverToBoxAdapter(
                child: Text('Featured',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
            SliverToBoxAdapter(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('videos')
                    .where('isRecommended', isEqualTo: true)
                    .orderBy('createdAt', descending: true)
                    .limit(10)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return _buildShimmerRow();
                  }
                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('No featured videos yet.',
                          style: TextStyle(color: Colors.grey)),
                    );
                  }
                  final videos = snap.data!.docs
                      .map((doc) => VideoItem.fromFirestore(doc))
                      .toList();
                  return SizedBox(
                    height: 220,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      children: videos
                          .map((v) => _buildFeaturedCard(v))
                          .toList(),
                    ),
                  );
                },
              ),
            ),

            // ── Category filter ──
            SliverToBoxAdapter(child: _buildCategoryFilter()),

            // ── All Videos ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              sliver: SliverToBoxAdapter(
                child: Text(
                  _selectedCategory != null
                      ? _selectedCategory!
                      : 'All Videos',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('videos')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return SliverToBoxAdapter(
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: _buildShimmerList(),
                    ),
                  );
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                          child: Text('No videos available yet.',
                              style: TextStyle(color: Colors.grey))),
                    ),
                  );
                }

                // Build category list once
                final allVideos = snap.data!.docs
                    .map((doc) => VideoItem.fromFirestore(doc))
                    .toList();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final cats = allVideos
                      .where((v) => v.category != null)
                      .map((v) => v.category!)
                      .toSet()
                      .toList()
                    ..sort();
                  if (mounted && cats.length != _allCategories.length) {
                    setState(() => _allCategories = cats);
                  }
                });

                final filtered = _applyFilters(allVideos);

                if (filtered.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.search_off,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          const Text('No videos match your search',
                              style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                                _selectedCategory = null;
                              });
                            },
                            child: const Text('Clear filters'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _buildVideoCard(filtered[i]),
                    childCount: filtered.length,
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  // ─── Search bar ──────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search videos…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () =>
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      }),
                )
              : null,
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: colors.surface,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    if (_allCategories.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _categoryChip('All', null, colors),
          ..._allCategories
              .map((c) => _categoryChip(c, c, colors))
              .toList(),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, String? value, ColorScheme colors) {
    final selected = _selectedCategory == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color:
              selected ? colors.primary : colors.surface,
          border: Border.all(
            color:
                selected ? colors.primary : Colors.grey.withOpacity(0.4),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : null,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ─── Hero ────────────────────────────────────────────────────────────────

  Widget _buildHeroSection() {
    return Stack(
      children: [
        Image.asset(
          'assets/images/video_header.jpg',
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
        ),
        Container(
          width: double.infinity,
          height: 220,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black87, Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: SafeArea(
            child: CircleAvatar(
              backgroundColor: Colors.white24,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Video Library',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sermons, worship sessions & ministry highlights',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Shimmer ─────────────────────────────────────────────────────────────

  Widget _buildShimmerRow() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 3,
          itemBuilder: (_, __) => Container(
            width: 200,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 120,
                height: 75,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(
                        height: 12, width: 120, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Cards ───────────────────────────────────────────────────────────────

  Widget _buildVideoCard(VideoItem video) {
    final videoId = _extractYouTubeId(video.videoUrl);
    final thumb =
        videoId != null ? _youtubeThumbnail(videoId) : video.thumbnailUrl;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _playVideo(video),
        child: Row(
          children: [
            // Thumbnail
            SizedBox(
              width: 130,
              height: 80,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: thumb,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: Colors.grey[200]),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.video_library,
                          color: Colors.grey, size: 32),
                    ),
                  ),
                  const Positioned.fill(
                    child: Center(
                      child: Icon(Icons.play_circle_fill,
                          color: Colors.white, size: 36),
                    ),
                  ),
                  // Category badge
                  if (video.category != null)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          video.category!,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 9),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    StreamBuilder<int>(
                      stream: _videoService.getVideoViews(video.id),
                      builder: (_, snap) {
                        final views = snap.data ?? video.views;
                        return Text(
                          '${MediaUtils.formatViews(views)} • ${MediaUtils.formatRelativeDate(video.postedDate)}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11),
                        );
                      },
                    ),
                    if (video.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        video.description!,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(VideoItem video) {
    final videoId = _extractYouTubeId(video.videoUrl);
    final thumb =
        videoId != null ? _youtubeThumbnail(videoId) : video.thumbnailUrl;

    return GestureDetector(
      onTap: () => _playVideo(video),
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 130,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: thumb,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: Colors.grey[300]),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.video_library,
                            size: 40, color: Colors.grey),
                      ),
                    ),
                    const Positioned.fill(
                      child: Center(
                        child: Icon(Icons.play_circle_fill,
                            color: Colors.white, size: 48),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: Theme.of(context).cardColor,
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${MediaUtils.formatViews(video.views)} • ${MediaUtils.formatRelativeDate(video.postedDate)}',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Separate Video Player Page ──────────────────────────────────────────────

class _VideoPlayerPage extends StatefulWidget {
  const _VideoPlayerPage({
    required this.video,
    required this.controller,
    required this.videoService,
  });

  final VideoItem video;
  final YoutubePlayerController controller;
  final VideoService videoService;

  @override
  State<_VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<_VideoPlayerPage> {
  bool _hasLiked = false;

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
  }

  Future<void> _checkIfLiked() async {
    final prefs = await SharedPreferences.getInstance();
    final liked = prefs.getStringList('liked_videos') ?? [];
    if (mounted) {
      setState(() => _hasLiked = liked.contains(widget.video.id));
    }
  }

  Future<void> _likeVideo() async {
    if (_hasLiked) return; // idempotent guard

    final prefs = await SharedPreferences.getInstance();
    final liked = prefs.getStringList('liked_videos') ?? [];
    liked.add(widget.video.id);
    await prefs.setStringList('liked_videos', liked);

    try {
      final ref = FirebaseFirestore.instance
          .collection('videos')
          .doc(widget.video.id);
      await ref.update({'likes': FieldValue.increment(1)});
      if (mounted) {
        setState(() => _hasLiked = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks for liking! 👍')),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerScaffold(
      controller: widget.controller,
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.video.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              player,
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.video.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<int>(
                        stream: widget.videoService
                            .getVideoViews(widget.video.id),
                        builder: (_, snap) {
                          final views = snap.data ?? widget.video.views;
                          return Text(
                            '${MediaUtils.formatViews(views)} • ${MediaUtils.formatRelativeDate(widget.video.postedDate)}',
                            style: const TextStyle(color: Colors.grey),
                          );
                        },
                      ),
                      if (widget.video.category != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.video.category!,
                            style: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const Divider(height: 24),
                      // Action row
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                        children: [
                          _ActionButton(
                            icon: _hasLiked
                                ? Icons.thumb_up
                                : Icons.thumb_up_outlined,
                            label: _hasLiked
                                ? 'Liked!'
                                : '${widget.video.likes} Likes',
                            color: _hasLiked
                                ? Theme.of(context).colorScheme.primary
                                : null,
                            onTap: _hasLiked ? null : _likeVideo,
                          ),
                          _ActionButton(
                            icon: Icons.share_outlined,
                            label: 'Share',
                            onTap: () => SharePlus.instance.share(
                              ShareParams(
                                text: '🎬 "${widget.video.title}"\n${widget.video.videoUrl}',
                              ),
                            ),
                          ),
                          _ActionButton(
                            icon: Icons.open_in_new,
                            label: 'YouTube',
                            onTap: () async {
                              final uri =
                                  Uri.parse(widget.video.videoUrl);
                              if (await canLaunchUrl(uri)) {
                                launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
                        ],
                      ),
                      // Description
                      if (widget.video.description != null &&
                          widget.video.description!.isNotEmpty) ...[
                        const Divider(height: 24),
                        const Text('Description',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(
                          widget.video.description!,
                          style: const TextStyle(
                              fontSize: 13,
                              height: 1.6,
                              color: Colors.black87),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 22,
                color: color ?? (onTap == null ? Colors.grey : null)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11,
                  color: color ?? (onTap == null ? Colors.grey : null)),
            ),
          ],
        ),
      ),
    );
  }
}
