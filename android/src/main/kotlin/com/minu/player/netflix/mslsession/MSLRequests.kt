package com.minu.player.netflix.mslsession

import android.content.Context
import android.content.res.Resources
import android.os.Handler
import android.os.Looper
import android.preference.PreferenceManager
import android.text.TextUtils
import android.util.Base64
import android.util.Log
import android.widget.Toast
import com.google.gson.annotations.SerializedName
import com.google.gson.internal.LinkedTreeMap
import com.google.gson.reflect.TypeToken
import com.minu.player.netflix.Crypto
import com.minu.player.netflix.GSON
import com.minu.player.netflix.MSLUtils
import com.minu.player.netflix.appContext
import com.minu.player.netflix.model.AuthData
import com.minu.player.netflix.model.EncryptionEnvelope
import com.minu.player.netflix.model.HeaderData
import com.minu.player.netflix.model.MSLData
import com.minu.player.netflix.model.MasterToken
import com.minu.player.netflix.model.PlainText
import com.minu.player.netflix.toMap
import com.minuai.thutt.minuplayer.utils.SharedPrefs
import okio.IOException
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStream
import java.lang.reflect.Type
import java.net.HttpURLConnection
import java.net.URL
import java.util.zip.Inflater

class MSLRequests(context: Context): MSLRequestBuilder(context) {

    var mslSwitchRequested = false

    val HTTP_HEADER = object {
        @SerializedName("User-Agent")
        val userAgent = ""
        @SerializedName("Content-Type")
        val contentType = "text/plain"
        @SerializedName("Accept")
        val accept = "*/*"
        @SerializedName("Host")
        val host = "www.netflix.com"
    }

    fun loadMSLData(mslData: MSLData) {
        crypto.loadMSLData(mslData)
        crypto.loadCryptoSession(mslData)
    }

    private fun performKeyHandshake(): Boolean {
        val forceL3 = PreferenceManager.getDefaultSharedPreferences(context).getBoolean(
            SharedPrefs.NFLX.FORCE_L3_PREFS, false)
        val esn = crypto.generateAndroidESN(forceL3)
        if(TextUtils.isEmpty(esn)) {
            return false
        }

        val response = post(MSLUtils.ENDPOINT.manifest, handshakeRequest(esn)) ?: return false
//        Log.d("PerformHandshake", response)
        val header = JSONObject(processJsonResponse(response).first)
        val headerData = decryptHeaderData(header.getString("headerdata"), false)
//        Log.d("custom headerdata", headerData)
        val headerObj = GSON.fromJson<HeaderData>(headerData, HeaderData::class.java)
        crypto.parseKeyResponse(headerObj, esn, true)
        crypto.clearUserIdTokens()

        return true
    }

    private fun getOwnerUserIdToken() {
        val screenWidth = Resources.getSystem().displayMetrics.widthPixels
        val screenHeight = Resources.getSystem().displayMetrics.heightPixels
        val app_id = System.currentTimeMillis() * 10 + (1..10001).random()
        val forceL3 = PreferenceManager.getDefaultSharedPreferences(context).getBoolean(
            SharedPrefs.NFLX.FORCE_L3_PREFS, false)

        val logBlobData = object {
            val logblobs = object {
                val entries = listOf(object {
                    val browserua = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.77 Safari/537.36"
                    val browserhref = "https://www.netflix.com/browse"
//                    val screensize = "${screenWidth}x${screenHeight}"
                    val screensize = "1920x1080"
                    val screenavailsize = "1920x1080"
                    val clientsize = "1920x1080"
                    val type = "startup"
                    val sev = "info"
                    val devmod = "chrome-cadmium"
                    val clver = "6.0035.414.911"
                    val osplatform = "MacOSX"
                    val osver = "10.15.5"
                    val browsername = "Chrome"
                    val browserver = "96.0.4664.77"
                    val appLogSeqNum = 0
                    val uniqueLogId = "f4eae679-486b-4b02-aab1-2261a6fb5ec1"
                    val appId = app_id
                    val esn = crypto.generateAndroidESN(forceL3)
                    val lver = ""
                    val clienttime = System.currentTimeMillis()
                    val client_utc = System.currentTimeMillis() / 1000
                    val uiver = "shakti-v2341bd5f"
                })
            }
        }

        val generateLogBlobsParams = GSON.toJson(logBlobData)

        val endpointUrl = "https://www.netflix.com/msl/playapi/cadmium/logblob/1?reqAttempt=&reqName=bind&clienttype=akira&uiversion=v2341bd5f&browsername=chrome&browserversion=96.0.4664.77&osname=mac+os+x&osversion=10.15.5"
        val response = chunkedRequest(endpointUrl, buildRequestData("/logblob", generateLogBlobsParams), crypto.generateAndroidESN(forceL3), forceAuthCredential = true)
        Log.d("Response of logblob", response.toString())
    }

