package com.minu.player.netflix.model

import com.google.gson.annotations.SerializedName

open class LanguageTrack (
    @SerializedName("isNoneTrack") val isNoneTrack : Boolean,
    @SerializedName("language") var language : String,
)