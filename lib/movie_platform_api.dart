
import 'disney_api.dart';

abstract class MoviePlatformApi {
  Future<MovieInfo> getMovieInfo(String movieId);

  Future<MoviePlayback> getPlaybackUrl(String movieId);

  Future<dynamic> getToken({ List<dynamic>? params });

  Future<dynamic> refreshToken();

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

  MovieInfo({required this.title, required this.thumbnail, required this.duration});

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

  MoviePlayback({required this.playbackUrl, required this.licenseKeyUrl, required this.licenseCertificateUrl});

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

class MoviePlatformFactory {
  MoviePlatformFactory._();

  static MoviePlatformApi create(MoviePlatformType type) {
    switch(type) {
      case MoviePlatformType.disney:
        return DisneyApi();
      default:
        throw "Unsupported plaform type: $type";
    }
  }
}

