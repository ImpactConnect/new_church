/// Shared utility functions for the Media / Sermon / Video features.
class MediaUtils {
  MediaUtils._();

  /// Format a view count to a human-readable string (e.g. 1.2K, 3.5M).
  static String formatViews(int views, {bool hideLabel = false}) {
    final suffix = hideLabel ? '' : ' views';
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M$suffix';
    }
    if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K$suffix';
    }
    return '$views$suffix';
  }

  /// Relative date string (e.g. "2d ago", "3mo ago").
  static String formatRelativeDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  /// Format a [Duration] as mm:ss or hh:mm:ss.
  static String formatDuration(Duration duration) {
    String two(int n) => n.toString().padLeft(2, '0');
    final hours = two(duration.inHours);
    final minutes = two(duration.inMinutes.remainder(60));
    final seconds = two(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }
}
