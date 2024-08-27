import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'logger.dart';
import 'movie_platform_api.dart';
import 'platform_constant.dart';
import 'player_view.dart';

abstract class DrmPlayer {
  MoviePlayback moviePlayback;
  MoviePlatformType platform;
  String? authorizeToken;
 
  final channel = const MethodChannel(platformChannel);
  
  final List<PlayerListener> _listeners = [];

  DrmPlayer({ required this.moviePlayback, required this.platform, this.authorizeToken });

  factory DrmPlayer.creatPlayer({ required MoviePlayback moviePlayback, required MoviePlatformType platform, String? authorizeToken}) {
    if(Platform.isAndroid) {
      return _WideVinePlayer(moviePlayback: moviePlayback, platform: platform, authorizeToken: authorizeToken);
    }
    throw "Unimplemented for this platform";
  }

  Map<String, dynamic> get paramsForPlayerView {
    return {
      PlatformViewParams.playbackUrl.name : moviePlayback.playbackUrl,
      PlatformViewParams.licenseUrl.name : moviePlayback.licenseKeyUrl,
      PlatformViewParams.platformId.name: platform.name,
      PlatformViewParams.token.name : authorizeToken
    };
  }

  void updatePlayer({ required MoviePlayback moviePlayback, required MoviePlatformType platform, String? authorizeToken}){
    this.moviePlayback = moviePlayback;
    this.platform = platform;
    this.authorizeToken = authorizeToken;
  }

  Widget get widgetPlayer {
    return PlayerView.creatPlater(player: this, params: paramsForPlayerView);
  }

  void pause();

  void stop();

  void seek(Duration duration);

  void play();

  void addListener(PlayerListener listener) {
    if(!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  void removeListener(PlayerListener listener) {
    _listeners.remove(listener);
  }
  
}

mixin PlayerListener {
  void onPlaybackStateChanged(PlayerState state);

  void onPlayerError(PlayerError error);
}

class _WideVinePlayer extends DrmPlayer {
 
  _WideVinePlayer({ required super.moviePlayback, required super.platform, super.authorizeToken }) {
    channel.setMethodCallHandler(_handleMethodCall);
  }

  @override
  void play() {
    channel.invokeMethod(NativeMethodCall.controlPlayer.name, { "action" : PlayerControlAction.play.name });
  }

  @override
  void pause() {
    channel.invokeMethod(NativeMethodCall.controlPlayer.name, { "action" : PlayerControlAction.pause.name });    
  }

  @override
  void seek(Duration duration) {
    channel.invokeMethod(NativeMethodCall.controlPlayer.name, { "action" : PlayerControlAction.seek.name, "value" : duration.inMilliseconds });
  }

  @override
  void stop() {
    channel.invokeMethod(NativeMethodCall.controlPlayer.name, { "action" : PlayerControlAction.stop.name });
  }
  
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    final nativeCall = NativeMethodCall.fromString(call.method);
    
    switch(nativeCall) {
      case NativeMethodCall.refreshToken:
        final platformType = MoviePlatformType.fromString(call.arguments as String);
        final platformApi = MoviePlatformFactory.create(platformType);
        return platformApi.refreshToken();
      
      case NativeMethodCall.onPlaybackStateChanged:
        final nativeState = call.arguments as int;
        final playerState = PlayerState.fromInt(nativeState);
        for(final listener in _listeners) {
          listener.onPlaybackStateChanged(playerState);
        }
        logger.i("Player instance: $this");
      
      case NativeMethodCall.onPlayerError:
        final error = PlayerError.fromJson(call.arguments);
        for(final listener in _listeners) {
          listener.onPlayerError(error);
        }
        
      default:
        throw "Unsupported method call: $nativeCall";
    }
  } 
}

enum PlayerState {
  idle, bufferring, ready, end;

  static PlayerState fromInt(int value) {
    switch(value) {
      case 1: return idle;
      case 2: return bufferring;
      case 3: return ready;
      case 4: return end;
      default: throw "Incorrect player state value: $value";
    }
  }
}


class PlayerError extends Error {
  final int errorCode;
  final String errorCodeName;
  final String? message;

  PlayerError({required this.errorCode, required this.errorCodeName, required this.message});
  
  factory PlayerError.fromJson(dynamic data) {
    return PlayerError(errorCode: data["errorCode"], errorCodeName: data["errorCodeName"], message: data["message"]);
  } 

  dynamic toJson() => {
      "errorCode" : errorCode,
      "errorCodeName" : errorCodeName,
      "message" : message
    };

  @override
  String toString() {
    return "${toJson()}";
  }
}