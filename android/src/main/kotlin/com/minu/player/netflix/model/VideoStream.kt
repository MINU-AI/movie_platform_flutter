package com.minu.player.netflix.model

import com.google.gson.annotations.SerializedName
import com.minu.player.netflix.model.Moov
import com.minu.player.netflix.model.Sidx
import com.minu.player.netflix.model.Ssix
import com.minu.player.netflix.model.Stream
import com.minu.player.netflix.model.Urls

class VideoStream(moov: Moov, sidx: Sidx, ssix: Ssix): Stream(moov, sidx, ssix) {
	@SerializedName("trackType")
	val trackType: String = ""
	@SerializedName("content_profile")
	val content_profile: String = ""
	@SerializedName("bitrate")
	val bitrate: Int = 0
	@SerializedName("peakBitrate")
	val peakBitrate: Int = 0
	@SerializedName("dimensionsCount")
	val dimensionsCount: Int = 0
	@SerializedName("dimensionsLabel")
	val dimensionsLabel: String = ""
	@SerializedName("drmHeaderId")
	val drmHeaderId: String = ""
	@SerializedName("pix_w")
	val pix_w: Int = 0
	@SerializedName("pix_h")
	val pix_h: Int = 0
	@SerializedName("res_w")
	val res_w: Int = 0
	@SerializedName("res_h")
	val res_h: Int = 0
	@SerializedName("framerate_value")
	val framerate_value: Long = 0
	@SerializedName("framerate_scale")
	val framerate_scale: Long = 0
	@SerializedName("size")
	val size: Long = 0
	@SerializedName("startByteOffset")
	val startByteOffset: Int = 0
	@SerializedName("vmaf")
	val vmaf: Int = 0
	@SerializedName("segmentVmaf")
	val segmentVmaf: List<String> = emptyList()
	@SerializedName("crop_x")
	val crop_x: Int = 0
	@SerializedName("crop_y")
	val crop_y: Int = 0
	@SerializedName("crop_w")
	val crop_w: Int = 0
	@SerializedName("crop_h")
	val crop_h: Int = 0
	@SerializedName("downloadable_id")
	val downloadable_id: String = ""
	@SerializedName("tags")
	val tags: List<String> = emptyList()
	@SerializedName("new_stream_id")
	val new_stream_id: String = ""
	@SerializedName("type")
	val type: Int = 0
	@SerializedName("urls")
	val urls: List<Urls> = emptyList()
	@SerializedName("isDrm")
	val isDrm: Boolean = false
}