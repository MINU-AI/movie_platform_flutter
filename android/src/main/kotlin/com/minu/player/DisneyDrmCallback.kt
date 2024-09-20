package com.minu.player

import android.os.Handler
import android.os.Looper
import android.provider.ContactsContract.Data
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
import androidx.media3.exoplayer.drm.MediaDrmCallbackException
import com.google.common.io.ByteStreams
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Semaphore
import okhttp3.internal.wait
import java.util.Date
import java.util.UUID


@UnstableApi
class DisneyDrmCallback(
    private val channel: MethodChannel,
    private val licenseUrl: String,
    private val dataSourceFactory: HttpDataSource.Factory,
    private  var token: String,
    ) :
    MoviePlatformDrmCallback {

    private var retryTimePoint: Long? = null
    private val maxRetryTime = 2 * 60 * 1000

    override fun executeKeyRequest(uuid: UUID, request: ExoMediaDrm.KeyRequest): ByteArray {
        val requestProperties: MutableMap<String, String> = HashMap()

        // Add standard request properties for supported schemes.
        requestProperties["Content-Type"] = "application/octet-stream"
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
                        val oldToken = token
                        token = ""
                        val semaphore = Semaphore(1)
                        MainScope().launch {
                            channel.invokeMethod(MethodCalls.refreshToken.name, MoviePlatform.disney.name, object: MethodChannel.Result {
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
                                    token = oldToken
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

                    else -> {
                        if (retryTimePoint == null) {
                            retryTimePoint = Date().time
                        }
                        val currentTime = Date().time
                        if(currentTime - retryTimePoint!! > maxRetryTime) {
                            retryTimePoint = null
                            throw MediaDrmCallbackException(
                                originalDataSpec,
                                Assertions.checkNotNull(dataSource.lastOpenedUri),
                                dataSource.responseHeaders,
                                dataSource.bytesRead,  /* cause= */
                                e
                            )
                        }
                        try {
                            Thread.sleep(1000)
                        } catch (_: InterruptedException) {
                        }
                        return executePost(dataSourceFactory, url, httpBody, requestProperties)
                    }
                }
            }
            retryTimePoint = null
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
