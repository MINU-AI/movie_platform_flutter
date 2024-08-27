
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:player/player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override
  State<StatefulWidget> createState() => _HomeState();

}

class _HomeState extends State<HomeScreen> {
  DrmPlayer? _player;

  final movieList = [
    MoviePlayback(playbackUrl: "https://vod-akc-na-central-1.media.dssott.com/dvt1=exp=1724732116~url=%2Fgrn%2Fps01%2Fdisney%2F771b8483-3048-4a4c-adec-c659ae4b2f8b%2F~aid=f3a97c05-5882-48c6-b512-800c7cd73d58~did=b0fcde28-b4fc-4452-97d2-30018b4fe4db~kid=k01~hmac=0426c5ab20f26cb60eeb5306f1d35e9f6eda5ecd3c754496531dea20661cd6c7/grn/ps01/disney/771b8483-3048-4a4c-adec-c659ae4b2f8b/ctr-all-a26595c4-4cd0-4451-849d-99694fc2b867-a73b8771-a714-4530-a24d-b6dc7df7fcf0.m3u8?v=1&hash=38b6ad538f185012f126b566206ea1759de6fab9", licenseKeyUrl: "https://disney.playback.edge.bamgrid.com/widevine/v1/obtain-license", licenseCertificateUrl: "https://playback-certs.bamgrid.com/static/v1.0/widevine.bin"),
    MoviePlayback(playbackUrl: "https://vod-akc-na-east-1.media.dssott.com/dvt1=exp=1724732385~url=%2Fps01%2Fdisney%2F8f262fdd-5850-46cb-9a93-5217e0dbd0c8%2F~aid=f3a97c05-5882-48c6-b512-800c7cd73d58~did=b0fcde28-b4fc-4452-97d2-30018b4fe4db~kid=k01~hmac=7c1eebab34e6fd766b86b7c1c3d5943b4481631815330d6bc6fe452dbce2dff3/ps01/disney/8f262fdd-5850-46cb-9a93-5217e0dbd0c8/ctr-all-b529f023-84bc-4d8d-9281-17228e038781-f0fd9dcd-bdb6-49b7-b723-e3614efeac68.m3u8?a=3&v=1&hash=5db04df3a9a939a6c0610b41e04fca56eed9b533", licenseKeyUrl: "https://disney.playback.edge.bamgrid.com/widevine/v1/obtain-license", licenseCertificateUrl: "https://playback-certs.bamgrid.com/static/v1.0/widevine.bin")
  ];
  var _currentMovieIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth =  MediaQuery.of(context).size.width;

    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          SizedBox(
            width: screenWidth,
            height: 9 / 16 * screenWidth,
            child: _player?.widgetPlayer,
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  _player?.play();
                },
                child: const Text("Play"),
              ),

              const SizedBox(width: 8,),

              TextButton(
                onPressed: () {
                  _player?.pause();
                },
                child: const Text("Pause"),
              ),

              const SizedBox(width: 8,),

              TextButton(
                onPressed: () {
                  _player?.stop();
                },
                child: const Text("Stop"),
              ),

            ],
          ),

          GestureDetector(
          onTap: () {
            final pickerView = MoviePickerView.createView(MoviePlatformType.disney);

            Navigator.of(context).push(CupertinoPageRoute(builder: (_) => pickerView)).then(
              (value) async {           
                  final moviePlayback = value as MoviePlayback?;                  
                  if(moviePlayback != null) {
                    final accessToken = await dataCacheManager.get(CacheDataKey.disney_video_access_token);
                    if(_player == null) {              
                      setState(() {
                        _player = DrmPlayer.creatPlayer(moviePlayback: moviePlayback, platform: MoviePlatformType.disney, authorizeToken: accessToken);
                      });                                                    
                    } else {             
                      _player!.updatePlayer(moviePlayback: moviePlayback, platform: MoviePlatformType.disney, authorizeToken: accessToken);
                      const MethodChannel(platformChannel).invokeMethod(NativeMethodCall.controlPlayer.name, {"action" : PlayerControlAction.changePlayback.name, "value" : _player!.paramsForPlayerView});
                    }
                  }                       
              }
            );
          },
          child: const Text("Pick video"),          
        ),

        // GestureDetector(
        //   onTap: () async {
        //     final moviePlayback = movieList[(_currentMovieIndex++) % 2];
        //     final accessToken = await dataCacheManager.get(CacheDataKey.disney_video_access_token);

        //     if(_player == null) {              
        //       setState(() {
        //         _player = DrmPlayer.creatPlayer(moviePlayback: moviePlayback, platform: MoviePlatformType.disney, authorizeToken: accessToken);
        //       });                                                    
        //     } else {              
        //       final player = DrmPlayer.creatPlayer(moviePlayback: moviePlayback, platform: MoviePlatformType.disney, authorizeToken: accessToken);  
        //       const MethodChannel(platformChannel).invokeMethod(NativeMethodCall.controlPlayer.name, {"action" : PlayerControlAction.changePlayback.name, "value" : player.paramsForPlayerView});
        //     }
        //   },
        //   child: Text("Change video"),
        // )
        ],
      );
    }
}
