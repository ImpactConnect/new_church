import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../models/live_stream.dart';
import '../services/live_stream_service.dart';
import '../utils/toast_utils.dart';

class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({Key? key}) : super(key: key);

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final LiveStreamService _service = LiveStreamService();
  late final WebViewController _webViewController;

  bool _isFullScreen = false;
  bool _isLoading = true;
  bool _showControls = true;
  String? _currentUrl;
  String _currentPlatform = 'youtube';
  String? _errorMessage;
  String _streamTitle = 'Live Stream';

  Timer? _controlsTimer;
  StreamSubscription<LiveStream?>? _streamSubscription;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  // Looping LIVE badge pulse animation
  late final AnimationController _liveDotController;
  late final Animation<double> _liveDotAnimation;

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

  // ─── WebView Setup ─────────────────────────────────────────────────────────

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..enableZoom(false);

    if (_webViewController.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      (_webViewController.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
  }

  // ─── Stream Listener ───────────────────────────────────────────────────────

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

    setState(() {
      _errorMessage = null;
      _streamTitle = stream.title.isNotEmpty ? stream.title : 'Live Stream';
    });

    final String url = stream.url;
    final String platform = stream.platform.value;

    if (url != _currentUrl) {
      _currentUrl = url;
      _currentPlatform = platform;
      _loadMedia(url, platform: platform);
    }
  }

  // ─── Media Loading ─────────────────────────────────────────────────────────

  void _loadMedia(String url, {String platform = 'youtube'}) {
    // Vimeo / raw HLS → use native video player
    if (platform == 'vimeo' || platform == 'hls') {
      _initializeNativePlayer(url);
      return;
    }

    final String embedUrl = _buildEmbedUrl(url, platform);
    if (embedUrl.isEmpty) {
      setState(() {
        _errorMessage = 'Invalid stream URL.';
        _isLoading = false;
      });
      return;
    }

    final html = _buildPlayerHtml(embedUrl, platform);
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
      ..loadHtmlString(html);
  }

  String _buildEmbedUrl(String url, String platform) {
    if (platform == 'youtube') {
      final videoId = _extractYouTubeId(url);
      if (videoId.isEmpty) return '';
      return 'https://www.youtube.com/embed/$videoId'
          '?autoplay=1&controls=1&rel=0&modestbranding=1&playsinline=1';
    }
    if (platform == 'facebook') {
      return 'https://www.facebook.com/plugins/video.php'
          '?href=${Uri.encodeComponent(url)}&show_text=false&autoplay=true';
    }
    return url;
  }

  String _extractYouTubeId(String url) {
    final regExp = RegExp(
      r'^.*(?:youtu\.be\/|v\/|vi\/|u\/\w\/|embed\/|shorts\/|(?:watch)?\?v(?:i)?=|&v(?:i)?=)([^#&?]+).*',
      caseSensitive: false,
    );
    return regExp.firstMatch(url)?.group(1) ?? '';
  }

  String _buildPlayerHtml(String embedUrl, String platform) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <meta charset="utf-8">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body, html {
      width: 100%; height: 100vh;
      background: #000;
      overflow: hidden;
    }
    iframe {
      position: fixed; top: 0; left: 0;
      width: 100%; height: 100%;
      border: 0;
    }
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

  Future<void> _initializeNativePlayer(String url) async {
    setState(() => _isLoading = true);
    try {
      _videoPlayerController?.dispose();
      _chewieController?.dispose();
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoPlayerController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        isLive: true,
        allowFullScreen: false,
        aspectRatio: 16 / 9,
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

  // ─── Controls ──────────────────────────────────────────────────────────────

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

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.paused) {
      _videoPlayerController?.pause();
      if (_currentPlatform != 'vimeo' && _currentPlatform != 'hls') {
        _webViewController.runJavaScript('''
          try {
            var iframe = document.querySelector('iframe');
            if (iframe && iframe.contentWindow) {
              iframe.contentWindow.postMessage(
                JSON.stringify({event:'command',func:'pauseVideo',args:''}), '*');
            }
          } catch(e) {}
        ''');
      }
    }
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _streamSubscription?.cancel();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _liveDotController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _resetOrientation();
    super.dispose();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isFullScreen,
      onPopInvoked: (didPop) {
        if (!didPop && _isFullScreen) _toggleFullScreen();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // ── Player ──
              if (_errorMessage != null)
                _buildErrorView()
              else
                _buildPlayerView(),

              // ── Loading overlay ──
              if (_isLoading && _errorMessage == null)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),

              // ── Controls overlay ──
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: GestureDetector(
                  onTap: _toggleControls,
                  behavior: HitTestBehavior.translucent,
                  child: Stack(children: [
                    _buildTopBar(),
                    _buildBottomBar(),
                    if (_errorMessage == null) _buildLiveBadge(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerView() {
    return GestureDetector(
      onTap: _toggleControls,
      child: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: (_currentPlatform == 'vimeo' || _currentPlatform == 'hls')
              ? (_chewieController != null
                  ? Chewie(controller: _chewieController!)
                  : const SizedBox.shrink())
              : WebViewWidget(controller: _webViewController),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.live_tv_rounded, size: 64, color: Colors.white38),
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
    );
  }

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
              if (_currentPlatform != 'vimeo' && _currentPlatform != 'hls')
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
