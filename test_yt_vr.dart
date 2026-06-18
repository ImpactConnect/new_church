import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  final videoId = 'n61ZwhOTV18'; 
  final manifest = await yt.videos.streamsClient.getManifest(videoId, ytClients: [YoutubeApiClient.androidVr]);
  final streamInfo = manifest.audioOnly.withHighestBitrate();
  
  // Try fetching the VR stream without UA
  var res = await http.head(streamInfo.url);
  print('HEAD Status (no UA): ${res.statusCode}');
  
  // Try fetching the VR stream with VR UA
  res = await http.head(streamInfo.url, headers: {
    'User-Agent': 'com.google.android.apps.youtube.vr/1.54.26 (Linux; U; Android 10) gzip'
  });
  print('HEAD Status (VR UA): ${res.statusCode}');
  
  yt.close();
}
