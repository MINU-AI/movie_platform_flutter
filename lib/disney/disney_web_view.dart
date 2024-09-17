import 'dart:convert';
import 'dart:io';

import 'package:player/extension.dart';

import '../cache_data_manager.dart';
import '../logger.dart';
import '../movie_platform_api.dart';
import '../movie_web_view.dart';

class DisneyWebView extends MovieWebView {
  const DisneyWebView({super.key, required super.platform });

  @override
  PlatformState<MovieWebView> get state => _DisneyState();
}

class _DisneyState extends PlatformState<DisneyWebView> {

  @override
  String? get userAgent => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36";
  
  @override
  String get url => "https://www.disneyplus.com/login";

  @override
  void onUrlChange(String url) async {    
    if(url.endsWith("/select-profile")) {
       const jsCode = """
                      let profileElement = document.querySelector("[data-testid^='profile-avatar-']");
                      var profileId = profileElement.getAttribute("data-gv2elementvalue");
                      if(profileId == null) {
                        profileId = "";
                      }
                      profileId;
                    """;
      var profileId = (await runJavaScriptReturningResult(jsCode) as String);
      if(Platform.isAndroid) {
        profileId = profileId.trimStringFromJavascript();
      }
      logger.i("ProfileId: $profileId");
      if(profileId.isNotEmpty) {
        await getApiToken();
        try {
          await platformApi.getToken(params: [profileId]);
        } catch(e) {
          logger.e("switchProfile error: $e");
        }
      }
    } else if(url.contains("/play/")) {
      toggleLoading(true);
      final uri = Uri.parse(url);
      final contentId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
      logger.i("Get contentId from uri: $contentId");
      if(contentId != null) { 
        await getApiToken();
        try {       
          final movieInfo = await platformApi.getMovieInfo(contentId);          
          // logger.i("Get movie info: $movieInfo");        
          final moviePlayback = await platformApi.getPlaybackUrl(contentId);          
          final moviePayload = MoviePayload(playback: moviePlayback, info: movieInfo, metadata: await platformApi.metadata);
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
    var data = (await runJavaScriptReturningResult(jsCode) as String);
    if(Platform.isAndroid) {
      data = data.trimStringFromJavascript();
    }

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


