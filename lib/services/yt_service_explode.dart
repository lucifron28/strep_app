import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:io';

void downloadClient(String url) async {
  var yt = YoutubeExplode();

  var video = await yt.videos.get(url);

  Map<String, String> details = {
    "title": video.title,
    "artist": video.author,
    "description": video.description,
  };

  var manifest = await yt.videos.streamsClient.getManifest(url);
  var audioStreamInfo = manifest.audioOnly.withHighestBitrate();

  var file = new File(video.title);

  var output = file.openWrite();

  var stream = yt.videos.streamsClient.get(audioStreamInfo);

  await stream.pipe(output);

  await output.close();

  yt.close();
}