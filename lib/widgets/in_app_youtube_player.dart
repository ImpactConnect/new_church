import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

// ─── Video ID Extraction Utility ─────────────────────────────────────────────

/// Extracts the exact 11-character YouTube video ID from any YouTube URL
/// format, or returns the input directly if it already looks like a bare ID.
String extractYouTubeVideoId(String input) {
  final clean = input.trim();
  // Already an 11-char bare ID (no slashes)
  if (clean.length == 11 && !clean.contains('/')) return clean;

  final regExp = RegExp(
    r'(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?|shorts)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
    caseSensitive: false,
  );
  final match = regExp.firstMatch(clean);
  return match?.group(1) ?? clean;
}

// ─── InAppYoutubePlayer Widget ────────────────────────────────────────────────

/// A YouTube player widget that plays videos entirely in-app without
/// redirecting to the YouTube app or browser.
///
/// Key properties:
/// - Uses `youtube_player_iframe` with `youtube-nocookie.com` origin to fix
///   Error 150 / 101 iframe rejections.
/// - Wraps the raw `YoutubePlayer` in `AbsorbPointer` to intercept all native
///   YouTube UI touch events (title taps, watermarks, etc.).
/// - Renders a custom app-native overlay with Play/Pause, Rewind 10s,
///   Forward 10s controls.
class InAppYoutubePlayer extends StatefulWidget {
  /// Raw video URL or 11-character video ID.
  final String videoUrl;

  /// Whether to start playing immediately.
  final bool autoPlay;

  const InAppYoutubePlayer({
    super.key,
    required this.videoUrl,
    this.autoPlay = true,
  });

  @override
  State<InAppYoutubePlayer> createState() => _InAppYoutubePlayerState();
}

class _InAppYoutubePlayerState extends State<InAppYoutubePlayer> {
  late final YoutubePlayerController _controller;
  bool _showControls = true;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    final videoId = extractYouTubeVideoId(widget.videoUrl);
    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: widget.autoPlay,
      params: const YoutubePlayerParams(
        showControls: false,         // Disable native YouTube controls & title overlay
        showFullscreenButton: false, // Use app-native orientation controls
        mute: false,
        enableCaption: true,
        // CRITICAL: Fixes Error 150/101 iframe rejection in mobile WebViews
        origin: 'https://www.youtube-nocookie.com',
      ),
    );

    // Track play state from controller
    _controller.listen((state) {
      if (!mounted) return;
      final playing = state.playerState == PlayerState.playing;
      if (playing != _isPlaying) {
        setState(() => _isPlaying = playing);
      }
    });
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerScaffold(
      controller: _controller,
      aspectRatio: 16 / 9,
      builder: (context, player) {
        return GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. AbsorbPointer prevents tapping native YouTube title/watermark
              //    which would otherwise open the YouTube app or browser.
              AbsorbPointer(
                absorbing: true,
                child: player,
              ),

              // 2. Touch shield layer: blocks native touches from reaching YouTube WebView
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.001),
                ),
              ),

              // 3. App-native control overlay
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Container(
                  color: Colors.black45,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Rewind 10s ──────────────────────────────────────
                        IconButton(
                          iconSize: 36,
                          color: Colors.white,
                          icon: const Icon(Icons.replay_10_rounded),
                          onPressed: () async {
                            final current = await _controller.currentTime;
                            _controller.seekTo(
                              seconds: (current - 10).clamp(0, double.infinity),
                            );
                          },
                        ),
                        const SizedBox(width: 16),

                        // ── Play / Pause ────────────────────────────────────
                        IconButton(
                          iconSize: 56,
                          color: Colors.white,
                          icon: Icon(
                            _isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_filled_rounded,
                          ),
                          onPressed: () {
                            if (_isPlaying) {
                              _controller.pauseVideo();
                            } else {
                              _controller.playVideo();
                            }
                          },
                        ),
                        const SizedBox(width: 16),

                        // ── Forward 10s ─────────────────────────────────────
                        IconButton(
                          iconSize: 36,
                          color: Colors.white,
                          icon: const Icon(Icons.forward_10_rounded),
                          onPressed: () async {
                            final current = await _controller.currentTime;
                            final dur = await _controller.duration;
                            _controller.seekTo(
                              seconds: (current + 10).clamp(0, dur),
                            );
                          },
                        ),
                      ],
                    ),
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
