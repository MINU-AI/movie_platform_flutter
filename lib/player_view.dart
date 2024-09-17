import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:player/assets.dart';
import 'package:player/extension.dart';
import 'package:player/logger.dart';
import 'package:player/splash_button.dart';
import 'package:player/text_view.dart';
import 'package:volume_controller/volume_controller.dart';

import 'drmplayer.dart';
import 'native_constant.dart';

abstract class PlayerView extends StatefulWidget {
  final PlatformViewType viewType = PlatformViewType.widevinePlayer;
  final DrmPlayer player;
  final bool showFullScreen;
  final void Function(bool)? onFullscreen;

  const PlayerView({super.key, required this.player, this.showFullScreen = true, this.onFullscreen });

  Widget get nativePlayerView;

  factory PlayerView.create({required DrmPlayer player, void Function(bool)? onFullscreen }) {
    if(Platform.isAndroid) {
      return _AndroidPlayerView(player: player, onFullscreen: onFullscreen, );
    }

    if(Platform.isIOS) {
      return _IOSPlayerView(player: player, onFullscreen: onFullscreen,);
    }
    throw "Unimplemented for this platform";
  }

  @override
  State<StatefulWidget> createState() => _PlayerViewState();

}

class _PlayerViewState extends State<PlayerView> with PlayerListener, TickerProviderStateMixin {
  var _showPlayerLoading = true;
  var _progressWidth = 0.0;
  var _progressBufferWidth = 0.0;
  bool? _isPlaying;
  Timer? _updatePlayerTimer;
  Timer? _hideControllTimer;
  bool? _isSeeking;
  AnimationController? _animationController;
  Animation<double>? _animation;

  final _animationDuration = 500;
  double? _screenWidth;
  final _splashColor = const Color(0xFF353641).withOpacity(0.6);
  int? _duration;
  int? _currentPosition;
  var _currentVolume = 0.0;
  var _showControl = false;
  var _isLanscape = false;
  var _isChangingVolume = false;
  var _currentBrightness = 0.0;

  double get seekBarWidth {
    _screenWidth ??=  MediaQuery.of(context).size.width;
    return _screenWidth!;
  }

  double get progressMaxWidth => seekBarWidth - 12;

  @override
  void initState() {
    widget.player.addListener(this);    
    initVolumeController();    
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Stack(
              alignment: Alignment.center,
              children: [
                
               Container(
                color: const Color(0xFF000000),
                child: widget.nativePlayerView,
               ),

                Visibility(visible: _showPlayerLoading, child: const CupertinoActivityIndicator(color: Color(0xFFFFFFFF), radius: 14,)),

                GestureDetector(
                  onTap: onControlsTapped,
                  child: Container(color: Colors.transparent, width: double.infinity, height: double.infinity,)
                ),

                Visibility(
                  visible: _showControl,
                  child: playerControlsView,
                ),                                                  
              ],
            );
  }

  @override
  void dispose() {
    widget.player.removeListener(this);    
    _animationController?.dispose();
    releaseControlTimer();
    releaseUpdatePlayerTimer();
    VolumeController().removeListener();
    
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft
    ]);

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
    // logger.i("Got onPlaybackStateChanged: $state");
    if(state == PlayerState.end) {
      releaseUpdatePlayerTimer();
    }    
    
    setState(() {
      _showPlayerLoading =  state == PlayerState.bufferring;
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
    initBrightness();
    if(isPlaying && _isSeeking != true){
      createUpdatePlayerTimer(); 
    }    
  }

}

extension on _PlayerViewState {
  void createUpdatePlayerTimer() {
    _updatePlayerTimer?.cancel();
    _updatePlayerTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
      final currentPosition = await widget.player.currentPosition;      
      final duration = await widget.player.duration;
      final bufferedPercentage = await widget.player.bufferedPercentage;
      if(currentPosition == null || duration == null || bufferedPercentage == null) {
        return;
      }
      logger.i("Got currentPosition: $currentPosition, $bufferedPercentage");
      final newBufferWidth = (bufferedPercentage / 100.0) * seekBarWidth;
      if(newBufferWidth != _progressBufferWidth) {
          final animationDuration = ((_progressBufferWidth - newBufferWidth).abs() / seekBarWidth) * _animationDuration;
          final tween = newBufferWidth > _progressBufferWidth ? Tween(begin: _progressBufferWidth, end: newBufferWidth) : Tween(begin: _progressBufferWidth, end: newBufferWidth);
          _animationController?.dispose();
          _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: animationDuration.toInt()));
          _animation = tween.animate(_animationController!)..addListener(() {
            setState((){
              _progressBufferWidth = _animation!.value;          
            });
          },);

