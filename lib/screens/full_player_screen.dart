import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sermon.dart';
import '../services/audio_player_service.dart';
import '../utils/media_utils.dart';

/// Full-screen immersive audio player that expands from the MiniPlayer.
class FullPlayerScreen extends StatefulWidget {
  const FullPlayerScreen({
    Key? key,
    required this.sermon,
    required this.audioPlayerService,
  }) : super(key: key);

  final Sermon sermon;
  final AudioPlayerService audioPlayerService;

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _speed = 1.0;
  bool _showQueue = false;
  final List<StreamSubscription> _subs = [];

  late final AnimationController _albumArtController;
  late final Animation<double> _albumArtAnimation;

  bool _hasLiked = false;
  int _localLikeCount = 0;

  @override
  void initState() {
    super.initState();
    _albumArtController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _albumArtAnimation =
        Tween(begin: 0.0, end: 1.0).animate(_albumArtController);

    _subs.add(widget.audioPlayerService.playingStream.listen((p) {
      if (!mounted) return;
      setState(() => _isPlaying = p);
      if (p) {
        _albumArtController.forward();
      } else {
        _albumArtController.stop();
      }
    }));
    _subs.add(widget.audioPlayerService.positionStream.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    }));
    _subs.add(widget.audioPlayerService.durationStream.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d ?? Duration.zero);
    }));
    _subs.add(widget.audioPlayerService.speedStream.listen((s) {
      if (!mounted) return;
      setState(() => _speed = s);
    }));

    _checkIfLiked();
  }

  Future<void> _checkIfLiked() async {
    final prefs = await SharedPreferences.getInstance();
    final liked = prefs.getStringList('liked_sermons') ?? [];
    if (mounted) {
      setState(() {
        _hasLiked = liked.contains(_currentSermon.id);
      });
    }
  }

  Future<void> _likeSermon() async {
    if (_hasLiked) return;

    final sermonId = _currentSermon.id;
    final prefs = await SharedPreferences.getInstance();
    final liked = prefs.getStringList('liked_sermons') ?? [];
    liked.add(sermonId);
    await prefs.setStringList('liked_sermons', liked);

    if (mounted) {
      setState(() {
        _hasLiked = true;
        _localLikeCount++;
      });
    }

    try {
      await FirebaseFirestore.instance
          .collection('sermons')
          .doc(sermonId)
          .update({'likes': FieldValue.increment(1)});
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final s in _subs) s.cancel();
    _albumArtController.dispose();
    super.dispose();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Sermon get _currentSermon =>
      widget.audioPlayerService.currentSermon ?? widget.sermon;

  String _speedLabel(double speed) =>
      speed == speed.truncate() ? '${speed.toInt()}x' : '${speed}x';

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child:
                  _showQueue ? _buildQueuePanel() : _buildMainContent(colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.white, size: 32),
            tooltip: 'Collapse',
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Now Playing',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.8),
            ),
          ),
          IconButton(
            icon: Icon(
              _showQueue ? Icons.queue_music : Icons.queue_music_outlined,
              color: Colors.white,
            ),
            tooltip: _showQueue ? 'Hide Queue' : 'Show Queue',
            onPressed: () => setState(() => _showQueue = !_showQueue),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(ColorScheme colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // ── Rotating Album Art ──
          _buildAlbumArt(),
          const SizedBox(height: 32),
          // ── Title & Preacher ──
          Text(
            _currentSermon.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentSermon.preacherName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 15,
            ),
          ),
          if (_currentSermon.scriptureReference != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _currentSermon.scriptureReference!,
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (_currentSermon.category.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _currentSermon.category.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
                letterSpacing: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 32),
          // ── Progress ──
          _buildProgressBar(colors),
          const SizedBox(height: 8),
          // ── Controls ──
          _buildControls(colors),
          const SizedBox(height: 16),
          // ── Speed / extras ──
          _buildExtraControls(),
          const SizedBox(height: 20),
          // ── Description ──
          if (_currentSermon.description != null &&
              _currentSermon.description!.isNotEmpty)
            _buildDescription(),
        ],
      ),
    );
  }

  Widget _buildAlbumArt() {
    return AnimatedBuilder(
      animation: _albumArtAnimation,
      builder: (context, child) => Transform.rotate(
        angle: _albumArtAnimation.value * 2 * 3.14159,
        child: child,
      ),
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipOval(
          child: _currentSermon.thumbnailUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: _currentSermon.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _albumArtPlaceholder(),
                  errorWidget: (_, __, ___) => _albumArtPlaceholder(),
                )
              : _albumArtPlaceholder(),
        ),
      ),
    );
  }

  Widget _albumArtPlaceholder() {
    return Container(
      color: const Color(0xFF1E1E2E),
      child: const Icon(Icons.church, color: Colors.white30, size: 80),
    );
  }

  Widget _buildProgressBar(ColorScheme colors) {
    final maxVal = _duration.inMilliseconds > 0
        ? _duration.inMilliseconds.toDouble()
        : 1.0;
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3.5,
            activeTrackColor: colors.primary,
            inactiveTrackColor: Colors.white24,
            thumbColor: colors.primary,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: _position.inMilliseconds.toDouble().clamp(0, maxVal),
            min: 0,
            max: maxVal,
            onChanged: (v) => widget.audioPlayerService
                .seek(Duration(milliseconds: v.toInt())),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(MediaUtils.formatDuration(_position),
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
              Text(MediaUtils.formatDuration(_duration),
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(ColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Previous
        IconButton(
          icon: Icon(Icons.skip_previous_rounded,
              color: widget.audioPlayerService.hasPrevious
                  ? Colors.white
                  : Colors.white30,
              size: 36),
          onPressed: widget.audioPlayerService.hasPrevious
              ? widget.audioPlayerService.playPrevious
              : null,
        ),
        // Seek -10s
        IconButton(
          icon: const Icon(Icons.replay_10_rounded,
              color: Colors.white, size: 32),
          onPressed: () => widget.audioPlayerService
              .seekBackward(const Duration(seconds: 10)),
        ),
        // Play / Pause
        GestureDetector(
          onTap: () {
            if (_isPlaying) {
              widget.audioPlayerService.pause();
            } else {
              widget.audioPlayerService.resume();
            }
          },
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primary,
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
        ),
        // Seek +30s
        IconButton(
          icon: const Icon(Icons.forward_30_rounded,
              color: Colors.white, size: 32),
          onPressed: () => widget.audioPlayerService
              .seekForward(const Duration(seconds: 30)),
        ),
        // Next
        IconButton(
          icon: Icon(Icons.skip_next_rounded,
              color: widget.audioPlayerService.hasNext
                  ? Colors.white
                  : Colors.white30,
              size: 36),
          onPressed: widget.audioPlayerService.hasNext
              ? widget.audioPlayerService.playNext
              : null,
        ),
      ],
    );
  }

  Widget _buildExtraControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Like Button
        GestureDetector(
          onTap: _likeSermon,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _hasLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_outline_rounded,
                  color: _hasLiked ? Colors.redAccent : Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 5),
                Text(
                  '${_currentSermon.likes + _localLikeCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Speed toggle
        GestureDetector(
          onTap: () async {
            await widget.audioPlayerService.cycleSpeed();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.speed_rounded,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 5),
                Text(
                  _speedLabel(_speed),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _currentSermon.description!,
        style:
            const TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
      ),
    );
  }

  // ─── Queue Panel ───────────────────────────────────────────────────────────

  Widget _buildQueuePanel() {
    final playlist = widget.audioPlayerService.playlist;
    final currentId = _currentSermon.id;

    if (playlist.isEmpty) {
      return const Center(
        child:
            Text('No queue available', style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: playlist.length,
      itemBuilder: (context, i) {
        final s = playlist[i];
        final isActive = s.id == currentId;
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CachedNetworkImage(
              imageUrl: s.thumbnailUrl,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(width: 48, height: 48, color: Colors.white10),
              errorWidget: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: Colors.white10,
                  child: const Icon(Icons.music_note,
                      color: Colors.white30, size: 20)),
            ),
          ),
          title: Text(
            s.title,
            style: TextStyle(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            s.preacherName,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          trailing: isActive
              ? Icon(Icons.equalizer_rounded,
                  color: Theme.of(context).colorScheme.primary)
              : null,
          onTap: () =>
              widget.audioPlayerService.playSermonFromPlaylist(s, playlist),
        );
      },
    );
  }
}
