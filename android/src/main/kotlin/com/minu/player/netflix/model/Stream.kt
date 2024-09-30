package com.minu.player.netflix.model

import com.google.gson.annotations.SerializedName
import com.minu.player.netflix.model.Moov
import com.minu.player.netflix.model.Sidx
import com.minu.player.netflix.model.Ssix

open class Stream (
    @SerializedName("moov") val moov : Moov,
    @SerializedName("sidx") val sidx : Sidx,
    @SerializedName("ssix") val ssix : Ssix,
)