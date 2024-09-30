package com.minuai.thutt.minuplayer.models.netflix/*
Copyright (c) 2022 Kotlin Data Classes Generated from JSON powered by http://www.json2kotlin.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

For support, please feel free to contact me at https://www.linkedin.com/in/syedabsar */
import com.google.gson.annotations.SerializedName
import com.minu.player.netflix.model.Moov
import com.minu.player.netflix.model.Sidx
import com.minu.player.netflix.model.Ssix
import com.minu.player.netflix.model.Stream
import com.minu.player.netflix.model.Urls

class AudioStream(moov: Moov, sidx: Sidx, ssix: Ssix): Stream(moov, sidx, ssix) {
	@SerializedName("trackType")
	 val trackType: String = ""
	@SerializedName("content_profile")
	val content_profile: String = ""
	@SerializedName("bitrate")
	val bitrate: Int = 0
	@SerializedName("size")
	val size: Long = 0
	@SerializedName("downloadable_id")
	val downloadable_id: String = ""
	@SerializedName("new_stream_id")
	val new_stream_id: String = ""
	@SerializedName("type")
	val type: Int = 0
	@SerializedName("channels")
	val channels: String = ""
	@SerializedName("surroundFormatLabel")
	val surroundFormatLabel: String = ""
	@SerializedName("channelsFormat")
	val channelsFormat: String = ""
	@SerializedName("language")
	val language: String = ""
	@SerializedName("tags")
	val tags: List<String> = emptyList()
	@SerializedName("urls")
	val urls: List<Urls> = emptyList()
	@SerializedName("audioKey")
	val audioKey: String? = null
	@SerializedName("isDrm")
	val isDrm: Boolean = false
}
