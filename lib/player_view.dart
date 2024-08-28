import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'drmplayer.dart';
import 'platform_constant.dart';

abstract class PlayerView extends StatefulWidget {
  final PlatformViewType viewType = PlatformViewType.widevine_player;
  final DrmPlayer player;

  const PlayerView({super.key, required this.player });

  Widget get nativePlayerView;

  factory PlayerView.creatPlater({required DrmPlayer player}) {
    if(Platform.isAndroid) {
      return _AndroidPlayerView(player: player);
    }
    throw "Unimplemented for this platform";
  }

  @override
  State<StatefulWidget> createState() => _PlayerViewState();

}

class _PlayerViewState extends State<PlayerView> with PlayerListener {
  var _showPlayerLoading = false;

  @override
  void initState() {
    widget.player.addListener(this);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant PlayerView oldWidget) {    
    super.didUpdateWidget(oldWidget);    
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        widget.nativePlayerView,
        Visibility(visible: _showPlayerLoading, child: const CupertinoActivityIndicator(color: Color(0xFFFFFFFF), radius: 14,))
      ],
    );
  }

  @override
  void dispose() {
    widget.player.removeListener(this);

    super.dispose();
  }

  void showAlertDialog({ String? title, String? content, void Function()? onOkPressed }) {
    showCupertinoDialog(context: context, builder: (_) {
      final theme = Theme.of(context);
      final isDarkMode = theme.brightness == Brightness.dark;

      return CupertinoAlertDialog(
                title: title != null ? Text(title, style: TextStyle(color: Color(isDarkMode ? 0xFFFFFFFF : 0xFF000000), fontWeight: FontWeight.bold, fontSize: 16, decoration: TextDecoration.none),) : null,
                content: content != null ? Text(content, style: TextStyle(color: Color(isDarkMode ? 0xFFFFFFFF : 0xFF000000), fontWeight: FontWeight.normal, fontSize: 14, decoration: TextDecoration.none),) : const SizedBox(),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onOkPressed?.call();
                    },
                    child: const Text("OK", style: TextStyle(color: Color(0xFF007AFF), decoration: TextDecoration.none),),
                  )
                ],
              );
     });
  }
  
  @override
  void onPlaybackStateChanged(PlayerState state) {
    setState(() {
        _showPlayerLoading = state == PlayerState.bufferring;  
      });    
  }
  
  @override
  void onPlayerError(PlayerError error) {
    setState(() {
        _showPlayerLoading = false;  
        showAlertDialog(title: "Cannot play the movie", content: "${error.errorCodeName} - ${error.message}");
      }); 
  }
}

class _AndroidPlayerView extends PlayerView {
  
  const _AndroidPlayerView({required super.player });
  
  @override
  Widget get nativePlayerView {
    return AndroidView(
      viewType: viewType.name,
      layoutDirection: TextDirection.ltr,
      creationParams: player.paramsForPlayerView,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
  
}