
import 'package:player/cache_data_manager.dart';
import 'package:player/hulu/hulu_api.dart';
import 'package:player/network_service.dart';
import 'package:player/prime/prime_api.dart';
import 'package:player/youtube/youtube_api.dart';

import 'disney/disney_api.dart';

abstract class MoviePlatformApi with NetworkService {
  Future<MovieInfo> getMovieInfo(String movieId);

  Future<MoviePlayback> getPlaybackUrl(String movieId);

  Future<dynamic> getToken({ List<dynamic>? params });

  Future<dynamic> refreshToken();

  Future<Map<String, dynamic>> get metadata => Future.value({});

  MoviePlatformApi();

  final cacheManager = dataCacheManager;

  factory MoviePlatformApi.create(MoviePlatform platform) {
    switch(platform) {
      case MoviePlatform.disney:
        return DisneyApi();
      case MoviePlatform.prime:
        return PrimeApi();
      case MoviePlatform.youtube:
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

  MovieInfo({required this.title, required this.movieId, this.thumbnail, this.duration});

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

Future<bool> get isDiseyLoggedIn async {
  final token = await dataCacheManager.get(CacheDataKey.disney_video_access_token);
  return token != null;
}

Future<bool> get isHuluLoggedIn async {
  final token = await dataCacheManager.get(CacheDataKey.hulu_access_token);
  return token != null;
}

Future<bool> get isPrimeLoggedIn async {
  final isLoggedIn = await dataCacheManager.get(CacheDataKey.prime_logged_in);
  return isLoggedIn == true;
}