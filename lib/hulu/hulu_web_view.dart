import 'package:player/cache_data_manager.dart';
import 'package:player/logger.dart';
import 'package:player/movie_repository.dart';
import 'package:player/movie_web_view.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';

class HuluWebView extends MovieWebView {
  const HuluWebView({super.key, required super.platform, super.doLoggingIn });

  @override
  PlatformState<MovieWebView> get state => _HuluState();
  
}

class _HuluState extends PlatformState<HuluWebView> {
  @override
  String get url => "https://auth.hulu.com/web/login?next=https%3A%2F%2Fwww.hulu.com%2Fwelcome";

  var _isGotMovie = false;

  @override
  void onUrlChange(String url) async {
    if(_isGotMovie) {
      _isGotMovie = false;
      return;
    }
    
    if(url == "https://www.hulu.com/hub/home") {
       await getWebToken(url); 
      if(widget.doLoggingIn) {
        popScreen(true);
      }
      return;
    }

    if(url.contains("/watch/")) {
      final uri = Uri.parse(url);
      final movieId = uri.pathSegments.lastOrNull;
      if(movieId != null) {
        logger.i("Got movie id: $movieId");
        _isGotMovie = true;
        toggleLoading(true);
        final (token, deviceToken) = await getWebToken(url);        
        if(token == null || deviceToken == null) {
          toggleLoading(false);
          return;
        }
        
        handleMovieId(movieId);
      }
    }
  }

  
  
}

extension on _HuluState {
  Future<(String?, String?)> getWebToken(String url) async {
    final cookies = await WebviewCookieManager().getCookies("https://www.hulu.com");
    String? token, deviceToken;
    for(final cookie in cookies) {
      if(cookie.name == "_hulu_session") {        
        token = cookie.value;
        logger.i("Got token: $token");
      } else if(cookie.name == "_hulu_dt") {
        deviceToken = cookie.value;
        logger.i("Got device token: $deviceToken");
      }
    }

    await dataCacheManager.cache(CacheDataKey.hulu_access_token, token);
    await dataCacheManager.cache(CacheDataKey.hulu_device_token, deviceToken);

    return (token, deviceToken);
  }
  
}