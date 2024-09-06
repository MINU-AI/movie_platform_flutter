
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:player/assets.dart';
import 'package:player/hulu/hulu_web_view.dart';
import 'package:player/prime/prime_web_view.dart';
import 'package:player/youtube/youtube_web_view.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'disney/disney_web_view.dart';
import 'loading_view.dart';
import 'logger.dart';
import 'movie_picker.dart';
import 'movie_platform_api.dart';


final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = {
  Factory(() => EagerGestureRecognizer())
};

abstract class MovieWebView extends MoviePickerView {
  final MoviePlatform platform;

  const MovieWebView({super.key, required this.platform });

  factory MovieWebView.create({ required MoviePlatform platform }) {
    switch(platform) {
      case MoviePlatform.disney:
        return DisneyWebView( platform: platform,);
        
      case MoviePlatform.prime:
        return PrimeWebView(isLoggedIn: true, platform: platform);
      
      case MoviePlatform.youtube:
        return YoutubeWebView(platform: platform);
      
      case MoviePlatform.hulu:
        return HuluWebView(platform: platform);

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
    _moviePlatformApi ??= MoviePlatformApi.create(widget.platform);
    return _moviePlatformApi!;
  }

  void onUrlChange(String url) {}

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

  var _isDisposed = false;

  String? get userAgent => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.54 Safari/537.36";

  late final WeakReference<PlatformState<V>> _weakSelf;

  void toggleLoading(bool value) {
    if(_isDisposed) {
        return;
    }
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
          onUrlChange: (url) {
            logger.i("onUrlChange: ${url.url}");
            final urlString = url.url;
            if(urlString == null) {
              return;
            }
            _weakSelf.target?.onUrlChange(urlString);
          },
          onPageStarted: (url) {
            logger.i("onPageStarted: $url");   
            if(injectedJavascript != null) {
              runJavascript(injectedJavascript!);
            }         
            _weakSelf.target?.onPageStarted(url);
          },
          onPageFinished: (url) {
            logger.i("onPageFinished: $url");                       
            _weakSelf.target?.onPageFinished(url);
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
    _weakSelf = WeakReference(this);

    super.initState();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
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
