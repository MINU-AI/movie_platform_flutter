package com.minu.player.netflix.model/*
Copyright (c) 2022 Kotlin Data Classes Generated from JSON powered by http://www.json2kotlin.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

For support, please feel free to contact me at https://www.linkedin.com/in/syedabsar */
import com.google.gson.annotations.SerializedName
import com.minuai.thutt.minuplayer.models.netflix.AudioStream

class AudioTrack(isNoneTrack: Boolean, language: String): LanguageTrack(isNoneTrack, language) {
	@SerializedName("trackType")
	val trackType: String = ""
	@SerializedName("rawTrackType")
	val rawTrackType: String = ""
	@SerializedName("channels")
	val channels: String = ""
	@SerializedName("surroundFormatLabel")
	val surroundFormatLabel: String = ""
	@SerializedName("channelsFormat")
	val channelsFormat: String = ""
	@SerializedName("languageDescription")
	val languageDescription: String = ""
	@SerializedName("disallowedSubtitleTracks")
	val disallowedSubtitleTracks: List<String> = emptyList()
	@SerializedName("track_id")
	val track_id: String = ""
	@SerializedName("id")
	val id: String = ""
	@SerializedName("new_track_id")
	val new_track_id: String = ""
	@SerializedName("type")
	val type: Int = 0
	@SerializedName("profileType")
	val profileType: String = ""
	@SerializedName("defaultTimedText")
	val defaultTimedText: String = ""
	@SerializedName("stereo")
	val stereo: Boolean = false
	@SerializedName("profile")
	val profile: String = ""
	@SerializedName("codecName")
	val codecName: String = ""
	@SerializedName("streams")
	val streams: List<AudioStream> = emptyList()
	@SerializedName("rank")
	val rank: Int = 0
	@SerializedName("offTrackDisallowed")
	val offTrackDisallowed: Boolean = false
	@SerializedName("hydrated")
	val hydrated: Boolean = false
	@SerializedName("isNative")
	val isNative: Boolean = false
	@SerializedName("hasDrmStreams")
	val hasDrmStream: Boolean = false
}