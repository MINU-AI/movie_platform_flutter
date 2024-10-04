package com.minuai.thutt.minuplayer.utils

class SharedPrefs {
    companion object {
        object Netflix {
            const val AUTH_PREFS = "nflx_authentication"
            const val OWNER_USER_PREFS = "nflx_ownerUserGuid"
            const val CURRENT_USER_PREFS = "nflx_currentUserGuid"
            const val CURRENT_LANG_PREFS = "nflx_currentUserLanguage"
            const val FORCE_L3_PREFS = "nflx_forceL3"

            val ESN_PREFS = "nflx_esn_pref"
            val MSL_PREFS = "nflx_msl_pref"
            val SECURITY_PREFS = "nflx_security_level_pref"
            val XID_PREFS = "nflx_xid_pref"
            val COOKIES_PREFS = "nflx_cookies_pref"
        }

        val NFLX: Netflix = Netflix

        object HboMax {
            val TOKEN_PREFS = "hbo_token_pref"
            val EXPIRE_PREFS = "hbo_expires_pref"
            val LOGIN_STATUS = "hbo_login_status"
        }

        val HBOMAX: HboMax = HboMax

        object DisneyPlus {
            val ACCESS_TOKEN_PREFS = "disney_access_token_pref"
            val EXPIRE_PREFS = "disney_expires_pref"
            val REFRESH_TOKEN_PREFS = "disney_refresh_token_pref"
            val PROFILE_GUID = "disney_profile_guid"
            val SESSION_DATA = "disney_session_data"
            val LOGIN_STATUS = "disney_login_status"
        }

        val DISNEYPLUS: DisneyPlus = DisneyPlus

        object Hulu {
            val ACCESS_TOKEN_PREFS = "hulu_access_token_pref"
            val EXPIRE_PREFS = "hulu_expires_pref"
            val PROFILE_ID = "hulu_profile_id"
            val DEVICE_TOKEN_PREFS = "hulu_device_token_pref"
            val LOGIN_STATUS = "hulu_login_status"
        }

        val HULU: Hulu = Hulu

        object AmazonPrime {
            val COOKIES_PREFS = "amazon_cookies_pref"
            val LOGIN_STATUS = "amazon_login_status"
            val USER_INFO = "amazon_user_info"
        }

        val AMAZONPRIME: AmazonPrime = AmazonPrime
    }
}