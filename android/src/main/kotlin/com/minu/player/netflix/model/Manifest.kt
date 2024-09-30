package com.minu.player.netflix.model/*
Copyright (c) 2022 Kotlin Data Classes Generated from JSON powered by http://www.json2kotlin.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

For support, please feel free to contact me at https://www.linkedin.com/in/syedabsar */

import com.google.gson.annotations.SerializedName

data class Manifest (
    @SerializedName("audioTextShortcuts") val audioTextShortcuts : List<AudioTextShortcuts>,
    @SerializedName("bookmark") val bookmark : Int,
    @SerializedName("cdnResponseData") val cdnResponseData : CdnResponseData,
    @SerializedName("clientIpAddress") val clientIpAddress : String,
    @SerializedName("drmContextId") val drmContextId : String,
    @SerializedName("drmType") val drmType : String,
    @SerializedName("drmVersion") val drmVersion : Int,
    @SerializedName("duration") val duration : Int,
    @SerializedName("expiration") val expiration : Long,
    @SerializedName("hasClearProfile") val hasClearProfile : Boolean,
    @SerializedName("hasClearStreams") val hasClearStreams : Boolean,
    @SerializedName("hasDrmProfile") val hasDrmProfile : Boolean,
    @SerializedName("hasDrmStreams") val hasDrmStreams : Boolean,
    @SerializedName("links") val links : Links,
    @SerializedName("locations") val locations : List<Locations>,
    @SerializedName("manifestExpirationDuration") val manifestExpirationDuration : Int,
    @SerializedName("movieId") val movieId : Int,
    @SerializedName("packageId") val packageId : Int,
    @SerializedName("playbackContextId") val playbackContextId : String,
    @SerializedName("servers") val servers : List<Servers>,
    @SerializedName("steeringAdditionalInfo") val steeringAdditionalInfo : SteeringAdditionalInfo,
    @SerializedName("timedtexttracks") val timedtexttracks : List<TextTrack>,
    @SerializedName("trickplays") val trickplays : List<Trickplays>,
    @SerializedName("type") val type : String,
    @SerializedName("urlExpirationDuration") val urlExpirationDuration : Int,
    @SerializedName("viewableType") val viewableType : String,
    @SerializedName("badgingInfo") val badgingInfo : BadgingInfo,
    @SerializedName("recommendedMedia") val recommendedMedia : RecommendedMedia,
    @SerializedName("partiallyHydrated") val partiallyHydrated : Boolean,
    @SerializedName("maxRecommendedAudioRank") val maxRecommendedAudioRank : Int,
    @SerializedName("maxRecommendedTextRank") val maxRecommendedTextRank : Int,
    @SerializedName("dpsid") val dpsid : String,
    @SerializedName("auxiliaryManifests") val auxiliaryManifests : List<String>,
    @SerializedName("audio_tracks") val audio_tracks : List<AudioTrack>,
    @SerializedName("isBranching") val isBranching : Boolean,
    @SerializedName("isSupplemental") val isSupplemental : Boolean,
    @SerializedName("video_tracks") val video_tracks : List<VideoTrack>
)