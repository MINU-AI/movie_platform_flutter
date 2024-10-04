package com.minu.player.netflix

import com.google.gson.GsonBuilder


val GSON = GsonBuilder().disableHtmlEscaping().create()

class MSLUtils {
    companion object {
        val CHROME_BASE_URL = "https://www.netflix.com/nq/msl_v1/cadmium/"
        val CHROME_PLAYAPI_URL = "https://www.netflix.com/msl/playapi/cadmium/"

       object EndPoint {
            val manifest = CHROME_BASE_URL + "pbo_manifests/%5E1.0.0/router"
            val license = CHROME_BASE_URL + "pbo_licenses/%5E1.0.0/router"
            val events = CHROME_PLAYAPI_URL + "event/1"
            val logblobs = CHROME_PLAYAPI_URL + "logblob/1"
        }

        val ENDPOINT: EndPoint = EndPoint

        val MSL_DATA_FILENAME = "msl_data.json"

        val EVENT_START = "start"
        val EVENT_STOP = "stop"
        val EVENT_KEEP_ALIVE = "keepAlive"
        val EVENT_ENGAGE = "engage"
        val EVENT_BIND = "bind"
    }
}

class DisneyUtils {
    companion object {
        object Queries {
            val REGISTER_DEVICE = "mutation (\$registerDevice: RegisterDeviceInput!) {registerDevice(registerDevice: \$registerDevice) {__typename}}"
            val LOGIN = "mutation loginTv(\$input: LoginInput!) { login(login: \$input) { __typename account { __typename ...accountGraphFragment } actionGrant activeSession { __typename ...sessionGraphFragment } }} fragment accountGraphFragment on Account { __typename id activeProfile { __typename id } profiles { __typename ...profileGraphFragment } parentalControls { __typename isProfileCreationProtected } flows { __typename star { __typename isOnboarded } } attributes { __typename email emailVerified userVerified locations { __typename manual { __typename country } purchase { __typename country } registration { __typename geoIp { __typename country } } } }}\nfragment profileGraphFragment on Profile { __typename id name maturityRating { __typename ratingSystem ratingSystemValues contentMaturityRating maxRatingSystemValue isMaxContentMaturityRating } isAge21Verified flows { __typename star { __typename eligibleForOnboarding isOnboarded } } attributes { __typename isDefault kidsModeEnabled groupWatch { __typename enabled } languagePreferences { __typename appLanguage playbackLanguage preferAudioDescription preferSDH subtitleLanguage subtitlesEnabled } parentalControls { __typename isPinProtected kidProofExitEnabled liveAndUnratedContent { __typename enabled } } playbackSettings { __typename autoplay backgroundVideo prefer133 } avatar { __typename id userSelected } }}\nfragment sessionGraphFragment on Session { __typename sessionId device { __typename id } entitlements experiments { __typename featureId variantId version } homeLocation { __typename countryCode } inSupportedLocation isSubscriber location { __typename countryCode } portabilityLocation { __typename countryCode } preferredMaturityRating { __typename impliedMaturityRating ratingSystem }}"
            val REFRESH_TOKEN = "mutation refreshToken(\$input: RefreshTokenInput!) {refreshToken(refreshToken: \$input) {activeSession {sessionId}}}"
            val SWITCH_PROFILE = "mutation switchProfile(\$input: SwitchProfileInput!) { switchProfile(switchProfile: \$input) { __typename account { __typename ...accountGraphFragment } activeSession { __typename ...sessionGraphFragment } } } fragment accountGraphFragment on Account { __typename id activeProfile { __typename id } profiles { __typename ...profileGraphFragment } parentalControls { __typename isProfileCreationProtected } flows { __typename star { __typename isOnboarded } } attributes { __typename email emailVerified userVerified locations { __typename manual { __typename country } purchase { __typename country } registration { __typename geoIp { __typename country } } } } } fragment profileGraphFragment on Profile { __typename id name maturityRating { __typename ratingSystem ratingSystemValues contentMaturityRating maxRatingSystemValue isMaxContentMaturityRating } isAge21Verified flows { __typename star { __typename eligibleForOnboarding isOnboarded } } attributes { __typename isDefault kidsModeEnabled groupWatch { __typename enabled } languagePreferences { __typename appLanguage playbackLanguage preferAudioDescription preferSDH subtitleLanguage subtitlesEnabled } parentalControls { __typename isPinProtected kidProofExitEnabled liveAndUnratedContent { __typename enabled } } playbackSettings { __typename autoplay backgroundVideo prefer133 } avatar { __typename id userSelected } } } fragment sessionGraphFragment on Session { __typename sessionId device { __typename id } entitlements experiments { __typename featureId variantId version } homeLocation { __typename countryCode } inSupportedLocation isSubscriber location { __typename countryCode } portabilityLocation { __typename countryCode } preferredMaturityRating { __typename impliedMaturityRating ratingSystem } }"
            val ENTITLEMENTS = "query EntitledGraphMeQuery { me { __typename account { __typename ...accountGraphFragment } activeSession { __typename ...sessionGraphFragment } } } fragment accountGraphFragment on Account { __typename id activeProfile { __typename id } profiles { __typename ...profileGraphFragment } parentalControls { __typename isProfileCreationProtected } flows { __typename star { __typename isOnboarded } } attributes { __typename email emailVerified userVerified locations { __typename manual { __typename country } purchase { __typename country } registration { __typename geoIp { __typename country } } } } } fragment profileGraphFragment on Profile { __typename id name maturityRating { __typename ratingSystem ratingSystemValues contentMaturityRating maxRatingSystemValue isMaxContentMaturityRating } isAge21Verified flows { __typename star { __typename eligibleForOnboarding isOnboarded } } attributes { __typename isDefault kidsModeEnabled groupWatch { __typename enabled } languagePreferences { __typename appLanguage playbackLanguage preferAudioDescription preferSDH subtitleLanguage subtitlesEnabled } parentalControls { __typename isPinProtected kidProofExitEnabled liveAndUnratedContent { __typename enabled } } playbackSettings { __typename autoplay backgroundVideo prefer133 preferImaxEnhancedVersion} avatar { __typename id userSelected } } } fragment sessionGraphFragment on Session { __typename sessionId device { __typename id } entitlements experiments { __typename featureId variantId version } homeLocation { __typename countryCode } inSupportedLocation isSubscriber location { __typename countryCode } portabilityLocation { __typename countryCode } preferredMaturityRating { __typename impliedMaturityRating ratingSystem } }"
        }

        val QUERIES: Queries = Queries

        val CONFIG_URL = "https://bam-sdk-configs.bamgrid.com/bam-sdk/v3.0/disney-svod-3d9324fc/android/v6.1.0/google/tv/prod.json"
        val API_KEY = "ZGlzbmV5JmFuZHJvaWQmMS4wLjA.bkeb0m230uUhv8qrAXuNu39tbE_mD5EEhM_NAcohjyA"
    }
}

class HuluUtils {
    companion object {
        val USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.81 Safari/537.36"
    }
}

class YoutubeUtils {
    companion object {
        val USER_AGENT = "Mozilla/5.0 (Linux; Android 7.0; SM-G892A Build/NRD90M; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/67.0.3396.87 Mobile Safari/537.36"
    }
}