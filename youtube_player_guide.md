# 🎥 In-App YouTube Video Playback Implementation & Troubleshooting Guide

This guide details the tech stack, core architecture, and troubleshooting procedures for embedding YouTube videos in Flutter applications without external redirects or "Watch on YouTube" error screens.

---

## 1. 🛠️ Tech Stack & Packages

In your Flutter project `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  youtube_player_iframe: ^5.2.1
  webview_flutter: ^4.10.0
```

---

## 2. 🚨 Common Causes for "Watch on YouTube" & Error 150 / 101

When an embedded YouTube video refuses to play and shows the **"Watch on YouTube"** / **"Playback on other websites has been disabled by the video owner"** error screen, it is typically caused by:

1. **Missing `origin` Parameter**: YouTube iFrame API rejects requests from mobile WebViews (`file://` or `about:blank`) without a valid web domain origin.
2. **"Allow Embedding" Disabled in YouTube Studio**: The video owner unchecked embedding permissions for that specific video.
3. **Invalid Video ID**: Passing a full URL string (e.g., `https://www.youtube.com/watch?v=xyz123`) instead of the required 11-character Video ID (`xyz123`).
4. **Native Controls Active**: Native YouTube web player title overlays and watermarks remain clickable, redirecting users out of the mobile app when tapped.

---

## 3. 🏗️ Architecture & Core Code Implementation

### A. Video ID Extraction Utility

Extract the exact 11-character YouTube video ID regardless of input format:

```dart
String extractYouTubeId(String input) {
  final clean = input.trim();
  if (clean.length == 11 && !clean.contains('/')) return clean;

  final regExp = RegExp(
    r'(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
    caseSensitive: false,
  );
  final match = regExp.firstMatch(clean);
  return match?.group(1) ?? clean;
}
```

---

### B. Controller Initialization with Required Origin

Initialize `YoutubePlayerController` with `youtube-nocookie.com` origin and disabled native controls:

```dart
final videoId = extractYouTubeId(rawVideoId);

final controller = YoutubePlayerController.fromVideoId(
  videoId: videoId,
  autoPlay: true,
  params: const YoutubePlayerParams(
    showControls: false,          // Disables native YouTube controls & titles
    showFullscreenButton: false,  // Uses app-native orientation controls
    origin: 'https://www.youtube-nocookie.com', // CRITICAL: Fixes Error 150/101 iframe rejection
  ),
);
```

---

### C. Touch Absorption Layer (`AbsorbPointer`) & Custom App Overlay

Wrap the raw `YoutubePlayer` widget inside `AbsorbPointer(absorbing: true)` to intercept all touch events, and render app-native Flutter controls over it:

```dart
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class InAppYoutubePlayer extends StatefulWidget {
  final YoutubePlayerController controller;

  const InAppYoutubePlayer({
    super.key,
    required this.controller,
  });

  @override
  State<InAppYoutubePlayer> createState() => _InAppYoutubePlayerState();
}

class _InAppYoutubePlayerState extends State<InAppYoutubePlayer> {
  bool _showControls = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. AbsorbPointer blocks touch events from reaching YouTube native UI
          // (prevents clicking title/watermark to leave app)
          AbsorbPointer(
            absorbing: true,
            child: YoutubePlayer(
              controller: widget.controller,
              aspectRatio: 16 / 9,
            ),
          ),

          // 2. App-Native Control Overlay
          if (_showControls)
            Container(
              color: Colors.black45,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Rewind 10s
                    IconButton(
                      iconSize: 36,
                      color: Colors.white,
                      icon: const Icon(Icons.replay_10_rounded),
                      onPressed: () async {
                        final current = await widget.controller.currentTime;
                        widget.controller.seekTo(
                          seconds: (current - 10).clamp(0, double.infinity),
                        );
                      },
                    ),
                    const SizedBox(width: 20),

                    // Play / Pause Toggle
                    IconButton(
                      iconSize: 56,
                      color: Colors.white,
                      icon: const Icon(Icons.pause_circle_filled_rounded),
                      onPressed: () => widget.controller.pauseVideo(),
                    ),
                    const SizedBox(width: 20),

                    // Forward 10s
                    IconButton(
                      iconSize: 36,
                      color: Colors.white,
                      icon: const Icon(Icons.forward_10_rounded),
                      onPressed: () async {
                        final current = await widget.controller.currentTime;
                        final dur = await widget.controller.duration;
                        widget.controller.seekTo(
                          seconds: (current + 10).clamp(0, dur),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

---

## 4. 📋 Developer Troubleshooting Matrix

| Issue | Cause | Resolution |
| :--- | :--- | :--- |
| **"Video unavailable / Watch on YouTube"** | YouTube Studio embedding policy | Go to **YouTube Studio** $\rightarrow$ **Video Details** $\rightarrow$ **Show More** $\rightarrow$ Enable **"Allow embedding"**. |
| **Error 150 or 101 in Console** | Unspecified HTTP origin header | Supply `origin: 'https://www.youtube-nocookie.com'` in `YoutubePlayerParams`. |
| **Tapping title opens YouTube browser/app** | Native YouTube webview touches unhandled | Enclose `YoutubePlayer` within `AbsorbPointer(absorbing: true)`. |
| **Blank player / Black screen** | Invalid raw URL string passed | Sanitize input using the `extractYouTubeId` regex helper before passing to controller. |
