import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../models/live_stream.dart';
import '../services/live_stream_service.dart';
import '../utils/toast_utils.dart';
import '../widgets/in_app_youtube_player.dart';

// ─── Sync State ────────────────────────────────────────────────────────────────

/// Three possible states for a synchronized scheduled stream.
enum _SyncState {
  /// Stream has not started yet — show countdown.
  countdown,

  /// Stream is active — play video from the sync-offset position.
  playing,

  /// Stream has ended — show "Over" screen with re-watch option.
  ended,
}

// ─── LiveStreamScreen ──────────────────────────────────────────────────────────

class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({Key? key}) : super(key: key);

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final LiveStreamService _service = LiveStreamService();

  // ── YouTube ──────────────────────────────────────────────────────────────────
  YoutubePlayerController? _ytController;

  // ── WebView (Facebook / other embeds) ───────────────────────────────────────
  late final WebViewController _webViewController;

  // ── Native video (Vimeo / HLS / Firebase MP4) ───────────────────────────────
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  // ── Stream state ─────────────────────────────────────────────────────────────
  bool _isFullScreen = false;
  bool _isLoading = true;
  bool _showControls = true;
  bool _isPlaying = true;
  String? _currentUrl;
  String _currentPlatform = 'youtube';
  String? _errorMessage;
  String _streamTitle = 'Live Stream';

  // ── Sync state ───────────────────────────────────────────────────────────────
  LiveStream? _currentStream;
  _SyncState _syncState = _SyncState.playing;
  Timer? _countdownTimer;
  Duration _countdownRemaining = Duration.zero;

  // ── Timers & subscriptions ───────────────────────────────────────────────────
  Timer? _controlsTimer;
  StreamSubscription<LiveStream?>? _streamSubscription;

  // ── LIVE badge animation ─────────────────────────────────────────────────────
  late final AnimationController _liveDotController;
  late final Animation<double> _liveDotAnimation;

  // ── Seeking banner ───────────────────────────────────────────────────────────
  bool _showSeekingBanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _liveDotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _liveDotAnimation =
        Tween<double>(begin: 0.3, end: 1.0).animate(_liveDotController);
    _initializeWebView();
    _startListening();
  }

  // ─── WebView Setup ────────────────────────────────────────────────────────────

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..enableZoom(false);
  }

  // ─── Stream Listener ──────────────────────────────────────────────────────────

  void _startListening() {
    _streamSubscription =
        _service.watchCurrentLiveStream().listen(_onStreamUpdate, onError: (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to connect to live stream service.';
        _isLoading = false;
      });
    });
  }

  void _onStreamUpdate(LiveStream? stream) {
    if (!mounted) return;

    if (stream == null) {
      setState(() {
        _errorMessage = 'No live stream available at the moment.';
        _isLoading = false;
      });
      return;
    }

    _currentStream = stream;

    setState(() {
      _errorMessage = null;
      _streamTitle = stream.title.isNotEmpty ? stream.title : 'Live Stream';
    });

    // Determine sync state and handle accordingly
    if (stream.isSynchronized) {
      _handleSynchronizedStream(stream);
    } else {
      // Non-synchronized: play immediately as before
      _syncState = _SyncState.playing;
      _loadMediaIfNew(stream.url, stream.platform.value);
    }
  }

  // ─── Synchronized Stream Logic ────────────────────────────────────────────────

  void _handleSynchronizedStream(LiveStream stream) {
    _countdownTimer?.cancel();

    if (stream.hasEnded) {
      // Stream is over
      setState(() {
        _syncState = _SyncState.ended;
        _isLoading = false;
      });
      _releaseMediaControllers();
      return;
    }

    if (!stream.hasStarted) {
      // Stream hasn't started yet — show countdown
      setState(() {
        _syncState = _SyncState.countdown;
        _isLoading = false;
      });
      _releaseMediaControllers();
      _startCountdown(stream);
      return;
    }

    // Stream is in playing range — load media and seek to offset
    setState(() => _syncState = _SyncState.playing);
    _loadMediaIfNew(stream.url, stream.platform.value,
        seekOffsetSeconds: stream.syncSeekOffsetSeconds);
  }

  void _startCountdown(LiveStream stream) {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining =
          stream.effectiveVideoStart.difference(DateTime.now());

      if (remaining.isNegative || remaining.inSeconds <= 0) {
        // Time's up — switch to playing
        _countdownTimer?.cancel();
        _handleSynchronizedStream(stream);
        return;
      }

      setState(() => _countdownRemaining = remaining);
    });

    // Set initial value immediately
    setState(() {
      _countdownRemaining =
          stream.effectiveVideoStart.difference(DateTime.now());
    });
  }

  // ─── Media Loading ────────────────────────────────────────────────────────────

  void _loadMediaIfNew(String url, String platform,
      {int seekOffsetSeconds = 0}) {
    if (url == _currentUrl) {
      // URL hasn't changed — just seek if needed
      if (seekOffsetSeconds > 0) _seekToOffset(seekOffsetSeconds);
      return;
    }
    _currentUrl = url;
    _currentPlatform = platform;
    _loadMedia(url, platform: platform, seekOffsetSeconds: seekOffsetSeconds);
  }

  void _loadMedia(String url,
      {String platform = 'youtube', int seekOffsetSeconds = 0}) {
    // Vimeo / raw HLS / Firebase MP4 → native video player
    if (platform == 'vimeo' || platform == 'hls' || platform == 'firebase') {
      _initializeNativePlayer(url, seekOffsetSeconds: seekOffsetSeconds);
      return;
    }

    // YouTube → InAppYoutubePlayer with nocookie origin
    if (platform == 'youtube') {
      final videoId = extractYouTubeVideoId(url);
      if (videoId.isEmpty) {
        setState(() {
          _errorMessage = 'Invalid YouTube URL.';
          _isLoading = false;
        });
        return;
      }
      _ytController?.close();
      _ytController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: true,
        startSeconds: seekOffsetSeconds.toDouble(),
        params: const YoutubePlayerParams(
          showControls: false,
          showFullscreenButton: false,
          mute: false,
          enableCaption: false,
          // CRITICAL: Fixes Error 150/101 iframe rejection
          origin: 'https://www.youtube-nocookie.com',
        ),
      );
      _ytController!.listen((state) {
        if (!mounted) return;
        final playing = state.playerState == PlayerState.playing;
        if (playing != _isPlaying) {
          setState(() => _isPlaying = playing);
        }
      });
      if (seekOffsetSeconds > 0) {
        _showSeekingBannerBriefly();
      }
      setState(() => _isLoading = false);
      return;
    }

    // Facebook & others → embed via WebView
    final String embedUrl = _buildEmbedUrl(url, platform);
    if (embedUrl.isEmpty) {
      setState(() {
        _errorMessage = 'Invalid stream URL.';
        _isLoading = false;
      });
      return;
    }

    final html = _buildPlayerHtml(embedUrl);
    _webViewController
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _isLoading = true);
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _isLoading = false);
        },
        onWebResourceError: (error) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Error loading stream.';
              _isLoading = false;
            });
          }
        },
      ))
      ..loadHtmlString(html, baseUrl: 'https://www.youtube.com');
  }

  // Seek an already-loaded player to an offset (used when URL hasn't changed).
  void _seekToOffset(int seconds) {
    if (_currentPlatform == 'youtube' && _ytController != null) {
      _ytController!.seekTo(seconds: seconds.toDouble());
    } else if (_videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized) {
      _videoPlayerController!.seekTo(Duration(seconds: seconds));
    }
  }

  void _showSeekingBannerBriefly() {
    setState(() => _showSeekingBanner = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSeekingBanner = false);
    });
  }

  String _buildEmbedUrl(String url, String platform) {
    if (platform == 'facebook') {
      return 'https://www.facebook.com/plugins/video.php'
          '?href=${Uri.encodeComponent(url)}&show_text=false&autoplay=true';
    }
    return url;
  }

  String _buildPlayerHtml(String embedUrl) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <meta charset="utf-8">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body, html { width: 100%; height: 100vh; background: #000; overflow: hidden; }
    iframe { position: fixed; top: 0; left: 0; width: 100%; height: 100%; border: 0; }
  </style>
</head>
<body>
  <iframe
    src="$embedUrl"
    frameborder="0"
    allowfullscreen="true"
    webkitallowfullscreen="true"
    mozallowfullscreen="true"
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture">
  </iframe>
</body>
</html>''';
  }

  Future<void> _initializeNativePlayer(String url,
      {int seekOffsetSeconds = 0}) async {
    setState(() => _isLoading = true);
    try {
      _videoPlayerController?.dispose();
      _chewieController?.dispose();
      _videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoPlayerController!.initialize();
      _videoPlayerController!.addListener(() {
        if (!mounted) return;
        final playing = _videoPlayerController!.value.isPlaying;
        if (playing != _isPlaying) {
          setState(() => _isPlaying = playing);
        }
      });

      // Seek to sync offset immediately after init
      if (seekOffsetSeconds > 0) {
        await _videoPlayerController!
            .seekTo(Duration(seconds: seekOffsetSeconds));
        _showSeekingBannerBriefly();
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        isLive: false, // False so the progress bar appears for seeking
        allowFullScreen: false,
        aspectRatio: 16 / 9,
        startAt: Duration(seconds: seekOffsetSeconds),
        errorBuilder: (context, message) => Center(
          child: Text(message, style: const TextStyle(color: Colors.white)),
        ),
      );
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading stream. Please retry.';
          _isLoading = false;
        });
      }
    }
  }

  void _releaseMediaControllers() {
    _ytController?.close();
    _ytController = null;
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
    _chewieController?.dispose();
    _chewieController = null;
    _currentUrl = null;
  }

  // ─── Controls ─────────────────────────────────────────────────────────────────

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startControlsTimer();
  }

  void _toggleFullScreen() {
    setState(() => _isFullScreen = !_isFullScreen);
    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      _resetOrientation();
    }
  }

  void _resetOrientation() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _retryStream() {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
      _currentUrl = null;
    });
    _streamSubscription?.cancel();
    _startListening();
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.paused) {
      _videoPlayerController?.pause();
      _ytController?.pauseVideo();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _controlsTimer?.cancel();
    _streamSubscription?.cancel();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _ytController?.close();
    _liveDotController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _resetOrientation();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isFullScreen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isFullScreen) _toggleFullScreen();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    // Error state (no stream / connection error)
    if (_errorMessage != null) {
      return _buildErrorView();
    }

    // Loading initial data
    if (_isLoading && _currentStream == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // Synchronized states
    if (_currentStream != null && _currentStream!.isSynchronized) {
      switch (_syncState) {
        case _SyncState.countdown:
          return _buildCountdownView();
        case _SyncState.ended:
          return _buildEndedView();
        case _SyncState.playing:
          break; // fall through to player
      }
    }

    return _buildPlayerStack();
  }

  Widget _buildPlayerStack() {
    return GestureDetector(
      onTap: _toggleControls,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          // ── Player ────────────────────────────────────────────────────────────
          _buildPlayerView(),

          // ── Loading overlay ───────────────────────────────────────────────────
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // ── "Seeking to current position" banner ──────────────────────────────
          if (_showSeekingBanner)
            Positioned(
              top: 72,
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Joining live — seeking to current position…',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Always-visible overlays (Service Title & LIVE badge) ──────────────
          _buildTopBar(),
          _buildLiveBadge(),

          // ── Toggleable controls overlay (Center play/pause & Bottom bar) ──────
          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Stack(children: [
              _buildCenterControls(),
              _buildBottomBar(),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerView() {
    // YouTube: InAppYoutubePlayer with nocookie origin + AbsorbPointer
    if (_currentPlatform == 'youtube' && _ytController != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: YoutubePlayerScaffold(
            controller: _ytController!,
            aspectRatio: 16 / 9,
            builder: (context, player) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  AbsorbPointer(
                    absorbing: true,
                    child: player,
                  ),
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.001),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    // Vimeo / HLS / Firebase MP4: native Chewie player
    if (_currentPlatform == 'vimeo' ||
        _currentPlatform == 'hls' ||
        _currentPlatform == 'firebase') {
      return GestureDetector(
        onTap: _toggleControls,
        child: Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: _chewieController != null
                ? Chewie(controller: _chewieController!)
                : const SizedBox.shrink(),
          ),
        ),
      );
    }

    // Facebook & others: WebView embed
    return GestureDetector(
      onTap: _toggleControls,
      child: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: WebViewWidget(controller: _webViewController),
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    if (_currentPlatform != 'youtube' &&
        _currentPlatform != 'vimeo' &&
        _currentPlatform != 'hls' &&
        _currentPlatform != 'firebase') {
      return const SizedBox.shrink();
    }

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentStream?.isSynchronized == true) ...[
            IconButton(
              iconSize: 36,
              color: Colors.white,
              icon: const Icon(Icons.replay_10_rounded),
              onPressed: () async {
                if (_currentPlatform == 'youtube' && _ytController != null) {
                  final current = await _ytController!.currentTime;
                  _ytController!.seekTo(
                      seconds: (current - 10).clamp(0, double.infinity));
                } else if (_videoPlayerController != null) {
                  final current = _videoPlayerController!.value.position;
                  _videoPlayerController!
                      .seekTo(current - const Duration(seconds: 10));
                }
              },
            ),
            const SizedBox(width: 20),
          ],
          IconButton(
            iconSize: 64,
            color: Colors.white,
            icon: Icon(
              _isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_filled_rounded,
            ),
            onPressed: () {
              if (_currentPlatform == 'youtube' && _ytController != null) {
                if (_isPlaying) {
                  _ytController!.pauseVideo();
                } else {
                  _ytController!.playVideo();
                }
              } else if (_videoPlayerController != null) {
                if (_isPlaying) {
                  _videoPlayerController!.pause();
                } else {
                  _videoPlayerController!.play();
                }
              }
            },
          ),
          if (_currentStream?.isSynchronized == true) ...[
            const SizedBox(width: 20),
            IconButton(
              iconSize: 36,
              color: Colors.white,
              icon: const Icon(Icons.forward_10_rounded),
              onPressed: () async {
                if (_currentPlatform == 'youtube' && _ytController != null) {
                  final current = await _ytController!.currentTime;
                  final dur = await _ytController!.duration;
                  _ytController!.seekTo(seconds: (current + 10).clamp(0, dur));
                } else if (_videoPlayerController != null) {
                  final current = _videoPlayerController!.value.position;
                  _videoPlayerController!
                      .seekTo(current + const Duration(seconds: 10));
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  // ─── Countdown View ───────────────────────────────────────────────────────────

  Widget _buildCountdownView() {
    final h = _countdownRemaining.inHours;
    final m = _countdownRemaining.inMinutes.remainder(60);
    final s = _countdownRemaining.inSeconds.remainder(60);

    final timeStr = h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Stack(
      children: [
        // Background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0D1B2A), Color(0xFF1B2838)],
            ),
          ),
        ),
        // Back button
        Positioned(
          top: 8,
          left: 4,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        // Content
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Church icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3), width: 2),
                  ),
                  child: const Icon(Icons.church_rounded,
                      color: Colors.white, size: 44),
                ),
                const SizedBox(height: 28),
                Text(
                  _streamTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Starts in',
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
                const SizedBox(height: 20),
                // Countdown digits
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    timeStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'We\'ll start automatically when the service begins.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Ended View ───────────────────────────────────────────────────────────────

  Widget _buildEndedView() {
    return Stack(
      children: [
        // Background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0D0D0D), Color(0xFF1A1A2E)],
            ),
          ),
        ),
        // Back button
        Positioned(
          top: 8,
          left: 4,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        // Content
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ended icon
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.stop_circle_outlined,
                      color: Colors.white60, size: 52),
                ),
                const SizedBox(height: 28),
                Text(
                  _streamTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Service is over.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                // Re-watch button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text(
                      'Re-Watch in Video Section',
                      style: TextStyle(fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      // Navigate back and then push the Videos screen
                      Navigator.of(context)
                          .popUntil((route) => route.isFirst);
                      Navigator.of(context).pushNamed('/videos');
                    },
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back',
                      style: TextStyle(color: Colors.white54)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Error View ───────────────────────────────────────────────────────────────

  Widget _buildErrorView() {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.live_tv_rounded,
                    size: 64, color: Colors.white38),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _retryStream,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 8,
          left: 4,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  // ─── Top / Bottom bars ────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (!_isFullScreen)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    _streamTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_currentPlatform != 'vimeo' &&
                  _currentPlatform != 'hls' &&
                  _currentPlatform != 'firebase')
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () {
                    _webViewController.reload();
                    ToastUtils.showToast('Refreshing stream...');
                  },
                ),
              IconButton(
                icon: Icon(
                  _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                ),
                onPressed: _toggleFullScreen,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Positioned(
      top: 60,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _liveDotAnimation,
              builder: (_, __) => Opacity(
                opacity: _liveDotAnimation.value,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
