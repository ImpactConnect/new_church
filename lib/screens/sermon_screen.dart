import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sermon.dart';
import '../services/audio_player_service.dart';
import '../services/sermon_service.dart';
import '../widgets/mini_player.dart';
import '../widgets/sermon_card.dart';
import '../widgets/bottom_nav_bar.dart';
import 'album_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sermon_category.dart';

class SermonScreen extends StatefulWidget {
  const SermonScreen({
    Key? key,
    required this.sermonService,
    required this.audioPlayerService,
    this.initialSermonId,
  }) : super(key: key);

  final SermonService sermonService;
  final AudioPlayerService audioPlayerService;
  final String? initialSermonId;

  @override
  State<SermonScreen> createState() => _SermonScreenState();
}

class _SermonScreenState extends State<SermonScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // ── State ──────────────────────────────────────────────────────────────────
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedPreacher;
  String? _selectedTag;

  List<Sermon> _allSermons = [];
  List<String> _categories = [];
  List<String> _preachers = [];
  List<String> _tags = [];
  List<SermonCategory> _fetchedCategories = [];

  // Sermons the user has started but not finished — keyed by sermon id,
  // value is the saved playback position in seconds.
  Map<String, int> _savedPositions = {};
  List<Sermon> _inProgressSermons = [];

  bool _isLoading = true;
  String? _error;

  Sermon? _currentSermon;
  bool _showMiniPlayer = false;

  StreamSubscription? _playerSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSermons();

    // Track currently playing sermon to update mini player + refresh in-progress list
    _playerSub = widget.audioPlayerService.playerStateStream.listen((_) {
      final current = widget.audioPlayerService.currentSermon;
      if (current != null && mounted) {
        setState(() {
          _currentSermon = current;
          _showMiniPlayer = true;
        });
        // Refresh in-progress list a few seconds after playback starts so
        // the just-started sermon appears in Continue Listening
        Future.delayed(const Duration(seconds: 15), () {
          if (mounted) _refreshInProgressSermons();
        });
      }
    });

    if (widget.initialSermonId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playInitialSermon();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _playerSub?.cancel();
    super.dispose();
  }

  // ── Data Loading ───────────────────────────────────────────────────────────

  Future<void> _loadSermons({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final sermons = await widget.sermonService.getSermons();
      await _refreshInProgressSermons(sermons: sermons);
      final snapshot = await FirebaseFirestore.instance
          .collection('sermon_categories')
          .get();
      final fetchedCategories = snapshot.docs
          .map((doc) => SermonCategory.fromFirestore(doc))
          .toList();

      setState(() {
        _allSermons = sermons;
        _fetchedCategories = fetchedCategories;
        _categories = sermons.map((s) => s.category).toSet().toList()..sort();
        _preachers = sermons.map((s) => s.preacherName).toSet().toList()
          ..sort();
        _tags = sermons.expand((s) => s.tags).toSet().toList()..sort();
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!silent) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Reads SharedPreferences and builds the in-progress sermon list.
  /// Pass [sermons] to avoid a second network round-trip during initial load.
  Future<void> _refreshInProgressSermons({List<Sermon>? sermons}) async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    final positionKeys = allKeys.where((k) => k.startsWith('sermon_position_'));

    final positions = <String, int>{};
    for (final key in positionKeys) {
      final id = key.replaceFirst('sermon_position_', '');
      final pos = prefs.getInt(key);
      if (pos != null && pos > 10) {
        positions[id] = pos;
      }
    }

    final source = sermons ?? _allSermons;
    // Keep only sermons present in the fetched list, sort by saved position descending
    final inProgress = source.where((s) => positions.containsKey(s.id)).toList()
      ..sort((a, b) => (positions[b.id] ?? 0).compareTo(positions[a.id] ?? 0));

    if (mounted) {
      setState(() {
        _savedPositions = positions;
        _inProgressSermons = inProgress.take(10).toList();
      });
    }
  }

  // ── Filtering (all done in-memory, single network fetch) ─────────────────

  List<Sermon> get _filteredSermons {
    return _allSermons.where((sermon) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          sermon.title.toLowerCase().contains(q) ||
          sermon.preacherName.toLowerCase().contains(q) ||
          sermon.category.toLowerCase().contains(q) ||
          sermon.tags.any((t) => t.toLowerCase().contains(q)) ||
          (sermon.scriptureReference?.toLowerCase().contains(q) ?? false);

      final matchesPreacher =
          _selectedPreacher == null || sermon.preacherName == _selectedPreacher;
      final matchesCategory =
          _selectedCategory == null || sermon.category == _selectedCategory;
      final matchesTag =
          _selectedTag == null || sermon.tags.contains(_selectedTag);

      return matchesSearch && matchesPreacher && matchesCategory && matchesTag;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = null;
      _selectedPreacher = null;
      _selectedTag = null;
    });
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedCategory != null ||
      _selectedPreacher != null ||
      _selectedTag != null;

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<String?> _showFilterSheet(String title, List<String> items) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: items.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ListTile(
                          title: const Text('All',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          trailing: const Icon(Icons.clear, size: 16),
                          onTap: () => Navigator.pop(context, null),
                        );
                      }
                      final item = items[index - 1];
                      return ListTile(
                        title: Text(item),
                        onTap: () => Navigator.pop(context, item),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _playSermon(Sermon sermon) {
    setState(() {
      _showMiniPlayer = true;
      _currentSermon = sermon;
    });
    widget.audioPlayerService.playSermonFromPlaylist(sermon, _filteredSermons);
  }

  void _closeMiniPlayer() {
    setState(() {
      _showMiniPlayer = false;
      _currentSermon = null;
    });
    widget.audioPlayerService.stop();
  }

  Future<void> _playInitialSermon() async {
    try {
      final sermon =
          await widget.sermonService.getSermonById(widget.initialSermonId!);
      if (sermon != null && mounted) {
        _playSermon(sermon);
      }
    } catch (e) {
      debugPrint('Error playing initial sermon: $e');
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      body: Stack(
        children: [
          RefreshIndicator(
            // Refresh re-fetches data WITHOUT clearing filter state
            onRefresh: () => _loadSermons(silent: false),
            child: NestedScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(child: _buildSearchAndFilters()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.15),
                          ),
                          labelColor: Theme.of(context).colorScheme.primary,
                          labelStyle:
                              const TextStyle(fontWeight: FontWeight.bold),
                          unselectedLabelColor: Colors.grey.shade600,
                          unselectedLabelStyle:
                              const TextStyle(fontWeight: FontWeight.w600),
                          tabs: const [
                            Tab(text: 'All'),
                            Tab(text: 'Albums'),
                            Tab(text: 'Bookmarked'),
                            Tab(text: 'Downloaded'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildError()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildSermonList(null),
                            _buildAlbumList(),
                            _buildSermonList('bookmarked'),
                            _buildSermonList('downloaded'),
                          ],
                        ),
            ),
          ),
          // ── Mini Player ──
          if (_showMiniPlayer && _currentSermon != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayer(
                sermon: _currentSermon!,
                audioPlayerService: widget.audioPlayerService,
                onClose: _closeMiniPlayer,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black),
      flexibleSpace: FlexibleSpaceBar(
        background: Image.asset(
          'assets/images/sermon_hero.jpg',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search sermons…',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search_rounded, color: colors.primary),
                suffixIcon: _hasActiveFilters
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, color: colors.primary),
                        onPressed: _clearFilters,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(height: 16),
          // Filter row
          Row(
            children: [
              const Text('Filter By:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (_hasActiveFilters)
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label:
                      const Text('Clear All', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 0),
                      minimumSize: Size.zero),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Preacher: ${_selectedPreacher ?? 'All'}',
                  selected: _selectedPreacher != null,
                  onTap: () async {
                    final val =
                        await _showFilterSheet('Select Preacher', _preachers);
                    setState(() => _selectedPreacher = val);
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Category: ${_selectedCategory ?? 'All'}',
                  selected: _selectedCategory != null,
                  onTap: () async {
                    final val =
                        await _showFilterSheet('Select Category', _categories);
                    setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Tag: ${_selectedTag ?? 'All'}',
                  selected: _selectedTag != null,
                  onTap: () async {
                    final val = await _showFilterSheet('Select Tag', _tags);
                    setState(() => _selectedTag = val);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      {required String label,
      required bool selected,
      required VoidCallback onTap}) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colors.primary : const Color(0xFFF3F4F6),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  String _getFriendlyErrorMessage(String rawError) {
    final lower = rawError.toLowerCase();
    if (lower.contains('permission-denied') ||
        lower.contains('permission_denied')) {
      return 'Unable to access this content. Please try again later.';
    } else if (lower.contains('unavailable') ||
        lower.contains('network') ||
        lower.contains('failed host lookup') ||
        lower.contains('offline')) {
      return 'Please check your internet connection and try again.';
    } else if (lower.contains('not-found')) {
      return 'The requested content could not be found.';
    }
    return 'An unexpected error occurred. Please try again.';
  }

  Widget _buildError() {
    final friendlyMessage = _error != null
        ? _getFriendlyErrorMessage(_error!)
        : 'An unexpected error occurred.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  size: 48, color: Colors.red),
            ),
            const SizedBox(height: 16),
            const Text(
              'Oops!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              friendlyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSermons,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumList() {
    final Map<String, List<Sermon>> albums = {};
    for (final s in _filteredSermons) {
      final category = s.category.isEmpty ? 'Uncategorized' : s.category;
      albums.putIfAbsent(category, () => []).add(s);
    }
    final sortedCategories = albums.keys.toList()..sort();

    if (sortedCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No albums found',
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: _showMiniPlayer ? 110 : 16,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final sermonsInAlbum = albums[category]!;
        final firstSermon = sermonsInAlbum.first;

        SermonCategory? metaCategory;
        try {
          metaCategory = _fetchedCategories.firstWhere(
              (c) => c.name.toLowerCase() == category.toLowerCase());
        } catch (_) {}

        return _buildAlbumCard(
            category, sermonsInAlbum, firstSermon, metaCategory);
      },
    );
  }

  Widget _buildAlbumCard(String albumName, List<Sermon> sermons,
      Sermon firstSermon, SermonCategory? metaCategory) {
    final colors = Theme.of(context).colorScheme;
    final displayImageUrl =
        metaCategory != null && metaCategory.imageUrl.isNotEmpty
            ? metaCategory.imageUrl
            : firstSermon.thumbnailUrl;
    final displayDescription = metaCategory?.description;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlbumDetailScreen(
              albumName: albumName,
              sermons: sermons,
              audioPlayerService: widget.audioPlayerService,
              sermonService: widget.sermonService,
              coverImageUrl: displayImageUrl,
              description: displayDescription,
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
              color: Colors.black.withValues(alpha: 0.05),
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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    displayImageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: displayImageUrl,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: colors.primary.withValues(alpha: 0.1)),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Row(
                        children: [
                          const Icon(Icons.audiotrack,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${sermons.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    albumName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (displayDescription != null &&
                      displayDescription.isNotEmpty)
                    Text(
                      displayDescription,
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      'Album / Playlist',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSermonList(String? filter) {
    var sermons = _filteredSermons;

    if (filter == 'bookmarked') {
      sermons = sermons.where((s) => s.isBookmarked).toList();
    } else if (filter == 'downloaded') {
      sermons = sermons.where((s) => s.isDownloaded).toList();
    }

    if (sermons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              filter == 'bookmarked'
                  ? Icons.bookmark_border
                  : filter == 'downloaded'
                      ? Icons.download_outlined
                      : Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              filter == 'bookmarked'
                  ? 'No bookmarked sermons'
                  : filter == 'downloaded'
                      ? 'No downloaded sermons'
                      : _hasActiveFilters
                          ? 'No sermons match your filters'
                          : 'No sermons found',
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
            if (_hasActiveFilters && filter == null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        top: 8,
        bottom: _showMiniPlayer ? 110 : 16,
      ),
      itemCount: sermons.length + (filter == null ? 1 : 0),
      itemBuilder: (context, index) {
        // "Continue Listening" header — only in the All tab
        if (filter == null && index == 0) {
          return _buildContinueListeningSection();
        }
        final i = filter == null ? index - 1 : index;
        return SermonCard(
          sermon: sermons[i],
          audioPlayerService: widget.audioPlayerService,
          sermonService: widget.sermonService,
          onTap: () => _playSermon(sermons[i]),
        );
      },
    );
  }

  Widget _buildContinueListeningSection() {
    // Only show if there are in-progress sermons (started but not finished)
    if (_inProgressSermons.isEmpty) return const SizedBox.shrink();

    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.history_rounded, size: 16, color: primary),
              ),
              const SizedBox(width: 8),
              const Text(
                'Continue Listening',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // ── Horizontal card list ──
        SizedBox(
          height: 172,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16, right: 8),
            itemCount: _inProgressSermons.length,
            itemBuilder: (context, index) {
              final s = _inProgressSermons[index];
              return _buildContinueCard(s, primary);
            },
          ),
        ),

        // ── Divider + All Sermons label ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              Expanded(
                  child: Divider(color: Colors.grey.withValues(alpha: 0.3))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'ALL SERMONS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: Colors.grey,
                  ),
                ),
              ),
              Expanded(
                  child: Divider(color: Colors.grey.withValues(alpha: 0.3))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContinueCard(Sermon s, Color primary) {
    return GestureDetector(
      onTap: () => _playSermon(s),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 14, bottom: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Background thumbnail ──
              s.thumbnailUrl.isNotEmpty
                  ? Image.network(
                      s.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _cardPlaceholder(primary),
                    )
                  : _cardPlaceholder(primary),

              // ── Gradient overlay ──
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),

              // ── Category pill (top-left) ──
              if (s.category.isNotEmpty)
                Positioned(
                  top: 10,
                  left: 10,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        color: Colors.black.withValues(alpha: 0.3),
                        child: Text(
                          s.category,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Play button (top-right) ──
              Positioned(
                top: 8,
                right: 8,
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Container(
                      width: 32,
                      height: 32,
                      color: Colors.white.withValues(alpha: 0.2),
                      child: const Icon(Icons.play_arrow_rounded,
                          size: 20, color: Colors.white),
                    ),
                  ),
                ),
              ),

              // ── Title + preacher (bottom) ──
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.preacherName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _cardPlaceholder(Color primary) {
    return Container(
      color: primary.withValues(alpha: 0.15),
      child: Icon(Icons.church_rounded,
          color: primary.withValues(alpha: 0.4), size: 40),
    );
  }
}
