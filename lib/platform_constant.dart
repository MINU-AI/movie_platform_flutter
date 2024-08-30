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
  onPlayingChange,
  controlPlayer;

  static NativeMethodCall fromString(String methodName) {
    switch(methodName) {
      case "refreshToken":
        return refreshToken;
      case "onPlaybackStateChanged":
        return onPlaybackStateChanged;
      case "onPlayerError":
        return onPlayerError;
      case "onPlayingChange":
        return onPlayingChange;
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
  showControl,
  changePlayback
}
