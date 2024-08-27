
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
  final bool isLoggedIn;

  const MovieWebView({super.key, required this.isLoggedIn });

  factory MovieWebView.create({ required MoviePlatformType platform }) {
    switch(platform) {
      case MoviePlatformType.disney:
        return const DisneyWebView(isLoggedIn: false);
      default:
        throw "Unsupported platform: $platform";
    }
  }
}

abstract class PlatformState< V extends MovieWebView> extends State<V> {

  late final WebViewController _controller;

  void onUrlChange(UrlChange urlChange) {}

  void onPageStarted(String url) {}

  void onPageFinished(String url) {}

  void onJavascriptReceived(String message){}

  String? get injectedJs {
    return null;
  }

  abstract final String url;

  bool _showLoading = false;

  String? get userAgent => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.54 Safari/537.36";

  void toggleLoading(bool value) {
    setState(() {
      _showLoading = value;
    });
  }

  @override
  void initState() {
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
      ..setUserAgent(userAgent)
      ..loadRequest(Uri.parse(url));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
            child: Stack(
                    children: [
                      WebViewWidget(                        
                        controller: _controller,
                        gestureRecognizers: gestureRecognizers,
                      ),

                      Visibility(
                        visible: _showLoading,
                        child: const LoadingView(),
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