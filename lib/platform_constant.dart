enum PlatformViewType {
  widevinePlayer
}

enum PlatformViewParams {
  playbackUrl,
  licenseUrl,
  platformId,
  metadata,
}

const platformChannel = "com.minu.player/channel";

enum MethodCalls {
  refreshToken, 
  onPlaybackStateChanged,
  onPlayerError,
  onPlayingChange,
  getDuration,
  getCurrentPosition,
  controlPlayer;

  static MethodCalls fromString(String methodName) {
    switch(methodName) {
      case "refreshToken":
        return refreshToken;
      case "onPlaybackStateChanged":
        return onPlaybackStateChanged;
      case "onPlayerError":
        return onPlayerError;
      case "onPlayingChange":
        return onPlayingChange;
      case "getDuration":
        return getDuration;
      case "getCurrentPosition":
        return getCurrentPosition;
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
