package com.minu.player

import androidx.media3.common.util.Assertions
import androidx.media3.common.util.UnstableApi
import androidx.media3.common.util.Util
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DataSourceInputStream
import androidx.media3.datasource.DataSpec
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.datasource.HttpDataSource.InvalidResponseCodeException
import androidx.media3.datasource.StatsDataSource
import androidx.media3.exoplayer.drm.ExoMediaDrm
import androidx.media3.exoplayer.drm.MediaDrmCallback
import androidx.media3.exoplayer.drm.MediaDrmCallbackException
import com.google.common.io.ByteStreams
import java.util.UUID

@UnstableApi
interface MoviePlatformDrmCallback : MediaDrmCallback {
    override fun executeProvisionRequest(
        uuid: UUID,
        request: ExoMediaDrm.ProvisionRequest
    ): ByteArray {
        val url = request.defaultUrl + "&signedRequest=" + String(request.data)
        return executePost(DefaultHttpDataSource.Factory(), url, null, emptyMap())
    }

    val TAG: String
        get() = "MoviePlatformDrmCallback"

    @Throws(MediaDrmCallbackException::class)
    fun executePost(
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
            throw MediaDrmCallbackException(
                originalDataSpec,
                Assertions.checkNotNull(dataSource.lastOpenedUri),
                dataSource.responseHeaders,
                dataSource.bytesRead,  /* cause= */
                e
            )
        }
    }

    fun getRedirectUrl(
        exception: InvalidResponseCodeException, manualRedirectCount: Int
    ): String? {
        // For POST requests, the underlying network stack will not normally follow 307 or 308
        // redirects automatically. Do so manually here.
        val manuallyRedirect = (
                (exception.responseCode == 307 || exception.responseCode == 308)
                        && manualRedirectCount < 5)
        if (!manuallyRedirect) {
            return null
        }
        val headerFields = exception.headerFields
        val locationHeaders = headerFields["Location"]
        if (!locationHeaders.isNullOrEmpty()) {
            return locationHeaders[0]
        }
        return null
    }
}