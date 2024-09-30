package com.minu.player.netflix.model/*
Copyright (c) 2022 Kotlin Data Classes Generated from JSON powered by http://www.json2kotlin.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

For support, please feel free to contact me at https://www.linkedin.com/in/syedabsar */
import com.google.gson.annotations.SerializedName
import com.minu.player.netflix.model.DrmHeader
import com.minu.player.netflix.model.License
import com.minu.player.netflix.model.Snippets
import com.minu.player.netflix.model.VideoStream

data class VideoTrack (
    @SerializedName("trackType") val trackType : String,
    @SerializedName("track_id") val track_id : String,
    @SerializedName("new_track_id") val new_track_id : String,
    @SerializedName("dimensionsCount") val dimensionsCount : Int,
    @SerializedName("dimensionsLabel") val dimensionsLabel : String,
    @SerializedName("stereo") val stereo : Boolean,
    @SerializedName("profileType") val profileType : String,
    @SerializedName("type") val type : Int,
    @SerializedName("ict") val ict : Boolean,
    @SerializedName("hasClearProfile") val hasClearProfile : Boolean,
    @SerializedName("hasDrmProfile") val hasDrmProfile : Boolean,
    @SerializedName("hasClearStreams") val hasClearStreams : Boolean,
    @SerializedName("hasDrmStreams") val hasDrmStreams : Boolean,
    @SerializedName("groupName") val groupName : String,
    @SerializedName("snippets") val snippets : Snippets,
    @SerializedName("streams") val streams : List<VideoStream>,
    @SerializedName("profile") val profile : String,
    @SerializedName("pixelAspectX") val pixelAspectX : Int,
    @SerializedName("pixelAspectY") val pixelAspectY : Int,
    @SerializedName("maxWidth") val maxWidth : Int,
    @SerializedName("maxHeight") val maxHeight : Int,
    @SerializedName("maxCroppedWidth") val maxCroppedWidth : Int,
    @SerializedName("maxCroppedHeight") val maxCroppedHeight : Int,
    @SerializedName("maxCroppedX") val maxCroppedX : Int,
    @SerializedName("maxCroppedY") val maxCroppedY : Int,
    @SerializedName("max_framerate_value") val max_framerate_value : Long,
    @SerializedName("max_framerate_scale") val max_framerate_scale : Long,
    @SerializedName("minWidth") val minWidth : Int,
    @SerializedName("minHeight") val minHeight : Int,
    @SerializedName("minCroppedWidth") val minCroppedWidth : Int,
    @SerializedName("minCroppedHeight") val minCroppedHeight : Int,
    @SerializedName("minCroppedX") val minCroppedX : Int,
    @SerializedName("minCroppedY") val minCroppedY : Int,
    @SerializedName("flavor") val flavor : String,
    @SerializedName("drmHeader") val drmHeader : DrmHeader,
    @SerializedName("license") val license : License
)