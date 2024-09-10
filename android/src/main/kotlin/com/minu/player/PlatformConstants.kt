package com.minu.player

enum class PlatformViewType {
    widevinePlayer
}

class PlatformViewParams {
    companion object  {
        const val playbackUrl = "playbackUrl"
        const val licenseUrl = "licenseUrl"
        const val platformId = "platformId"
        const val metadata = "metadata"
    }
}

enum class MoviePlatform {
    youtube, disney, prime, hulu;

    companion object  {
        fun fromString(platformId: String): MoviePlatform {
            return when(platformId) {
                youtube.name -> youtube
                disney.name -> disney
                prime.name -> prime
                hulu.name -> hulu
                else -> throw RuntimeException("Unsupported platformId: $platformId")
            }
        }
    }
}

enum class MethodCalls {
    refreshToken,
    onPlaybackStateChanged,
    onPlayerError,
    onPlayingChange,
    getDuration,
    getCurrentPosition,
    getBufferedPosition,
    getBufferedPercentage,
    setBrightness,
    controlPlayer;

    companion object {
        fun fromString(value: String): MethodCalls {
            return when(value) {
                refreshToken.name -> refreshToken
                controlPlayer.name -> controlPlayer
                getDuration.name -> getDuration
                getCurrentPosition.name -> getCurrentPosition
                getBufferedPercentage.name -> getBufferedPercentage
                getBufferedPosition.name -> getBufferedPosition
                setBrightness.name -> setBrightness
                else -> throw RuntimeException("Unsupported platformId: $value")
            }
        }
    }
}

const val platformChannel = "com.minu.player/channel"
