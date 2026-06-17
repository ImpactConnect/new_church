import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sermon.dart';
import '../services/audio_player_service.dart';
import '../services/sermon_service.dart';
import '../widgets/mini_player.dart';
import '../widgets/sermon_card.dart';
import '../widgets/bottom_nav_bar.dart';

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
    _tabController = TabController(length: 3, vsync: this);
    _loadSermons();

    // Track currently playing sermon to update mini player + refresh in-progress list
    _playerSub =
        widget.audioPlayerService.playerStateStream.listen((_) {
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
      setState(() {
        _allSermons = sermons;
        _categories = sermons.map((s) => s.category).toSet().toList()..sort();
        _preachers =
            sermons.map((s) => s.preacherName).toSet().toList()..sort();
        _tags =
            sermons.expand((s) => s.tags).toSet().toList()..sort();
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
    final inProgress = source
        .where((s) => positions.containsKey(s.id))
        .toList()
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
                              style:
                                  TextStyle(fontWeight: FontWeight.bold)),
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
    widget.audioPlayerService
        .playSermonFromPlaylist(sermon, _filteredSermons);
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
      final sermon = await widget.sermonService
          .getSermonById(widget.initialSermonId!);
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
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: Colors.grey,
                      tabs: const [
                        Tab(text: 'All'),
                        Tab(text: 'Bookmarked'),
                        Tab(text: 'Downloaded'),
                      ],
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
      expandedHeight: 200,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Sermons'),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/sermon_hero.jpg',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search sermons…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _hasActiveFilters
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearFilters,
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
          const SizedBox(height: 12),
          // Filter row
          Row(
            children: [
              const Text('Filter By:',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (_hasActiveFilters)
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear All',
                      style: TextStyle(fontSize: 12)),
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
                    final val = await _showFilterSheet(
                        'Select Category', _categories);
                    setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Tag: ${_selectedTag ?? 'All'}',
                  selected: _selectedTag != null,
                  onTap: () async {
                    final val =
                        await _showFilterSheet('Select Tag', _tags);
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
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? colors.primary.withOpacity(0.15)
              : colors.surface,
          border: Border.all(
            color: selected ? colors.primary : Colors.grey.withOpacity(0.4),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? colors.primary : null,
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(_error!),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSermons,
            child: const Text('Retry'),
          ),
        ],
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
              style:
                  TextStyle(fontSize: 15, color: Colors.grey[600]),
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
                  color: primary.withOpacity(0.12),
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
              Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
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
              Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
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
        width: 155,
        margin: const EdgeInsets.only(right: 12, bottom: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
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
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),

              // ── Category pill (top-left) ──
              if (s.category.isNotEmpty)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
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

              // ── Play button (top-right) ──
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.play_arrow_rounded,
                      size: 18, color: primary),
                ),
              ),

              // ── Title + preacher (bottom) ──
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
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
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.preacherName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 10,
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
      color: primary.withOpacity(0.15),
      child: Icon(Icons.church_rounded, color: primary.withOpacity(0.4), size: 40),
    );
  }
}
