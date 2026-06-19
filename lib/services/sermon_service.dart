import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../models/sermon.dart';
import '../utils/audio_format_utils.dart';
import '../utils/toast_utils.dart';

class SermonService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _prefsKey = 'sermons';

  // ─── Prefs Helpers ─────────────────────────────────────────────────────────

  Future<void> _saveToPrefs(Sermon sermon) async {
    final prefs = await SharedPreferences.getInstance();
    final sermons = await _loadFromPrefs();
    final index = sermons.indexWhere((s) => s.id == sermon.id);
    if (index != -1) {
      sermons[index] = sermon;
    } else {
      sermons.add(sermon);
    }
    final serialized = sermons.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_prefsKey, serialized);
  }

  Future<List<Sermon>> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = prefs.getStringList(_prefsKey) ?? [];
    return serialized
        .map((s) => Sermon.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  // ─── Fetching ──────────────────────────────────────────────────────────────

  /// Fetches ALL sermons from Firestore, sorted newest-first, and merges
  /// local bookmark / download state from SharedPreferences.
  /// All in-memory filtering is delegated to the caller.
  Future<List<Sermon>> getSermons() async {
    try {
      final snapshot = await _firestore
          .collection('sermons')
          .orderBy('dateCreated', descending: true)
          .get();

      final sermons =
          snapshot.docs.map((doc) => Sermon.fromFirestore(doc)).toList();

      // Merge local bookmark / download state
      final localSermons = await _loadFromPrefs();
      final localMap = {for (final s in localSermons) s.id: s};

      return sermons.map((s) {
        final local = localMap[s.id];
        if (local == null) return s;
        return s.copyWith(
          isBookmarked: local.isBookmarked,
          isDownloaded: local.isDownloaded,
          localAudioPath: local.localAudioPath,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching sermons: $e');
      ToastUtils.showErrorToast('Error loading sermons');

      // Fall back to local cache
      final cached = await _loadFromPrefs();
      if (cached.isNotEmpty) return cached;
      return _createMockSermons();
    }
  }

  List<Sermon> _createMockSermons() {
    return [
      Sermon(
        id: 'mock1',
        title: 'Welcome to Our Church',
        preacherName: 'Pastor John Doe',
        category: 'Welcome',
        tags: ['welcome', 'introduction'],
        thumbnailUrl: 'https://example.com/thumbnail1.jpg',
        audioUrl: 'https://example.com/sermon1.mp3',
        dateCreated: DateTime.now(),
      ),
    ];
  }

  // ─── Download (Streaming / Chunked) ────────────────────────────────────────

  /// Downloads sermon audio using a chunked HTTP stream.
  ///
  /// Automatically detects the correct file extension by:
  ///   1. Inspecting the HTTP Content-Type response header.
  ///   2. Falling back to the URL path extension (e.g. `.m4a`, `.flac`).
  ///   3. Defaulting to `.mp3` if neither produces a known format.
  ///
  /// Reports download progress (0.0–1.0) via [onProgress].
  Future<void> downloadSermon(
    Sermon sermon, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      ToastUtils.showToast('Download started for "${sermon.title}"');

      final appDir = await getApplicationDocumentsDirectory();

      // ── 1. Determine the actual URL to download ──────────────────────────
      String actualUrl = sermon.audioUrl;
      final ytRegex = RegExp(
        r'(?:https?:\/\/)?(?:www\.|m\.)?(?:youtube\.com\/(?:watch\?.*v=|shorts\/|embed\/)|youtu\.be\/)([\w\-]+)',
        caseSensitive: false,
      );

      YoutubeExplode? yt;
      if (ytRegex.hasMatch(actualUrl)) {
        yt = YoutubeExplode();
        try {
          final videoId = VideoId(actualUrl);
          final manifest = await yt.videos.streamsClient.getManifest(videoId);
          final streamInfo = manifest.audioOnly.withHighestBitrate();
          actualUrl = streamInfo.url.toString();
          debugPrint(
              '[SermonService] Extracted YouTube download URL: $actualUrl');
        } catch (e) {
          debugPrint(
              '[SermonService] Failed to extract YouTube stream for download: $e');
        } finally {
          yt.close();
        }
      }

      // ── 2. Open the HTTP connection ──────────────────────────────────────
      final request = http.Request('GET', Uri.parse(actualUrl));
      final response = await http.Client().send(request);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            'HTTP ${response.statusCode} downloading ${sermon.audioUrl}');
      }

      // ── 2. Detect format from Content-Type header (most reliable) ────────
      final contentType = response.headers['content-type'];
      String ext = AudioFormatUtils.extensionFromMimeType(contentType);

      // If MIME gave us the fallback 'mp3', double-check the URL extension
      if (ext == 'mp3') {
        final urlExt = AudioFormatUtils.extensionFromUrl(sermon.audioUrl);
        if (urlExt != 'mp3') ext = urlExt; // prefer explicit URL extension
      }

      debugPrint(
          '[SermonService] Detected format: $ext for ${sermon.title} (MIME: $contentType)');

      // ── 3. Check if file already exists with this extension ──────────────
      final fileName = '${sermon.id}.$ext';
      final file = File('${appDir.path}/$fileName');

      if (!file.existsSync()) {
        final totalBytes = response.contentLength ?? 0;
        var receivedBytes = 0;

        final sink = file.openWrite();
        await response.stream.listen((chunk) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          if (totalBytes > 0 && onProgress != null) {
            onProgress(receivedBytes / totalBytes);
          }
        }).asFuture();
        await sink.flush();
        await sink.close();

        // Verify the downloaded file is non-empty
        if (file.lengthSync() == 0) {
          await file.delete();
          throw Exception('Downloaded file is empty — possible server error');
        }
      } else {
        // File already exists (re-download scenario skipped)
        onProgress?.call(1.0);
      }

      sermon.isDownloaded = true;
      sermon.localAudioPath = file.path;
      await _saveToPrefs(sermon);

      ToastUtils.showSuccessToast(
          'Download completed for "${sermon.title}" (${AudioFormatUtils.label(ext)})');
    } catch (e) {
      debugPrint('Error downloading sermon: $e');
      ToastUtils.showErrorToast('Failed to download "${sermon.title}"');
      rethrow;
    }
  }

  Future<void> deleteDownloadedSermon(Sermon sermon) async {
    try {
      if (sermon.localAudioPath != null) {
        final file = File(sermon.localAudioPath!);
        if (file.existsSync()) await file.delete();
      }
      sermon.isDownloaded = false;
      sermon.localAudioPath = null;
      await _saveToPrefs(sermon);
      ToastUtils.showSuccessToast('Deleted "${sermon.title}" from downloads');
    } catch (e) {
      debugPrint('Error deleting downloaded sermon: $e');
      ToastUtils.showErrorToast('Failed to delete "${sermon.title}"');
      rethrow;
    }
  }

  // ─── Bookmarks ─────────────────────────────────────────────────────────────

  Future<void> toggleBookmark(Sermon sermon) async {
    try {
      sermon.isBookmarked = !sermon.isBookmarked;
      await _saveToPrefs(sermon);
      ToastUtils.showSuccessToast(sermon.isBookmarked
          ? '"${sermon.title}" added to bookmarks'
          : '"${sermon.title}" removed from bookmarks');
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
      ToastUtils.showErrorToast(
          'Failed to ${sermon.isBookmarked ? 'bookmark' : 'unbookmark'} "${sermon.title}"');
      rethrow;
    }
  }

  Future<List<Sermon>> getDownloadedSermons() async {
    final sermons = await _loadFromPrefs();
    return sermons.where((s) => s.isDownloaded).toList();
  }

  Future<List<Sermon>> getBookmarkedSermons() async {
    final sermons = await _loadFromPrefs();
    return sermons.where((s) => s.isBookmarked).toList();
  }

  // ─── Single Fetch ──────────────────────────────────────────────────────────

  Future<Sermon?> getSermonById(String id) async {
    try {
      final doc = await _firestore.collection('sermons').doc(id).get();
      if (doc.exists) {
        final sermon = Sermon.fromFirestore(doc);
        // Merge local state for this specific sermon
        final localSermons = await _loadFromPrefs();
        final local = localSermons.firstWhere(
          (s) => s.id == id,
          orElse: () => sermon,
        );
        return sermon.copyWith(
          isBookmarked: local.isBookmarked,
          isDownloaded: local.isDownloaded,
          localAudioPath: local.localAudioPath,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error getting sermon by ID: $e');
      return null;
    }
  }

  // ─── Liking ────────────────────────────────────────────────────────────────

  Future<void> likeSermon(String sermonId) async {
    try {
      await _firestore
          .collection('sermons')
          .doc(sermonId)
          .update({'likes': FieldValue.increment(1)});
    } catch (e) {
      debugPrint('Error liking sermon: $e');
      // We don't throw here to avoid disrupting the UI if it fails
    }
  }
}
