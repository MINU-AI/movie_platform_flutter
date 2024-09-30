package com.minu.player.netflix

import android.content.Context
import android.media.MediaDrm
import android.preference.PreferenceManager
import android.util.Base64
import android.util.Log
import androidx.media3.common.C
import com.google.gson.Gson
import com.minu.player.netflix.model.KeyResponse
import com.minu.player.netflix.model.MSLData
import com.minu.player.netflix.model.MasterToken
import com.minuai.thutt.minuplayer.models.netflix.*
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.lang.Exception
import java.security.SecureRandom
import java.util.*
import kotlin.collections.HashMap

val GSON = Gson()

class Crypto(val context: Context) {
    var mslData = MSLData()
    private var masterToken: MasterToken? = null
    private var serialNumber: Long? = null
    private var sequenceNumber: Int? = null
    private var renewalWindow: Long = 0
    private var expiration: Long = 0
    var boundESN: String = ""

    private var cryptoSession: MediaDrm.CryptoSession? = null
    private var keysetId: String? = null
    private var keyId: ByteArray? = null
    private var hmacKeyId: ByteArray? = null

    private var sessionId: ByteArray? = null
    private var mediaDrm: MediaDrm = MediaDrm(C.WIDEVINE_UUID)

    companion object {
        @JvmStatic
        fun generateRandomIV(): ByteArray {
            val random = SecureRandom()
            val byteArray = ByteArray(16)
            random.nextBytes(byteArray)

            return byteArray
        }

        @JvmStatic
        fun generateRandomKey(): ByteArray {
            val random = SecureRandom()
            val byteArray = ByteArray(16)
            random.nextBytes(byteArray)

            return byteArray
        }
    }

    init {
        try {
            sessionId = mediaDrm.openSession()

            cryptoSession = mediaDrm.getCryptoSession(sessionId!!, "AES/CBC/NoPadding", "HmacSHA256")
            Log.d("custom debug", "Widevine CryptoSession successful constructed")
        } catch (ex: Exception) {
            Log.e("custom error", "Failed openSession ", ex)
        }

    }

    private fun readProp(process: Process): String {
        val reader = BufferedReader(InputStreamReader(process.inputStream))
        return reader.readLine()
    }

    private fun stripTabNL(string: String): String {
        return string.replace("\\t", "").replace("\\n", "").replace("\\r", "").uppercase()
    }

    fun generateAndroidESN(forceL3: Boolean): String {
        var esn = ""
        val sdkVersion = readProp(
            Runtime.getRuntime().exec(arrayOf("/system/bin/getprop", "ro.build.version.sdk"))
        )
//        Log.d("custom sdk_version", sdkVersion)
        val manufacturer = stripTabNL(
            readProp(
                Runtime.getRuntime().exec(arrayOf("/system/bin/getprop", "ro.product.manufacturer"))
            )
        )
//        Log.d("custom manufacturer", manufacturer)
        val model = stripTabNL(
            readProp(
                Runtime.getRuntime().exec(arrayOf("/system/bin/getprop", "ro.product.model"))
            )
        )
//        Log.d("custom model", model)
        var nrdp_modelgroup = ""
        nrdp_modelgroup = if (Integer.parseInt(sdkVersion) >= 28) {
            stripTabNL(
                readProp(
                    Runtime.getRuntime()
                        .exec(arrayOf("/system/bin/getprop", "ro.vendor.nrdp.modelgroup"))
                )
            )
        } else {
            stripTabNL(
                readProp(
                    Runtime.getRuntime().exec(arrayOf("/system/bin/getprop", "ro.nrdp.modelgroup"))
                )
            )
        }
//        Log.d("custom nrdp_modelgroup", nrdp_modelgroup)

        var securityLevel = MediaDrm(C.WIDEVINE_UUID).getPropertyString("securityLevel")
        val systemId = MediaDrm(C.WIDEVINE_UUID).getPropertyString("systemId")

//        Log.d("custom propertySysId", "$securityLevel $systemId")
        if (forceL3) {
            securityLevel = "L3"
        }

        if (securityLevel == "L1") {
            esn += "NFANDROID2-PRV-"
            if (nrdp_modelgroup != "") {
                esn += "$nrdp_modelgroup-"
            } else {
                esn += model.replace(" ", "") + "-"
            }
        } else {
            esn += "NFANDROID1-PRV-"
            esn += "T-L3-"
        }

        esn += manufacturer.subSequence(0, 5)
        esn += model.replace(" ", "=")
        esn = esn.replace("[^A-Za-z0-9=-]".toRegex(), "=")
        if (systemId != "") {
            esn += "-$systemId-"
        }

        Log.d("custom esn", esn)

        return esn
    }

