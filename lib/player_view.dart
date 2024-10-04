// ignore_for_file: invalid_use_of_protected_member

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
  final bool showControl;
  final bool playWhenReady;
  final bool showLoading;
  final void Function(int)? onForward;
  final void Function(bool)? onTogglePlaying;
  final void Function(bool)? onFullscreen;
  final void Function(Duration)? onTimeChanged;
  final void Function(Duration)? onSeek;

  const PlayerView({super.key, required this.player, 
                    this.showFullScreen = true, 
                    this.showControl = true, 
                    this.playWhenReady = true, 
                    this.showLoading = true,
                    this.onFullscreen, this.onForward, 
                    this.onTogglePlaying, 
                    this.onTimeChanged, 
                    this.onSeek });

  Widget get nativePlayerView;

  factory PlayerView.create({required DrmPlayer player, 
          bool showFullscreen = true, 
          bool showControl = true, 
          bool playWhenReady = true,
          bool showLoading = true,
          void Function(bool)? onFullscreen,
          void Function(int)? onForward, 
          void Function(bool)? onTogglePlaying,
          void Function(Duration)? onTimeChanged, 
          void Function(Duration)? onSeek }) 
  {
    if(Platform.isAndroid) {
      return _AndroidPlayerView(player: player, showFullScreen: showFullscreen, 
                                showControl: showControl, showLoading: showLoading, playWhenReady: playWhenReady, 
                                onFullscreen: onFullscreen, onForward: onForward, 
                                onTogglePlaying: onTogglePlaying, onTimeChanged: onTimeChanged, 
                                onSeek: onSeek,
                              );
    }

    if(Platform.isIOS) {
      return _IOSPlayerView(player: player, showFullScreen: showFullscreen, 
                            showControl: showControl, showLoading: showLoading, playWhenReady: playWhenReady, 
                            onFullscreen: onFullscreen, onForward: onForward, 
                            onTogglePlaying: onTogglePlaying, onTimeChanged: onTimeChanged, 
                            onSeek: onSeek, );
    }
    throw "Unimplemented for this platform";
  }

  @override
  State<StatefulWidget> createState() => _PlayerViewState();

}

class _PlayerViewState extends State<PlayerView> with PlayerListener, TickerProviderStateMixin, WidgetsBindingObserver {
  var _showPlayerLoading = true;
  var _progressWidth = 0.0;
  var _progressBufferWidth = 0.0;
  int? _bufferedPercentage;
  bool? _isPlaying;
  Timer? _updatePlayerTimer;
  Timer? _hideControllTimer;
  bool? _isSeeking;
  AnimationController? _animationController;
  Animation<double>? _animation;

  final _animationDuration = 500;
  final _splashColor = const Color(0xFF353641).withOpacity(0.6);
  int? _duration;
  int? _currentPosition;
  var _currentVolume = 0.0;
  var _showControl = false;
  var _isLanscape = false;
  var _isChangingVolume = false;
  double? _currentBrightness;
  var _playToEnd = false;

  double get seekBarWidth => MediaQuery.of(context).size.width;

  double get progressMaxWidth => seekBarWidth - 12;

  @override
  void initState() {
    _showPlayerLoading = widget.showLoading;
    widget.player.addListener(this);    
    initVolumeController();    
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      DeviceOrientation.portraitUp
    ]);

    super.dispose();
  }

  @override
  void didChangeMetrics() {    
    super.didChangeMetrics();
    if(!mounted) {
      return;
    }
    if(_currentPosition == null || _duration == null || _bufferedPercentage == null) {
      return;
    }        
    setState(() {
      _progressWidth = (_currentPosition! / _duration!) * progressMaxWidth;
      _progressBufferWidth = (_bufferedPercentage! / 100.0) * seekBarWidth;  
    });    
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
    _playToEnd = state == PlayerState.end;

    if(_playToEnd) {
      releaseUpdatePlayerTimer();
      _currentPosition = _duration;  
      _progressWidth = progressMaxWidth;
    }    
    _showPlayerLoading = widget.showLoading && state == PlayerState.bufferring;
    
    setState(() {      
    });    
  }
  
  @override
  void onPlayerError(PlayerError error) {
    setState(() {
      _showPlayerLoading = false;  
      showAlertDialog(title: "Cannot play the movie", content: "${error.errorCodeName} - ${error.message}");
    }); 
    _playToEnd = false;
  }
  
  @override
  void onPlayingChange(bool isPlaying) {    
    _isPlaying = isPlaying;
    if(!widget.playWhenReady) {
      _showPlayerLoading = false;
    }
    if(_currentBrightness == null) {
      initBrightness();
    }
    if(isPlaying && _isSeeking != true){            
      createUpdatePlayerTimer(); 
    }    
  }

}

extension on _PlayerViewState {
  Future<void> updateVideoProgerss() async {    
    final currentPosition = await widget.player.currentPosition;      
      final duration = await widget.player.duration;
      _bufferedPercentage = await widget.player.bufferedPercentage;
      if(currentPosition == null || duration == null || _bufferedPercentage == null) {
        return;
      }
      // logger.i("Got currentPosition: $currentPosition, $bufferedPercentage");
      widget.onTimeChanged?.call(Duration(milliseconds: currentPosition));
      final newBufferWidth = (_bufferedPercentage! / 100.0) * seekBarWidth;
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
  }
  void createUpdatePlayerTimer() {
    _updatePlayerTimer?.cancel();
    updateVideoProgerss();
    _updatePlayerTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
      await updateVideoProgerss();      
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
    currentPosition = currentPosition + step.inMilliseconds;
    logger.i("Got seek position: $currentPosition");
    widget.player.seek(Duration(milliseconds: currentPosition));    
    widget.onForward?.call(step.inSeconds);
  }

