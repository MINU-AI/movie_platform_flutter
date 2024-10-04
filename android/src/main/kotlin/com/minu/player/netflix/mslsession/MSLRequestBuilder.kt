package com.minu.player.netflix.mslsession

import android.content.Context
import android.preference.PreferenceManager
import android.util.Base64
import android.util.Log
import com.minu.player.netflix.Crypto
import com.minu.player.netflix.GSON
import com.minu.player.netflix.model.AuthData
import com.minuai.thutt.minuplayer.utils.SharedPrefs
import org.json.JSONObject
import javax.crypto.Cipher
import javax.crypto.spec.IvParameterSpec
import javax.crypto.spec.SecretKeySpec
import kotlin.math.pow


open class MSLRequestBuilder(val context: Context) {
    var currentMessageId: Long = 0
    val crypto = Crypto(context)
    val masterToken = crypto.getMasterToken()

    fun mslRequest(data: String, esn: String, authData: AuthData): String {
        val request = GSON.toJson(signedHeader(esn, authData)) + GSON.toJson(encryptedChunk(data, esn))
//        Log.d("Custom msl request", request)
        return request
    }

    fun signedHeader(esn: String, authData: AuthData): Any {
        val encryptionEnvelope = crypto.encrypt(headerdata(authData = authData, esn = esn))
//        Log.d("custom header", encryptionEnvelope)
        return object {
            val headerdata = Base64.encode(encryptionEnvelope.toByteArray(), Base64.NO_WRAP).decodeToString()
            val signature = crypto.sign(encryptionEnvelope)
            val mastertoken = crypto.getMasterToken()
        }
    }

    fun encryptedChunk(data: String = "", esn: String? = null, envelopePayload: Boolean = true): Any {
        var _data = data
//        Log.d("custom encrypted", _data)
        if (_data.isNotEmpty()) {
            _data = String(Base64.encode(data.toByteArray(), Base64.NO_WRAP))
        }
//        Log.d("custom encrypted 1", _data)
        var payload = JSONObject()
        payload.put("messageid", currentMessageId)
        payload.put("data", _data)
        payload.put("sequencenumber", 1)
        payload.put("endofmsg", true)
        var _payload = payload.toString()
        var signature = ""
        if (envelopePayload) {
            _payload = crypto.encrypt(_payload)
            signature = crypto.sign(_payload)
        }
//        Log.d("custom payload", _payload)
        return object {
            val payload = String(Base64.encode(_payload.toByteArray(), Base64.NO_WRAP))
            val signature = signature
        }
    }

    fun handshakeRequest(esn: String): String {
        val header = GSON.toJson(
            object {
                val entityauthdata = object {
                    val scheme = "NONE"
                    val authdata = object {
                        val identity = esn
                    }
                }
                val headerdata = Base64.encode(headerdata(AuthData(), isHandshake = true).toByteArray(), Base64.NO_WRAP).decodeToString()
                val signature = ""
            }
        )
//        Log.d("custom request 1", header)
        val payload = GSON.toJson(encryptedChunk(envelopePayload = false))
        val result = header + payload
//        Log.d("custom request 2", payload)
        return result
    }

    fun headerdata(authData: AuthData, esn: String? = null, isHandshake: Boolean = false): String {
        this.currentMessageId = (0 until 2.0.pow(52.0).toLong()).random()
        val headerdata = HashMap<String, Any>()
        headerdata.put("messageid", currentMessageId)
        headerdata.put("renewable", true)
        headerdata.put("capabilities", object {
            val languages = listOf(PreferenceManager.getDefaultSharedPreferences(context).getString(
                SharedPrefs.NFLX.CURRENT_LANG_PREFS, "") ?: "")
            val compressionalgos = listOf<String>()
        })


        if (isHandshake) {
            val keyReq = crypto.keyRequestData()
            headerdata.put("keyrequestdata", keyReq)
        } else {
            if (esn != null) {
                headerdata.put("sender", esn)
            }
            addAuthInfo(headerdata, authData)
        }
//        Log.d("custom header data", "return " + GSON.toJson(headerdata))
        return GSON.toJson(headerdata)
    }

    fun decryptHeaderData(data: String, enveloped: Boolean = true): String {
        val headerdata = String(Base64.decode(data, Base64.NO_WRAP))
        val headerDataObject = JSONObject(headerdata)

        if(enveloped) {
            val initVector = Base64.decode(headerDataObject.getString("iv"), Base64.NO_WRAP)
            val cipherText = Base64.decode(headerDataObject.getString("ciphertext"), Base64.NO_WRAP)
            return crypto.decrypt(initVector, cipherText)
        }
        return headerdata
    }

    fun addAuthInfo(headerData: HashMap<String, Any>, authData: AuthData) {
        val currentGuid = PreferenceManager.getDefaultSharedPreferences(context).getString(
            SharedPrefs.NFLX.CURRENT_USER_PREFS, "")
        if (authData.userIdToken != null) {
            if (authData.useSwitchProfile) {
                headerData.put("userauthdata", object {
                    val scheme = "SWITCH_PROFILE"
                    val authdata = object {
                        val useridtoken = authData.userIdToken
                        val profileguid = currentGuid
                    }
                })
            } else {
                headerData.put("useridtoken", authData.userIdToken!!)
            }
        } else {
            val authentication = PreferenceManager.getDefaultSharedPreferences(context).getString(
                SharedPrefs.NFLX.AUTH_PREFS, "")

            val authObj = String(Base64.decode(authentication, Base64.NO_WRAP))
            val authJSON = JSONObject(authObj)
            val encryptedAuthData = authJSON.getString("data")
            val randomIV = authJSON.getString("iv")

            val randomBytes = Base64.decode(randomIV, Base64.NO_WRAP)
            val decryptedStr = decrypt(encryptedAuthData, Base64.decode(randomIV, Base64.NO_WRAP))
            val authDataBase64 = String(Base64.decode(decryptedStr, Base64.NO_WRAP))

            val decryptedAuthJSON = JSONObject(authDataBase64)

            val credential = object {
                val email = decryptedAuthJSON.getString("username")
                val password = decryptedAuthJSON.getString("password")
            }
            headerData.put("userauthdata", object {
                val scheme = "EMAIL_PASSWORD"
                val authdata = object {
                    val email = credential.email
                    val password = credential.password
                }
            })
        }
    }

    fun decrypt(value: String, ivData: ByteArray): String? {
        try {
            val randomKeySpec = "MinuEncryptionKey@#12345".toByteArray()

            val cipher = Cipher.getInstance("AES/CBC/PKCS5PADDING")
            cipher.init(Cipher.DECRYPT_MODE, SecretKeySpec(randomKeySpec, "AES"), IvParameterSpec(ivData))

            val decryption = String(Base64.decode(value, Base64.NO_WRAP))
            Log.d("custom decryption", decryption)
            val decrypted = cipher.doFinal(Base64.decode(value, Base64.NO_WRAP))
            return String(decrypted)
        } catch (ex: Exception) {
            Log.d("custom error", ex.localizedMessage)
        }
        return null
    }

    fun buildRequestData(url: String, params: Any, echo: String = ""): String {
        val timeStamp = System.currentTimeMillis()
        val requestData = object {
            val version = 2
            val url = url
            val id = timeStamp
            val languages = listOf(PreferenceManager.getDefaultSharedPreferences(context).getString(SharedPrefs.NFLX.CURRENT_LANG_PREFS, "") ?: "")
            val params = params
            val echo = echo
        }

        return GSON.toJson(requestData)
    }
}
