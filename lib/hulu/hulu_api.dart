import 'package:path_provider/path_provider.dart';
import 'package:player/cache_data_manager.dart';
import 'package:player/extension.dart';
import 'package:player/logger.dart';
import 'package:player/movie_platform_api.dart';
import 'package:xml/xml.dart';
import 'dart:io';

class HuluApi extends MoviePlatformApi {
  @override
  Future<MovieInfo> getMovieInfo(String movieId, [int retry = 1]) async {
    if(retry > 4) {
      throw "Exceed the times of retry";
    }

    try {
      final eabId = await _getEabId(movieId);
      final movieItem = await _getMovieItem(eabId);
      
      var title = movieItem["name"];
      String? thumbnail;
      int? duration = movieItem["bundle"]["duration"];
      final type = movieItem["_type"];
      if(type == "episode") {
        final seriesName = movieItem["series_name"];
        if(seriesName != null) {
          title += " - $seriesName";
        }
        final season = movieItem["season"];
        if(season != null) {
          title += " - S$season";
        }
        final episode = movieItem["number"];
        if(episode != null) {
          title += "-E$episode";
        } 

        final imagePath = movieItem["artwork"]["video.horizontal.hero"]["path"];
        thumbnail = getImageLink(imagePath);

      } else if(type == "movie") {
        final imagePath = movieItem["artwork"]["program.tile"]["path"];
        thumbnail = getImageLink(imagePath);
      }

      return MovieInfo(movieId: movieId, title: title, thumbnail: thumbnail, duration: duration);

    } catch (e) {
      logger.e(e);
      await refreshToken();
      getMovieInfo(movieId, retry+1);
    }

    throw "Cannot get movie info";
  }

  @override
  Future<MoviePlayback> getPlaybackUrl(String movieId) async {
    final token = await cacheManager.get(CacheDataKey.hulu_access_token);    
    final eabId = await _getEabId(movieId);
    final payload = {
      "content_eab_id" : eabId,
       "play_intent" : "resume",
       "unencrypted" : true,
       "device_id" : Platform.isAndroid ? null : "E2B11E95-FA2B-488D-90DA-776E0B7DE54A",
       "version" : Platform.isAndroid ? 17 : 3,
//                    var version = 1
       "deejay_device_id" :Platform.isAndroid ? 188 : 176,
//                    var deejay_device_id = 191
       "skip_ad_support" : true,
       "all_cdn" : false,
       "ignore_kids_block" : false,
       "device_identifier" : Platform.isAndroid ?  "0000b872ee876f0cb26a20d57d8396a382fe" : "E2B11E95-FA2B-488D-90DA-776E0B7DE54A",
//                    var device_identifier = "302DFAC6BC84A5E8697ADAB4240499B8:b216"
       "include_t2_rev_beacon" : false,
       "include_t2_adinteraction_beacon" : false,
       "support_brightline" : false,
       "support_innovid" : false,
       "support_innovid_truex" : false,
       "support_gateway" : false,
       "limit_ad_tracking" : true,
       "network_mode" : "wifi",
       "enable_selectors" : false,
       "format" : "json",
       "is_tablet" : false,
//                    var all_cdn = true
       "region" : "US",
       "language" : "en",
       "playback" : {
          "version" : 2,
          "video" : {
            "codecs" : {
              "selection_mode" : Platform.isAndroid ? "ALL" : "ONE",
              "values" : Platform.isAndroid ? [
                {
                  "type" : "H264",
                  "width" : 1920,
                  "height" : 1080,
                  "framerate" : 60,
                  "level" : "4.1",
                  "profile" : "HIGH"
                }
              ] : [
                {
                  "tier" : "MAIN",
                  "type" : "H265",
                  "width" : 1920,
                  "height" : 1080,
                  "level" : "4.1",
                  "profile" : "MAIN_10"
                }, 
                {                  
                  "type" : "H264",
                  "width" : 1920,
                  "height" : 1080,
                  "level" : "4.1",
                  "profile" : "HIGH"
                }
              ]
            }
        },

        "audio" : {
          "codecs" : {
              "selection_mode" : "ALL",
              "values" : Platform.isAndroid ? [
                {
                  "type" : "AAC"
                }
              ] : [
                 {
                  "type" : "AAC"
                 },
                //  {
                //   "type" : "EC3"
                //  }
              ]
            }
        },

        "drm" : {
          "selection_mode" : "ONE",
          "values" : Platform.isAndroid ? [
            {
              "type" : "WIDEVINE",
              "version" : "MODULAR",
              "security_level" : "L1",
            }
          ] : [
            {
              "type" : "FAIRPLAY",
            }
          ]
        },

        "manifest" : {
          "type" : Platform.isAndroid ? "DASH" : "HLS",
          "https" : true,
          "multiple_cdns" : false,
          "patch_updates" : true,
          "hulu_types" : false,
          "live_dai" : false,
          "multiple_periods" : false,
          "xlink" : false,
          "secondary_audio" : true,
          "live_fragment_delay" : 3,
        },

        "segments" : {
          "values" : Platform.isAndroid ? [
            {
            "type" : "FMP4",
            "encryption" :  {
                "mode" : "CENC",
                "type" : "CENC"
            },
            "https" : true
            }
          ] : [
            {
              "muxed": false, 
              "https": true, 
              "type": "FMP4",
              "encryption": {
                "mode": "CBCS", 
                "type": "CENC"
              }
            },

            {
              "muxed": true, 
              "https": true, 
              "type": "MPEGTS",
              "encryption": {
                "mode": "CBCS", 
                "type": "SAMPLE_AES"
              }
            },
          ],
          "selection_mode" : "ONE"
        }
      }
    };

    const endpoint = "https://play.hulu.com/v6/playlist";
    final headers = {
      "Authorization" : "Bearer $token"
    };

    var response = await post(endpoint, headers: headers, body: payload);
    var playbackUrl = response["stream_url"];
    if(playbackUrl == null) {
      throw "Got getPlaybackUrl error: $response";
    }

    final licenseKeyUrl = Platform.isAndroid ? response["wv_server"] : response["fp_server"];
    final certificateUrl = Platform.isAndroid ? null : response["fp_cert"];

    if(Platform.isAndroid) {
      response = await get(playbackUrl, parseResponseBody: false);
      final xmlDocument = XmlDocument.parse(response);
      final contentProtectionElements = xmlDocument.findAllElements("ContentProtection").where( (element) => element.getAttribute("cenc:default_KID") != null);
      for(final element in contentProtectionElements) {
        final defaultKID = element.getAttribute("cenc:default_KID");
        final defaultKIDWithDash = defaultKID?.parseUuidWithoutDashes();
        element.setAttribute("cenc:default_KID", defaultKIDWithDash);
        logger.i("Got cenc:default_KID: $defaultKID, $defaultKIDWithDash");
      }

      final directory = await getApplicationCacheDirectory();
      final mpdFile = File("${directory.path}/playback_${DateTime.now().millisecondsSinceEpoch}.mpd");
      await mpdFile.create();
      await mpdFile.writeAsString(xmlDocument.toXmlString());
      logger.i("Got mpd file path: ${mpdFile.path}");   
      playbackUrl = "file://${mpdFile.path}";
    }

    return MoviePlayback(playbackUrl: playbackUrl, licenseKeyUrl: licenseKeyUrl, licenseCertificateUrl: certificateUrl);
  }

