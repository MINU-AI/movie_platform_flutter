
import 'package:player/cache_data_manager.dart';
import 'package:player/hulu/hulu_api.dart';
import 'package:player/network_service.dart';
import 'package:player/prime/prime_api.dart';
import 'package:player/youtube/youtube_api.dart';

import 'disney/disney_api.dart';

abstract class MovieRepository with NetworkService {
  Future<MovieInfo> getMovieInfo(String movieId);

  Future<MoviePlayback> getPlaybackUrl(String movieId);

  Future<dynamic> getToken({ List<dynamic>? params });

  Future<dynamic> refreshToken();

  Future<Map<String, dynamic>> get metadata => Future.value({});

  MovieRepository();

  final cacheManager = dataCacheManager;

  factory MovieRepository.create(MoviePlatform platform) {
    switch(platform) {
      case MoviePlatform.disney:
        return DisneyApi();
      case MoviePlatform.prime:
        return PrimeApi();
      case MoviePlatform.youtube:
      case MoviePlatform.youtubeMusic:
        return YoutubeApi();
      case MoviePlatform.hulu:
        return HuluApi();

      default:
        throw "Unsupported plaform type: $platform";
    }
  }

}

enum MoviePlatform {
  youtube,
  disney,
  hulu,
  youtubeMusic,
  prime;

  static MoviePlatform fromString(String value) {
    switch(value) {
      case "disney":
        return disney;
      case "prime":
        return prime;
      case "youtube":
        return youtube;
      case "hulu":
        return hulu;
      case "youtubeMusic":
        return youtubeMusic;
      default:
        throw "Unsupported platform type: $value";
    }
  }
}

final class MovieInfo {
  final String movieId;
  final String title;
  final String? thumbnail;
  final int? duration;
  final String? author;

  MovieInfo({required this.title, required this.movieId, this.thumbnail, this.duration, this.author });

  dynamic toJson() {
    return {
      "title" : title,
      "thumbnail" : thumbnail,
      "duration" : duration
    };
  }

  @override
  String toString() {
    return "${toJson()}";
  }
}

final class MoviePlayback {
  final String playbackUrl;
  final String? licenseKeyUrl;
  final String? licenseCertificateUrl;

  MoviePlayback({required this.playbackUrl, this.licenseKeyUrl, this.licenseCertificateUrl});

  dynamic toJson() {
    return {
      "playbackUrl" : playbackUrl,
      "licenseKeyUrl" : licenseKeyUrl,
      "licenseCertificateUrl" : licenseCertificateUrl
    };
  }

  @override
  String toString() {
    return "${toJson()}";
  }
}

class MoviePayload {
  final MoviePlayback playback;
  final MovieInfo? info;
  final Map<String, dynamic> metadata;

  MoviePayload({required this.playback, required this.info, required this.metadata});
}

Future<bool> get _isDiseyLoggedIn async {
  final token = await dataCacheManager.get(CacheDataKey.disney_video_access_token);
  return token != null;
}

Future<bool> get _isHuluLoggedIn async {
  final token = await dataCacheManager.get(CacheDataKey.hulu_access_token);
  return token != null;
}

Future<bool> get _isPrimeLoggedIn async {
  final isLoggedIn = (await dataCacheManager.get(CacheDataKey.prime_logged_in)) ?? false;
  return isLoggedIn;
}

Future<bool> isMoviePlatformLoggedIn(MoviePlatform platform) async {
  switch(platform) {
    case MoviePlatform.youtube:
    case MoviePlatform.youtubeMusic:
      return true;
    case MoviePlatform.disney:
      return _isDiseyLoggedIn;
    case MoviePlatform.hulu:
      return _isHuluLoggedIn;
    case MoviePlatform.prime:
      return _isPrimeLoggedIn;
  }
}