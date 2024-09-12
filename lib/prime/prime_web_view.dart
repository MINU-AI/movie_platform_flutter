import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:player/logger.dart';
import 'package:player/movie_web_view.dart';
import 'package:player/player.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import 'package:collection/collection.dart';
import '../extension.dart';

class PrimeWebView extends MovieWebView {
  const PrimeWebView({super.key, required super.platform });

  @override
  PlatformState<MovieWebView> get state => _PrimeState();
  
}

class _PrimeState extends PlatformState<PrimeWebView> {
  
  String? _videoId;

  @override  
  bool get loadUrlAtStartUp => false;

  @override
  String get url =>  "https://www.amazon.com/Amazon-Video/b?ie=UTF8&node=2858778011&ref_=nav_signin";

  @override
  String? get userAgent => "Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1";

  @override
  String? get injectedJavascript => """
        document.addEventListener('click', function(event) {
            var targetElement = event.target || event.srcElement;
            let textContent = targetElement.textContent;
            let message = JSON.stringify({ "click" : textContent });
            messageHandler.postMessage(message);
        });

    """;

  @override
  void initState() {
    super.initState();
    initLoadUrl();
  }

  @override
  void onUrlChange(String url) {    
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    if(pathSegments.contains("video") && pathSegments.contains("detail")) {
      if(pathSegments.length > 2) {
        _videoId = pathSegments[pathSegments.length - 2];
        logger.i("Got video id: $_videoId");
      }
    }

    if(url.startsWith("https://www.amazon.com/Amazon-Video")) {
      dataCacheManager.cache(CacheDataKey.prime_logged_in, true);
    }
  }

  @override
  void onJavascriptReceived(String message) {
    final data = jsonDecode(message);
    logger.i("onJavascriptReceived: $data");
    final clickButton = (data["click"] as String).toLowerCase().trim();    
    if(clickButton.contains("watch now") || clickButton.contains("continue watching")) {
      int? episode;
      if(clickButton.contains("episode")) {
        final reg = RegExp(r'[0-9]');
        final episodeString = reg.allMatches(clickButton).firstOrNull?.group(0);
        episode = episodeString != null ? int.parse(episodeString) : null;
        logger.i("Got episode: $episode");        
      } 
      _extractMoviePlayback(episode: episode);
    } else if(clickButton == "sign out") {
      dataCacheManager.cache(CacheDataKey.prime_logged_in, false);
    }
  }

}

extension on _PrimeState {
  Future<void> _extractMoviePlayback({ int? episode }) async {
    toggleLoading(true);
    var html = (await runJavaScriptReturningResult("document.documentElement.outerHTML") as String).trimStringFromJavascript();
    html = html.decodeUnicode(); 
    final document = parse(html);
    String? movieId;

    if(episode != null) {      
      final playHrefElement = document.getElementsByClassName("fbl-play-btn").firstWhereOrNull((item) {
        final itemLabel = item.attributes["aria-label"];
        return itemLabel != null && itemLabel.toLowerCase().contains("watch");
      });

      if(playHrefElement != null) {
        final playURL = playHrefElement.attributes["href"];
        logger.i("Got play url: $playURL");
        if(playURL != null) {
          final playUri = Uri.parse(playURL);
          final queriesItems = playUri.queryParameters;
          for(final item in queriesItems.entries) {
            if(item.key == "gti") {
              movieId = item.value;
              logger.i("Got titleId: $movieId");                            
            }
          }
        }
      }
    } else {
      final movieIdElement = document.querySelector("input[name='titleID']");
      if(movieIdElement != null) {
        movieId = movieIdElement.attributes["value"];
        logger.i("Got movie id: $movieId");
      }
    }

    if(movieId != null) {
      final movieInfo = _extractMovieInfo(document, episode: episode);
      logger.i("Got movie title: $movieInfo");
      final cookies = await _getCookies();
      final moviePlayback = await platformApi.getPlaybackUrl([movieId, cookies]);
      final Map<String, dynamic> metadata = { "cookies" : cookies, "movieId" : movieId };
      metadata.addAll(platformApi.metadata);
      final moviePayload = MoviePayload(playback: moviePlayback, info: movieInfo, metadata: metadata);
      popScreen(moviePayload);
    }

    toggleLoading(false);
  }

  MovieInfo? _extractMovieInfo(Document document, { int? episode }) {
    final titleElement = document.querySelector("[data-automation-id='title']");        
    var title = titleElement?.text;
    
    final titleArtElement = document.querySelector("[data-testid='title-art']");
    final logoElement = titleArtElement?.children.firstOrNull;
    final imageElement = logoElement?.children.firstOrNull;
    title ??= imageElement?.attributes["alt"];
    var thumbnail = imageElement?.attributes["src"];
    title ??= "";
    if(episode != null) {
      final session = document.querySelector("*[for='av-droplist-av-atf-season-selector']")?.text.trim();
      logger.i("Got session: $session");                          
      if(session != null) {
        title += " - $session - Episode $episode";
      }      
    }

    return MovieInfo(title: title, thumbnail: thumbnail);
  }

  Future<String> _getCookies() async {
    var cookies = "";
    final cookieManager = WebviewCookieManager();
    final allCookies = await cookieManager.getCookies("https://amazon.com");
    for (final cookie in allCookies) {
      cookies += "${cookie.name}=${cookie.value};";
    }
    logger.i("Got cookies: $cookies");
    return cookies;
  }

}

extension on _PrimeState {
  void initLoadUrl() async {
    final isLoggedIn = await dataCacheManager.get(CacheDataKey.prime_logged_in) ?? false;
    final url = isLoggedIn ? "https://www.amazon.com/Amazon-Video/b?ie=UTF8&node=2858778011&ref_=nav_signin" : "https://www.amazon.com/ap/signin?openid.pape.max_auth_age=0&openid.return_to=https%3A%2F%2Fwww.amazon.com%2FAmazon-Video%2Fb%3Fie%3DUTF8%26node%3D2858778011%26ref_%3Dnav_signin&openid.identity=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.assoc_handle=usflex&openid.mode=checkid_setup&openid.claimed_id=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0";
    loadUrl(url);
  }
}