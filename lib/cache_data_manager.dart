
import 'package:shared_preferences/shared_preferences.dart';

abstract class DataCacheManager {
  Future<void> cache<T>(CacheDataKey key, T value);
  Future<T> get<T>(CacheDataKey key);


  static DataCacheManager get defaultInstance {
     return _DataCacheManagerImpl();
  }
}

 DataCacheManager get dataCacheManager {
  return DataCacheManager.defaultInstance;
}

enum CacheDataKey {
  disney_api_access_token,
  disney_video_access_token,
  disney_refresh_token,
  disney_expire_time
}

class _DataCacheManagerImpl extends DataCacheManager {

  Future<SharedPreferences> get prefs async {
    return await SharedPreferences.getInstance();
  }

  @override
  Future<T> get<T>(CacheDataKey key) async {
    return (await prefs).get(key.name) as T;
  }

  @override
  Future<void> cache<T>(CacheDataKey key, T value) async {
    if(value is int) {
      (await prefs).setInt(key.name, value as int);
    } else if (value is String) {
      (await prefs).setString(key.name, value as String);
    } else if (value is double) {
      (await prefs).setDouble(key.name, value as double);
    } else {
      throw "Unsupported type for caching - $value";
    }
  }

}