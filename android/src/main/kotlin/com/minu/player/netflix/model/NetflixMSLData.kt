package com.minu.player.netflix.model

data class MSLData (
    var key_set_id: String = "",
    var key_id: String = "",
    var hmac_key_id: String = "",
    var tokens: Tokens? = null,
    var boundESN: String = "",
    var user_id_tokens: HashMap<String, MasterToken> = HashMap()
)

data class Tokens (
    var mastertoken: MasterToken
)

data class KeyResponse (
    val mastertoken: MasterToken,
    val keydata: KeyData
)

data class KeyData (
    val cdmkeyresponse: String,
    val encryptionkeyid: String,
    val hmackeyid: String
)

data class MasterToken (
    var tokendata: String = "",
    var signature: String = ""
)

data class HeaderData (
    val keyresponsedata: KeyResponse
)

data class TokenData (
    val serialNumber: Long,
    val sequenceNumber: Int,
    val renewalWindow: Long,
    val expiration: Long
)

//data class Chunk (
//    val payload = ""
//    val signature = ""
//)

data class EncryptionEnvelope (
    val ciphertext: String,
    val iv: String
)

data class PlainText (
    val data: String,
    val compressionalgo: String
)

data class AuthData (
    var useSwitchProfile: Boolean = false,
    var userIdToken: MasterToken? = null
)