  @override
  Future getToken({List? params}) {
    throw UnimplementedError();
  }

  @override
  Future refreshToken() async {
    final deviceToken = await cacheManager.get(CacheDataKey.hulu_device_token);
    final body = "action=token_refresh&device_token=$deviceToken";
    final headers = {
      "Content-Type" : "application/x-www-form-urlencoded"
    };

    const url = "https://auth.hulu.com/v1/device/device_token/authenticate";
    final response = await post(url, body: body, headers: headers, parseBodyToJson: false);
    final token = response["user_token"];
    logger.i("Got new token: $token");
    await cacheManager.cache(CacheDataKey.hulu_access_token, token);
  }

  Future<String> _getEabId(String movieId) async {
    final token = await cacheManager.get(CacheDataKey.hulu_access_token);
    const endpoint = "https://discover.hulu.com/content/v5/deeplink/playback";
    final headers = {
      "Authorization" : "Bearer $token"
    };

    final params = {
      "id": movieId,
      "namespace": "entity",
      "schema" : "1"
    };

    final response = await get(endpoint, headers: headers, params: params);
    if(response["eab_id"] == null) {
      throw "Got _getEabId error: $response";
    }

    return response["eab_id"];
  }

  Future<dynamic> _getMovieItem(String eabId) async {
    final token = await cacheManager.get(CacheDataKey.hulu_access_token);
    const endpoint = "https://discover.hulu.com/content/v3/entity";
    final params = {
      "language" : "en",
      "eab_ids" : eabId
    };

    final headers = {
      "Authorization": "Bearer $token"
    };

    final response = await get(endpoint, headers: headers, params: params);
    if(response["items"] is! List<dynamic>) {
      throw "Got _getMovieItem error: $response";
    }
    return (response["items"] as List<dynamic>).first;
  }

  String? getImageLink(String imagePath) {
    final uri = Uri.parse(imagePath);
    var imageId = uri.pathSegments.lastOrNull;
    if(imageId != null) {
      if(uri.queryParameters.isNotEmpty) {
        imageId += "?";
      }
      for(final entry in uri.queryParameters.entries) {
        imageId = "$imageId${entry.key}=${entry.value}&";
      }      
      
      return "https://img3.hulu.com/user/v3/artwork/${imageId}operations=%5B%7B%22resize%22:%22600x500%7Cmax%22%7D,%7B%22format%22:%22jpeg%22%7D%5D";
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>> get metadata async {
    final token = await dataCacheManager.get(CacheDataKey.hulu_access_token);
    final metadata = {
      "token" : token,
    };
    return metadata;
  }
  
}