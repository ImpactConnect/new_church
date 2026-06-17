import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/sermon.dart';
import '../screens/full_player_screen.dart';
import '../services/audio_player_service.dart';
import '../utils/media_utils.dart';

/// Compact bottom-sheet audio player.
/// All subscriptions are properly tracked and cancelled on dispose.
class AudioPlayerBottomSheet extends StatefulWidget {
  const AudioPlayerBottomSheet({
    Key? key,
    required this.sermon,
    required this.audioPlayerService,
    required this.onClose,
  }) : super(key: key);

  final Sermon sermon;
  final AudioPlayerService audioPlayerService;
  final VoidCallback onClose;

  @override
  State<AudioPlayerBottomSheet> createState() =>
      _AudioPlayerBottomSheetState();
}

class _AudioPlayerBottomSheetState extends State<AudioPlayerBottomSheet> {
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
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: FullPlayerScreen(
            sermon: widget.sermon,
            audioPlayerService: widget.audioPlayerService,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 350),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maxVal =
        _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Info row
          GestureDetector(
            onTap: _expandToFullPlayer,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: widget.sermon.thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.sermon.thumbnailUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                              width: 56,
                              height: 56,
                              color: colors.primary.withOpacity(0.1)),
                          errorWidget: (_, __, ___) => Container(
                              width: 56,
                              height: 56,
                              color: colors.primary.withOpacity(0.1),
                              child: const Icon(Icons.church)),
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          color: colors.primary.withOpacity(0.1),
                          child: const Icon(Icons.church)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.sermon.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.sermon.preacherName,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.keyboard_arrow_up_rounded,
                    color: Colors.grey),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 14),
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
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(MediaUtils.formatDuration(_duration),
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Speed
              GestureDetector(
                onTap: () => widget.audioPlayerService.cycleSpeed(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _speed == _speed.truncate()
                        ? '${_speed.toInt()}x'
                        : '${_speed}x',
                    style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.replay_10_rounded),
                onPressed: () => widget.audioPlayerService
                    .seekBackward(const Duration(seconds: 10)),
              ),
              IconButton(
                icon: Icon(
                  _isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: colors.primary,
                ),
                iconSize: 52,
                onPressed: () {
                  if (_isPlaying) {
                    widget.audioPlayerService.pause();
                  } else {
                    widget.audioPlayerService.resume();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.forward_30_rounded),
                onPressed: () => widget.audioPlayerService
                    .seekForward(const Duration(seconds: 30)),
              ),
              // Expand icon
              IconButton(
                icon: const Icon(Icons.open_in_full_rounded, size: 20),
                tooltip: 'Full Player',
                onPressed: _expandToFullPlayer,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
