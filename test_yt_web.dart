import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  // Is there a way to configure the client payload?
  // Let's just look at the getManifest signature.
  print(yt.videos.streamsClient.runtimeType);
}
