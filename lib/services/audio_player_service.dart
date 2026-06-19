import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../models/sermon.dart';

/// Singleton audio player service that handles:
/// - Any audio format supported by just_audio (MP3, M4A, AAC, OGG, FLAC,
///   WAV, Opus, AIFF, WebM, etc.)
/// - Network streams (via LockCachingAudioSource for progressive caching)
/// - Local downloaded files (via AudioSource.file, bypasses network entirely)
/// - Playlist navigation, speed control, and position persistence
class AudioPlayerService {
  factory AudioPlayerService() => _instance;

  AudioPlayerService._internal() {
    _initPositionListener();
  }

  static final AudioPlayerService _instance = AudioPlayerService._internal();

  AudioPlayer? _player;
  List<Sermon> _playlist = [];
  int _currentIndex = -1;
  Sermon? _currentSermon;

  // ─── Speed ─────────────────────────────────────────────────────────────────
  static const List<double> speedOptions = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  double _currentSpeed = 1.0;
  double get currentSpeed => _currentSpeed;

  // ─── Player Accessor ────────────────────────────────────────────────────────
  AudioPlayer get player {
    _player ??= AudioPlayer();
    return _player!;
  }

  // ─── Position Persistence ──────────────────────────────────────────────────
  void _initPositionListener() {
    player.positionStream.listen((position) async {
      if (_currentSermon != null) {
        final prefs = await SharedPreferences.getInstance();
        if (position.inSeconds > 10) {
          await prefs.setInt(
              'sermon_position_${_currentSermon!.id}', position.inSeconds);
        }
        final duration = player.duration;
        if (duration != null &&
            (duration.inSeconds - position.inSeconds < 10)) {
          await prefs.remove('sermon_position_${_currentSermon!.id}');
        }
      }
    });
  }

  // ─── Getters / Streams ─────────────────────────────────────────────────────
  Sermon? get currentSermon =>
      _currentIndex >= 0 && _currentIndex < _playlist.length
          ? _playlist[_currentIndex]
          : _currentSermon;

  Stream<PlayerState> get playerStateStream => player.playerStateStream;
  Stream<Duration> get positionStream => player.positionStream;
  Stream<Duration?> get durationStream => player.durationStream;
  Stream<bool> get playingStream => player.playingStream;
  Stream<double> get speedStream => player.speedStream;

  bool get hasNext =>
      _playlist.isNotEmpty && _currentIndex < _playlist.length - 1;
  bool get hasPrevious => _playlist.isNotEmpty && _currentIndex > 0;
  List<Sermon> get playlist => List.unmodifiable(_playlist);

  bool isPlaying(String sermonId) =>
      _currentSermon?.id == sermonId && player.playing;

  // ─── Playback ──────────────────────────────────────────────────────────────

  Future<void> playSermon(Sermon sermon) async {
    if (_currentSermon?.id != sermon.id) {
      _currentSermon = sermon;
      await player.stop();

      try {
        final mediaItem = MediaItem(
          id: sermon.id,
          album: sermon.category.isNotEmpty ? sermon.category : 'Sermons',
          title: sermon.title,
          artist: sermon.preacherName,
          artUri: sermon.thumbnailUrl.isNotEmpty
              ? Uri.parse(sermon.thumbnailUrl)
              : null,
          duration: sermon.duration,
          extras: {
            if (sermon.scriptureReference != null)
              'scripture': sermon.scriptureReference,
          },
        );

        final prefs = await SharedPreferences.getInstance();
        final savedPosition = prefs.getInt('sermon_position_${sermon.id}');

        final audioSource = await _buildAudioSource(sermon, mediaItem);

        await player.setAudioSource(audioSource);
        await player.setSpeed(_currentSpeed);

        if (savedPosition != null && savedPosition > 10) {
          await player.seek(Duration(seconds: savedPosition));
        }

        await player.play();

        // Increment stream count
        try {
          await FirebaseFirestore.instance
              .collection('sermons')
              .doc(sermon.id)
              .update({'streams': FieldValue.increment(1)});
        } catch (_) {}
      } catch (e) {
        debugPrint('[AudioPlayerService] Error playing sermon: $e');
        rethrow;
      }
    } else {
      // Same sermon — toggle play/pause
      if (player.playing) {
        await player.pause();
      } else {
        await player.play();
      }
    }
  }