    fun chunkedRequest(endpoint: String, requestData: String, esn: String, disableMSLSwitch: Boolean = true, forceAuthCredential: Boolean = false): String? {
        masterTokenChecks()
        val authData = checkUserIdToken(disableMSLSwitch, forceAuthCredential)
        Log.d("custom authData", authData.toString())
        Log.d("custom requestData", requestData)
        val response = post(endpoint, mslRequest(requestData, esn, authData)) ?: return null
        Log.d("custom endpoint", endpoint)
        Log.d("custom chunked", response)
        val chunkedResponse = processChunkedResponse(response, saveUIDTokenToOwner = TextUtils.isEmpty(authData.userIdToken?.tokendata))
        val chunkedResponseObj = JSONObject(chunkedResponse)
        return if (chunkedResponseObj.has("result")) {
            chunkedResponseObj.getString("result")
        } else null
    }

    @Throws(IOException::class)
    fun post(endpoint: String, requestData: String): String? {
        val isAttemptsEnabled = endpoint.contains("reqAttempt=")
        var retry = 1
        var _endpoint = endpoint

        var urlConnection: HttpURLConnection? = null
        val start = System.currentTimeMillis()
        while (true) {
            if(isAttemptsEnabled) {
                _endpoint = endpoint.replace("reqAttempt=", "reqAttempt=$retry")
            }

            try {
                Log.d("custom post", _endpoint + " " + requestData)

                val url = URL(_endpoint)
                urlConnection = url.openConnection() as HttpURLConnection
                urlConnection.connectTimeout = 1000
                urlConnection.readTimeout = 3000
                urlConnection.requestMethod = "POST"
                urlConnection.doOutput = true
                urlConnection.useCaches = true;
                urlConnection.setChunkedStreamingMode(0);
                urlConnection.setRequestProperty("User-Agent", "Mozilla/5.0 (X11; CrOS aarch64 14324.33.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.77 Safari/537.36")
                urlConnection.setRequestProperty("Accept", "*/*")
                urlConnection.setRequestProperty("Host", "www.netflix.com")
                urlConnection.setRequestProperty("Content-Type", "text/plain")

                val out: ByteArray = requestData.toByteArray(Charsets.UTF_8)
                val stream: OutputStream = urlConnection.outputStream
                stream.write(out)
                val code: Int = urlConnection.responseCode
                Log.d("custom code", code.toString())

                if (code == 502 && _endpoint.startsWith("https://www.netflix.com/nq/msl_v1/cadmium/pbo_manifests/%5E1.0.0/router?reqAttempt=")) {
                    Handler(Looper.getMainLooper()).post {
                        Toast.makeText(appContext, "Your Netflix session has expired. Please login again", Toast.LENGTH_LONG).show()
                    }
                    return null
                }
                
                if (code != 200) {

                    if(retry == 3) {
                        return null
                    }
                    retry++
                    continue
                }

                val rd = BufferedReader(
                    InputStreamReader(
                        urlConnection.inputStream
                    )
                )

                var line: String?
                while (rd.readLine().also { line = it } != null) {
                    Log.d("custom line", line!!)
                    return line!!
                }
            } catch (ex: Exception) {
                Log.d("custom error", ex.localizedMessage + ex.printStackTrace())
            } finally {
                Log.d("custom close", "close the http url")
                val end = System.currentTimeMillis()
                Log.d("custom duration", ((end - start).toString()))
                urlConnection?.disconnect()
            }
        }
    }



    fun processJsonResponse(response: String): Pair<String, ArrayList<String>> {
//        Log.d("custom process", response)
        val commaSeparatedResponse = response.replace("}{","},{")
        val listOfMyClassObject: Type = object : TypeToken<ArrayList<Any>>(){}.type
        val data: List<Any> = GSON.fromJson("[$commaSeparatedResponse]", listOfMyClassObject)
        val payloads = ArrayList<String>()
        for(item in data) {
            (item as LinkedTreeMap<String, String>).let {
                if(it["payload"] != null) {
                    payloads.add(GSON.toJson(item))
                }
            }
        }
//        Log.d("processJson", GSON.toJson(data[0]))
//        Log.d("processJson 1", payloads.toString())

        return Pair(raiseIfError(GSON.toJson(data[0])), payloads)
    }

