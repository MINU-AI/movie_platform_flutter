package com.minu.player

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.media.MediaCodecList
import android.media.MediaDrm
import android.provider.Settings
import android.util.Log
import android.view.View
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.Tracks
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.datasource.FileDataSource
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.dash.DashMediaSource
import androidx.media3.exoplayer.dash.DefaultDashChunkSource
import androidx.media3.exoplayer.drm.DefaultDrmSessionManager
import androidx.media3.exoplayer.drm.ExoMediaDrm
import androidx.media3.exoplayer.drm.FrameworkMediaDrm
import androidx.media3.exoplayer.drm.WidevineUtil
import androidx.media3.exoplayer.hls.HlsMediaSource
import androidx.media3.exoplayer.source.MediaSource
import androidx.media3.exoplayer.upstream.DefaultAllocator
import androidx.media3.exoplayer.upstream.DefaultBandwidthMeter
import androidx.media3.ui.PlayerView
import com.minu.player.netflix.readInstanceProperty
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import kotlin.reflect.KProperty1
import kotlin.reflect.KVisibility
import kotlin.reflect.full.memberProperties
import kotlin.reflect.jvm.isAccessible


class NativePlayerView(
    val context: Context,
    binaryMessenger: BinaryMessenger,
    private val creationParams: Map<*, *>
) :
    PlatformView {
    val methodChannel = MethodChannel(binaryMessenger, platformChannel).apply {
        setMethodCallHandler(handleMethodCall)
    }

    val videoView: PlayerView = PlayerView(context).apply {
        useController = false
        player = createPlayer(creationParams)
    }

    val player: ExoPlayer?
        get() = videoView.player as ExoPlayer?

    var activity: Activity? = null

    var playToTheEnd = false

    override fun getView(): View {
        return videoView
    }

    override fun dispose() {
        player?.release()
    }

    override fun onFlutterViewAttached(flutterView: View) {
        super.onFlutterViewAttached(flutterView)
        var context = view.context
        while (context is ContextWrapper) {
            context = context.baseContext
            if (context is Activity) {
                activity = context
                break
            }
        }
    }

    override fun onFlutterViewDetached() {
        super.onFlutterViewDetached()
        activity = null
    }

    val TAG = "NativePlayerView"
}

