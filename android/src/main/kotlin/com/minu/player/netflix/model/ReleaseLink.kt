package com.minu.player.netflix.model

import com.google.gson.annotations.SerializedName
import com.minu.player.netflix.model.LicenseLink

data class ReleaseLink (

    @SerializedName("releaseLicense") val releaseLicense : LicenseLink
)