    fun processChunkedResponse(response: String, saveUIDTokenToOwner: Boolean = false): String {
        Log.d("Chunked response", "Received encrypted chunked response")
//        Log.d("custom response", response)
//        Log.d("custom response 2", saveUIDTokenToOwner.toString())
        val data = processJsonResponse(response)
        val header = JSONObject(data.first)
        val payloads = data.second

        val headerdata = JSONObject(decryptHeaderData(header.getString("headerdata")))
        if(!TextUtils.isEmpty(headerdata.getString("useridtoken"))) {
            // TODO: hard-coded first, fix owner and active profile later
            if (saveUIDTokenToOwner) {
                val profileGuid = PreferenceManager.getDefaultSharedPreferences(context).getString(
                    SharedPrefs.NFLX.CURRENT_USER_PREFS, "") ?: ""
                val userIdToken: MasterToken = GSON.fromJson(headerdata.getString("useridtoken"), MasterToken::class.java)
                crypto.saveUserIdToken(profileGuid, userIdToken)
            }
        }
        val decryptedResponse = decryptChunks(payloads, crypto)
        return raiseIfError(decryptedResponse)
    }

    // Perform checks to the MasterToken and executes a new key handshake when necessary
    private fun masterTokenChecks() {
        var isHandshakeRequired = false
        if (crypto.getMasterToken() != null) {
            if (crypto.isCurrentMasterTokenExpired()) {
                Log.d("custom debug", "Stored MSL MasterToken is expired, a new key handshake will be performed")
                isHandshakeRequired = true
            } else {
                // Check if the current ESN is same of ESN bound to MasterToken
//                val sharedPreferences = getSharedPreferences(SHARED_PREF, Context.MODE_PRIVATE)

                // hardcoded esn true
                val esn = PreferenceManager.getDefaultSharedPreferences(context).getString(
                    SharedPrefs.NFLX.ESN_PREFS, "")
                if (esn != crypto.boundESN) {
                    Log.d("custom debug", "Stored MSL MasterToken is bound to a different ESN, a new key handshake will be performed")
                    isHandshakeRequired = true
                }
            }
        } else {
            Log.d("custom debug", "MSL MasterToken is not available, a new key handshake will be performed")
            isHandshakeRequired = true
        }
        if (isHandshakeRequired) {
            if (performKeyHandshake()) {
                val mslData = PreferenceManager.getDefaultSharedPreferences(context).getString(SharedPrefs.NFLX.MSL_PREFS, "")
                val mslDataObj: MSLData = GSON.fromJson(mslData, MSLData::class.java)

                crypto.loadMSLData(mslDataObj)
                crypto.loadCryptoSession(mslDataObj)
            }
        }
    }

    private fun checkUserIdToken(disableMSLSwitch: Boolean, forceAuthCredential: Boolean = false): AuthData {
        val currentProfileGUID = PreferenceManager.getDefaultSharedPreferences(context).getString(
            SharedPrefs.NFLX.OWNER_USER_PREFS, "") ?: ""
        val ownerProfileGUID = PreferenceManager.getDefaultSharedPreferences(context).getString(
            SharedPrefs.NFLX.OWNER_USER_PREFS, "") ?: ""
        Log.d("custom profileGuid", currentProfileGUID)
        Log.d("custom ownerGuid", ownerProfileGUID)
        var useSwitchProfile = false
        var userIdToken: MasterToken? = null

        if (!forceAuthCredential) {
            if (currentProfileGUID == ownerProfileGUID) {
                userIdToken = crypto.getUserIdToken(currentProfileGUID)
            } else {
                userIdToken = crypto.getUserIdToken(currentProfileGUID)
                if (userIdToken == null && !disableMSLSwitch) {
                    useSwitchProfile = true
                    userIdToken = crypto.getUserIdToken(ownerProfileGUID)

                    if (userIdToken == null) {
                        Log.d("custom debug", "The owner profile token id does not exist/valid, then get it")
                        getOwnerUserIdToken()
                        userIdToken = crypto.getUserIdToken(ownerProfileGUID)
                    }
                    mslSwitchRequested = true
                }
            }
        }

        val result = AuthData()
        result.useSwitchProfile = useSwitchProfile
        result.userIdToken = userIdToken
        return result
    }

