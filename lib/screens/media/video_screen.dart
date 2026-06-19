import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/video_item.dart';
import '../../models/video_category.dart';
import 'video_album_screen.dart';
import '../../services/video_service.dart';
import '../../services/youtube_api_service.dart';
import '../../utils/media_utils.dart';
import 'package:marquee/marquee.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({Key? key}) : super(key: key);

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final VideoService _videoService = VideoService();
  final YouTubeApiService _ytApiService = YouTubeApiService();
  YoutubePlayerController? _youtubeController;

  // ── Search / Filter ──────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  List<String> _allCategories = [];
  List<VideoCategory> _fetchedCategories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('video_categories').get();
      if (mounted) {
        setState(() {
          _fetchedCategories =
              snap.docs.map((d) => VideoCategory.fromFirestore(d)).toList();
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  @override
  void dispose() {
    _youtubeController?.close();
    _searchController.dispose();
    super.dispose();
  }

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
    _videoService.incrementVideoViews(video.id);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    YoutubePlayerController? youtubeController;

    // Branch on video type
    if (video.isYouTube) {
      final videoId = _extractYouTubeId(video.videoUrl);
      if (videoId == null) {
        _showError('Could not parse YouTube video ID');
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        return;
      }
      _youtubeController?.close();
      youtubeController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          enableCaption: true,
          showVideoAnnotations: false,
          enableJavaScript: true,
          playsInline: false,
          // Use an unrestricted origin so YouTube allows more embeds
          origin: 'https://www.youtube.com',
        ),
      );
      _youtubeController = youtubeController;
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _VideoPlayerPage(
          video: video,
          youtubeController: youtubeController,
          videoService: _videoService,
          onPlayRelated: (relatedVideo) {
            Navigator.pop(context); // Close current player
            _playVideo(relatedVideo); // Open new one
          },
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            _loadCategories();
          },
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('videos')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allDocs =
                  snap.hasData ? snap.data!.docs : <DocumentSnapshot>[];
              final allVideos =
                  allDocs.map((doc) => VideoItem.fromFirestore(doc)).toList();

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

              return NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(child: _buildHeroSection()),
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Container(
                          decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(30)),
                          child: TabBar(
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            indicator: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.15),
                            ),
                            labelColor: Theme.of(context).colorScheme.primary,
                            labelStyle:
                                const TextStyle(fontWeight: FontWeight.bold),
                            unselectedLabelColor: Colors.grey.shade600,
                            unselectedLabelStyle:
                                const TextStyle(fontWeight: FontWeight.w600),
                            tabs: const [
                              Tab(text: 'All Videos'),
                              Tab(text: 'Albums')
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                body: TabBarView(
                  children: [
                    _buildAllVideosTab(filtered),
                    _buildAlbumGrid(allVideos),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAllVideosTab(List<VideoItem> filtered) {
    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
          sliver: SliverToBoxAdapter(
            child: Text('Featured',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
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
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: videos.map((v) => _buildFeaturedCard(v)).toList(),
                ),
              );
            },
          ),
        ),
        SliverToBoxAdapter(child: _buildCategoryFilter()),
        if (_selectedCategory == null && _searchQuery.isEmpty) ...[
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
            sliver: SliverToBoxAdapter(
              child: Text('From Our YouTube Channel',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<List<VideoItem>>(
              future: _ytApiService.fetchChannelVideos(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting)
                  return _buildShimmerRow();
                if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Could not load channel videos.',
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                return SizedBox(
                  height: 220,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children:
                        snap.data!.map((v) => _buildFeaturedCard(v)).toList(),
                  ),
                );
              },
            ),
          ),
        ],
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          sliver: SliverToBoxAdapter(
            child: Text(
              _selectedCategory != null ? _selectedCategory! : 'All Videos',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
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
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _buildVideoCard(filtered[i]),
              childCount: filtered.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildAlbumGrid(List<VideoItem> filteredVideos) {
    if (_isLoadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }

    final existingCategoryNames =
        _fetchedCategories.map((c) => c.name.toLowerCase()).toSet();
    final combinedCategories = List<VideoCategory>.from(_fetchedCategories);

    for (var v in filteredVideos) {
      final cat = (v.category ?? '').trim();
      if (cat.isNotEmpty &&
          !existingCategoryNames.contains(cat.toLowerCase())) {
        existingCategoryNames.add(cat.toLowerCase());
        combinedCategories.add(VideoCategory(
            id: 'virtual_$cat', name: cat, imageUrl: '', description: ''));
      }
    }

    if (combinedCategories.isEmpty) {
      return const Center(child: Text('No albums available'));
    }

    final sortedCategories = combinedCategories
      ..sort((a, b) => a.name.compareTo(b.name));

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final videosInAlbum = filteredVideos.where((v) {
          final cat = (v.category ?? '').trim().toLowerCase();
          return cat == category.name.toLowerCase();
        }).toList();

        final coverImageUrl = category.imageUrl;
        final colors = Theme.of(context).colorScheme;

        String displayImageUrl = coverImageUrl;
        if (displayImageUrl.isEmpty && videosInAlbum.isNotEmpty) {
          final firstVid = videosInAlbum.first;
          displayImageUrl = _extractYouTubeId(firstVid.videoUrl) != null
              ? _youtubeThumbnail(_extractYouTubeId(firstVid.videoUrl)!)
              : firstVid.thumbnailUrl;
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VideoAlbumScreen(
                  albumName: category.name,
                  videos: videosInAlbum,
                  onVideoTap: (video) => _playVideo(video),
                  coverImageUrl: category.imageUrl,
                  description: category.description,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: displayImageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: displayImageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: Colors.grey.shade200),
                            errorWidget: (context, url, error) => Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.video_library,
                                    color: Colors.grey)),
                          )
                        : Container(
                            color: colors.primary,
                            child: const Icon(Icons.folder,
                                size: 48, color: Colors.white54)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('${videosInAlbum.length} Videos',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Search bar ──────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Search videos...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () => setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    }),
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
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
          ..._allCategories.map((c) => _categoryChip(c, c, colors)).toList(),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? colors.primary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
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
                  color: Colors.white.withValues(alpha: 0.85),
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
                    Container(height: 12, width: 120, color: Colors.white),
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
        onTap: () => _playVideo(video),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // Thumbnail
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
                  // Category badge
                  if (video.category != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          video.category!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 20,
                      child: video.title.length > 30
                          ? Marquee(
                              text: video.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14),
                              scrollAxis: Axis.horizontal,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              blankSpace: 30.0,
                              velocity: 30.0,
                              startPadding: 0.0,
                            )
                          : Text(
                              video.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                    const SizedBox(height: 6),
                    StreamBuilder<int>(
                      stream: _videoService.getVideoViews(video.id),
                      builder: (_, snap) {
                        final views = snap.data ?? video.views;
                        return Text(
                          '${MediaUtils.formatViews(views)} views • ${MediaUtils.formatRelativeDate(video.postedDate)}',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        );
                      },
                    ),
                    if (video.preacher != null &&
                        video.preacher!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              video.preacher!,
                              style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
        width: 260,
        margin: const EdgeInsets.only(right: 16, bottom: 8),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 140,
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
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 36),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 20,
                      child: video.title.length > 30
                          ? Marquee(
                              text: video.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14),
                              scrollAxis: Axis.horizontal,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              blankSpace: 30.0,
                              velocity: 30.0,
                              startPadding: 0.0,
                            )
                          : Text(
                              video.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${MediaUtils.formatViews(video.views)} views • ${MediaUtils.formatRelativeDate(video.postedDate)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    if (video.preacher != null &&
                        video.preacher!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              video.preacher!,
                              style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
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
    required this.videoService,
    required this.onPlayRelated,
    this.youtubeController,
  });

  final VideoItem video;
  final YoutubePlayerController? youtubeController;
  final VideoService videoService;
  final Function(VideoItem) onPlayRelated;

  @override
  State<_VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<_VideoPlayerPage> {
  bool _hasLiked = false;
  bool _ytEmbedError = false;

  // For network (MP4) videos
  VideoPlayerController? _vpController;
  ChewieController? _chewieController;

  // For Facebook videos
  WebViewController? _webController;

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
    _initNonYouTubePlayer();

    // Listen for YouTube embedding errors (e.g. error 150/152 = embedding disabled)
    if (widget.youtubeController != null) {
      widget.youtubeController!.listen((state) {
        if (state.error != null && mounted) {
          setState(() => _ytEmbedError = true);
        }
      });
    }
  }

  void _initNonYouTubePlayer() {
    if (widget.video.isNetworkVideo) {
      _vpController = VideoPlayerController.networkUrl(
        Uri.parse(widget.video.videoUrl),
      )..initialize().then((_) {
          _chewieController = ChewieController(
            videoPlayerController: _vpController!,
            autoPlay: true,
            looping: false,
            allowFullScreen: true,
            allowMuting: true,
            placeholder: const Center(child: CircularProgressIndicator()),
          );
          if (mounted) setState(() {});
        });
    } else if (widget.video.isFacebook) {
      // Build Facebook embed URL
      final embedUrl =
          'https://www.facebook.com/plugins/video.php?href=${Uri.encodeComponent(widget.video.videoUrl)}&show_text=0&autoplay=1';
      _webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(embedUrl));
    }
  }

  @override
  void dispose() {
    _vpController?.dispose();
    _chewieController?.dispose();
    super.dispose();
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
      final ref =
          FirebaseFirestore.instance.collection('videos').doc(widget.video.id);
      await ref.update({'likes': FieldValue.increment(1)});
      if (mounted) {
        setState(() => _hasLiked = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks for liking! 👍')),
        );
      }
    } catch (_) {}
  }

  /// Builds the top player area based on video type.
  Widget _buildPlayer() {
    if (widget.video.isYouTube && widget.youtubeController != null) {
      // Show a friendly fallback if embedding is blocked (error 150/151/152)
      if (_ytEmbedError) {
        return AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_circle_outline,
                      color: Colors.white54, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Embedding disabled by uploader.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    icon: const Icon(Icons.open_in_new, color: Colors.white),
                    label: const Text('Open in YouTube',
                        style: TextStyle(color: Colors.white)),
                    onPressed: () async {
                      final uri = Uri.parse(widget.video.videoUrl);
                      if (await canLaunchUrl(uri)) {
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return YoutubePlayer(controller: widget.youtubeController!);
    } else if (widget.video.isFacebook && _webController != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: WebViewWidget(controller: _webController!),
      );
    } else if (widget.video.isNetworkVideo) {
      if (_chewieController != null) {
        return AspectRatio(
          aspectRatio: _vpController!.value.aspectRatio,
          child: Chewie(controller: _chewieController!),
        );
      }
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    // Fallback
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: const Center(
          child:
              Icon(Icons.play_circle_outline, color: Colors.white54, size: 64),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget pageBody = Scaffold(
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
          _buildPlayer(),
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
                    stream: widget.videoService.getVideoViews(widget.video.id),
                    builder: (_, snap) {
                      final views = snap.data ?? widget.video.views;
                      return Text(
                        '${MediaUtils.formatViews(views)} • ${MediaUtils.formatRelativeDate(widget.video.postedDate)}',
                        style: const TextStyle(color: Colors.grey),
                      );
                    },
                  ),
                  if (widget.video.preacher != null &&
                      widget.video.preacher!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          widget.video.preacher!,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87),
                        ),
                      ],
                    ),
                  ],
                  if (widget.video.category != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.video.category!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const Divider(height: 24),
                  // Action row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                            text:
                                '🎬 "${widget.video.title}"\n${widget.video.videoUrl}',
                          ),
                        ),
                      ),
                      _ActionButton(
                        icon: Icons.open_in_new,
                        label: 'Open',
                        onTap: () async {
                          final uri = Uri.parse(widget.video.videoUrl);
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
                          fontSize: 13, height: 1.6, color: Colors.black87),
                    ),
                  ],
                  const Divider(height: 24),

                  // Comments Section
                  _VideoCommentsSection(videoId: widget.video.id),

                  const Divider(height: 24),

                  // Recommended Videos (Same Category)
                  _RecommendedVideosSection(
                    currentVideo: widget.video,
                    onPlay: widget.onPlayRelated,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // Wrap in YoutubePlayerScaffold only for YouTube videos
    if (widget.video.isYouTube && widget.youtubeController != null) {
      return YoutubePlayerScaffold(
        controller: widget.youtubeController!,
        builder: (context, player) {
          // Replace the player with the scaffold-provided one
          return pageBody;
        },
      );
    }
    return pageBody;
  }

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
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverAppBarDelegate({required this.child});

  @override
  double get minExtent => 64.0;
  @override
  double get maxExtent => 64.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return oldDelegate.child != child;
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 22, color: color ?? (onTap == null ? Colors.grey : null)),
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

