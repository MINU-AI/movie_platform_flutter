import 'package:collection/collection.dart';
import 'package:player/logger.dart';
import 'package:player/player.dart';
import 'package:uuid/uuid.dart';

class PrimeApi extends MoviePlatformApi {
  AmazonUserProfile? _userProfile;

  @override
  Future<MovieInfo> getMovieInfo(String movieId) {
    throw UnimplementedError();
  }

  @override
  Future<MoviePlayback> getPlaybackUrl(List<dynamic> params) async {
    final movieId = params[0] as String;
    final cookies = params[1] as String;
    _userProfile ??= await _getUserProfile();

    const endpoint = "https://atv-ps.amazon.com/cdp/catalog/GetPlaybackResources";
    final headers = { "Cookie" : cookies };

    final requestParams = {
            "asin": movieId,
            "deviceTypeID": "AOAGZA014O5RE",
            "firmware": "1",
            "deviceID": _userProfile!.deviceId,
            "marketplaceID": _userProfile!.mid,
            "format": "json",
            "version": "2",
            "subtitleFormat": "TTMLv2",
            "resourceUsage": "ImmediateConsumption",
            "consumptionType": "Streaming",
            "deviceDrmOverride": "CENC",
            "deviceStreamingTechnologyOverride": "DASH",
            "deviceProtocolOverride": "Https",
            "deviceBitrateAdaptationsOverride": "CBR",
            "audioTrackId": "all",
            "languageFeature": "MLFv2",
            "videoMaterialType": "Feature",
            "desiredResources": "PlaybackUrls,SubtitleUrls,ForcedNarratives",
            "supportedDRMKeyScheme": "DUAL_KEY",
            "deviceVideoCodecOverride": "H264",
//            "deviceVideoQualityOverride": "HD",
//            "liveManifestType": "accumulating,live",
          //  "operatingSystemName": "Windows",
            "gascEnabled": "false"
            // add gascEnabled because we used fe
    };
    final response = await get(endpoint, headers: headers, params: requestParams);
    logger.i("Got movie playback: $response");
    final urlSets = response["playbackUrls"]["urlSets"] as Map<String, dynamic>;
    final firstKey = urlSets.keys.first;
    final urlData = urlSets[firstKey];
    final playbackUrl = urlData["urls"]["manifest"]["url"];
    logger.i("Got playback url: $playbackUrl");

    return MoviePlayback(playbackUrl:  playbackUrl);
  }

  @override
  Future getToken({List? params}) {
    throw UnimplementedError();
  }

  @override
  Future refreshToken() {
    throw UnimplementedError();
  }
  
  @override
  get metadata => {"deviceId" : _userProfile?.deviceId, "mid" : _userProfile?.mid };
  
}

extension on PrimeApi {
  Future<AmazonUserProfile> _getUserProfile() async {
    final deviceId = const Uuid().v1().replaceAll("-", "");
    const endpoint = "https://atv-ps.amazon.com/cdp/usage/v2/GetAppStartupConfig";
    final params = { "deviceTypeID" : "A28RQHJKHM2A2W", "deviceID" : deviceId, "firmware" : "1", "version" : "1", "format" : "json" };
  
    final config = await get(endpoint, params: params);
    final baseUrl = config["territoryConfig"]["primeSignupBaseUrl"];
    final mid = config["territoryConfig"]["avMarketplace"];
    final host = config["territoryConfig"]["defaultVideoWebsite"] as String;
    final pv = host.contains("primevideo");
    var req = (config["customerConfig"]["homeRegion"] as String).toLowerCase();
    req = (req.contains("na")) ? "" : "-$req";
    const atvurl = "https://atv-ps-fe.primevideo.com"; //host.replaceAll("www.", "").replaceAll("//", "//atv-ps$req.");
    final homeRegion = (config["customerConfig"]["homeRegion"] as String).toLowerCase();
    

    final List<(String, String)> areas = [
      ("A1PA6795UKMFR9", "de"),
      ("A1F83G8C2ARO7P", "uk"),
      ("ATVPDKIKX0DER", "us"),
      ("A1VC38T7YXB528", "jp"),
      ("A3K6Y4MI8GDYMT", "us"),
      ("A2MFUE2XK8ZSSY", "us"),
      ("A15PK738MTQHSO", "us"),
      ("ART4WZ8MWBX2Y", "us")
    ];
    final area = areas.firstWhereOrNull((item) => item.$1 == mid);
    final country = area?.$2 ?? "";
    
    final userProfile = AmazonUserProfile(baseUrl: baseUrl, deviceId: deviceId, mid: mid, country: country, pv: pv, atvurl: atvurl, homeRegion: homeRegion);
    logger.i("Got user profile: $userProfile");

    return userProfile;
  }

}

class AmazonUserProfile {
  final String baseUrl;
  final String deviceId;
  final String mid;
  final String country;
  final bool pv;
  final String atvurl;
  final String homeRegion;

  AmazonUserProfile({required this.baseUrl, required this.deviceId, required this.mid, required this.country, required this.pv, required this.atvurl, required this.homeRegion});

  dynamic toJson() => {
    "baseUrl" : baseUrl,
    "deviceId" : deviceId,
    "mid" : mid,
    "country" : country,
    "pv" : pv,
    "atvurl" : atvurl,
    "homeRegion" : homeRegion
  };

  AmazonUserProfile.fromJson(dynamic json):
    baseUrl = json["baseUrl"], deviceId = json["deviceId"], mid = json["mid"], country = json["country"], pv = json["pv"], atvurl = json["atvurl"], homeRegion = json["homeRegion"];

  @override
  String toString() {
    return "${toJson()}";
  }
  
}