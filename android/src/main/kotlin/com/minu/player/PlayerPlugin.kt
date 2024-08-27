package com.minu.player

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** PlayerPlugin */
class PlayerPlugin: FlutterPlugin {

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    flutterPluginBinding
      .platformViewRegistry
      .registerViewFactory(PlatformViewType.widevine_player.name, NativePlayerViewFactory(flutterPluginBinding.binaryMessenger))
  }


  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
  }
}
