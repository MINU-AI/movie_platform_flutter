package com.minu.player

import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.media3.common.util.Assertions
import androidx.media3.common.util.UnstableApi
import androidx.media3.common.util.Util
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DataSourceInputStream
import androidx.media3.datasource.DataSpec
import androidx.media3.datasource.HttpDataSource
import androidx.media3.datasource.HttpDataSource.InvalidResponseCodeException
import androidx.media3.datasource.StatsDataSource
import androidx.media3.exoplayer.drm.ExoMediaDrm
import androidx.media3.exoplayer.drm.MediaDrmCallback
import androidx.media3.exoplayer.drm.MediaDrmCallbackException
import com.google.common.io.ByteStreams
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.UUID


@UnstableApi
class DisneyDrmCallback(
    private val binaryMessenger: BinaryMessenger,
    private val licenseUrl: String,
    private val dataSourceFactory: HttpDataSource.Factory,
    private  var token: String,
    ) : MoviePlatformDrmCallback {

    override fun executeKeyRequest(uuid: UUID, request: ExoMediaDrm.KeyRequest): ByteArray {
        val requestProperties: MutableMap<String, String> = HashMap()

        // Add standard request properties for supported schemes.
        requestProperties["Content-Type"] = "application/octet-stream"
        requestProperties["X-BAMSDK-Platform"] = "android-tv"
        requestProperties["Accept"] = "application/json, application/vnd.media-service+json; version=2"
        requestProperties["X-BAMSDK-Client-ID"] = "disney-svod-3d9324fc"
        requestProperties["X-DSS-Edge-Accept"] = "vnd.dss.edge+json; version=2"
        requestProperties["Authorization"] = "Bearer $token"
        return executePost(dataSourceFactory, licenseUrl, request.data, requestProperties)
    }

    @Throws(MediaDrmCallbackException::class)
    override fun executePost(
        dataSourceFactory: DataSource.Factory,
        url: String,
        httpBody: ByteArray?,
        requestProperties: Map<String, String>
    ): ByteArray {
        val dataSource = StatsDataSource(dataSourceFactory.createDataSource())
        var manualRedirectCount = 0
        var dataSpec =
            DataSpec.Builder()
                .setUri(url)
                .setHttpRequestHeaders(requestProperties)
                .setHttpMethod(DataSpec.HTTP_METHOD_POST)
                .setHttpBody(httpBody)
                .setFlags(DataSpec.FLAG_ALLOW_GZIP)
                .build()
        val originalDataSpec = dataSpec
        try {
            while (true) {
                val inputStream = DataSourceInputStream(dataSource, dataSpec)
                try {
                    return ByteStreams.toByteArray(inputStream)
                } catch (e: InvalidResponseCodeException) {
                    val redirectUrl = getRedirectUrl(e, manualRedirectCount) ?: throw e
                    manualRedirectCount++
                    dataSpec = dataSpec.buildUpon().setUri(redirectUrl).build()
                } finally {
                    Util.closeQuietly(inputStream)
                }
            }
        } catch (e: java.lang.Exception) {
            if( e is InvalidResponseCodeException) {
                when(e.responseCode) {
                    401 -> {
                        token = ""
                        Handler(Looper.getMainLooper()).post {
                            MethodChannel(binaryMessenger, platformChannel).invokeMethod(NativeMethodCall.refreshToken.name, MoviePlatformType.disney.name, object: MethodChannel.Result {
                                override fun success(result: Any?) {
                                    Log.i(TAG, "Call native method succeeded: $result")
                                    (result as String?)?.let { newToken ->
                                        //Update new token
                                        Log.i(TAG, "Update new token")
                                        token = newToken
                                    }
                                }

                                override fun error(
                                    errorCode: String,
                                    errorMessage: String?,
                                    errorDetails: Any?
                                ) {
                                    Log.e(TAG, "Call native method with error: $errorCode, $errorMessage")
                                }

                                override fun notImplemented() {
                                    Log.e(TAG, "Call native method with error: notImplemented")
                                }

                            })
                        }
                        while (token.isBlank()) {
                        }
                        return executePost(dataSourceFactory, url, httpBody, requestProperties)
                    }

                    else -> return executePost(dataSourceFactory, url, httpBody, requestProperties)
                }
            }
            throw MediaDrmCallbackException(
                originalDataSpec,
                Assertions.checkNotNull(dataSource.lastOpenedUri),
                dataSource.responseHeaders,
                dataSource.bytesRead,  /* cause= */
                e
            )
        }
    }
}
