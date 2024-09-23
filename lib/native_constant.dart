enum PlatformViewType {
  widevinePlayer
}

enum PlatformViewParams {
  playbackUrl,
  licenseUrl,
  platformId,
  certificateUrl,
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
  getBufferedPosition,
  getBufferedPercentage,
  setBrightness,
  getBrightness,
  getPlayToTheEnd,
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
      case "getBufferedPercentage":
        return getBufferedPercentage;
      case "getBufferedPosition":
        return getBufferedPosition;
      case "setBrightness":
        return setBrightness;
      case "getBrightness":
        return getBrightness;
      case "getPlayToTheEnd":
        return getPlayToTheEnd;
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
  changePlayback,
  changeVolume
}
