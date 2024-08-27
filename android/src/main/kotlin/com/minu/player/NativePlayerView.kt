package com.minu.player

import android.content.Context
import android.view.View
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.drm.DefaultDrmSessionManager
import androidx.media3.exoplayer.hls.HlsMediaSource
import androidx.media3.exoplayer.source.MediaSource
import androidx.media3.exoplayer.upstream.DefaultAllocator
import androidx.media3.exoplayer.upstream.DefaultBandwidthMeter
import androidx.media3.ui.PlayerView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView


class NativePlayerView(
    val context: Context,
    val binaryMessenger: BinaryMessenger,
    val id: Int,
    private val creationParams: Map<*, *>
) :
    PlatformView {
    val methodChannel = MethodChannel(binaryMessenger, platformChannel).apply {
        setMethodCallHandler(handleMethodCall)
    }

    private val videoView: PlayerView = PlayerView(context).apply {
//        useController = false
        player = createPlayer(creationParams)
    }

    val player: ExoPlayer?
        get() = videoView.player as ExoPlayer?

    override fun getView(): View {
        return videoView
    }

    override fun dispose() {
        player?.release()
    }

    val TAG = "NativePlayerView"
}

val NativePlayerView.handleMethodCall: MethodChannel.MethodCallHandler
    @OptIn(UnstableApi::class)
    get() = MethodChannel.MethodCallHandler { call, result ->
        val method = NativeMethodCall.fromString(call.method)
        when(method) {
            NativeMethodCall.controlPlayer -> {
                val params = call.arguments as Map<*, *>
                val action = params["action"] as String

                when(action) {
                    "play" -> {
                        player?.play()
                    }

                    "pause" -> {
                        player?.pause()
                    }

                    "stop" -> {
                        player?.stop()
                    }

                    "seek" -> {
                        val value = params["value"] as Long
                        player?.seekTo(value)
                    }

                    "changePlayback" -> {
                        val passedParams = params["value"] as Map<*, *>
                        val mediaSource = createMediaSource(passedParams)
                        player?.setMediaSource(mediaSource, true)
                        player?.prepare()
                    }
                }

                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }


    }

@OptIn(UnstableApi::class)
fun NativePlayerView.createPlayer(creationParams: Map<*, *>): Player {
    val defaultLoadControl = DefaultLoadControl.Builder()
        .setAllocator(DefaultAllocator(true, C.DEFAULT_BUFFER_SEGMENT_SIZE))
        .setTargetBufferBytes(C.LENGTH_UNSET)
        .setBufferDurationsMs(1000, 2000, 500, 500)
        .setPrioritizeTimeOverSizeThresholds(true)
        .build()

    // Prepare the player.
    val player = ExoPlayer.Builder(context)
        .setLoadControl(defaultLoadControl)
        .setSeekForwardIncrementMs(10000)
        .setSeekBackIncrementMs(10000)
        .build()

    player.addListener(object: Player.Listener {
        override fun onPlaybackStateChanged(playbackState: Int) {
            super.onPlaybackStateChanged(playbackState)
            methodChannel.invokeMethod(NativeMethodCall.onPlaybackStateChanged.name, playbackState)
        }

        override fun onPlayerError(error: PlaybackException) {
            super.onPlayerError(error)
            val argument = mutableMapOf<String, Any?>()
            argument["errorCode"] = error.errorCode
            argument["errorCodeName"] = error.errorCodeName
            argument["message"] = error.message
            methodChannel.invokeMethod(NativeMethodCall.onPlayerError.name, argument )
        }
    })


    player.playWhenReady = true
    player.setMediaSource(createMediaSource(creationParams), true)
    player.prepare()

    return player
}

@OptIn(UnstableApi::class)
fun NativePlayerView.createMediaSource(creationParams: Map<*, *>): MediaSource {
    val platformIdValue = creationParams[PlatformViewParams.platformId] as String
    val playBackUrl: String =  creationParams[PlatformViewParams.playbackUrl] as String
    val moviePlatformType = MoviePlatformType.fromString(platformIdValue)
    val licenseKeyUrl = creationParams[PlatformViewParams.licenseUrl] as String
    val token = creationParams[PlatformViewParams.token] as String?

    val drmSchemeUuid = C.WIDEVINE_UUID // DRM Type

    when(moviePlatformType) {
        MoviePlatformType.disney -> {
            val dataSourceFactory = DefaultHttpDataSource.Factory()
                .setTransferListener(
                    DefaultBandwidthMeter.Builder(context)
                        .setResetOnNetworkTypeChange(false)
                        .build()
                )
                .setConnectTimeoutMs(20000)
                .setReadTimeoutMs(20000)

            val disneyMediaDrmCallback = DisneyDrmCallback(binaryMessenger, licenseKeyUrl, dataSourceFactory, token!!)
            val drmSessionManager = DefaultDrmSessionManager.Builder().build(disneyMediaDrmCallback)
            val manifestDataSourceFactory = DefaultHttpDataSource.Factory()

            val hlsMediaSource =
                HlsMediaSource.Factory(manifestDataSourceFactory)
                    .setDrmSessionManagerProvider { drmSessionManager }
                    .createMediaSource(
                        MediaItem.Builder()
                            .setUri(playBackUrl)
                            // DRM Configuration
                            .setDrmConfiguration(
                                MediaItem.DrmConfiguration.Builder(drmSchemeUuid)
                                    .setLicenseUri(licenseKeyUrl)
//                                    .setLicenseRequestHeaders(mapOf("Content-Type" to "application/octet-stream"))
//                                    .setLicenseRequestHeaders(mapOf("X-BAMSDK-Platform" to "android-tv"))
//                                    .setLicenseRequestHeaders(mapOf("Accept" to "application/json, application/vnd.media-service+json; version=2"))
//                                    .setLicenseRequestHeaders(mapOf("X-BAMSDK-Client-ID" to "disney-svod-3d9324fc"))
//                                    .setLicenseRequestHeaders(mapOf("X-DSS-Edge-Accept" to "vnd.dss.edge+json; version=2"))
//                                    .setLicenseRequestHeaders(mapOf("Authorization" to "Bearer $token"))
                                    .build()
                            )
                            .setMimeType(MimeTypes.APPLICATION_M3U8)
                            .setTag(null)
                            .build()
                    )

            return hlsMediaSource
        }
        else -> {
            throw RuntimeException("Unimplemented player for movie platform: $moviePlatformType")
        }
    }
}