          _animationController!.forward();
      }

      setState(() {
        _currentPosition = currentPosition;
        _duration = duration;
        _progressWidth = (currentPosition / duration) * progressMaxWidth;  
      });
      
    });
  }

  void releaseUpdatePlayerTimer() {
    _updatePlayerTimer?.cancel();
    _updatePlayerTimer = null;
  }

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
    releaseControlTimer();
    if(_isPlaying!) {
      widget.player.pause();
    } else {
      widget.player.play();
    }
    createControlTimer();
  }

  void updateProgress(Offset offset) async {
    _progressWidth += offset.dx;
    
    setState(() {
      if(_progressWidth < 0) {
        _progressWidth = 0;
      } else if (_progressWidth > progressMaxWidth) {
        _progressWidth = progressMaxWidth;
      }
    });    
  }

  Future<void> updatePlayerPosition() async {
    final duration = await widget.player.duration;
    if(duration == null) {
      return;
    }
    final newPosition = (_progressWidth / progressMaxWidth) * duration;
    logger.i("Got new position: $newPosition, ${newPosition.round()}");
    widget.player.seek(Duration(microseconds: (newPosition * 1000).toInt()));
  }

  void onControlsTapped() {
    logger.i("Got tapp on player");

    setState(() {
      _showControl = !_showControl;
      _hideControllTimer?.cancel();
      if(_showControl) {
       createControlTimer();           
      } else {
        releaseControlTimer();
      }
    });
  }

  void createControlTimer() {
    _hideControllTimer = Timer(const Duration(seconds: 5), () {
      setState(() {
        _showControl = false;
      },);          
    });    
  }

  void releaseControlTimer() {
    _hideControllTimer?.cancel();
    _hideControllTimer = null;
  }

  void onFullscreenTapped() {
    releaseControlTimer();
    _isLanscape = !_isLanscape;
    widget.onFullscreen?.call(_isLanscape);
    final orientation = _isLanscape ? DeviceOrientation.landscapeRight : DeviceOrientation.portraitUp;
    SystemChrome.setPreferredOrientations([
      orientation
    ]);
    createControlTimer();
  }

  void initVolumeController() {
    final volumeController =  VolumeController();
    volumeController.listener((volume) {  
      if(_isChangingVolume) {
        return;
      }
      setState(() {
        _currentVolume = volume;
      });
    });
    volumeController.showSystemUI = true;
    volumeController.getVolume().then((volume) {
      logger.i("Got current volume: $volume");
      setState(() {
        _currentVolume = volume;
      });
    });
  }

  void initBrightness() async {
    final brightness = await widget.player.brightness ?? 0;  
    setState(() {
      _currentBrightness = brightness;
    },);    
  }
}

extension on _PlayerViewState {
  Widget get playerControlsView {
    return Stack(
              alignment: Alignment.center,
              children: [
                IgnorePointer(
                  child: Container(color: Colors.black.withOpacity(0.4),),
                ),

                widget.player.payload.info?.title != null ? 
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: ConstrainedBox(constraints: BoxConstraints(maxHeight: seekBarWidth - 32), child: TextView(text: widget.player.payload.info!.title, maxLines: 1, fontSize: 12,)),
                  ) : const SizedBox(),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Spacer(),

                    _currentPosition != null && _duration != null ? Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 2),
                          child: TextView(text: "${_currentPosition!.toTimeDisplay()} / ${_duration!.toTimeDisplay()}", fontSize: 10,)
                        )
                      ],
                    ) : const SizedBox(),
                    
                    GestureDetector(
                      onHorizontalDragStart: (details) {
                        _isSeeking = true;
                        releaseControlTimer();
                        releaseUpdatePlayerTimer();
                      },
                      onHorizontalDragUpdate: (details) {
                        logger.i("onHorizontalDragUpdate: ${details.delta.dx}"); 
                        updateProgress(details.delta);
                      },
                      onHorizontalDragEnd: (details) async {
                        logger.i("onHorizontalDragEnd: $details");
                        await updatePlayerPosition();
                        _isSeeking = false;   
                        createControlTimer();                     
                      },
                      child: Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(color: const Color(0xFFD9D9D9).withOpacity(0.2)),
                                      height: 4,                                      
                                  ),

                                  Container(
                                      width: _progressBufferWidth,
                                      decoration: const BoxDecoration(color: Color(0xFFE5E8EA)),
                                      height: 4,                                      
                                  ),

                                  Container(
                                    height: 4,
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
                    
                   widget.showFullScreen ? SplashButton(      
                      splashColor: _splashColor,
                      borderRadius: BorderRadius.circular(32),                                          
                      onPressed: onFullscreenTapped,                      
                      child: const Padding(padding: EdgeInsets.all(8), child: Image(image: AssetImage(Assets.icFullscreen), width: 24, height: 24,),)
                      
                    ) : const SizedBox(),                    

                  ],
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                      const SizedBox(width: 24,),

                      _VerticalSeekBar(topIcon: Assets.icPlayerBrightness, initialValue: _currentBrightness, onStart: releaseControlTimer, onEnd: (value) => createControlTimer, onUpdate: (value) {
                        _currentBrightness = value;
                        widget.player.setBrightness(value);
                      }),

                      const Spacer(),

                      SplashButton(      
                        splashColor: _splashColor,
                        borderRadius: BorderRadius.circular(40),                                          
                        onPressed: () {
                          releaseControlTimer();
                          forward(const Duration(seconds: -10));
                          createControlTimer();
                        },                      
                        child: const Image(image: AssetImage(Assets.icBackward), width: 32, height: 32,)
                        
                      ),

                      const SizedBox(width: 32,),

                      SplashButton(      
                        splashColor: _splashColor,
                        borderRadius: BorderRadius.circular(60),                                          
                        onPressed: togglePlay,                      
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: _isPlaying != null ? Image(image: AssetImage(_isPlaying! ?  Assets.icPause : Assets.icPlayerPlay), width: 48, height: 48,) : null,
                        )                        
                      ),

                      const SizedBox(width: 32,),

                      SplashButton(      
                        splashColor: _splashColor,
                        borderRadius: BorderRadius.circular(40),                                          
                        onPressed: () {
                          releaseControlTimer();
                          forward(const Duration(seconds: 10));
                          createControlTimer();
                        },                      
                        child: const Image(image: AssetImage(Assets.icForward), width: 32, height: 32,)
                        
                      ),

                      const Spacer(),

                      _VerticalSeekBar(topIcon: Assets.icPlayerVolume, initialValue: _currentVolume, onStart: () {
                        _isChangingVolume = true;
                        releaseControlTimer();
                      }, onEnd: (volume) {                        
                        createControlTimer();
                        _isChangingVolume = false;
                      },  onUpdate: (volume) {  
                        _currentVolume = volume;
                        // widget.player.setVolume(volume);
                        VolumeController().setVolume(volume);                        
                      },),

                      const SizedBox(width: 24,),
                  ],
                )
                  
              ],
            );
  }
}

