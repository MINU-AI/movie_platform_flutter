package com.minu.player

enum class PlatformViewType {
    widevine_player
}

class PlatformViewParams {
    companion object  {
        const val playbackUrl = "playbackUrl"
        const val licenseUrl = "licenseUrl"
        const val token = "token"
        const val platformId = "platformId"
    }
}

enum class MoviePlatformType {
    youtube, disney, prime, hulu;

    companion object  {
        fun fromString(platformId: String): MoviePlatformType {
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

enum class NativeMethodCall {
    refreshToken,
    onPlaybackStateChanged,
    onPlayerError,
    controlPlayer;

    companion object {
        fun fromString(value: String): NativeMethodCall {
            return when(value) {
                refreshToken.name -> refreshToken
                controlPlayer.name -> controlPlayer
                else -> throw RuntimeException("Unsupported platformId: $value")
            }
        }
    }
}

const val platformChannel = "com.minu.player/channel"
