
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:player/full_screen_modal_sheet.dart';
import 'package:player/player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override
  State<StatefulWidget> createState() => _HomeState();

}

class _HomeState extends State<HomeScreen> {
  DrmPlayer? _player;

  final platform = MoviePlatform.youtube;
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
            child: _player != null ? PlayerView.create(player: _player!, showFullscreen: false, onFullscreen: (isLandscape) {
              setState(() {
                _isLandscape = isLandscape;
              });
            },) : null,
          ),

          _isLandscape ? const SizedBox() : GestureDetector(
                      onTap: () async {
                        final pickerView = MoviePickerView.createView(platform);
                        
                        final value = await showFullScreenModalBottomSheet(
                          useSafeArea: true,
                          showDragHandle: true,
                          barrierColor: Colors.grey,                          
                          dragHandleColor: const Color(0xFF666666),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          context: context, 
                          builder: (_) {
                            return pickerView;
                          }
                        );    
                        final moviePayload = value as MoviePayload?;                  
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
                    )
       
        ],
      );
    }
}