class _VerticalSeekBar extends StatefulWidget {
  final String topIcon;
  final double initialValue;
  final void Function()? onStart;
  final void Function(double)? onEnd;
  final void Function(double) onUpdate;

  const _VerticalSeekBar({required this.topIcon, required this.initialValue, required this.onUpdate, this.onStart, this.onEnd });

  @override
  State<StatefulWidget> createState() => _VerticalSeekBarState();
}

class _VerticalSeekBarState extends State<_VerticalSeekBar> {

  final double seekbarheight = 60;

  double get maxProgress => seekbarheight - 12;

  var _progress = 0.0 ;

  @override
  void didUpdateWidget(_VerticalSeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(widget.initialValue != oldWidget.initialValue) {
      setState(() {
        _progress = widget.initialValue * maxProgress;
      });
    }    
  }

  @override
  void initState() {
    _progress = widget.initialValue * maxProgress;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: (details) {
        widget.onStart?.call();
      },
      onVerticalDragUpdate: (details) async {
        final offset = details.delta;
        // final step = 0.01 * maxProgress;
        setState(() {
          _progress += -offset.dy ;// > 0 ? -step : step;
          if(_progress < 0) {
            _progress = 0;
          }
          if(_progress > maxProgress) {
            _progress = maxProgress;
          }
          widget.onUpdate(_progress / maxProgress);
        });        
      },
      onVerticalDragEnd: (details) {
        widget.onEnd?.call(_progress / maxProgress);
      },
      child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image(image: AssetImage(widget.topIcon), width: 24, height: 24,),

                  const SizedBox(height: 4,),

                  Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          color: const Color(0xFFD9D9D9).withOpacity(0.2),
                          width: 2,
                          height: seekbarheight,
                        ),

                       Container(
                          color: const Color(0xFFFAFAFA),
                          width: 2,
                          height: _progress,
                        ),

                        Transform.translate(
                          offset: Offset(0, -_progress),
                          child: Container(
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFFFAFAFA),),
                                    width: 12,
                                    height: 12,
                                  ),
                        )
                        
                      ],
                    ),
                ],
              )
            ),
    );
  }
  
}

class _AndroidPlayerView extends PlayerView {
  
  const _AndroidPlayerView({required super.player, super.onFullscreen });
  
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

class _IOSPlayerView extends PlayerView {
  const _IOSPlayerView({ required super.player, super.onFullscreen, });
  
  @override
  Widget get nativePlayerView =>
    UiKitView(
      viewType: viewType.name,
      layoutDirection: TextDirection.ltr,
      creationParams: player.paramsForPlayerView,
      creationParamsCodec: const StandardMessageCodec(),
    );
  
}