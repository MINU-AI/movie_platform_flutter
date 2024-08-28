enum PlatformViewType {
  widevine_player
}

enum PlatformViewParams {
  playbackUrl,
  licenseUrl,
  platformId,
  metadata,
}

const platformChannel = "com.minu.player/channel";

enum NativeMethodCall {
  refreshToken, 
  onPlaybackStateChanged,
  onPlayerError,
  controlPlayer;

  static NativeMethodCall fromString(String methodName) {
    switch(methodName) {
      case "refreshToken":
        return refreshToken;
      case "onPlaybackStateChanged":
        return onPlaybackStateChanged;
      case "onPlayerError":
        return onPlayerError;
      default:
        throw "Unsupported method call :$methodName";
    }
  }
}

enum PlayerControlAction {
  play,
  pause,
  seek,
  stop,
  changePlayback
}
