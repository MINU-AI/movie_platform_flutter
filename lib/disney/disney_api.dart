
import 'dart:io';

import '../cache_data_manager.dart';
import '../logger.dart';
import '../movie_platform_api.dart';

class DisneyApi extends MoviePlatformApi {
  dynamic config;

  @override
  Future<MovieInfo> getMovieInfo(String movieId) async {
    final resource = await _getResource(movieId);  
    final item = resource["item"];
    var title = item["visuals"]["title"] as String;
    final isSeries = resource["sequentialEpisode"] as bool;
    if(isSeries) {
      final fullEpisodeTitle = item["visuals"]["fullEpisodeTitle"] as String?;
      if(fullEpisodeTitle != null) {
        title += " - $fullEpisodeTitle";
      } else {
        final fullEpisodeTitleTts = item["visuals"]["fullEpisodeTitleTts"] as String?;
        if(fullEpisodeTitleTts != null) {
          title += " - $fullEpisodeTitleTts";
        }
      }
    }

    var thumbnailData = item["visuals"]["artwork"]["standard"]["tile"];
    thumbnailData ??= item["visuals"]["artwork"]["standard"]["thumbnail"];
    thumbnailData ??= item["visuals"]["artwork"]["standard"]["title_treatment"];
    thumbnailData = thumbnailData as Map;
    final imageId = thumbnailData.values.first["imageId"] as String?;
    final thumbnail = "https://disney.images.edge.bamgrid.com/ripcut-delivery/v2/variant/disney/$imageId/compose?format=webp&width=200";
    final durationInMillisec = item["visuals"]["durationMs"] as int?;

    return MovieInfo(movieId: movieId, title: title, thumbnail: thumbnail, duration: durationInMillisec);
  }

  @override
  Future<MoviePlayback> getPlaybackUrl(List<dynamic> params) async {
    final movieId = params[0] as String;
    final resourceId = await _getResourceId(movieId);
    await _refreshToken();
    final playbackEncryptionDefault = config["services"]["media"]["extras"]["playbackEncryptionDefault"] as String;
    const mediaQualityDefault = "regular"; // config["services"]["media"]["extras"]["mediaQualityDefault"] as String;
    final url = "$_getPlaybackUrl/$playbackEncryptionDefault-$mediaQualityDefault";
    final token = await dataCacheManager.get(CacheDataKey.disney_video_access_token) as String;
    final headers = _createHeader({
                                    "Content-Type": "application/json",
                                    "accept" : "application/vnd.media-service+json; version=6",
                                    "authorization" : token,
                                    "x-dss-feature-filtering" : "true",
                    });
    final body = {
            "playbackId": resourceId,
            "playback": {
                "attributes": {
                    "codecs": {
                        'supportsMultiCodecMaster': false,
                    },
                    "protocol": "HTTPS",                   
                    "frameRates": [60],
                    "assetInsertionStrategy": "SGAI",
                    "playbackInitializationContext": "ONLINE"
                },
            }
        };
    final response = await post(url, body: body, headers: headers);
    String? licenseKeyURL;
    String? licenseCertificateURL;
    if(Platform.isAndroid) {
      licenseKeyURL = config["services"]["drm"]["client"]["endpoints"]["widevineLicense"]["href"] as String?;
      licenseCertificateURL = config["services"]["drm"]["client"]["endpoints"]["widevineCertificate"]["href"] as String?;
    }
    
    licenseKeyURL = config["services"]["drm"]["client"]["endpoints"]["fairPlayLicense"]["href"] as String?;
    licenseCertificateURL = config["services"]["drm"]["client"]["endpoints"]["fairPlayCertificate"]["href"] as String?;
      
    final sources = response["stream"]["sources"] as List<dynamic>;
    final playbackUrl = sources.first["complete"]["url"] as String;
    final mediaPlayback = MoviePlayback(playbackUrl: playbackUrl, licenseKeyUrl: licenseKeyURL, licenseCertificateUrl: licenseCertificateURL);
    logger.i("Got movie playback: $mediaPlayback");
    return mediaPlayback;
  }

  @override
  Future<dynamic> getToken({List<dynamic>? params}) async {
    if(params == null || params.isEmpty) {
      throw "Required params cannot be null or empty";
    }

    final profileId = params.first as String;
    return _switchProfile(profileId);    
  }

  Future<dynamic> _switchProfile(String profileId) async {
      await _getConfig();

      final payload = {
            'operationName': 'switchProfile',
            'variables': {
                'input': {
                    'profileId': profileId,
                },
            },
            'query': _Queries.switchProfile,
      };
      
      final endpoint = config['services']['orchestration']['client']['endpoints']['query']['href'];
      final accessToken = await dataCacheManager.get(CacheDataKey.disney_api_access_token);
      final headers = _createHeader({"authorization" : accessToken });
      
      final response = await post(endpoint, headers: headers, body: payload);      
      _saveTokenData(response);
  }

  Future<void> _getConfig() async {
    if(config != null) {
      return;
    }        
    config = await get(_configUrl);
  }

  Future<dynamic> _getResource(String contentId) async {
    final apiAccessToken = await dataCacheManager.get(CacheDataKey.disney_api_access_token);
    final headers = {
      "authorization" : "Bearer $apiAccessToken"
    };
    final queryUrl = "$_resourceUrl?contentId=$contentId";
    final response = await get(queryUrl, headers: headers);
    final items = (response["data"]["upNext"]["items"] as List<dynamic>?);
    if(items != null) {
      if(items.isEmpty) {
        throw "Resource item is empty";
      }
      return items.first;
    }
    return "Cannot get resource";
  }

