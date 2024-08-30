
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:player/assets.dart';
import 'package:player/prime_web_view.dart';
import 'package:player/youtube_web_view.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'disney_web_view.dart';
import 'loading_view.dart';
import 'logger.dart';
import 'movie_picker.dart';
import 'movie_platform_api.dart';


final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = {
  Factory(() => EagerGestureRecognizer())
};

abstract class MovieWebView extends MoviePickerView {
  final MoviePlatformType platform;

  const MovieWebView({super.key, required this.platform });

  factory MovieWebView.create({ required MoviePlatformType platform }) {
    switch(platform) {
      case MoviePlatformType.disney:
        return DisneyWebView( platform: platform,);
        
      case MoviePlatformType.prime:
        return PrimeWebView(isLoggedIn: true, platform: platform);
      
      case MoviePlatformType.youtube:
        return YoutubeWebView(platform: platform);

      default:
        throw "Unsupported platform: $platform";
    }
  }

  PlatformState<MovieWebView> get state;

  @override
  State<StatefulWidget> createState() => state;
  
}

abstract class PlatformState< V extends MovieWebView> extends State<V> {

  late final WebViewController _controller;
  MoviePlatformApi? _moviePlatformApi;
  Color _loadingBackgroundColor =  const Color(0x60000000);

  MoviePlatformApi get platformApi {
    _moviePlatformApi ??= MoviePlatformApiFactory.create(widget.platform);
    return _moviePlatformApi!;
  }

  void onUrlChange(UrlChange urlChange) {}

  void onPageStarted(String url) {}

  void onPageFinished(String url) {}

  void onJavascriptReceived(String message){}

  void popScreen<T>(T result) => Navigator.of(context).pop(result);

  bool get loadUrlAtStartUp => true;

  Map<String, String> get headers => {};

  String? get injectedJavascript {
    return null;
  }

  set loadingBackgroundColor(Color value) {
    setState(() {
      _loadingBackgroundColor = value;  
    });    
  }

  abstract final String url;

  bool _showLoading = false;

  String? get userAgent => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.54 Safari/537.36";

  void toggleLoading(bool value) {
    setState(() {
      _showLoading = value;
    });
  }

  void initWebView() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params);

    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onUrlChange: onUrlChange,
          onPageStarted: (url) {
            logger.i("onPageStarted: $url");   
            if(injectedJavascript != null) {
              runJavascript(injectedJavascript!);
            }         
            onPageStarted(url);
          },
          onPageFinished: (url) {
            logger.i("onPageFinished: $url");                       
            onPageFinished(url);
          },
          onWebResourceError: (WebResourceError error) {
            logger.e(error);
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel("messageHandler", onMessageReceived: (message) {
        onJavascriptReceived(message.message);
      })
      ..setUserAgent(userAgent);
      // ..loadRequest(Uri.parse(url), headers: headers);
  }

  void loadUrl(String url, { Map<String, String>? headers  }) {
    _controller.loadRequest(Uri.parse(url), headers: headers ?? {});
  }

  @override
  void initState() {
    initWebView();
    if(loadUrlAtStartUp) {
      loadUrl(url, headers: headers);
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
            child: Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      WebViewWidget(                        
                        controller: _controller,
                        gestureRecognizers: gestureRecognizers,
                      ),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 16,),

                          Column(
                            mainAxisSize: MainAxisSize.min,                        
                            children: [
                              GestureDetector(
                                onTap: (){
                                  _controller.goBack();
                                },
                                child: Container(
                                  decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(40)),
                                  child: SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: Image.asset(Assets.icBack, width: 12,)
                                  )
                                )
                              ),

                              const SizedBox(height: 16,)

                            ],
                          ),
                        ],
                      ),

                      Visibility(
                        visible: _showLoading,
                        child: LoadingView(backgroundColor: _loadingBackgroundColor,),
                      ),                      
                    ],
                  )
          );
  }

  Future<void> runJavascript(String js) async {
    try {
      await _controller.runJavaScript(js);      
    } catch(e){
      logger.e(e);
    }
  }

  Future<Object> runJavaScriptReturningResult(String js) => _controller.runJavaScriptReturningResult(js);
}
