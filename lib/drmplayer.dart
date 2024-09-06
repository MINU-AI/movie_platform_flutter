import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import 'logger.dart';
import 'movie_platform_api.dart';
import 'platform_constant.dart';

abstract class DrmPlayer {
  MoviePayload payload;
  MoviePlatform platform;
 
  final channel = const MethodChannel(platformChannel);
  
  final List<PlayerListener> _listeners = [];

  DrmPlayer({ required this.payload, required this.platform, });

  factory DrmPlayer.creatPlayer({ required MoviePayload payload, required MoviePlatform platform}) {
    if(Platform.isAndroid) {
      return _WideVinePlayer(payload: payload, platform: platform);
    }
    throw "Unimplemented for this platform";
  }

  Map<String, dynamic> get paramsForPlayerView {
    return {
      PlatformViewParams.playbackUrl.name : payload.playback.playbackUrl,
      PlatformViewParams.licenseUrl.name : payload.playback.licenseKeyUrl,
      PlatformViewParams.platformId.name: platform.name,
      PlatformViewParams.metadata.name: payload.metadata,
    };
  }

  void updatePlayer({ required MoviePayload payload, required MoviePlatform platform}){
    this.payload = payload;
    this.platform = platform;

    const MethodChannel(platformChannel).invokeMethod(MethodCalls.controlPlayer.name, {"action" : PlayerControlAction.changePlayback.name, "value" : paramsForPlayerView});
  }

  void pause();

  void stop();

  void seek(Duration duration);

  void play();

  void showControl(bool show);

  Future<int?> get getDuration => channel.invokeMethod(MethodCalls.getDuration.name);

  Future<int?> get currentPosition => channel.invokeMethod(MethodCalls.getCurrentPosition.name);

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

  void onPlayingChange(bool isPlaying);
}

class _WideVinePlayer extends DrmPlayer {
 
  _WideVinePlayer({ required super.payload, required super.platform }) {
    channel.setMethodCallHandler(_handleMethodCall);
  }

  @override
  void play() {
    channel.invokeMethod(MethodCalls.controlPlayer.name, { "action" : PlayerControlAction.play.name });
  }

  @override
  void pause() {
    channel.invokeMethod(MethodCalls.controlPlayer.name, { "action" : PlayerControlAction.pause.name });    
  }

  @override
  void seek(Duration duration) {
    channel.invokeMethod(MethodCalls.controlPlayer.name, { "action" : PlayerControlAction.seek.name, "value" : duration.inMilliseconds });
  }

  @override
  void stop() {
    channel.invokeMethod(MethodCalls.controlPlayer.name, { "action" : PlayerControlAction.stop.name });
  }

  @override
  void showControl(bool show) {
    channel.invokeMethod(MethodCalls.controlPlayer.name, { "action" : PlayerControlAction.showControl.name, "value" : show });
  }
  
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    final nativeCall = MethodCalls.fromString(call.method);
    
    switch(nativeCall) {
      case MethodCalls.refreshToken:
        final platformType = MoviePlatform.fromString(call.arguments as String);
        final platformApi = MoviePlatformApi.create(platformType);
        return platformApi.refreshToken();
      
      case MethodCalls.onPlaybackStateChanged:
        final nativeState = call.arguments as int;
        final playerState = PlayerState.fromInt(nativeState);
        for(final listener in _listeners) {
          listener.onPlaybackStateChanged(playerState);
        }
        // logger.i("Player instance: $this");
      
      case MethodCalls.onPlayerError:
        final error = PlayerError.fromJson(call.arguments);
        for(final listener in _listeners) {
          listener.onPlayerError(error);
        }
      
      case MethodCalls.onPlayingChange:
        final data = call.arguments;
        final isPlaying = data["isPlaying"] as bool;
        logger.i("onPlayingChange: $isPlaying");
        for(final listener in _listeners) {
          listener.onPlayingChange(isPlaying);
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