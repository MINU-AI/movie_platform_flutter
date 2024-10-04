package com.minu.player

import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSource
import androidx.media3.exoplayer.drm.ExoMediaDrm
import java.util.UUID

@UnstableApi
class HuluDrmCallback(private  val dataSourceFactory: DataSource.Factory, private val licenseUrl: String, private  val token: String): MoviePlatformDrmCallback {
    override fun executeKeyRequest(uuid: UUID, request: ExoMediaDrm.KeyRequest): ByteArray {
        // Add standard request properties for supported schemes.
        val requestProperties: MutableMap<String, String> = HashMap()

        requestProperties["Content-Type"] = "application/octet-stream"
        requestProperties["Authorization"] = "Bearer $token"

        return executePost(dataSourceFactory, licenseUrl, request.data, requestProperties)
    }

}