//package com.minuai.thutt.minuplayer.drm
//
//import com.minuai.thutt.minuplayer.models.netflix.AudioStream
//import com.minuai.thutt.minuplayer.models.netflix.AudioTrack
//import com.minuai.thutt.minuplayer.models.netflix.Manifest
//import com.minuai.thutt.minuplayer.models.netflix.TextTrack
//import com.minuai.thutt.minuplayer.models.netflix.VideoStream
//import com.minuai.thutt.minuplayer.models.netflix.VideoTrack
//import android.content.Context
//import android.preference.PreferenceManager
//import android.text.TextUtils
//import android.util.Xml
//import com.minuai.thutt.minuplayer.models.netflix.Stream
//import com.minuai.thutt.minuplayer.utils.applyLangCodeChanges
//import com.google.android.exoplayer2.util.Log
//import com.minuai.thutt.minuplayer.mslsession.toMap
//import org.json.JSONObject
//import org.xmlpull.v1.XmlSerializer
//import java.io.StringWriter
//import java.nio.ByteBuffer
//import android.util.Base64
//import com.minuai.thutt.minuplayer.utils.GSON
//import com.minuai.thutt.minuplayer.utils.SharedPrefs
//import java.util.*
//import java.util.regex.Pattern
//import kotlin.collections.ArrayList
//import kotlin.collections.LinkedHashMap
//import kotlin.reflect.KProperty1
//
//
//data class ProtectionInfo(
//    val pssh: String,
//    val keyid: String
//)
//
//// TODO: missing isAdapationSet for audio and video
//var idAdaptationSet = 0
//var appContext: Context? = null
//
//fun convertToDash(manifest: Manifest): String {
//    //TODO get cdn from G.ADDON.getSettingString('cdn_server')[-1]
//    val cdnIndex = 0
//    val seconds: Float = manifest.duration.toFloat() / 1000
//    val duration = "PT${seconds.toInt()}.00S"
//    val root = Xml.newSerializer()
//    val writer = StringWriter()
//    root.setOutput(writer)
//    mpdManifestRoot(root, duration)
//    root.startTag("", "Period")
//
//    val period = root
//
//    val hasVideoDrmStream = manifest.video_tracks[0].hasDrmStreams
//    val videoProtectionInfo = getProtectionInfo(manifest.video_tracks[0])
//    for (videoTrack in manifest.video_tracks) {
//        convertVideoTrack(videoTrack, period, videoProtectionInfo, hasVideoDrmStream, cdnIndex)
//    }
//
//    applyLangCodeChanges(manifest.audio_tracks)
//    applyLangCodeChanges(manifest.timedtexttracks)
//
//    val hasAudioDrmStream = manifest.audio_tracks[0].hasDrmStream
//    val idDefaultAudioTrack = getIdDefaultAudioTrack(manifest)
//
//    for (audioTrack in manifest.audio_tracks) {
//        val isDefault = audioTrack.id == idDefaultAudioTrack
//        convertAudioTrack(audioTrack, period, isDefault, hasAudioDrmStream, cdnIndex)
//    }
//
//    for(textTrack in manifest.timedtexttracks) {
//
//        if(textTrack.isNoneTrack) {
//            continue
//        }
//        val isDefault = isDefaultSubtitle(manifest, textTrack)
//        convertTextTrack(textTrack, period, isDefault, cdnIndex)
//    }
//
//    root.endTag("", "Period")
//    root.endTag("", "MPD")
//    root.endDocument()
//
//    val document = writer.toString()
//
//    return document.replace("\n", "").replace("\r", "")
//}
//
//fun buildRepId(first: String, second: String): String {
//    return String.format("%s?%s", second, first)
//}
//
//fun getMimeType(contentProfile: String): String? {
//    return when (contentProfile) {
////        "simplesdh", "dfxp-ls-sdh" -> "application/ttml+xml"
//        "playready-h264mpl13-dash", "playready-h264mpl22-dash", "playready-h264mpl30-dash",
//        "playready-h264mpl31-dash", "playready-h264hpl22-dash", "playready-h264mpl40-dash",
//        "playready-h264hpl30-dash", "playready-h264hpl31-dash", "playready-h264hpl40-dash",
//        "playready-h264bpl30-dash" -> "video/mp4"
//        "vp9-profile0-L30-dash-cenc", "vp9-profile0-L21-dash-cenc", "vp9-profile0-L31-dash-cenc" -> "video/x-vnd.on2.vp9"
//        "heaac-2hq-dash", "heaac-2-dash" -> "audio/mp4a-latm"
////        "webvtt-lssdh-ios8" -> "text/vtt"
//        else -> null
//    }
//}
//
//fun getCodecType(contentProfile: String): String? {
//    return when (contentProfile) {
//        "playready-h264mpl13-dash", "playready-h264mpl22-dash", "playready-h264mpl30-dash",
//        "playready-h264mpl31-dash", "playready-h264hpl22-dash", "playready-h264mpl40-dash",
//        "playready-h264hpl30-dash", "playready-h264hpl31-dash", "playready-h264hpl40-dash",
//        "playready-h264bpl30-dash" -> "avc1"
//        "vp9-profile0-L30-dash-cenc", "vp9-profile0-L21-dash-cenc", "vp9-profile0-L31-dash-cenc" -> "vp9"
//        "heaac-2hq-dash", "heaac-2-dash" -> "mp4a.40.29"
//        else -> null
//    }
//}
//
//fun convertTextTrack(textTrack: TextTrack, xmlSerializer: XmlSerializer, isDefault: Boolean, cdnIndex: Int) {
//    if (textTrack == null) {
//        return
//    }
//    val downloadable = GSON.toJson(textTrack.ttDownloadables)
//    val gsonTextTrack = GSON.toJson(textTrack)
//
//    var contentProfile = ""
//    val pattern = Pattern.compile("\\{\"(.*?)\"")
//    val matcher = pattern.matcher(downloadable)
//    if (matcher.find()) {
//        contentProfile = matcher.group(1)
//    }
//
//    val isIOS8 = contentProfile == "webvtt-lssdh-ios8"
//    val impaired = if (textTrack.trackType == "ASSISTIVE") {
//        "true"
//    } else {
//        "false"
//    }
//    val forced = if (textTrack.isForcedNarrative) {
//        "true"
//    } else {
//        "false"
//    }
//    val default = if (isDefault) {
//        "true"
//    } else {
//        "false"
//    }
//
//    var codecs = ""
//    var mimeType = ""
//
//    if (isIOS8) {
//        codecs = "wvtt"
//        mimeType = "text/vtt"
//    } else {
//        codecs = "stpp"
//        mimeType = "application/ttml+xml"
//    }
//
//    xmlSerializer.startTag(null, "AdaptationSet")
//    xmlSerializer.attribute(null, "lang", textTrack.language)
//    xmlSerializer.attribute(null, "codecs", codecs)
//    xmlSerializer.attribute(null, "contentType", "text")
//    xmlSerializer.attribute(null, "mimeType", mimeType)
//    xmlSerializer.attribute("", "subsegmentAlignment", "true")
//
////    xmlSerializer.attribute(null, "impaired", impaired)
////    xmlSerializer.attribute(null, "forced", forced)
////    xmlSerializer.attribute(null, "default", default)
//
//    xmlSerializer.startTag(null, "Role")
//    xmlSerializer.attribute(null, "schemeIdUri", "urn:mpeg:dash:role:2011")
//    xmlSerializer.attribute(null, "value", "subtitle")
//    xmlSerializer.endTag(null, "Role")
//
//    var id = ""
//    val pattern2 = Pattern.compile("(downloadableIds.*?\"(\\d.*?)\\D)")
//    val matcher2 = pattern2.matcher(gsonTextTrack)
//    if (matcher2.find()) {
//        id = matcher2.group(2)
//    }
//
//    xmlSerializer.startTag(null, "Representation")
//
////    xmlSerializer.attribute(null, "id", id)
//    xmlSerializer.attribute(null, "id", buildRepId(textTrack.new_track_id, id))
//    xmlSerializer.attribute("", "bandwidth", "0")
//    xmlSerializer.attribute("", "mimeType", "text/vtt")
////    xmlSerializer.attribute(null, "id", id)
////    xmlSerializer.attribute(null, "nflxProfile", contentProfile)
//
//    try {
//        val jsonObj = JSONObject(gsonTextTrack)
//        val ttDownloadables = jsonObj.getJSONObject("ttDownloadables")
//        val content = ttDownloadables.getJSONObject(contentProfile)
//        val downloadURLs = content.getJSONObject("downloadUrls")
//        val map = downloadURLs.toMap() as LinkedHashMap<String, String>
//        val values = ArrayList<String>(map.values)
//
//        val size = content.getLong("size")
//        if (size != 0L) {
//            addBaseUrlWithSize(xmlSerializer, values[cdnIndex], size)
//        } else {
//            addBaseUrl(xmlSerializer, values[cdnIndex])
//        }
//    } catch (ex: Exception) {
//        Log.e("custom error", "convertTextTrack error" + ex)
//    }
//
//    xmlSerializer.endTag(null, "Representation")
//    xmlSerializer.endTag(null, "AdaptationSet")
//}
//
//fun isDefaultSubtitle(manifest: Manifest, currentTextTrack: TextTrack): Boolean {
//    if(currentTextTrack.isForcedNarrative || currentTextTrack.trackType == "ASSISTIVE") {
//        return false
//    }
//
//    for(textTrack in manifest.timedtexttracks) {
//        if(textTrack.language == currentTextTrack.language && (textTrack.isForcedNarrative || textTrack.trackType == "ASSISTIVE")) {
//            return true
//        }
//    }
//
//    return false
//}
//
//fun convertAudioTrack(audioTrack: AudioTrack, xmlSerializer: XmlSerializer, isDefault: Boolean, hasDrmStreams: Boolean, cdnIndex: Int) {
//    val channelsCount = mapOf(Pair("1.0", "1"), Pair("2.0", "2"), Pair("5.1", "6"), Pair("7.1", "8"))
////    val impaired = if (audioTrack.trackType == "ASSISTIVE") "true" else "false"
////    val original = if (audioTrack.isNative) "true" else "false"
////    val default = if (isDefault) "true" else "false"
//
//    val adaptationSet = xmlSerializer
//    adaptationSet.startTag("", "AdaptationSet")
//    adaptationSet.attribute("", "lang", audioTrack.language)
//    adaptationSet.attribute("", "contentType", "audio")
//    adaptationSet.attribute("", "mimeType", "audio/mp4")
//    adaptationSet.attribute("", "subsegmentAlignment", "true")
//
//    // add
//    adaptationSet.startTag("", "AudioChannelConfiguration")
//    adaptationSet.attribute("", "schemeIdUri", "urn:mpeg:dash:23003:3:audio_channel_configuration:2011")
//    adaptationSet.attribute("", "value", channelsCount[audioTrack.channels]!!)
//    adaptationSet.endTag("", "AudioChannelConfiguration")
//
////    adaptationSet.attribute("", "impaired", impaired)
////    adaptationSet.attribute("", "original", original)
////    adaptationSet.attribute("", "default", default)
//
//    if(audioTrack.profile.startsWith("ddplus-atmos")) {
//        adaptationSet.attribute("", "name", "ATMOS")
//    }
//
//    adaptationSet.startTag("", "Role")
//    adaptationSet.attribute("", "schemeIdUri", "urn:mpeg:DASH:role:2011")
//    adaptationSet.attribute("", "value", "main")
//    adaptationSet.endTag("", "Role")
//
//    for(downloadable in audioTrack.streams) {
//        convertAudioDownloadable(downloadable, adaptationSet, channelsCount[downloadable.channels]!!, audioTrack.new_track_id, cdnIndex)
//    }
//
//    adaptationSet.endTag("", "AdaptationSet")
//}
//
//fun convertAudioDownloadable(downloadable: AudioStream, adaptationSet: XmlSerializer, channelCount: String, id: String, cdnIndex: Int) {
//    var codecType = "aac"
//    if(downloadable.content_profile.contains("ddplus-") || downloadable.content_profile.contains("dd-")) {
//        codecType = "ec-3"
//    }
//
//    // fix because mobile not receiving aac and ec-3
//
//    // Add codec hard-coded
//    val mimeType = getMimeType(downloadable.content_profile)
//    if (mimeType != null) {
//        adaptationSet.startTag("", "Representation")
////        adaptationSet.attribute("", "id", downloadable.downloadable_id)
//        adaptationSet.attribute("", "id", buildRepId(id, downloadable.downloadable_id))
//        adaptationSet.attribute("", "codecs", getCodecType(downloadable.content_profile))
//        adaptationSet.attribute("", "startWithSAP", "1")
//        adaptationSet.attribute("", "bandwidth", (downloadable.bitrate * 1024).toString())
//        adaptationSet.attribute("", "mimeType", mimeType)
//
//        adaptationSet.attribute(
//            "",
//            "audioSamplingRate",
//            (downloadable.bitrate / downloadable.channels.toDouble() * 1000).toLong().toString()
//        )
//
////    representation.startTag("", "AudioChannelConfiguration")
////    representation.attribute("", "schemeIdUri", "urn:mpeg:dash:23003:3:audio_channel_configuration:2011")
////    representation.attribute("", "value", channelCount)
////    representation.endTag("", "AudioChannelConfiguration")
//
//        if (downloadable.size != 0L) {
//            addBaseUrlWithSize(adaptationSet, downloadable.urls[cdnIndex].url, downloadable.size)
//        } else {
//            addBaseUrl(adaptationSet, downloadable.urls[cdnIndex].url)
//        }
//        addSegmentBase(adaptationSet, downloadable)
//        adaptationSet.endTag("", "Representation")
//    }
//}
//
//fun mpdManifestRoot(xmlParser: XmlSerializer, duration: String){
//
//    //Start Document
//    xmlParser.startDocument("UTF-8", true)
////    xmlParser.setFeature("http://xmlpull.org/v1/doc/features.html#indent-output", true)
//    //Open Tag <file>
//    xmlParser.startTag("", "MPD")
//    xmlParser.attribute("", "xmlns", "urn:mpeg:dash:schema:mpd:2011")
//    xmlParser.attribute("", "xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance")
//    xmlParser.attribute("", "xmlns:ns2", "http://www.w3.org/2001/XMLSchema")
//    xmlParser.attribute("", "xsi:schemaLocation", "urn:mpeg:DASH:schema:MPD:2011 DASH-MPD.xsd")
//    xmlParser.attribute("", "profiles", "urn:mpeg:dash:profile:isoff-on-demand:2011")
//    xmlParser.attribute("", "minBufferTime", "PT1.500S")
//    xmlParser.attribute("", "type", "static")
////    xmlParser.attribute("", "xmlns:cenc", "urn:mpeg:cenc:2013")
//    xmlParser.attribute("", "mediaPresentationDuration", duration)
////    xmlParser.endTag("", "MPD")
////    xmlParser.flush()
////    xmlParser.endDocument()
////    Log.d("custom xml", writer.toString())
//}
//
//fun getProtectionInfo(content: VideoTrack): ProtectionInfo {
//    val pssh = content.drmHeader.bytes
//    val keyid = content.drmHeader.keyIdId
//
//    return ProtectionInfo(pssh, keyid)
//}
//
//fun convertVideoTrack(videoTrack: VideoTrack, period: XmlSerializer, protection: ProtectionInfo?, hasDrmStreams: Boolean, cdnIndex: Int) {
//    period.startTag("", "AdaptationSet")
//    period.attribute("", "mimeType","video/mp4")
//    period.attribute("", "contentType", "video")
//    period.attribute("", "subsegmentAlignment", "true")
//
//    if (protection != null) {
//        addProtectionInfo(period, protection.pssh, protection.keyid)
//    }
//
//    period.startTag("", "Role")
//    period.attribute("", "schemeIdUri", "urn:mpeg:DASH:role:2011")
//    period.attribute("", "value", "main")
//    period.endTag("", "Role")
//
//    val limitRes = limitVideoResolution(videoTrack.streams, hasDrmStreams)
//
//    for(downloadable in videoTrack.streams) {
//        if(downloadable.isDrm != hasDrmStreams) {
//            continue
//        }
//        if(limitRes != null && downloadable.res_h > limitRes) {
//            continue
//        }
//
//        convertVideoDownloadable(downloadable, period, videoTrack.new_track_id, cdnIndex)
//    }
//
//    period.endTag("", "AdaptationSet")
//}
//
//fun convertVideoDownloadable(downloadable: VideoStream, adaptationSet: XmlSerializer, id: String, cdnIndex: Int) {
//    adaptationSet.startTag("", "Representation")
////    adaptationSet.attribute("", "id", downloadable.downloadable_id)
//    adaptationSet.attribute("", "id", buildRepId(id, downloadable.downloadable_id))
//    adaptationSet.attribute("", "width", downloadable.res_w.toString())
//    adaptationSet.attribute("", "height", downloadable.res_h.toString())
//    adaptationSet.attribute("", "bandwidth", (downloadable.bitrate * 1024).toString())
//    adaptationSet.attribute("", "maxPlayoutRate", "1")
////    adaptationSet.attribute("", "nflxContentProfile", downloadable.content_profile)
//    adaptationSet.attribute("", "startWithSAP", "1")
////    Log.d("custom Video", downloadable.content_profile)
//
//    val codecs = determineVideoCodec(downloadable.content_profile)
//
//    adaptationSet.attribute("", "codecs", codecs)
////    adaptationSet.attribute("", "frameRate", "${downloadable.framerate_value}/${downloadable.framerate_scale}")
//    adaptationSet.attribute("", "mimeType", "video/mp4")
//
//    if (downloadable.size != 0L) {
//        addBaseUrlWithSize(adaptationSet, downloadable.urls[cdnIndex].url, downloadable.size)
//    } else {
//        addBaseUrl(adaptationSet, downloadable.urls[cdnIndex].url)
//    }
//
//    addSegmentBase(adaptationSet, downloadable)
//
//    adaptationSet.endTag("","Representation")
//}
//
//fun addBaseUrl(representation: XmlSerializer, baseUrl: String) {
//    representation.startTag("", "BaseURL")
//    representation.text(baseUrl)
//    representation.endTag("", "BaseURL")
//}
//
//fun addBaseUrlWithSize(representation: XmlSerializer, baseUrl: String, size: Long) {
//    representation.startTag("", "BaseURL")
//    representation.attribute("","ns2:contentLength", size.toString())
//    representation.text(baseUrl)
//    representation.endTag("", "BaseURL")
//}
//
//fun addSegmentBase(representation: XmlSerializer, downloadable: Stream) {
//    if(downloadable.sidx == null) {
//        return
//    }
//    val sidxEndOffset = downloadable.sidx.offset + downloadable.sidx.size
//    var timeScale: String? = null
//    if(downloadable is VideoStream && downloadable.framerate_value != null) {
//        timeScale = "${1000 * downloadable.framerate_value * downloadable.framerate_scale}"
//    }
//    representation.startTag("", "SegmentBase")
//
////    representation.attribute("", "xmlns", "urn:mpeg:dash:schema:mpd:2011")
//
////    representation.attribute("", "indexRange", "${downloadable.sidx.offset}-${sidxEndOffset}")
//    representation.attribute("", "indexRange", "${downloadable.sidx.offset}-${downloadable.sidx.size + downloadable.sidx.offset - 1}")
////    representation.attribute("", "indexRangeExact", "true")
//
////    if(timeScale != null) {
////        representation.attribute("", "timescale", timeScale)
////    }
//    representation.startTag("", "Initialization")
////    representation.attribute("", "range", "0-${downloadable.sidx.offset - 1}")
//    representation.attribute("", "range", "0-${downloadable.moov.offset + downloadable.moov.size - 1}")
//    representation.endTag("", "Initialization")
//
//    representation.endTag("", "SegmentBase")
//
//}
//
//fun limitVideoResolution(videoTracks: List<VideoStream>, hasDrmStreams: Boolean): Int? {
//    val maxResolution = "--"
//    if (maxResolution != "--") {
//        val resLimit = when(maxResolution) {
//            "SD 480p" -> 480
//            "SD 576p" -> 576
//            "HD 720p" -> 720
//            "Full HD 1080p" -> 1080
//            "UHD 4K" -> 4096
//            else -> {
//                return null
//            }
//        }
//
//        for(downloadable: VideoStream in videoTracks) {
//            if(downloadable.isDrm != hasDrmStreams) {
//                continue
//            }
//            if(downloadable.res_h <= resLimit) {
//                return resLimit
//            }
//        }
//    }
//
//    return null
//}
//
//fun determineVideoCodec(contentProfile: String): String {
//    if (contentProfile.startsWith("hevc")) {
//        if (contentProfile.startsWith("hevc-dv")) {
//            return "dvhe"
//        }
//        return "hevc"
//    }
//    if (contentProfile.startsWith("vp9")) {
//        val _contentProfile = contentProfile.slice(11..12)
//        return "vp9.$_contentProfile"
//    }
//
//    // fix codec hardcoded
//    return "avc1"
////    return "h264"
//}
//
//fun getIdDefaultAudioTrack(manifest: Manifest): String {
//    val channelsStereo = listOf("1.0", "2.0")
//    val channelsMulti = listOf("5.1", "7.1")
//
//    // TODO: Create setting boolean for prefer audio stereo
//    val isPreferStereo = false
//
//    // TODO: Get all the settings approved by Kodi later, hardcoded first
//    var audioLanguage = "mediadefault"
//    var audioStream: AudioTrack? = null
//
//    if (audioLanguage == "mediadefault") {
//        // TODO: hardcoded first, fix later
//        val profileLanguageCode = PreferenceManager.getDefaultSharedPreferences(appContext).getString(SharedPrefs.NFLX.CURRENT_LANG_PREFS, "") ?: ""
//
//        // TODO: fix tomorrow logic
//        audioLanguage = profileLanguageCode.slice(0..2)
//    }
//    if (audioLanguage != "original") {
//        // TODO: if G.ADDON.getSettingBool('prefer_alternative_lang'):
//        val preferAlternativeLang = false
//        if (preferAlternativeLang) {
//            var stream: AudioTrack? = null
//            for (audioTrack in manifest.audio_tracks) {
//                if (audioTrack.language.startsWith("$audioLanguage-")) {
//                    stream = audioTrack
//                }
//            }
//            if (stream != null) {
//                audioLanguage = stream.language
//            }
//        }
//
//        if (!isPreferStereo) {
//            audioStream = findAudioStream(manifest, "language", audioLanguage, channelsMulti)
//        }
//        if (audioStream == null) {
//            audioStream = findAudioStream(manifest, "language", audioLanguage, channelsStereo)
//        }
//    }
//
//    if ((audioStream == null) && !isPreferStereo) {
//        audioStream = findAudioStream(manifest, "isNative", true, channelsMulti)
//    }
//    if (audioStream == null) {
//        audioStream = findAudioStream(manifest, "isNative", true, channelsStereo)
//    }
//
//    var impAudioStream: AudioTrack? = null
//    // TODO: if common.get_kodi_is_prefer_audio_impaired():
//    val isPreferAudioImpaired = false
//    if (isPreferAudioImpaired) {
//        if (!isPreferStereo) {
//            impAudioStream = findAudioStream(manifest, "language", audioLanguage, channelsMulti, true)
//        }
//        if (impAudioStream == null) {
//            impAudioStream = findAudioStream(manifest, "language", audioLanguage, channelsStereo, true)
//        }
//    }
//
//    if (impAudioStream != null) {
//        return impAudioStream.id
//    }
//    return audioStream!!.id
//}
//
//fun findAudioStream(manifest: Manifest, propertyName: String, propertyValue: Any, channelsList: List<String>, isImpaired: Boolean = false): AudioTrack? {
//    for (audioTrack in manifest.audio_tracks) {
//        if (propertyValue is String) {
//            if (((readInstanceProperty(audioTrack, propertyName) as String == propertyValue) && channelsList.contains(audioTrack.channels) && audioTrack.trackType == "ASSISTIVE") == isImpaired) {
//                return audioTrack
//            }
//        } else if (propertyValue is Boolean) {
//            if (((readInstanceProperty(audioTrack, propertyName) as Boolean == propertyValue) && channelsList.contains(audioTrack.channels) && audioTrack.trackType == "ASSISTIVE") == isImpaired) {
//                return audioTrack
//            }
//        }
//    }
//    return null
//}
//
//@Suppress("UNCHECKED_CAST")
//fun <R> readInstanceProperty(instance: Any, propertyName: String): R {
//    val property = instance::class.members
//        // don't cast here to <Any, R>, it would succeed silently
//        .first { it.name == propertyName } as KProperty1<Any, *>
//    // force a invalid cast exception if incorrect type here
//    return property.get(instance) as R
//}
//
//fun addProtectionInfo(adaptationSet: XmlSerializer, pssh: String, keyid: String) {
////    if(!TextUtils.isEmpty(keyid)) {
////        adaptationSet.startTag("", "ContentProtection")
////        adaptationSet.attribute("", "schemeIdUri", "urn:mpeg:dash:mp4protection:2011")
////        adaptationSet.attribute("", "cenc:default_KID", convertB64StrToUUID(keyid).toString())
////        adaptationSet.attribute("", "value", "cenc")
////        adaptationSet.endTag("", "ContentProtection")
////    }
//
//    if(!TextUtils.isEmpty(keyid)) {
//        adaptationSet.startTag("", "ContentProtection")
//        adaptationSet.attribute("", "schemeIdUri", "urn:uuid:edef8ba9-79d6-4ace-a3c8-27dcd51d21ed")
//        adaptationSet.endTag("", "ContentProtection")
//
//        adaptationSet.startTag("", "ContentProtection")
//        adaptationSet.attribute("", "value", "cenc")
//        adaptationSet.attribute("", "schemeIdUri", "urn:mpeg:dash:mp4protection:2011")
//        adaptationSet.attribute("", "cenc:default_KID", "9eb4050d-e44b-4802-932e-27d75083e266")
//        adaptationSet.endTag("", "ContentProtection")
//    }
//
////    adaptationSet.startTag("", "ContentProtection")
////    adaptationSet.attribute("", "schemeIdUri", "urn:uuid:EDEF8BA9-79D6-4ACE-A3C8-27DCD51D21ED")
////    adaptationSet.attribute("", "value", "widevine")
////
////    val sharedPrefs = PreferenceManager.getDefaultSharedPreferences(appContext)
////    val securityLevel = sharedPrefs.getString(MainActivity.SECURITY_PREFS, "L3")
////
////    if (securityLevel == "L1") {
////        adaptationSet.startTag("", "widevine:license")
////        adaptationSet.attribute("", "robustness_level", "HW_SECURE_CODECS_REQUIRED")
////        adaptationSet.endTag("", "widevine:license")
////    }
////
////    if (pssh != null) {
////        adaptationSet.startTag("", "cenc:pssh")
////        adaptationSet.text(pssh)
////        adaptationSet.endTag("", "cenc:pssh")
////    }
////
////    adaptationSet.endTag("", "ContentProtection")
//}
//
//fun convertB64StrToUUID(string: String): UUID {
//    val decoded = Base64.decode(string, Base64.NO_WRAP)
//    val byteBuffer = ByteBuffer.wrap(decoded)
//    val firstLong = byteBuffer.getLong()
//    val secondLong = byteBuffer.getLong()
//    return UUID(firstLong, secondLong)
//}