    fun loadCryptoSession(mslData: MSLData) {
        if (mslData.key_set_id.isEmpty()) {
            return
        }
        keysetId = String(Base64.decode(mslData.key_set_id, Base64.NO_WRAP), Charsets.UTF_8)
        keyId = Base64.decode(mslData.key_id, Base64.NO_WRAP)
        hmacKeyId = Base64.decode(mslData.hmac_key_id, Base64.NO_WRAP)

//        mediaDrm.restoreKeys(sessionId!!, keysetId!!.toByteArray())
    }

    private fun deleteSession() {
        cryptoSession = null
    }

    // Return a key request dict
    fun keyRequestData(): List<Any> {
//        mediaDrm.removeKeys(sessionId!!)

        val byteArray = byteArrayOf(10, 122, 0, 108, 56, 43)
//        Log.d("custom keyreq", mediaDrm.toString())
        val keyRequest = mediaDrm.getKeyRequest(sessionId!!, byteArray, "application/xml", MediaDrm.KEY_TYPE_OFFLINE, HashMap())

//        Log.d("custom", "Widevine CryptoSession getKeyRequest successful. Size: " + keyRequest.data.size)
        val base64KeyReq = String(Base64.encode(keyRequest.data, Base64.NO_WRAP), Charsets.UTF_8)
//        Log.d("custom key", base64KeyReq)
        val jsonObj = object  {
            val scheme = "WIDEVINE"
            val keydata = object  {
                val keyrequest = base64KeyReq
            }
        }

        return listOf(jsonObj)
    }

    private fun provideKeyResponse(data: ByteArray) {
        try {
            val keyResponse = mediaDrm.provideKeyResponse(sessionId!!, data)
            keysetId = keyResponse?.let { String(it, Charsets.UTF_8) }
        } catch (ex: Exception) {
            Log.e("thutt custom", "ProvideKeyResponse failed " + ex)
        }
    }


    private fun encodeBase64BytesToString(bytes: ByteArray): String {
        return String(Base64.encode(bytes, Base64.NO_WRAP), Charsets.UTF_8)
    }

    private fun decodeBase64StringToBytes(string: String): ByteArray {
        return Base64.decode(string, Base64.NO_WRAP)
    }

    //Encrypt the given Plaintext with the encryption key
    //:param plaintext:
    //:return: Serialized JSON String of the encryption Envelope
    fun encrypt(plainText: String): String {
        val initVector = generateRandomIV()
//        Log.d("custom encrypt 1", plainText)
        //Add PKCS5Padding
        val padding = 16 - plainText.length % 16
//        Log.d("custom encrypt 2", padding.toString())
        val paddedData = plainText + padding.toChar().toString().repeat(padding)
//        Log.d("custom encrypt 3", paddedData)
//        Log.d("custom encrypt 4", String(paddedData.encodeToByteArray()))
        Log.d("custom key", keyId!!.size.toString())
        val encryptedData = cryptoSession!!.encrypt(keyId!!, paddedData.encodeToByteArray(), initVector)

        val jsonObj = object {
            val version = 1
            val ciphertext = encodeBase64BytesToString(encryptedData)
            val sha256 = "AA=="
            val keyid = encodeBase64BytesToString(keyId!!)
            val iv = encodeBase64BytesToString(initVector)
        }
//        Log.d("custom encrypt", "return " + GSON.toJson(jsonObj))

        return GSON.toJson(jsonObj)
    }

    fun decrypt(initVector: ByteArray, cipherText: ByteArray): String {
        val decryptedData = cryptoSession!!.decrypt(keyId!!, cipherText, initVector)

//        Log.d("custom decrypt", String(decryptedData))

        // remove PKCS5Padding
        val padding = decryptedData[decryptedData.size - 1]
//        Log.d("custom decrypted 2", padding.toInt().toString())
        val result = decryptedData.slice(0..decryptedData.size-padding-1).toByteArray()
//        Log.d("custom decrypted 3", String(result))
        return result.decodeToString()
    }

    fun sign(message: String): String {
        val signature = cryptoSession!!.sign(hmacKeyId!!, message.encodeToByteArray())
        return encodeBase64BytesToString(signature)
    }

    private fun verify(message: String, signature: String): Boolean {
        return cryptoSession!!.verify(hmacKeyId!!, message.encodeToByteArray(), signature.encodeToByteArray())
    }

