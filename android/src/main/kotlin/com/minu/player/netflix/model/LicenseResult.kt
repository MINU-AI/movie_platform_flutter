package com.minu.player.netflix.model

import com.google.gson.annotations.SerializedName

class LicenseResult (
    @SerializedName("drmSessionId") val drmSessionId : String,
    @SerializedName("licenseResponseBase64") val licenseResponseBase64 : String,
    @SerializedName("links") val links : ReleaseLink,
    @SerializedName("secureStopExpected") val secureStopExpected : Boolean,
    @SerializedName("providerSessionToken") val providerSessionToken : String
)