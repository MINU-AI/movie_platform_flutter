
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:player/player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override
  State<StatefulWidget> createState() => _HomeState();

}

class _HomeState extends State<HomeScreen> {
  DrmPlayer? _player;

  final platform = MoviePlatform.disney;
  var _isLandscape = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth =  MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          
          SizedBox(
            width: screenWidth,
            height: _isLandscape ? screenHeight : 9 / 16 * screenWidth,
            child: _player != null ? PlayerView.create(player: _player!, showControl: true, showFullscreen: true, onFullscreen: (isLandscape) {
              setState(() {
                _isLandscape = isLandscape;
              });
            },) : null,
          ),

          _isLandscape ? const SizedBox() : GestureDetector(
                      onTap: () async {                      
                        final moviePayload = await showMoviePicker(context: context, platform: platform);
                        if(moviePayload != null) {
                          if(_player == null) {              
                            setState(() {
                              _player = DrmPlayer(payload: moviePayload, platform: platform);
                            });                                                    
                          } else {             
                            _player!.updatePlayer(payload: moviePayload, platform: platform);
                          }
                        }    
                        
                      },
                      child: const Text("Pick video"),          
                    ),          
       
        ],
      );
    }
}