val NativePlayerView.handleMethodCall: MethodChannel.MethodCallHandler
    @OptIn(UnstableApi::class)
    get() = MethodChannel.MethodCallHandler { call, result ->
        val method = MethodCalls.fromString(call.method)
        when(method) {
            MethodCalls.controlPlayer -> {
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
                        val value = params["value"] as Int
                        player?.seekTo(value.toLong())
                    }

                    "changePlayback" -> {
                        val passedParams = params["value"] as Map<*, *>
                        val mediaSource = createMediaSource(passedParams)
                        player?.setMediaSource(mediaSource, true)
                        player?.prepare()
                    }

                    "showControl" -> {
                        val show = params["value"] as Boolean
                        videoView.useController = show
                    }

                    "changeVolume" -> {
                        val volume = params["value"] as Double
                        player?.volume = volume.toFloat()
                    }
                }

                result.success(true)
            }

            MethodCalls.getDuration -> {
                if(player == null) {
                    result.error("player_err", "The player is not initialized", null)
                    return@MethodCallHandler
                }
                result.success(player!!.duration)
            }

            MethodCalls.getCurrentPosition -> {
                if(player == null) {
                    result.error("player_err", "The player is not initialized", null)
                    return@MethodCallHandler
                }
                result.success(player?.currentPosition)
            }

            MethodCalls.getBufferedPosition -> {
                if(player == null) {
                    result.error("player_err", "The player is not initialized", null)
                    return@MethodCallHandler
                }
                result.success(player?.bufferedPosition)
            }

            MethodCalls.getBufferedPercentage -> {
                if(player == null) {
                    result.error("player_err", "The player is not initialized", null)
                    return@MethodCallHandler
                }
                result.success(player?.bufferedPercentage)
            }

            MethodCalls.setBrightness -> {
                val params = call.arguments as Map<*, *>
                val brightness = params["value"] as Double
                activity?.let {
                    val layoutParams = it.window.attributes
                    layoutParams.screenBrightness = brightness.toFloat()
                    it.window.attributes = layoutParams
                }
            }

            MethodCalls.getBrightness -> {
                val brightness = try {
                    // Get the current brightness level (0 to 255)
                    val contentResolver = context.contentResolver
                    Settings.System.getFloat(contentResolver, "screen_brightness_float")
                } catch (e: Settings.SettingNotFoundException) {
                    e.printStackTrace()
                    // Handle exception if brightness setting is not found
                    0
                }
                result.success(brightness.toDouble())
            }

            MethodCalls.getPlayToTheEnd -> {
                result.success(playToTheEnd)
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
        .setBufferDurationsMs(60000, 60 * 60 * 1000, 1500, 3000)
        .setPrioritizeTimeOverSizeThresholds(true)
        .build()

    // Prepare the player.
    val player = ExoPlayer.Builder(context)
        .setLoadControl(defaultLoadControl)
        .setSeekForwardIncrementMs(10000)
        .setSeekBackIncrementMs(10000)
        .build()

    val playWhenReady = creationParams["playWhenReady"] as Boolean

    val mediaDrm = MediaDrm(C.WIDEVINE_UUID)
    val securityLevel = mediaDrm.getPropertyString("securityLevel")
    Log.d(TAG, "Got Widevine securityLevel: $securityLevel")

    player.addListener(object: Player.Listener {
        override fun onPlaybackStateChanged(playbackState: Int) {
            super.onPlaybackStateChanged(playbackState)
            playToTheEnd = playbackState == Player.STATE_ENDED
            methodChannel.invokeMethod(MethodCalls.onPlaybackStateChanged.name, playbackState)
        }

        override fun onPlayerError(error: PlaybackException) {
            super.onPlayerError(error)
            val argument = mutableMapOf<String, Any?>()
            argument["errorCode"] = error.errorCode
            argument["errorCodeName"] = error.errorCodeName
            argument["message"] = error.message
            methodChannel.invokeMethod(MethodCalls.onPlayerError.name, argument )
        }

        override fun onIsPlayingChanged(isPlaying: Boolean) {
            val argument = mutableMapOf<String, Any?>()
            argument["isPlaying"] = isPlaying
            methodChannel.invokeMethod(MethodCalls.onPlayingChange.name, argument)
        }

        override fun onTracksChanged(tracks: Tracks) {
            super.onTracksChanged(tracks)
            for (trackGroup in tracks.groups) {
                for (i in 0..<trackGroup.length) {
                    val format = trackGroup.getTrackFormat(i)
                    Log.d(TAG, "Got video format: ${format.sampleMimeType}, codecs: ${format.codecs}, width: ${format.width}, height: ${format.height}")
                }
            }
        }

    })


    player.playWhenReady = playWhenReady
    player.setMediaSource(createMediaSource(creationParams), true)
    player.prepare()

    return player
}

