package com.minu.player.netflix.model

data class Cdn(
    val id: String,
    val key: String,
    val lowgrade: Boolean,
    val name: String,
    val rank: Int,
    val type: String
)
