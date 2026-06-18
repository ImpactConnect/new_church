import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  final videoId = 'n61ZwhOTV18'; // user's video
  final manifest = await yt.videos.streamsClient.getManifest(videoId);
  final streamInfo = manifest.audioOnly.withHighestBitrate();
  
  try {
    var stream = yt.videos.streamsClient.get(streamInfo);
    var firstChunk = await stream.first;
    print('Got first chunk! Length: ${firstChunk.length}');
  } catch (e) {
    print('Failed to get stream: $e');
  }
  
  yt.close();
}
