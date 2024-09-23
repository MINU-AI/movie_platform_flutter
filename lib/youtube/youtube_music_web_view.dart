import 'package:flutter/material.dart';
import 'package:player/logger.dart';
import 'package:player/movie_platform_api.dart';
import 'package:player/movie_web_view.dart';

class YoutubeMusicWebView extends MovieWebView {
  const YoutubeMusicWebView({super.key, required super.platform, super.doLoggingIn });
  
  @override
  PlatformState<MovieWebView> get state => _YoutubeMusicState();
  
}

class _YoutubeMusicState extends PlatformState<YoutubeMusicWebView> {

  @override
  String get url => "https://music.youtube.com/";

  @override
  String? get userAgent => "Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1";

  var _processing = false;


   @override
  Future<void> onUrlChange(String url) async {        
    if(url.contains("/watch")) {
      if(_processing) {
        return;
      }
      _processing = true;
      final uri = Uri.parse(url);
      final watchId = uri.queryParameters["v"];
      logger.i("Got watchId: $watchId");
      if(watchId != null) {
        loadingBackgroundColor = Colors.black.withOpacity(0.4);
        toggleLoading(true);
        try {
          final movieInfo = await platformApi.getMovieInfo(watchId);
          logger.i("Got movie info: $movieInfo");
          final moviePlayback = await platformApi.getPlaybackUrl(watchId);
          logger.i("Got movie playback: $moviePlayback");
          final payload = MoviePayload(playback: moviePlayback, info: movieInfo, metadata: await platformApi.metadata);
          popScreen(payload);
        } catch(e) {
          logger.e(e);
        }
      }
    }
    
  }

  @override
  Future<void> onPageFinished(String url)  async {
  }
  
}