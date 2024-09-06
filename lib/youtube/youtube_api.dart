import 'package:player/logger.dart';
import 'package:player/player.dart';

class YoutubeApi extends MoviePlatformApi {
  @override
  Future<MovieInfo> getMovieInfo(String movieId) async {
    final response = await _getVideoMetadata(movieId);
    final title = response["videoDetails"]["title"];
    final durationStr = response["videoDetails"]["lengthSeconds"] as String?;
    int? duration;
    if(durationStr != null) {
      duration = int.tryParse(durationStr);
    }
    final thumbnailList = response["videoDetails"]["thumbnail"]["thumbnails"] as List<dynamic>?;
    final thumbnail = thumbnailList?.firstOrNull?["url"];

    logger.i("Got movie info: $title, $duration, $thumbnail");

    return MovieInfo(title: title, thumbnail: thumbnail, duration: duration);
  }

  @override
  Future<MoviePlayback> getPlaybackUrl(List params) async {
    final watchId = params[0] as String;
    final response = await _getVideoMetadata(watchId);
    final playbackUrl = response["streamingData"]["hlsManifestUrl"];

    return MoviePlayback(playbackUrl: playbackUrl);
  }

  @override
  Future getToken({List? params}) {    
    throw UnimplementedError();
  }

  @override
  Future refreshToken() {
    throw UnimplementedError();
  }
  
}

extension on YoutubeApi {
  Future<dynamic> _getVideoMetadata(String watchId) async {
    const requestUrl = "https://youtubei.googleapis.com/youtubei/v1/player?key=AIzaSyC6fvZSJHA7Vz5j8jCiKRt7tUIOqjE2N3g";
    final body = {
      "videoId" : watchId,
      "context" : {
        "client" : {
          "clientVersion" : "19.05",
          "gl" : "US",
          "clientName" : "IOS",
          "hl" : "en_US"
        }
      }
    };

    return await post(requestUrl, headers: {"Content-Type" : "application/json"}, body: body);
  }
}

