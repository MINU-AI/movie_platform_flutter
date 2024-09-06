import 'dart:async';

import 'package:flutter/material.dart';
import 'package:player/logger.dart';
import 'package:player/movie_platform_api.dart';
import 'package:player/movie_web_view.dart';

class YoutubeWebView extends MovieWebView {
  const YoutubeWebView({super.key, required super.platform });
  
  @override
  PlatformState<MovieWebView> get state => _YoutubeState();
  
}

class _YoutubeState extends PlatformState<YoutubeWebView> {

  @override
  String get url => "https://m.youtube.com/";

  @override
  String? get userAgent => "Mozilla/5.0 (Linux; Android 8.0.0; SM-G955U Build/R16NW) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36";

  @override
  bool get loadUrlAtStartUp => false;

  @override
  void initState() {
    super.initState();    
    loadWebView();
  }

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
          final moviePlayback = await platformApi.getPlaybackUrl([watchId]);
          logger.i("Got movie playback: $moviePlayback");
          final payload = MoviePayload(playback: moviePlayback, info: movieInfo, metadata: platformApi.metadata);
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

extension on _YoutubeState {
  void loadWebView() async {
    loadUrl(url);
  }
}