    private fun initKeys(keyResponseData: KeyResponse) {
        val keyResponse = decodeBase64StringToBytes(keyResponseData.keydata.cdmkeyresponse)

        provideKeyResponse(keyResponse)
        keyId = decodeBase64StringToBytes(keyResponseData.keydata.encryptionkeyid)
        hmacKeyId = decodeBase64StringToBytes(keyResponseData.keydata.hmackeyid)
    }

    private fun exportKeys(){
        mslData.key_set_id = encodeBase64BytesToString(keysetId!!.toByteArray(Charsets.UTF_8))
        mslData.key_id = encodeBase64BytesToString(keyId!!)
        mslData.hmac_key_id = encodeBase64BytesToString(hmacKeyId!!)
    }

    fun loadMSLData(mslDataArg: MSLData) {
        mslData = mslDataArg

        setMasterToken(mslDataArg.tokens!!.mastertoken)
        val forceL3 = PreferenceManager.getDefaultSharedPreferences(context).getBoolean(
            SharedPrefs.NFLX.FORCE_L3_PREFS, false)
        boundESN = mslDataArg.boundESN.ifEmpty { generateAndroidESN(forceL3) }
    }

    // Save crypto keys and MasterToken to disk
    private fun saveMSLData() {
        mslData.tokens = Tokens(masterToken!!)
        exportKeys()
        mslData.boundESN = boundESN
//        Log.d("custom save", masterToken.tokendata + "       " + masterToken.signature)
        //Save msl data
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        prefs.edit().putString(SharedPrefs.NFLX.MSL_PREFS, GSON.toJson(mslData)).apply()
    }

    // Set the MasterToken and check it for validity
    private fun setMasterToken(masterToken: MasterToken) {
        this.masterToken = masterToken
//        Log.d("custom mastertoken", masterToken.tokendata + "        " + masterToken.signature)
        val tokenData = String(decodeBase64StringToBytes(masterToken.tokendata), Charsets.UTF_8)
        val resultToken: TokenData = GSON.fromJson(tokenData, TokenData::class.java)
        serialNumber = resultToken.serialNumber
        sequenceNumber = resultToken.sequenceNumber
        renewalWindow = resultToken.renewalWindow
        expiration = resultToken.expiration
    }

    fun parseKeyResponse(headerData: HeaderData, esn: String, saveToDisk: Boolean) {
        setMasterToken(headerData.keyresponsedata.mastertoken)
        initKeys(headerData.keyresponsedata)
        boundESN = esn
        if (saveToDisk) {
            saveMSLData()
        }
    }

    // Get a valid the user id token associated to a profile guid
     fun getUserIdToken(profileGuid: String): MasterToken? {
        if (mslData.user_id_tokens.isNotEmpty()) {
            val userIdToken = mslData.user_id_tokens[profileGuid]
            if (userIdToken != null && !isUserIdTokenExpired(userIdToken)) {
                return userIdToken
            }
        }
        return null
    }

    // Save or update a user id token associated to a profile guid
    fun saveUserIdToken(profileGuid: String, userTokenId: MasterToken) {
        var saveMslData = false
        if (mslData.user_id_tokens.isEmpty()) {
            saveMslData = true
            mslData.user_id_tokens[profileGuid] = userTokenId
        } else {
            val getProfileGuid = (mslData.user_id_tokens[profileGuid] == userTokenId)
            saveMslData = !getProfileGuid
            mslData.user_id_tokens[profileGuid] = userTokenId
        }
        if (saveMslData) saveMSLData()
    }

    // Clear all user id tokens
     fun clearUserIdTokens() {
        mslData.user_id_tokens = HashMap()
    }

    // Check if user id token is expired
    private fun isUserIdTokenExpired(userIdToken: MasterToken): Boolean {
        val tokenDataJSON = String(Base64.decode(userIdToken.tokendata, Base64.NO_WRAP))
        val tokenData: TokenData = GSON.fromJson(tokenDataJSON, TokenData::class.java)
        return (tokenData.expiration - 300) < (System.currentTimeMillis() / 1000)
    }

    // Check if the current MasterToken is expired
     fun isCurrentMasterTokenExpired(): Boolean {
        return expiration <= (System.currentTimeMillis() / 1000)
    }

    // Gets a dict values to know if current MasterToken is renewable and/or expired
    private fun getCurrentMasterTokenValidity(): JSONObject {
        val now = System.currentTimeMillis() / 1000
        val renewable = renewalWindow < now
        val expired = expiration <= now

        val jsonObj = JSONObject()
        jsonObj.put("is_renewable", renewable)
        jsonObj.put("is_expired", expired)

        return jsonObj
    }

    public fun getMasterToken(): MasterToken? {
        return masterToken
    }
}