  Future<String> _getResourceId(String contentId) async {
    final resource = await _getResource(contentId);
    final actions = resource["item"]["actions"] as List<dynamic>;
    return actions.first["resourceId"];
  }

  Future<void> _refreshToken() async {
    await _getConfig();
    // final expireTime = await dataCacheManager.get<int?>(CacheDataKey.disney_expire_time) ?? 0;
    // final today = DateTime.now().millisecondsSinceEpoch;
    // if(today < expireTime) {
    //   return;
    // }
    
    final refreshToken = await dataCacheManager.get<String>(CacheDataKey.disney_refresh_token);
    
    final payload = {
            'operationName': 'refreshToken',
            'variables': {
                'input': {
                    'refreshToken': refreshToken,
                },
            },
            'query': _Queries.refreshToken,
      };
    
    final endpoint = config["services"]["orchestration"]["client"]["endpoints"]["refreshToken"]["href"] as String;
    final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $_apiKey"
    };
    
    final response = await post(endpoint, body: payload, headers: headers);
    await _saveTokenData(response);
  }

  Future<void> _saveTokenData(dynamic data) async {
    final videoAccessToken = data["extensions"]["sdk"]["token"]["accessToken"] as String?;
    final refreshToken = data["extensions"]["sdk"]["token"]["refreshToken"] as String?;
    final expireTime = data["extensions"]["sdk"]["token"]["expiresIn"] as int?;
    if (videoAccessToken != null && refreshToken != null && expireTime != null) {
      logger.i("Save video token: $videoAccessToken");
      await dataCacheManager.cache(CacheDataKey.disney_video_access_token, videoAccessToken);
      await dataCacheManager.cache(CacheDataKey.disney_refresh_token, refreshToken);
      final expireDateInMillis = DateTime.now().millisecondsSinceEpoch + expireTime * 1000;
      await dataCacheManager.cache(CacheDataKey.disney_expire_time, expireDateInMillis);
    }
  }

  Map<String, String> _createHeader(Map<String, String> headers) {
    var modifiedHeaders = headers;
    modifiedHeaders.addAll(_headers);
    return modifiedHeaders;
  }
  
  @override
  Future<dynamic> refreshToken() async {
    await _refreshToken();
    return dataCacheManager.get(CacheDataKey.disney_video_access_token);
  }
  
}

const _clientId = 'disney-svod-3d9324fc';
const _clientVersion = '9.10.0';
final _sdkPlatform = Platform.isAndroid ? "android-tv" : "apple/ios/iphone";

const _apiKey = 'ZGlzbmV5JmFuZHJvaWQmMS4wLjA.bkeb0m230uUhv8qrAXuNu39tbE_mD5EEhM_NAcohjyA';
final _configUrl = Platform.isAndroid ? 'https://bam-sdk-configs.bamgrid.com/bam-sdk/v5.0/$_clientId/android/v$_clientVersion/google/tv/prod.json' : "https://bam-sdk-configs.bamgrid.com/bam-sdk/v4.0/disney-svod-3d9324fc/apple/v11.1.4/ios/iphone/prod.json";
const _resourceUrl = "https://disney.api.edge.bamgrid.com/explore/v1.4/upNext";
const _getPlaybackUrl = "https://disney.playback.edge.bamgrid.com/v7/playback";

final _headers = {
    'User-Agent': 'BAMSDK/v$_clientVersion ($_clientId 2.26.2-rc1.0; v5.0/v$_clientVersion; android; tv)',
    'x-application-version': 'google',
    'x-bamsdk-platform-id': _sdkPlatform,
    'x-bamsdk-client-id': _clientId,
    'x-bamsdk-platform': _sdkPlatform,
    'x-bamsdk-version': _clientVersion,
    'Accept-Encoding': 'gzip',
};

class _Queries {
    static const switchProfile = "mutation switchProfile(\$input: SwitchProfileInput!) { switchProfile(switchProfile: \$input) { __typename account { __typename ...accountGraphFragment } activeSession { __typename ...sessionGraphFragment } } } fragment accountGraphFragment on Account { __typename id activeProfile { __typename id } profiles { __typename ...profileGraphFragment } parentalControls { __typename isProfileCreationProtected } flows { __typename star { __typename isOnboarded } } attributes { __typename email emailVerified userVerified locations { __typename manual { __typename country } purchase { __typename country } registration { __typename geoIp { __typename country } } } } } fragment profileGraphFragment on Profile { __typename id name maturityRating { __typename ratingSystem ratingSystemValues contentMaturityRating maxRatingSystemValue isMaxContentMaturityRating } isAge21Verified flows { __typename star { __typename eligibleForOnboarding isOnboarded } } attributes { __typename isDefault kidsModeEnabled groupWatch { __typename enabled } languagePreferences { __typename appLanguage playbackLanguage preferAudioDescription preferSDH subtitleLanguage subtitlesEnabled } parentalControls { __typename isPinProtected kidProofExitEnabled liveAndUnratedContent { __typename enabled } } playbackSettings { __typename autoplay backgroundVideo prefer133 } avatar { __typename id userSelected } } } fragment sessionGraphFragment on Session { __typename sessionId device { __typename id } entitlements experiments { __typename featureId variantId version } homeLocation { __typename countryCode } inSupportedLocation isSubscriber location { __typename countryCode } portabilityLocation { __typename countryCode } preferredMaturityRating { __typename impliedMaturityRating ratingSystem } }";
    static const refreshToken = "mutation refreshToken(\$input: RefreshTokenInput!) {refreshToken(refreshToken: \$input) {activeSession {sessionId}}}";    
}