    fun raiseIfError(data: String): String {
        var raiseError = false
        val jsonObj = JSONObject(data)
        val map = jsonObj.toMap()
        Log.d("custom map", map.toString())
        // Catch a manifest/chunk error
        if (map.containsKey("error") || map.containsKey("errordata")) {
            raiseError = true
        }
        // Catch a license error
        if (map.containsKey("result") && map["result"] is Array<*>) {
            val error = map["result"] as Array<HashMap<String, Any>>
            if (error[0].containsKey("error")) {
                raiseError = true
            }
        }

        if (raiseError) {
            val (errMessage, errNumber) = getErrorDetails(data)
            Log.e("custom error", "Full MSL error information: error message " + errMessage + "error number " + errNumber.toString())
        }

        return data
    }

    private fun getErrorDetails(data: String): Pair<String, Int> {
        var errMessage = "Unhandled error check log."
        var errNumber = 0
        val jsonObj = JSONObject(data)
        val map = jsonObj.toMap()

        if (map.containsKey("errordata")) {
            val errData = String(Base64.decode(map["errordata"] as String, Base64.NO_WRAP), Charsets.UTF_8)
            val errJSON = JSONObject(errData)
            val errMap = errJSON.toMap()
            errMessage = errMap["errormsg"] as String
            errNumber = errMap["internalcode"] as Int
        } else if (map.containsKey("error")) {
            val errMap = map["error"] as Map<String, *>
            if (errMap.containsKey("errorDisplayMessage")) {
                errMessage = errMap["errorDisplayMessage"] as String
                if (errMap.containsKey("bladeRunnerCode")) {
                    if (errMap["bladeRunnderCode"] is Int) {
                       errNumber = errMap["bladeRunnerCode"] as Int
                    }
                } else {
                    errNumber = 0
                }
            }
        } else if (map.containsKey("result") && map["result"] is Array<*>) {
            val error = map["result"] as Array<HashMap<String, *>>
            if (error[0].containsKey("error")) {
                val errorMess = error[0]["error"] as HashMap<String, *>
                if (errorMess.containsKey("errorDisplayMessage")) {
                    errMessage = errorMess["errorDisplayMessage"] as String
                }
                if (errorMess.containsKey("bladeRunnerCode")) {
                    errNumber = errorMess["bladeRunnerCode"] as Int
                }
            }
        }

        return Pair(errMessage, errNumber)
    }

    private fun decryptChunks(chunks: ArrayList<String>, crypto: Crypto): String {
        var decryptedPayload = ""
        for (chunk in chunks) {
            val chunkObj = JSONObject(chunk)
            val payload = chunkObj.getString("payload")
            val decodedPayload = String(Base64.decode(payload, Base64.NO_WRAP))
            val encryptionEnveloper: EncryptionEnvelope = GSON.fromJson(decodedPayload, EncryptionEnvelope::class.java)

            // Decrypt the text
            val plainText = crypto.decrypt(Base64.decode(encryptionEnveloper.iv, Base64.NO_WRAP), Base64.decode(encryptionEnveloper.ciphertext, Base64.NO_WRAP))
            Log.d("custom decrypt", plainText)
            // unpad the plaintext
            val plainTextObj: PlainText = GSON.fromJson(plainText, PlainText::class.java)
            var data = plainTextObj.data

            // uncompress data if compressed
            if (plainTextObj.compressionalgo == "GZIP") {
                val decodedData = Base64.decode(data, Base64.NO_WRAP)
                try {
                    val decompresser = Inflater()
                    decompresser.setInput(decodedData)
                    val result = ByteArray(decodedData.size * 4)
                    val resultLength = decompresser.inflate(result)
                    decompresser.end()

                    data = String(result, 0, resultLength, Charsets.UTF_8)
                } catch (ex: Exception) {
                    Log.e("custom error decryptCh", ex.toString())
                }
            } else {
                data = String(Base64.decode(data, Base64.NO_WRAP), Charsets.UTF_8)
            }
            decryptedPayload += data
        }
        Log.d("custom decrypted Return", decryptedPayload)
        return decryptedPayload
    }
}