package com.minu.player.netflix.model

import com.google.gson.annotations.SerializedName


data class DrmHeader (

	@SerializedName("bytes") val bytes : String,
	@SerializedName("checksum") val checksum : String,
	@SerializedName("drmHeaderId") val drmHeaderId : String,
	@SerializedName("keyId") val keyIdId : String,
	@SerializedName("resolution") val resolution : Resolution
)