import 'dart:async';

import 'package:flutter/material.dart';
import 'package:player/logger.dart';
import 'package:player/movie_platform_api.dart';
import 'package:player/movie_web_view.dart';

class YoutubeWebView extends MovieWebView {
  const YoutubeWebView({super.key, required super.platform, super.doLoggingIn });
  
  @override
  PlatformState<MovieWebView> get state => _YoutubeState();
  
}

class _YoutubeState extends PlatformState<YoutubeWebView> {

  @override
  String get url => "https://m.youtube.com/";

  @override
  String? get userAgent => "Mozilla/5.0 (Linux; Android 8.0.0; SM-G955U Build/R16NW) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36";

  
  @override
  Map<String, String> get headers => {
      "Cookie" : "GPS=1; YSC=HSS9zIANMbg; VISITOR_PRIVACY_METADATA=CgJWThIEGgAgTw%3D%3D; VISITOR_INFO1_LIVE=VdXIBwppj8o; VISITOR_PRIVACY_METADATA=CgJWThIEGgAgTw%3D%3D; PREF=f6=40000000&f4=4000000&f7=100;",
      "Priority" : "u=0, i",
      "Accept" : "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
    };

  @override
  Future<void> onUrlChange(String url) async {        
    if(url.contains("/watch")) {
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
