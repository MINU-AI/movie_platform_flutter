import 'dart:convert';

import 'package:player/extension.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'cache_data_manager.dart';
import 'logger.dart';
import 'movie_platform_api.dart';
import 'movie_web_view.dart';

class DisneyWebView extends MovieWebView {
  const DisneyWebView({super.key, required super.platform });

  @override
  PlatformState<MovieWebView> get state => _DisneyState();
}

class _DisneyState extends PlatformState<DisneyWebView> {

  @override
  MoviePlatformApi get platformApi => MoviePlatformApiFactory.create(MoviePlatformType.disney);

  @override
  String? get userAgent => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36";
  
  @override
  String get url => "https://www.disneyplus.com/login";

  @override
  void onUrlChange(UrlChange url) async {
    final urlString = url.url;
    logger.i("onUrlChange: $urlString");
    if(urlString == null) {
      logger.e("onUrlChange null and ignore this case");
      return;
    }

    if(urlString.endsWith("/select-profile")) {
       const jsCode = """
                      let profileElement = document.querySelector("[data-testid^='profile-avatar-']");
                      var profileId = profileElement.getAttribute("data-gv2elementvalue");
                      if(profileId == null) {
                        profileId = "";
                      }
                      profileId;
                    """;
      final profileId = (await runJavaScriptReturningResult(jsCode) as String).trimStringFromJavascript();
      logger.i("ProfileId: $profileId");
      if(profileId.isNotEmpty) {
        await getApiToken();
        try {
          await platformApi.getToken(params: [profileId]);
        } catch(e) {
          logger.e("switchProfile error: $e");
        }
      }
    } else if(urlString.contains("/play/")) {
      toggleLoading(true);
      final uri = Uri.parse(urlString);
      final contentId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
      logger.i("Get contentId from uri: $contentId");
      if(contentId != null) { 
        await getApiToken();
        try {       
          final movieInfo = await platformApi.getMovieInfo(contentId);          
          // logger.i("Get movie info: $movieInfo");        
          final moviePlayback = await platformApi.getPlaybackUrl([contentId]);
          final token = await dataCacheManager.get(CacheDataKey.disney_video_access_token);
          final refreshToken = await dataCacheManager.get(CacheDataKey.disney_refresh_token);
          final Map<String, dynamic> metadata = {"token" : token, "refreshToken" : refreshToken };
          metadata.addAll(platformApi.metadata);
          final moviePayload = MoviePayload(playback: moviePlayback, info: movieInfo, metadata: metadata);
          popScreen(moviePayload);
        } catch(e) {
          logger.e("Get movie info: $e");
        }
      }
       toggleLoading(false);
    }
  }
  
}

extension on _DisneyState {
  
  Future<String?> getApiToken() async {
    const jsCode = """
                      var storage = window.localStorage;
                      var value = "";
                      for (var i = 0; i < storage.length; i++) {
                        var key = storage.key(i);
                        if(key.includes("bam_sdk_access--disney")) {
                          value = storage.getItem(key);
                          break;
                        }
                      }
                      value;
                   """;
    final data = (await runJavaScriptReturningResult(jsCode) as String).trimStringFromJavascript();
    logger.i("Got token data: $data");
    if (data.isNotEmpty) {
      final jsonData = jsonDecode(data);
      final token = jsonData["context"]["token"] as String?;
      if(token != null) {
        logger.i("Stored access token: $token");
        dataCacheManager.cache(CacheDataKey.disney_api_access_token, token);        
      }
      return token;
    }
    return null;
  }
}


