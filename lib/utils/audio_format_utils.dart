/// Utilities for detecting and working with audio file formats.
class AudioFormatUtils {
  AudioFormatUtils._();

  /// Supported audio MIME types and their extensions.
  static const Map<String, String> _mimeToExtension = {
    'audio/mpeg': 'mp3',
    'audio/mp3': 'mp3',
    'audio/mp4': 'm4a',
    'audio/x-m4a': 'm4a',
    'audio/aac': 'aac',
    'audio/x-aac': 'aac',
    'audio/ogg': 'ogg',
    'audio/opus': 'opus',
    'audio/flac': 'flac',
    'audio/x-flac': 'flac',
    'audio/wav': 'wav',
    'audio/x-wav': 'wav',
    'audio/wave': 'wav',
    'audio/aiff': 'aiff',
    'audio/x-aiff': 'aiff',
    'audio/webm': 'webm',
    'audio/3gpp': '3gp',
    'audio/3gpp2': '3g2',
  };

  /// All recognised audio extensions (lowercase).
  static const Set<String> supportedExtensions = {
    'mp3',
    'm4a',
    'aac',
    'ogg',
    'opus',
    'flac',
    'wav',
    'aiff',
    'webm',
    '3gp',
    '3g2',
    'wma',  // Windows Media Audio (Android only via MediaCodec)
    'alac', // Apple Lossless (iOS/macOS)
    'caf',  // Core Audio Format (iOS/macOS)
  };

  // ─── Extension Detection ──────────────────────────────────────────────────

  /// Extracts the audio file extension from a URL, stripping query strings and
  /// fragments. Falls back to 'mp3' if no recognised extension is found.
  ///
  /// Examples:
  ///   https://cdn.example.com/sermons/abc.m4a?token=xyz  →  m4a
  ///   https://storage.googleapis.com/bucket/abc.flac     →  flac
  ///   https://cdn.example.com/stream/abc                 →  mp3  (fallback)
  static String extensionFromUrl(String url) {
    try {
      // Strip query params and fragment
      final uri = Uri.parse(url);
      final path = uri.path; // e.g. /bucket/abc.m4a

      final lastDot = path.lastIndexOf('.');
      if (lastDot != -1 && lastDot < path.length - 1) {
        final ext = path.substring(lastDot + 1).toLowerCase();
        if (supportedExtensions.contains(ext)) return ext;
      }
    } catch (_) {}
    return 'mp3'; // safe default
  }

  /// Returns the extension for a given MIME type string.
  static String extensionFromMimeType(String? mimeType) {
    if (mimeType == null) return 'mp3';
    final lower = mimeType.split(';').first.trim().toLowerCase();
    return _mimeToExtension[lower] ?? 'mp3';
  }

  /// Returns a human-readable label for a file extension.
  static String label(String ext) {
    switch (ext.toLowerCase()) {
      case 'mp3':
        return 'MP3';
      case 'm4a':
        return 'M4A';
      case 'aac':
        return 'AAC';
      case 'ogg':
        return 'OGG';
      case 'opus':
        return 'Opus';
      case 'flac':
        return 'FLAC';
      case 'wav':
        return 'WAV';
      case 'aiff':
        return 'AIFF';
      case 'webm':
        return 'WebM';
      case 'wma':
        return 'WMA';
      default:
        return ext.toUpperCase();
    }
  }

  /// Returns true if [ext] is a known supported audio extension.
  static bool isSupported(String ext) =>
      supportedExtensions.contains(ext.toLowerCase());
}
