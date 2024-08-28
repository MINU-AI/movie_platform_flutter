
import 'package:player/prime_api.dart';

import 'disney_api.dart';

abstract class MoviePlatformApi {
  Future<MovieInfo> getMovieInfo(String movieId);

  Future<MoviePlayback> getPlaybackUrl(List<dynamic> params);

  Future<dynamic> getToken({ List<dynamic>? params });

  Future<dynamic> refreshToken();

  dynamic get metadata => {};

}

enum MoviePlatformType {
  disney,
  prime;

  static MoviePlatformType fromString(String value) {
    switch(value) {
      case "disney":
        return disney;
      case "prime":
        return prime;
      default:
        throw "Unsupported platform type: $value";
    }
  }
}

final class MovieInfo {
  final String title;
  final String? thumbnail;
  final int? duration;

  MovieInfo({required this.title, this.thumbnail, this.duration});

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

class MoviePlatformApiFactory {
  MoviePlatformApiFactory._();

  static MoviePlatformApi create(MoviePlatformType type) {
    switch(type) {
      case MoviePlatformType.disney:
        return DisneyApi();
      case MoviePlatformType.prime:
        return PrimeApi();
      default:
        throw "Unsupported plaform type: $type";
    }
  }
}

