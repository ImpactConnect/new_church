import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/sermon.dart';
import '../screens/full_player_screen.dart';
import '../services/audio_player_service.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({
    Key? key,
    required this.sermon,
    required this.audioPlayerService,
    required this.onClose,
  }) : super(key: key);

  final Sermon sermon;
  final AudioPlayerService audioPlayerService;
  final VoidCallback onClose;

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _speed = 1.0;
  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    _subs.add(widget.audioPlayerService.playingStream.listen((p) {
      if (mounted) setState(() => _isPlaying = p);
    }));
    _subs.add(widget.audioPlayerService.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    }));
    _subs.add(widget.audioPlayerService.durationStream.listen((d) {
      if (mounted) setState(() => _duration = d ?? Duration.zero);
    }));
    _subs.add(widget.audioPlayerService.speedStream.listen((s) {
      if (mounted) setState(() => _speed = s);
    }));
  }

  @override
  void dispose() {
    for (final s in _subs) s.cancel();
    super.dispose();
  }

  void _expandToFullPlayer() {
    final current = widget.audioPlayerService.currentSermon ?? widget.sermon;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: FullPlayerScreen(
            sermon: current,
            audioPlayerService: widget.audioPlayerService,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 350),
        fullscreenDialog: true,
      ),
    );
  }

  String _speedLabel(double s) => s == s.truncate() ? '${s.toInt()}x' : '${s}x';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final sermon = widget.audioPlayerService.currentSermon ?? widget.sermon;
    final maxVal = _duration.inMilliseconds > 0
        ? _duration.inMilliseconds.toDouble()
        : 1.0;

    return GestureDetector(
      onTap: _expandToFullPlayer,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Thin progress bar at very top ──
              LinearProgressIndicator(
                value: maxVal > 0
                    ? (_position.inMilliseconds.toDouble() / maxVal)
                        .clamp(0.0, 1.0)
                    : 0,
                minHeight: 2,
                backgroundColor: colors.primary.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                child: Row(
                  children: [
                    // ── Thumbnail ──
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: sermon.thumbnailUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: sermon.thumbnailUrl,
                              width: 46,
                              height: 46,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                  width: 46,
                                  height: 46,
                                  color: colors.primary.withValues(alpha: 0.12),
                                  child: const Icon(Icons.church,
                                      color: Colors.grey, size: 22)),
                              errorWidget: (_, __, ___) => Container(
                                  width: 46,
                                  height: 46,
                                  color: colors.primary.withValues(alpha: 0.12),
                                  child: const Icon(Icons.church,
                                      color: Colors.grey, size: 22)),
                            )
                          : Container(
                              width: 46,
                              height: 46,
                              color: colors.primary.withValues(alpha: 0.12),
                              child: const Icon(Icons.church,
                                  color: Colors.grey, size: 22)),
                    ),
                    const SizedBox(width: 12),
                    // ── Title + preacher ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sermon.title,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            sermon.preacherName,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // ── Speed chip ──
                    GestureDetector(
                      onTap: () => widget.audioPlayerService.cycleSpeed(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _speedLabel(_speed),
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // ── Seek -10 ──
                    IconButton(
                      icon: const Icon(Icons.replay_10, size: 22),
                      onPressed: () => widget.audioPlayerService
                          .seekBackward(const Duration(seconds: 10)),
                    ),
                    // ── Play / Pause ──
                    IconButton(
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: colors.primary,
                      ),
                      iconSize: 40,
                      onPressed: () {
                        if (_isPlaying) {
                          widget.audioPlayerService.pause();
                        } else {
                          widget.audioPlayerService.resume();
                        }
                      },
                    ),
                    // ── Seek +30 ──
                    IconButton(
                      icon: const Icon(Icons.forward_30, size: 22),
                      onPressed: () => widget.audioPlayerService
                          .seekForward(const Duration(seconds: 30)),
                    ),
                    // ── Close ──
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        widget.onClose();
                        widget.audioPlayerService.stop();
                      },
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
