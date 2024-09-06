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

      return MovieInfo(title: title, thumbnail: thumbnail, duration: duration);

    } catch (e) {
      logger.e(e);
      await refreshToken();
      getMovieInfo(movieId, 2);
    }

    throw "Cannot get movie info";
  }

  @override
  Future<MoviePlayback> getPlaybackUrl(List params) async {
    final token = await cacheManager.get(CacheDataKey.hulu_access_token);
    final movieId = params[0] as String;
    final eabId = await _getEabId(movieId);
    final payload = {
      "content_eab_id" : eabId,
       "play_intent" : "resume",
       "unencrypted" : true,
      //  "device_id" : "E2B11E95-FA2B-488D-90DA-776E0B7DE54A",
       "version" : 17,
//                    var version = 1
       "deejay_device_id" : 188,
//                    var deejay_device_id = 191
       "skip_ad_support" : true,
       "all_cdn" : false,
       "ignore_kids_block" : false,
       "device_identifier" : "0000b872ee876f0cb26a20d57d8396a382fe",
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
      //  "region" : "US",
      //  "language" : "en",
       "playback" : {
          "version" : 2,
          "video" : {
            "codecs" : {
              "selection_mode" : "ALL",
              "values" : [
                {
                  "type" : "H264",
                  "width" : 1920,
                  "height" : 1080,
                  "framerate" : 60,
                  "level" : "4.1",
                  "profile" : "HIGH"
                }
              ]
            }
        },

        "audio" : {
          "codecs" : {
              "selection_mode" : "ALL",
              "values" : [
                {
                  "type" : "AAC"
                }
              ]
            }
        },

        "drm" : {
          "selection_mode" : "ONE",
          "values" : [
            {
              "type" : "WIDEVINE",
              "version" : "MODULAR",
              "security_level" : "L1"
            }
          ]
        },

        "manifest" : {
          "type" : "DASH",
          "https" : true,
          "multiple_cdns" : false,
          "patch_updates" : true,
          "hulu_types" : false,
          "live_dai" : false,
          "multiple_periods" : false,
          "xlink" : false,
          "secondary_audio" : true,
          "live_fragment_delay" : 3
        },

        "segments" : {
          "values" : [{
            "type" : "FMP4",
            "encryption" :  {
                "mode" : "CENC",
                "type" : "CENC"
            },
            "https" : true
          }],
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
    final licenseKeyUrl = response["wv_server"];

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

    return MoviePlayback(playbackUrl: playbackUrl, licenseKeyUrl: licenseKeyUrl);
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
  
}