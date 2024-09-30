package com.minu.player.netflix.model/*
Copyright (c) 2022 Kotlin Data Classes Generated from JSON powered by http://www.json2kotlin.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

For support, please feel free to contact me at https://www.linkedin.com/in/syedabsar */
import com.google.gson.annotations.SerializedName
import com.minu.player.netflix.model.Cdn
import com.minu.player.netflix.model.LanguageTrack


class TextTrack(isNoneTrack: Boolean, language: String): LanguageTrack(isNoneTrack, language) {
	@SerializedName("type")
	val type: String = ""
	@SerializedName("trackType")
	val trackType: String = ""
	@SerializedName("rawTrackType")
	val rawTrackType: String = ""
	@SerializedName("id")
	val id: String = ""
	@SerializedName("new_track_id")
	val new_track_id: String = ""
	@SerializedName("languageDescription")
	val languageDescription: String = ""
	@SerializedName("downloadableIds")
	val downloadableIds: Map<String, String> = emptyMap()
	@SerializedName("ttDownloadables")
	val ttDownloadables: Map<String, Map<String, Any>> = emptyMap()
	@SerializedName("cdnlist")
	val cdnlist: List<Cdn> = emptyList()
	@SerializedName("rank")
	val rank: Int = 0
	@SerializedName("hydrated")
	val hydrated: Boolean = false
	@SerializedName("encodingProfileNames")
	val encodingProfileNames: List<String> = emptyList()
	@SerializedName("isLanguageLeftToRight")
	val isLanguageLeftToRight: Boolean = false
	@SerializedName("isForcedNarrative")
	val isForcedNarrative: Boolean = false
}