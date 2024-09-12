//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<integration_test/IntegrationTestPlugin.h>)
#import <integration_test/IntegrationTestPlugin.h>
#else
@import integration_test;
#endif

#if __has_include(<path_provider_foundation/PathProviderPlugin.h>)
#import <path_provider_foundation/PathProviderPlugin.h>
#else
@import path_provider_foundation;
#endif

#if __has_include(<player/PlayerPlugin.h>)
#import <player/PlayerPlugin.h>
#else
@import player;
#endif

#if __has_include(<shared_preferences_foundation/SharedPreferencesPlugin.h>)
#import <shared_preferences_foundation/SharedPreferencesPlugin.h>
#else
@import shared_preferences_foundation;
#endif

#if __has_include(<volume_controller/VolumeControllerPlugin.h>)
#import <volume_controller/VolumeControllerPlugin.h>
#else
@import volume_controller;
#endif

#if __has_include(<webview_cookie_manager/WebviewCookieManagerPlugin.h>)
#import <webview_cookie_manager/WebviewCookieManagerPlugin.h>
#else
@import webview_cookie_manager;
#endif

#if __has_include(<webview_flutter_wkwebview/FLTWebViewFlutterPlugin.h>)
#import <webview_flutter_wkwebview/FLTWebViewFlutterPlugin.h>
#else
@import webview_flutter_wkwebview;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [IntegrationTestPlugin registerWithRegistrar:[registry registrarForPlugin:@"IntegrationTestPlugin"]];
  [PathProviderPlugin registerWithRegistrar:[registry registrarForPlugin:@"PathProviderPlugin"]];
  [PlayerPlugin registerWithRegistrar:[registry registrarForPlugin:@"PlayerPlugin"]];
  [SharedPreferencesPlugin registerWithRegistrar:[registry registrarForPlugin:@"SharedPreferencesPlugin"]];
  [VolumeControllerPlugin registerWithRegistrar:[registry registrarForPlugin:@"VolumeControllerPlugin"]];
  [WebviewCookieManagerPlugin registerWithRegistrar:[registry registrarForPlugin:@"WebviewCookieManagerPlugin"]];
  [FLTWebViewFlutterPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTWebViewFlutterPlugin"]];
}

@end
