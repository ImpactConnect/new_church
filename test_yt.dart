import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  final videoId = 'n61ZwhOTV18'; 
  final manifest = await yt.videos.streamsClient.getManifest(videoId, ytClients: [YoutubeApiClient.androidVr]);
  final streamInfo = manifest.audioOnly.withHighestBitrate();
  print('Stream URL: ${streamInfo.url}');
  yt.close();
}
