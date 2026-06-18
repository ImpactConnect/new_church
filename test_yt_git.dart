import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
void main() async {
  final yt = YoutubeExplode();
  final videoId = 'n61ZwhOTV18';
  final manifest = await yt.videos.streamsClient.getManifest(videoId);
  final streamInfo = manifest.audioOnly.withHighestBitrate();
  var res = await http.head(streamInfo.url);
  print('HEAD Status (git master): ${res.statusCode}');
  yt.close();
}
