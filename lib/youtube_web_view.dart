import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:player/cache_data_manager.dart';
import 'package:player/logger.dart';
import 'package:player/movie_platform_api.dart';
import 'package:player/movie_web_view.dart';
import 'package:webview_flutter_platform_interface/src/types/url_change.dart';

class YoutubeWebView extends MovieWebView {
  const YoutubeWebView({super.key, required super.platform });
  
  @override
  PlatformState<MovieWebView> get state => _YoutubeState();
  
}

class _YoutubeState extends PlatformState<YoutubeWebView> {
  var _loadHomeCount = 0;
  var _finishInitiation = false;
  final sampleUrl = "https://m.youtube.com/watch?v=EngW7tLk6R8&pp=ygUSc2hvcnQgc2FtcGxlIHZpZGVv";

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
  Future<void> onUrlChange(UrlChange urlChange) async {
    final url = urlChange.url;
    if(url == null || !_finishInitiation) {
      return;
    }

    logger.i("onUrlChange: $url");
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
    toggleLoading(false);
    if(url == sampleUrl) {
      toggleLoading(true);
      Timer(const Duration(seconds: 3), () async {
        await runJavascript("document.getElementsByClassName('mobile-topbar-header-endpoint')[0].click()");
        dataCacheManager.cache(CacheDataKey.youtube_is_initialize, true);   
        _finishInitiation = true;              
      });
    } else if(url == this.url) {
      const jsCode = """
                     document.getElementsByClassName("feed-nudge-text-container").length == 1;                                        
                  """;
      final isEmpty = await runJavaScriptReturningResult(jsCode) as bool;
      logger.i("Got result: $isEmpty");
      if(isEmpty && _loadHomeCount <= 5) {
        _loadHomeCount++;
        loadUrl(url);      
      } else {
        toggleLoading(false);
      }
      
    }
  }
  
}

extension on _YoutubeState {
  void loadWebView() async {
    final isInitialized = (await dataCacheManager.get(CacheDataKey.youtube_is_initialize) ?? false);
    _finishInitiation = isInitialized;
    if(!isInitialized) {
       loadingBackgroundColor = const Color(0xFF000000);
       toggleLoading(true);
    }
    loadUrl(isInitialized ? url : sampleUrl);
  }
}