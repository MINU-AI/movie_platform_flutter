import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:player/assets.dart';
import 'package:player/logger.dart';
import 'package:player/splash_button.dart';

import 'drmplayer.dart';
import 'platform_constant.dart';

abstract class PlayerView extends StatefulWidget {
  final PlatformViewType viewType = PlatformViewType.widevinePlayer;
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
  var _progressWidth = 0.0;
  bool? _isPlaying;
  Timer? _updatePlayerTimer;

  double get seekBarWidth =>  MediaQuery.of(context).size.width;

  double get activeBarMaxWidth => seekBarWidth - 12;

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

    return Scaffold(
      body: Stack(
              alignment: Alignment.center,
              children: [
                widget.nativePlayerView,

                Visibility(visible: _showPlayerLoading, child: const CupertinoActivityIndicator(color: Color(0xFFFFFFFF), radius: 14,)),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Spacer(),
                    
                    GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        logger.i("onHorizontalDragUpdate: ${details.delta.dx}"); 
                                              setState(() {
                                                _progressWidth += details.delta.dx;  
                                                if(_progressWidth < 0) {
                                                  _progressWidth = 0;
                                                } else if (_progressWidth > activeBarMaxWidth) {
                                                  _progressWidth = activeBarMaxWidth;
                                                }
                                              });    
                      },
                      onHorizontalDragEnd: (details) {
                        logger.i("onHorizontalDragEnd: $details");
                      },
                      child: Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  Container(
                                      width: double.infinity,
                                      decoration: const BoxDecoration(color: Color(0xFFF0F0F0)),
                                      height: 2,                                      
                                  ),

                                  Container(
                                      width: 200,
                                      decoration: const BoxDecoration(color: Colors.grey),
                                      height: 2,                                      
                                  ),

                                  Container(
                                    height: 2,
                                    decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF10904), Color(0xFFEA7B35)])),
                                    width: _progressWidth,
                                  ),

                                  Transform.translate(
                                            offset: Offset(_progressWidth, 0),
                                            child: Container(
                                                      width: 12,
                                                      height: 12,
                                                      decoration: BoxDecoration(color: const Color(0xFFEB7633), borderRadius: BorderRadius.circular(12)),
                                                    ),                                                        
                                          )
                                                
                                ],
                              ),
                      )
                    ),
                    
                    SplashButton(      
                      splashColor: Colors.amber,
                      borderRadius: BorderRadius.circular(32),                                          
                      onPressed: () {
                        
                      },                      
                      child: const Padding(padding: EdgeInsets.all(8), child: Image(image: AssetImage(Assets.icFullscreen), width: 24, height: 24,),)
                      
                    ),

                    const SizedBox(height: 4,)

                  ],
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                   SplashButton(      
                      splashColor: Colors.amber,
                      borderRadius: BorderRadius.circular(32),                                          
                      onPressed: () {
                        forward(const Duration(seconds: -10));
                      },                      
                      child: const Image(image: AssetImage(Assets.icBackward), width: 32, height: 32,)
                      
                    ),

                    const SizedBox(width: 32,),

                    SplashButton(      
                      splashColor: Colors.amber,
                      borderRadius: BorderRadius.circular(32),                                          
                      onPressed: togglePlay,                      
                      child: const Image(image: AssetImage(Assets.icPause), width: 48, height: 48,)
                      
                    ),

                    const SizedBox(width: 32,),

                    SplashButton(      
                      splashColor: Colors.amber,
                      borderRadius: BorderRadius.circular(32),                                          
                      onPressed: () {
                        forward(const Duration(seconds: 10));
                      },                      
                      child: const Image(image: AssetImage(Assets.icForward), width: 32, height: 32,)
                      
                    )
                  ],
                )
                  
              ],
            )
    );
  }

  @override
  void dispose() {
    widget.player.removeListener(this);
    _updatePlayerTimer?.cancel();

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
    widget.player.showControl(false);
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
  
  @override
  void onPlayingChange(bool isPlaying) {
    _isPlaying = isPlaying;
    if(isPlaying) {
      _updatePlayerTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
        final currentPosition = await widget.player.currentPosition;
        final duration = await widget.player.duration;
        if(currentPosition == null || duration == null) {
          return;
        }

        setState(() {
          _progressWidth = (currentPosition / duration) * activeBarMaxWidth;  
        });
        
      });
    }
  }

}

extension on _PlayerViewState {
  void forward(Duration step) async {
    var currentPosition = await widget.player.currentPosition;
    if(currentPosition == null) {
      return;
    }
    
    currentPosition += step.inMilliseconds;
    logger.i("Got seek position: $currentPosition");
    widget.player.seek(Duration(milliseconds: currentPosition));

  }

  void togglePlay() {
    if(_isPlaying == null) {
      return;
    }
    if(_isPlaying!) {
      widget.player.pause();
    } else {
      widget.player.play();
    }
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