// ─── Top-level YouTube Helpers ─────────────────────────────────────────────

String? _extractYouTubeId(String url) {
  final regExp = RegExp(
    r'^.*(?:youtu\.be\/|v\/|vi\/|u\/\w\/|embed\/|shorts\/|(?:watch)?\?v(?:i)?=|&v(?:i)?=)([^#&?]+).*',
    caseSensitive: false,
  );
  return regExp.firstMatch(url)?.group(1);
}

String _youtubeThumbnail(String videoId) =>
    'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';

// ─── Comments ──────────────────────────────────────────────────────────────

class _VideoCommentsSection extends StatefulWidget {
  final String videoId;
  const _VideoCommentsSection({required this.videoId});

  @override
  State<_VideoCommentsSection> createState() => _VideoCommentsSectionState();
}

class _VideoCommentsSectionState extends State<_VideoCommentsSection> {
  final _commentCtrl = TextEditingController();
  bool _isPosting = false;

  Future<void> _postComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPosting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? 'Anonymous';

      await FirebaseFirestore.instance
          .collection('videos')
          .doc(widget.videoId)
          .collection('comments')
          .add({
        'text': text,
        'authorName': userName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _commentCtrl.clear();
      FocusScope.of(context).unfocus();
    } catch (_) {}
    if (mounted) setState(() => _isPosting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Comments',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        // Input
        Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFF3F4F6),
              child: Icon(Icons.person, size: 18, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _commentCtrl,
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle: const TextStyle(fontSize: 13),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _isPosting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    icon: Icon(Icons.send,
                        color: Theme.of(context).colorScheme.primary),
                    onPressed: _postComment,
                  ),
          ],
        ),
        const SizedBox(height: 16),
        // List
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('videos')
              .doc(widget.videoId)
              .collection('comments')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData)
              return const Center(child: CircularProgressIndicator());
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No comments yet. Be the first to comment!',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                final text = data['text'] ?? '';
                final authorName = data['authorName'] ?? 'Anonymous';
                final createdAt = data['createdAt'] as Timestamp?;
                final dateStr = createdAt != null
                    ? MediaUtils.formatRelativeDate(createdAt.toDate())
                    : 'Just now';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(0xFFE5E7EB),
                        child: Icon(Icons.person, size: 16, color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(authorName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                const SizedBox(width: 8),
                                Text(dateStr,
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(text, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

// ─── Recommended Videos ──────────────────────────────────────────────────

class _RecommendedVideosSection extends StatelessWidget {
  final VideoItem currentVideo;
  final Function(VideoItem) onPlay;

  const _RecommendedVideosSection(
      {required this.currentVideo, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    if (currentVideo.category == null || currentVideo.category!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('More Like This',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('videos')
                .where('category', isEqualTo: currentVideo.category)
                .limit(10)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snap.hasData) return const SizedBox.shrink();

              // Filter out current video
              final videos = snap.data!.docs
                  .map((doc) => VideoItem.fromFirestore(doc))
                  .where((v) => v.id != currentVideo.id)
                  .toList();

              if (videos.isEmpty) {
                return const Text('No other videos found in this category.',
                    style: TextStyle(color: Colors.grey, fontSize: 13));
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: videos.length,
                itemBuilder: (context, i) {
                  final v = videos[i];
                  final videoId = _extractYouTubeId(v.videoUrl);
                  final thumb = videoId != null
                      ? _youtubeThumbnail(videoId)
                      : v.thumbnailUrl;

                  return GestureDetector(
                    onTap: () => onPlay(v),
                    child: Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 90,
                            width: 160,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[200],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedNetworkImage(
                                  imageUrl: thumb,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) =>
                                      Container(color: Colors.grey[200]),
                                  errorWidget: (_, __, ___) => const Icon(
                                      Icons.video_library,
                                      color: Colors.grey),
                                ),
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                        color:
                                            Colors.black.withValues(alpha: 0.4),
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.play_arrow_rounded,
                                        color: Colors.white, size: 24),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            v.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${MediaUtils.formatViews(v.views)} views',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
