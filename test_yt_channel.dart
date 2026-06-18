import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  try {
    // Example: Elevation Church Channel ID (or any known channel)
    // Elevation Church: UCnQGkEdA2-pBfEicB3b7Fzw
    final uploads = await yt.channels.getUploads('UCnQGkEdA2-pBfEicB3b7Fzw').take(5).toList();
    print('Found ${uploads.length} videos:');
    for (var v in uploads) {
      print('- ${v.title} (${v.url})');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    yt.close();
  }
}