  void togglePlay() async {
    if(_isPlaying == null) {
      return;
    }
    releaseControlTimer();
    if(await widget.player.isFinished || _playToEnd == true) {
      widget.player.seek(Duration.zero);
      _playToEnd = false;
    }
    if(_isPlaying!) {
      widget.player.pause();
    } else {
      widget.player.play();
    }
    widget.onTogglePlaying?.call(!_isPlaying!);
    createControlTimer();
  }

  void updateSeekbarProgress(Offset offset) async {
    _progressWidth += offset.dx;
    
    setState(() {
      if(_progressWidth < 0) {
        _progressWidth = 0;
      } else if (_progressWidth > progressMaxWidth) {
        _progressWidth = progressMaxWidth;
      }
    });    
  }

  Future<Duration?> updatePlayerPosition() async {
    final duration = await widget.player.duration;
    if(duration == null) {
      return null;
    }
    final newPosition = (_progressWidth / progressMaxWidth) * duration;
    // logger.i("Got new position: $newPosition, ${newPosition.round()}");
    final seekDuration = Duration(microseconds: (newPosition * 1000).toInt());
    widget.player.seek(seekDuration);
    return seekDuration;
  }

  void onControlsTapped() {
    // logger.i("Got tapp on player");

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
    final orientation = _isLanscape ? DeviceOrientation.landscapeLeft : DeviceOrientation.portraitUp;
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
    _currentBrightness = await widget.player.brightness ?? 0;  
    logger.i("Got brightness: $_currentBrightness");
    setState(() {      
    },);    
  }
}

extension on _PlayerViewState {
  Widget get playerControlsView {
    final playerIsReady = _isPlaying != null; 
    final canSeekPlayer = widget.showControl;   

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
                    child: ConstrainedBox(constraints: BoxConstraints(maxHeight: seekBarWidth - 32), child: TextView(text: widget.player.payload.info!.title, maxLines: 1, fontSize: 14,)),
                  ) : const SizedBox(),

                  _currentPosition != null && _duration != null ? 
                    Positioned(
                      bottom: widget.showFullScreen ? 50 : 30,
                      left: 4,
                      child: TextView(text: "${_currentPosition!.toTimeDisplay()} / ${_duration!.toTimeDisplay()}", fontSize: 10,)
                    ): const SizedBox(),

                playerIsReady ? Positioned(
                  bottom: widget.showFullScreen ? 28 : 8,
                  child: GestureDetector(
                      onHorizontalDragStart: (details) {
                        if(!canSeekPlayer) {
                          return;
                        }
                        _isSeeking = true;
                        _playToEnd = false;
                        releaseControlTimer();
                        releaseUpdatePlayerTimer();
                      },
                      onHorizontalDragUpdate: (details) {
                        if(!canSeekPlayer) {
                          return;
                        }
                        logger.i("onHorizontalDragUpdate: ${details.delta.dx}"); 
                        updateSeekbarProgress(details.delta);
                      },
                      onHorizontalDragEnd: (details) async {
                        if(!canSeekPlayer) {
                          return;
                        }
                        logger.i("onHorizontalDragEnd: $details");
                        final duration = await updatePlayerPosition();
                        _isSeeking = false;   
                        createControlTimer();
                        if(duration != null) {
                          widget.onSeek?.call(duration);
                        }
                      },
                      child: Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  Container(
                                      width: seekBarWidth,
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
                ) : const SizedBox(),

                widget.showFullScreen ? Positioned(
                  right: 4,
                  bottom: 0,
                  child: SplashButton(      
                      splashColor: _splashColor,
                      borderRadius: BorderRadius.circular(32),                                          
                      onPressed: onFullscreenTapped,                      
                      child: const Padding(padding: EdgeInsets.all(8), child: Image(image: AssetImage(Assets.icFullscreen), width: 24, height: 24,),)
                      
                    )) : const SizedBox(height: 0,),     

                playerIsReady && widget.showControl ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                      const SizedBox(width: 24,),

                      _VerticalSeekBar(topIcon: Assets.icPlayerBrightness, initialValue: _currentBrightness ?? 0, onStart: releaseControlTimer, onEnd: (value) => createControlTimer, onUpdate: (value) {
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
                          child: playerIsReady ? Image(image: AssetImage(_isPlaying! ?  Assets.icPause : Assets.icPlayerPlay), width: 48, height: 48,) : null,
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
                ) : const SizedBox()
                  
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
  
  const _AndroidPlayerView({required super.player, super.showFullScreen, super.showControl, super.showLoading, super.playWhenReady, super.onFullscreen, super.onForward, super.onTogglePlaying, super.onTimeChanged, super.onSeek });
  
  @override
  Widget get nativePlayerView {
    var params = player.paramsForPlayerView;
    params["playWhenReady"] = playWhenReady;

    return AndroidView(
      viewType: viewType.name,
      layoutDirection: TextDirection.ltr,
      creationParams: params,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
  
}

class _IOSPlayerView extends PlayerView {
  const _IOSPlayerView({ required super.player, super.showFullScreen, super.showControl, super.showLoading, super.playWhenReady, super.onFullscreen, super.onForward, super.onTogglePlaying, super.onTimeChanged, super.onSeek });
  
  @override
  Widget get nativePlayerView {
    var params = player.paramsForPlayerView;
    params["playWhenReady"] = playWhenReady;

    return UiKitView(
      viewType: viewType.name,
      layoutDirection: TextDirection.ltr,
      creationParams: params,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
  
}