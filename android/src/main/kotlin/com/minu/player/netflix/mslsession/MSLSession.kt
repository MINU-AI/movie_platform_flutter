//package com.minu.player.netflix.mslsession
//
//import android.content.Context
//import android.media.MediaDrm
//import android.media.NotProvisionedException
//import android.preference.PreferenceManager
//import android.util.Base64
//import android.util.Log
//import androidx.media3.common.C
//import androidx.media3.common.DrmInitData
//import androidx.media3.common.util.UnstableApi
//import androidx.media3.exoplayer.drm.ExoMediaDrm
//import androidx.media3.exoplayer.drm.FrameworkMediaDrm
//import androidx.media3.exoplayer.drm.MediaDrmCallback
//
//import com.google.gson.Gson
//import com.minu.player.netflix.GSON
//import com.minu.player.netflix.convertToDash
//import com.minu.player.netflix.model.LicenseResult
//import com.minu.player.netflix.model.Manifest
//import com.minuai.thutt.minuplayer.utils.SharedPrefs
//import java.io.*
//import java.lang.NullPointerException
//import java.lang.ref.WeakReference
//
//@UnstableApi
//public class MSLSession(var callback: WeakReference<onPlayerCallback>? = null, var context: Context? = null) {
//    var sessionId: ByteArray? = null
//    private lateinit var lastLicenseUrl: String
//    private val currentProvisionRequest: ExoMediaDrm.ProvisionRequest? = null
//    private lateinit var movieId: String
//    private lateinit var mediaDrmCallback: MediaDrmCallback
//
//    private var licences_xid = ArrayList<String>()
//    private var licenses_session_id = ArrayList<String>()
//    private var licenses_release_url = ArrayList<String>()
//
//    private var mediaDrm: FrameworkMediaDrm = FrameworkMediaDrm.newInstance(C.WIDEVINE_UUID)
//    private var mslRequest: MSLRequests? = null
//
//    lateinit var challengeB64: String
//
//    private var provisioningManager = CustomProvisionManagerImpl()
//
//    companion object {
//        var mslSession: MSLSession? = null
//
//        @JvmStatic
//        fun getInstance(): MSLSession {
//            if (mslSession == null) {
//                mslSession = MSLSession()
//            }
//
//            return mslSession!!
//        }
//    }
//
//    private fun MSLSession() {
//    }
//
//    fun startSession(movieId: String, mediaDrmCallback: MediaDrmCallback) {
//        this.movieId = movieId
//        this.mediaDrmCallback = mediaDrmCallback
//
//        val forceL3 = PreferenceManager.getDefaultSharedPreferences(context).getBoolean(
//            SharedPrefs.NFLX.FORCE_L3_PREFS, false)
//        val esn = generateAndroidESN(forceL3)
//        val sharedPrefs = PreferenceManager.getDefaultSharedPreferences(context)
//        sharedPrefs.edit().putString(SharedPrefs.NFLX.ESN_PREFS, esn).apply()
//
//        try {
//            sessionId = mediaDrm.openSession()
//            Log.d("custom debug", String(sessionId!!))
//
//            val PSSH = "AAAANHBzc2gAAAAA7e+LqXnWSs6jyCfc1R0h7QAAABQIARIQAAAAAAPSZ0kAAAAAAAAAAA=="
//            val schemeData = DrmInitData.SchemeData(C.WIDEVINE_UUID, "video/mp4", Base64.decode(PSSH, Base64.NO_WRAP))
////            val keyReq = mediaDrm.getKeyRequest(sessionId!!, Base64.getDecoder().decode(PSSH), "video/mp4", MediaDrm.KEY_TYPE_STREAMING, HashMap())
//            val keyReq = mediaDrm.getKeyRequest(sessionId!!, listOf(schemeData), MediaDrm.KEY_TYPE_STREAMING, HashMap())
//
//            challengeB64 = String(Base64.encode(keyReq.data, Base64.NO_WRAP))
//            Log.d("custom getKey", challengeB64)
//            mslRequest = MSLRequests(context!!)
//
//            Thread {
//                getManifest(esn, movieId)
//            }.start()
//
//        } catch (ex: NotProvisionedException) {
//            val customDrmSession = CustomDrmSession(C.WIDEVINE_UUID, mediaDrm, mediaDrmCallback, DefaultLoadErrorHandlingPolicy(), provisioningManager)
//            customDrmSession.acquire(null);
//            provisioningManager.provisionRequired(customDrmSession);
//        } catch (ex: Exception) {
//            Log.e("custom error", "Unable to open session mediadrm " + ex)
//        }
//
//    }
//
//    fun restartSession() {
////        startSession("81262746", mediaDrmCallback)
//        startSession(movieId, mediaDrmCallback)
//    }
//
//    private fun getManifest(esn: String, movieId: String) {
//        val endpointPair = buildManifestV2(movieId)
//        val response = mslRequest?.chunkedRequest(endpointPair.first, endpointPair.second, esn, disableMSLSwitch = false)
//
//        response?.also {
//            Log.d("custom getManifest", response)
//            val manifest = GSON.fromJson(it, Manifest::class.java)
//            val result = transformToDash(manifest)
//            Log.d("custom result", result)
//
//            writeMPDFile(result)
//
////            val license = getLicense(challengeB64, String(sessionId!!))
//
////            runOnUiThread {
////                initializePlayer()
////            }
//
//            callback?.get()?.onPlayerInit()
//            readFromFile(context!!)
//        }
//
//    }
//
//    private fun writeMPDFile(result: String) {
//        try {
//            val outputStreamWriter =
//                OutputStreamWriter(context!!.openFileOutput("file.mpd", Context.MODE_PRIVATE))
//
////            outputStreamWriter.write(test2)
//            outputStreamWriter.write(result)
//            outputStreamWriter.close()
//        } catch (e: IOException) {
//            Log.e("Exception", "File write failed: $e")
//        }
//    }
//
//    private fun readFromFile(context: Context): String? {
//        var ret = ""
//        try {
//            val inputStream: InputStream? = context.openFileInput("file.mpd")
//            if (inputStream != null) {
//                val inputStreamReader = InputStreamReader(inputStream)
//                val bufferedReader = BufferedReader(inputStreamReader)
//                var receiveString: String? = ""
//                val stringBuilder = StringBuilder()
//                while (bufferedReader.readLine().also { receiveString = it } != null) {
//                    stringBuilder.append("\n").append(receiveString)
//                }
//                inputStream.close()
//                ret = stringBuilder.toString()
//            }
//        } catch (e: FileNotFoundException) {
//            Log.e("login activity", "File not found: " + e.toString())
//        } catch (e: IOException) {
//            Log.e("login activity", "Can not read file: $e")
//        }
////        Log.d("manifest return", ret)
//        return ret
//    }
//
//    private fun transformToDash(manifest: Manifest): String {
//        lastLicenseUrl = manifest.links.license.href
//        return convertToDash(manifest)
//    }
//
////    fun getLicense(challenge: String, sid: String): ByteArray? {
//    fun getLicense(): ByteArray? {
//        // TODO: check mobile log (no need to create and split)
//        Log.d("cust MSLSession", "getLicense")
////        val split = licenseData.split("!")
////        val challenge = split[0]
////        val challenge = challenge
//        val challenge = challengeB64
//
////        val sid = String(Base64.getDecoder().decode(split[1]), Charsets.UTF_8)
////        val sid = sid
//        val sid = String(sessionId!!)
//        Log.d("cust License", "getLicense " + sid)
//        val timestamp = System.currentTimeMillis() * 10
//        val xid = (timestamp + 1610).toString()
//        Log.d("cust License 1", "timestamp " + timestamp)
//        Log.d("cust License 2", "xid " + xid)
//
//        val params = listOf( object {
//            val drmSessionId = sid
//            val clientTime = (timestamp / 10000)
//            val challengeBase64 = challenge
//            val xid = xid
//        })
//
//        // TODO: check with the endpoint url of mobile log
//        val endpointUrl = "https://www.netflix.com/nq/msl_v1/cadmium/pbo_licenses/%5E1.0.0/router?reqAttempt=&reqPriority=0&reqName=prefetch%2Flicense&clienttype=akira&uiversion=v1d1c3d61&browsername=chrome&browserversion=96.0.4664.77&osname=chrome+os&osversion=14324.33.0"
//        try {
//            val requestData = mslRequest?.buildRequestData(lastLicenseUrl, params, "drmSessionId")
//            Log.d("custom license 3", lastLicenseUrl)
//            val forceL3 = PreferenceManager.getDefaultSharedPreferences(context).getBoolean(
//                SharedPrefs.NFLX.FORCE_L3_PREFS, false)
//            val response = mslRequest?.chunkedRequest(endpointUrl, requestData!!, generateAndroidESN(forceL3))
//
//            val sharedPrefs = PreferenceManager.getDefaultSharedPreferences(context!!)
//            sharedPrefs.edit().putString(SharedPrefs.NFLX.XID_PREFS, xid).apply()
//
//            licences_xid.add(0, xid)
//            licenses_session_id.add(0, sid)
//            val result = response!!.drop(1).dropLast(1)
//            // catch 1044 error This title is not available to watch instantly -> forceL3
//            if (result.contains("error") && result.contains("IssueLicensePolicyError")) {
//                val sharedPrefs = PreferenceManager.getDefaultSharedPreferences(context!!)
//                sharedPrefs.edit().putBoolean(SharedPrefs.NFLX.FORCE_L3_PREFS, true).apply()
//                restartSession()
//                return null
//            }
//            val licenseResult: LicenseResult = GSON.fromJson(result, LicenseResult::class.java)
//            licenses_release_url.add(0, licenseResult.links.releaseLicense.href)
//
//            if (mslRequest!!.mslSwitchRequested) {
//                mslRequest!!.mslSwitchRequested = false
//                bindEvent()
//            }
//            Log.d("custom license", "license return " + licenseResult.licenseResponseBase64)
//            return Base64.decode(licenseResult.licenseResponseBase64, Base64.NO_WRAP)
//        } catch (ex: NullPointerException) {
//            Log.e("custom error", "got null pointer " + ex)
//            return null
//        } catch (ex: Exception) {
//            Log.e("custom error", "failed get license " + ex)
//            return null
//        }
//    }
//
//    private fun bindEvent() {
//
//    }
//
//    private fun buildManifestV2(movieId: String): Pair<String, String> {
//        Log.d("custom movieId", movieId)
//        val params = object {
//            val type = "standard"
//            val manifestVersion = "v2"
////            val viewableId = 70093699
////            val viewableId = 81001887
//            val viewableId = movieId.toLong()
////            val profiles = listOf("heaac-2-dash", "heaac-2hq-dash", "BIF240", "BIF320", "playready-h264mpl30-dash", "playready-h264mpl31-dash", "playready-h264mpl40-dash", "playready-h264hpl22-dash", "playready-h264hpl30-dash", "playready-h264hpl31-dash", "playready-h264hpl40-dash", "webvtt-lssdh-ios8", "ddplus-2.0-dash", "ddplus-5.1-dash", "ddplus-5.1hq-dash", "ddplus-atmos-dash")
//            val profiles = listOf("heaac-2-dash", "heaac-2hq-dash", "BIF240", "BIF320", "playready-h264mpl30-dash", "playready-h264mpl31-dash", "playready-h264mpl40-dash", "playready-h264hpl22-dash", "playready-h264hpl30-dash", "playready-h264hpl31-dash", "playready-h264hpl40-dash", "webvtt-lssdh-ios8")
//            val flavor = "PRE_FETCH"
//            val drmType = "widevine"
//            val drmVersion = 25
//            val usePsshBox = true
//            val isBranching = false
//            val useHttpsStreams = true
////                        val useHttpsStreams = false
//            val supportsUnequalizedDownloadables = true
//            val imageSubtitleHeight = 1080
//                        val uiVersion = "shakti-vd5c10190"
////            val uiVersion = "shakti-v2ecd1c2b"
//            val uiPlatform = "SHAKTI"
//            val clientVersion = "6.0034.626.911"
////            val clientVersion = "6.0033.414.911"
//            val supportsPreReleasePin = true
//            val supportsWatermark = true
//            //            val showAllSubDubTracks = false
//            val showAllSubDubTracks = true
//
//            val videoOutputInfo = listOf(object {
//                val type = "DigitalVideoOutputDescriptor"
//                val outputType = "unknown"
//                //                val supportedHdcpVersions = listOf("1.4")
//                val supportedHdcpVersions = emptyList<String>()
//                //                val isHdcpEngaged = true
//                val isHdcpEngaged = false
//            })
//
//            val titleSpecificData = object {
////                @SerializedName("81001887")
//                val movieId = object {
//                    val value = object {
//                        val unletterboxed = true
//                    }
//                }
//
//            }
//
//            val preferAssistiveAudio = false
//            val isUIAutoPlay = false
//            val isNonMember = false
//            val desiredVmaf = "plus_lts"
//            val desiredSegmentVmaf = "plus_lts"
//            val requestSegmentVmaf = false
//            val supportsPartialHydration = false
//            val contentPlaygraph = emptyList<String>()
//
//            val profileGroups = listOf(object {
//                val name = "default"
////                val profiles = listOf("heaac-2-dash", "heaac-2hq-dash", "BIF240", "BIF320", "playready-h264mpl30-dash", "playready-h264mpl31-dash", "playready-h264mpl40-dash", "playready-h264hpl22-dash", "playready-h264hpl30-dash", "playready-h264hpl31-dash", "playready-h264hpl40-dash", "webvtt-lssdh-ios8", "ddplus-2.0-dash", "ddplus-5.1-dash", "ddplus-5.1hq-dash", "ddplus-atmos-dash")
//                val profiles = listOf("heaac-2-dash", "heaac-2hq-dash", "BIF240", "BIF320", "playready-h264mpl30-dash", "playready-h264mpl31-dash", "playready-h264mpl40-dash", "playready-h264hpl22-dash", "playready-h264hpl30-dash", "playready-h264hpl31-dash", "playready-h264hpl40-dash", "webvtt-lssdh-ios8")
//            })
//            val licenseType = "limited"
//            val challenge = challengeB64
//            val challenges = object {
//                val default = listOf(object {
//                    val drmSessionId = String(sessionId!!)
//                    val clientTime = System.currentTimeMillis() / 1000
//                    val challengeBase64 = challengeB64
//                })
//            }
//        }
//
//        val manifest = object {
//            val version = 2
//            val url = "licensedManifest"
////            val url = "/manifest"
//            val id = System.currentTimeMillis()
//            val languages = listOf(PreferenceManager.getDefaultSharedPreferences(context).getString(SharedPrefs.NFLX.CURRENT_LANG_PREFS, "") ?: "")
//            val echo = ""
//            val params = params
////            val licenseType = "standard"
//        }
//        Log.d("custom manifestv2", Gson().toJson(manifest))
//
//        val endpointUrl = "https://www.netflix.com/nq/msl_v1/cadmium/pbo_manifests/%5E1.0.0/router?reqAttempt=&reqPriority=0&reqName=licensedManifest&clienttype=akira&uiversion=vd5c10190&browsername=chrome&browserversion=96.0.4664.77&osname=chrome+os&osversion=14324.33.0"
//        return Pair(endpointUrl, Gson().toJson(manifest))
//    }
//
//
//    private fun readProp(process: Process): String {
//        val reader = BufferedReader(InputStreamReader(process.inputStream))
//        return reader.readLine()
//    }
//
//    private fun stripTabNL(string: String): String {
//        return string.replace("\\t", "").replace("\\n", "").replace("\\r", "").uppercase()
//    }
//
//    private fun generateAndroidESN(forceL3: Boolean): String {
//        var esn = ""
//        val sdkVersion = readProp(
//            Runtime.getRuntime().exec(arrayOf("/system/bin/getprop", "ro.build.version.sdk"))
//        )
////        Log.d("custom sdk_version", sdkVersion)
//        val manufacturer = stripTabNL(
//            readProp(
//                Runtime.getRuntime().exec(arrayOf("/system/bin/getprop", "ro.product.manufacturer"))
//            )
//        )
////        Log.d("custom manufacturer", manufacturer)
//        val model = stripTabNL(
//            readProp(
//                Runtime.getRuntime().exec(arrayOf("/system/bin/getprop", "ro.product.model"))
//            )
//        )
////        Log.d("custom model", model)
//        val nrdp_modelgroup = if (Integer.parseInt(sdkVersion) >= 28) {
//            stripTabNL(
//                readProp(
//                    Runtime.getRuntime()
//                        .exec(arrayOf("/system/bin/getprop", "ro.vendor.nrdp.modelgroup"))
//                )
//            )
//        } else {
//            stripTabNL(
//                readProp(
//                    Runtime.getRuntime().exec(arrayOf("/system/bin/getprop", "ro.nrdp.modelgroup"))
//                )
//            )
//        }
////        Log.d("custom nrdp_modelgroup", nrdp_modelgroup)
//
//        var securityLevel = MediaDrm(C.WIDEVINE_UUID).getPropertyString("securityLevel")
//        val systemId = MediaDrm(C.WIDEVINE_UUID).getPropertyString("systemId")
//
//        if (forceL3) {
//            securityLevel = "L3"
//        }
//
////        Log.d("custom propertySysId", "$securityLevel $systemId")
//
//        if (securityLevel == "L1") {
//            esn += "NFANDROID2-PRV-"
//            if (nrdp_modelgroup != "") {
//                esn += "$nrdp_modelgroup-"
//            } else {
//                esn += model.replace(" ", "") + "-"
//            }
//        } else {
//            esn += "NFANDROID1-PRV-"
//            esn += "T-L3-"
//        }
//
//        esn += manufacturer.subSequence(0, 5)
//        esn += model.replace(" ", "=")
//        esn = esn.replace("[^A-Za-z0-9=-]".toRegex(), "=")
//        if (systemId != "") {
//            esn += "-$systemId-"
//        }
//
//        Log.d("custom esn", esn)
//
//        return esn
//    }
//
//}