package com.minu.player

import android.media.MediaDrm
import android.media.UnsupportedSchemeException
import android.util.Base64
import android.util.Log
import androidx.media3.common.C
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSource
import androidx.media3.exoplayer.drm.ExoMediaDrm
import okhttp3.FormBody
import okhttp3.HttpUrl
import okhttp3.HttpUrl.Companion.toHttpUrl
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody
import org.json.JSONObject
import java.util.UUID


@UnstableApi
class PrimeDrmCallback(
    private val dataSourceFactory: DataSource.Factory,
    private val movieId: String,
    private val deviceId: String,
    private val mid: String,
    private val cookies: String
): MoviePlatformDrmCallback {

    override fun executeKeyRequest(uuid: UUID, request: ExoMediaDrm.KeyRequest): ByteArray {
        val okHttpClient = OkHttpClient()
        val getResourceUrl = "https://atv-ps.amazon.com/cdp/catalog/GetPlaybackResources"
        val httpBuilder = getResourceUrl.toHttpUrl().newBuilder()
        httpBuilder.addQueryParameter("asin", movieId)
        httpBuilder.addQueryParameter("deviceID", deviceId)
        httpBuilder.addQueryParameter("deviceTypeID", "AOAGZA014O5RE")
        httpBuilder.addQueryParameter("gascEnabled", "false")
        httpBuilder.addQueryParameter("marketplaceID", mid)
        httpBuilder.addQueryParameter("firmware", "1")
        httpBuilder.addQueryParameter("operatingSystemName", "Windows")
        httpBuilder.addQueryParameter("consumptionType", "Streaming")
        httpBuilder.addQueryParameter("desiredResources", "Widevine2License")
        httpBuilder.addQueryParameter("resourceUsage", "ImmediateConsumption")
        httpBuilder.addQueryParameter("videoMaterialType", "Feature")
        httpBuilder.addQueryParameter("deviceProtocolOverride", "Https")
        httpBuilder.addQueryParameter("deviceStreamingTechnologyOverride", "DASH")
        httpBuilder.addQueryParameter("deviceDrmOverride", "CENC")
        httpBuilder.addQueryParameter("deviceHdrFormatsOverride", "None")
        httpBuilder.addQueryParameter("deviceVideoCodecOverride", "H264")
        httpBuilder.addQueryParameter("deviceVideoQualityOverride", "HD")
        httpBuilder.addQueryParameter("deviceBitrateAdaptationsOverride", "CBR")

        try {
            val securityLevel = MediaDrm(C.WIDEVINE_UUID).getPropertyString("securityLevel")

            if (securityLevel === "L3") {
                httpBuilder.addQueryParameter("operatingSystemName", "Android")
            } else {
                httpBuilder.addQueryParameter("operatingSystemName", "Windows")
                httpBuilder.addQueryParameter("deviceVideoQualityOverride", "HD")
            }
        } catch (e: UnsupportedSchemeException) {
            e.printStackTrace()
        }

        val base64Key: String = Base64.encodeToString(request.data, Base64.NO_WRAP)

        val formBody: RequestBody = FormBody.Builder()
            .add("widevine2Challenge", base64Key)
            .add("includeHdcpTestKeyInLicense", "true")
            .build()

        val contentType = "application/x-www-form-urlencoded".toMediaType()
        val requestHTTP = Request.Builder()
            .header("Cookie", cookies)
            .header("Content-Type", "application/x-www-form-urlencoded")
            .url(httpBuilder.build())
            .post(formBody)
            .build()

        try {
            val response = okHttpClient.newCall(requestHTTP).execute()
            val responseCode = response.code
            if (responseCode == 200) {
                response.body?.string()?.let { result ->
                    val resultJson = JSONObject(result)
                    Log.i(TAG, "Got license result: $result")
                    val licenseKey = resultJson.optJSONObject("widevine2License")?.optString("license")
                    Log.i(TAG, "Got license: $licenseKey")
                    if(!licenseKey.isNullOrEmpty()) {
                      return Base64.decode(licenseKey, Base64.NO_WRAP)
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        return ByteArray(0)
    }
}