  /// Builds the appropriate [AudioSource] based on whether the sermon has a
  /// locally downloaded file or must be streamed from the network.
  ///
  /// Format support matrix (just_audio + platform codecs):
  /// ┌─────────────┬─────────┬───────┐
  /// │ Format      │ Android │  iOS  │
  /// ├─────────────┼─────────┼───────┤
  /// │ MP3         │   ✓     │   ✓   │
  /// │ M4A / AAC   │   ✓     │   ✓   │
  /// │ OGG Vorbis  │   ✓     │   ✗   │
  /// │ Opus        │   ✓     │   ✓*  │ * iOS 16+
  /// │ FLAC        │   ✓     │   ✓   │
  /// │ WAV / PCM   │   ✓     │   ✓   │
  /// │ AIFF        │   ✗     │   ✓   │
  /// │ WebM        │   ✓     │   ✗   │
  /// │ WMA         │   ✓     │   ✗   │
  /// │ ALAC        │   ✗     │   ✓   │
  /// └─────────────┴─────────┴───────┘
  Future<AudioSource> _buildAudioSource(
      Sermon sermon, MediaItem mediaItem) async {
    // Priority 1: Use local file if downloaded (offline playback, no network)
    if (sermon.isDownloaded &&
        sermon.localAudioPath != null &&
        File(sermon.localAudioPath!).existsSync()) {
      debugPrint(
          '[AudioPlayerService] Playing from local file: ${sermon.localAudioPath}');
      return AudioSource.file(sermon.localAudioPath!, tag: mediaItem);
    }

    // Priority 2: Check if it’s a YouTube URL
    // Matches: youtube.com, www.youtube.com, m.youtube.com, youtu.be
    final ytRegex = RegExp(
      r'(?:https?:\/\/)?(?:www\.|m\.)?(?:youtube\.com\/(?:watch\?.*v=|shorts\/|embed\/)|youtu\.be\/)([\w\-]+)',
      caseSensitive: false,
    );
    if (ytRegex.hasMatch(sermon.audioUrl)) {
      debugPrint(
          '[AudioPlayerService] Detected YouTube URL: ${sermon.audioUrl}');
      final yt = YoutubeExplode();
      try {
        final videoId = VideoId.parseVideoId(sermon.audioUrl);
        if (videoId == null)
          throw Exception('Could not parse YouTube video ID');
        final manifest = await yt.videos.streamsClient.getManifest(
          videoId,
          ytClients: [YoutubeApiClient.androidVr],
        );
        final streams = manifest.audioOnly;
        if (streams.isEmpty) throw Exception('No audio-only streams available');
        final streamInfo = streams.withHighestBitrate();
        final streamUrl = streamInfo.url;
        yt.close();
        debugPrint(
            '[AudioPlayerService] Extracted YouTube audio stream (${streamInfo.codec.mimeType}): $streamUrl');

        // Use the Android VR client to completely bypass the POToken 403 blocks
        // that currently affect the standard Android client.
        return AudioSource.uri(
          streamUrl,
          tag: mediaItem,
          headers: const {
            'User-Agent':
                'com.google.android.apps.youtube.vr/1.54.26 (Linux; U; Android 10) gzip',
          },
        );
      } catch (e) {
        yt.close();
        debugPrint('[AudioPlayerService] YouTube stream extraction failed: $e');
        rethrow; // Surface error to caller — don’t silently fall through to LockCaching
      }
    }

    // Priority 3: Network stream with progressive caching
    // LockCachingAudioSource works for ALL formats — the format is determined
    // by the HTTP Content-Type header, not the URL extension.
    debugPrint(
        '[AudioPlayerService] Streaming from network: ${sermon.audioUrl}');
    return LockCachingAudioSource(
      Uri.parse(sermon.audioUrl),
      tag: mediaItem,
    );
  }

  // ─── Playlist ──────────────────────────────────────────────────────────────

  Future<void> playSermonFromPlaylist(
      Sermon sermon, List<Sermon> playlist) async {
    _playlist = List.of(playlist);
    _currentIndex = _playlist.indexWhere((s) => s.id == sermon.id);
    if (_currentIndex == -1) {
      _playlist.insert(0, sermon);
      _currentIndex = 0;
    }
    await playSermon(sermon);
  }

  Future<void> playNext() async {
    if (_playlist.isEmpty || _currentIndex == -1) return;
    _currentIndex = (_currentIndex + 1) % _playlist.length;
    await playSermon(_playlist[_currentIndex]);
  }

  Future<void> playPrevious() async {
    if (_playlist.isEmpty || _currentIndex == -1) return;
    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    await playSermon(_playlist[_currentIndex]);
  }

  // ─── Seek ──────────────────────────────────────────────────────────────────

  Future<void> seekForward(Duration duration) async {
    await seek(player.position + duration);
  }

  Future<void> seekBackward(Duration duration) async {
    final pos = player.position - duration;
    await seek(pos.isNegative ? Duration.zero : pos);
  }

  Future<void> seek(Duration position) async {
    final duration = player.duration;
    if (duration != null && position > duration) {
      position = duration;
    }
    await player.seek(position);
  }

  // ─── Speed ─────────────────────────────────────────────────────────────────

  /// Cycles to the next speed in [speedOptions].
  Future<void> cycleSpeed() async {
    final currentIdx = speedOptions.indexOf(_currentSpeed);
    final nextIdx = (currentIdx + 1) % speedOptions.length;
    await setSpeed(speedOptions[nextIdx]);
  }

  Future<void> setSpeed(double speed) async {
    _currentSpeed = speed;
    await player.setSpeed(speed);
  }

  // ─── Controls ──────────────────────────────────────────────────────────────

  Future<void> pause() async => player.pause();
  Future<void> resume() async => player.play();

  Future<void> stop() async {
    await player.stop();
    _currentSermon = null;
    _currentIndex = -1;
    _playlist = [];
  }

  Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
    _currentSermon = null;
    _currentIndex = -1;
    _playlist = [];
  }
}
