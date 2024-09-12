import 'dart:async';

import 'package:flutter/services.dart';

import 'logger.dart';
import 'movie_platform_api.dart';
import 'native_constant.dart';

class DrmPlayer {
  MoviePayload payload;
  MoviePlatform platform;
 
  final channel = const MethodChannel(platformChannel);
  
  final List<PlayerListener> _listeners = [];

  DrmPlayer({ required this.payload, required this.platform, }) {
     channel.setMethodCallHandler(_handleMethodCall);
  }

  Map<String, dynamic> get paramsForPlayerView {
    return {
      PlatformViewParams.playbackUrl.name : payload.playback.playbackUrl,
      PlatformViewParams.licenseUrl.name : payload.playback.licenseKeyUrl,
      PlatformViewParams.certificateUrl.name : payload.playback.licenseCertificateUrl,
      PlatformViewParams.platformId.name: platform.name,
      PlatformViewParams.metadata.name: payload.metadata,
    };
  }

  void updatePlayer({ required MoviePayload payload, required MoviePlatform platform}){
    this.payload = payload;
    this.platform = platform;

    const MethodChannel(platformChannel).invokeMethod(MethodCalls.controlPlayer.name, {"action" : PlayerControlAction.changePlayback.name, "value" : paramsForPlayerView});
  }

  void play() {
    channel.invokeMethod(MethodCalls.controlPlayer.name, { "action" : PlayerControlAction.play.name });
  }

  void pause() {
    channel.invokeMethod(MethodCalls.controlPlayer.name, { "action" : PlayerControlAction.pause.name });    
  }

  void seek(Duration duration) {
    channel.invokeMethod(MethodCalls.controlPlayer.name, { "action" : PlayerControlAction.seek.name, "value" : duration.inMilliseconds });
  }

  void stop() {
    channel.invokeMethod(MethodCalls.controlPlayer.name, { "action" : PlayerControlAction.stop.name });
  }

  void showControl(bool show) {
    channel.invokeMethod(MethodCalls.controlPlayer.name, { "action" : PlayerControlAction.showControl.name, "value" : show });
  }

  Future<int?> get duration => channel.invokeMethod(MethodCalls.getDuration.name);

  Future<int?> get currentPosition => channel.invokeMethod(MethodCalls.getCurrentPosition.name);

  Future<int?> get bufferedPosition => channel.invokeMethod(MethodCalls.getBufferedPosition.name);

  Future<int?> get bufferedPercentage => channel.invokeMethod(MethodCalls.getBufferedPercentage.name);

   void setBrightness(double brightness) {
    channel.invokeMethod(MethodCalls.setBrightness.name, {"value" : brightness });
  }

  void addListener(PlayerListener listener) {
    if(!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  void removeListener(PlayerListener listener) {
    _listeners.remove(listener);
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
        logger.i("Got onPlayingChange: $isPlaying");
        for(final listener in _listeners) {
          listener.onPlayingChange(isPlaying);
        }
        
      default:
        throw "Unsupported method call: $nativeCall";
    }
  }
  
}

mixin PlayerListener {
  void onPlaybackStateChanged(PlayerState state);

  void onPlayerError(PlayerError error);

  void onPlayingChange(bool isPlaying);
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