@OptIn(UnstableApi::class)
fun NativePlayerView.createMediaSource(creationParams: Map<*, *>): MediaSource {
    val platformIdValue = creationParams[PlatformViewParams.platformId] as String
    val playBackUrl: String =  creationParams[PlatformViewParams.playbackUrl] as String
    val moviePlatform = MoviePlatform.fromString(platformIdValue)
    val licenseKeyUrl = creationParams[PlatformViewParams.licenseUrl] as String?
    val metadata = creationParams[PlatformViewParams.metadata] as Map<*, *>

    val drmSchemeUuid = C.WIDEVINE_UUID // DRM Type
    val dataSourceFactory = DefaultHttpDataSource.Factory()
        .setTransferListener(
            DefaultBandwidthMeter.Builder(context)
                .setResetOnNetworkTypeChange(false)
                .build()
        )
        .setConnectTimeoutMs(20000)
        .setReadTimeoutMs(20000)

    val manifestDataSourceFactory = DefaultHttpDataSource.Factory()
    playToTheEnd = false

    when(moviePlatform) {
        MoviePlatform.disney -> {
            val token = metadata["token"] as String
            val disneyMediaDrmCallback = DisneyDrmCallback(methodChannel, licenseKeyUrl!!, dataSourceFactory, token)
            val drmSessionManager = DefaultDrmSessionManager
                                                                .Builder()
                                                                .setMultiSession(true)
                                                                .build(disneyMediaDrmCallback)

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
                                    .build()
                            )
                            .setMimeType(MimeTypes.APPLICATION_M3U8)
                            .setTag(null)
                            .build()
                    )

            return hlsMediaSource
        }

        MoviePlatform.prime -> {
            val movieId = metadata["movieId"] as String
            val deviceId = metadata["deviceId"] as String
            val mid = metadata["mid"] as String
            val cookies = metadata["cookies"] as String
            val primeMediaDrmCallback = PrimeDrmCallback(dataSourceFactory, movieId, deviceId, mid, cookies )
            val drmSessionManager = DefaultDrmSessionManager
                                                                .Builder()
                                                                .build(primeMediaDrmCallback)
            val dashChunkSourceFactory = DefaultDashChunkSource.Factory(dataSourceFactory)

            val dashMediaSource = DashMediaSource.Factory(dashChunkSourceFactory, manifestDataSourceFactory)
                    .setDrmSessionManagerProvider { drmSessionManager }
                    .createMediaSource(
                        MediaItem.Builder()
                            .setUri(playBackUrl)
                            // DRM Configuration
                            .setDrmConfiguration(
                                MediaItem.DrmConfiguration.Builder(drmSchemeUuid)
                                    .setLicenseUri(licenseKeyUrl)
                                    .build()
                            )
                            .setMimeType(MimeTypes.APPLICATION_MPD)
                            .setTag(null)
                            .build()
                    )

            return dashMediaSource
        }

        MoviePlatform.youtube, MoviePlatform.youtubeMusic -> {
            val hlsMediaSource =
                HlsMediaSource.Factory(manifestDataSourceFactory)
                    .createMediaSource(
                        MediaItem.Builder()
                            .setUri(playBackUrl)
                            .setMimeType(MimeTypes.APPLICATION_M3U8)
                            .build()
                    )

            return hlsMediaSource
        }

        MoviePlatform.hulu -> {
            val fileSourceFactory = FileDataSource.Factory()
            val dashChunkSourceFactory = DefaultDashChunkSource.Factory(dataSourceFactory)
            val token = metadata["token"] as String
            val primeMediaDrmCallback = HuluDrmCallback(dataSourceFactory, licenseKeyUrl!!, token)

            val frameworkMediaDrm = FrameworkMediaDrm.newInstance(C.WIDEVINE_UUID)
            val kClass = frameworkMediaDrm::class
            val mediaDrmProperty = kClass.memberProperties.find { it.name == "mediaDrm" }
            mediaDrmProperty?.let { item ->
                item.isAccessible = true
                item as KProperty1<FrameworkMediaDrm, MediaDrm>
                val value = item.get(frameworkMediaDrm)
                value.setPropertyString("securityLevel", "L3")
            }

            val drmSessionManager = DefaultDrmSessionManager
                .Builder()
                .setUuidAndExoMediaDrmProvider(C.WIDEVINE_UUID) { frameworkMediaDrm }
                .build(primeMediaDrmCallback)
            val dashMediaSource = DashMediaSource.Factory(dashChunkSourceFactory, fileSourceFactory)
                .setDrmSessionManagerProvider { drmSessionManager }
                .createMediaSource(
                    MediaItem.Builder()
                        .setUri(playBackUrl)
                        // DRM Configuration
                        .setDrmConfiguration(
                            MediaItem.DrmConfiguration.Builder(drmSchemeUuid)
//                                .setLicenseUri(licenseKeyUrl)
//                                .setLicenseRequestHeaders(mapOf("Authorization" to "Bearer $token"))
                                .build()
                        )
                        .setMimeType(MimeTypes.APPLICATION_MPD)
                        .build()
                )

            return dashMediaSource
        }

        else -> {
            throw RuntimeException("Unimplemented player for movie platform: $moviePlatform")
        }
    }
}

fun printSupportedCodes() {
    val codecList = MediaCodecList(MediaCodecList.ALL_CODECS)
    val codecInfos = codecList.codecInfos

    for (codecInfo in codecInfos) {
        if (!codecInfo.isEncoder) {
            val supportedTypes = codecInfo.supportedTypes
            for (type in supportedTypes) {
                if (type.equals("video/avc", ignoreCase = true)) {
                    val capabilities = codecInfo.getCapabilitiesForType("video/avc")
                    val profileLevels = capabilities.profileLevels

                    for (profileLevel in profileLevels) {
                        Log.d("Got CodecSupport", "H.264 profile ${profileLevel.profile} with level ${profileLevel.level} is supported")
                    }
                }
            }
        }
    }
}