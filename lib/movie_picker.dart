import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'full_screen_modal_sheet.dart';
import 'movie_repository.dart';
import 'movie_web_view.dart';

abstract class MoviePickerView extends StatefulWidget {
  const MoviePickerView({super.key});
  
  factory MoviePickerView.createView(MoviePlatform platform, { bool doLoggingIn = false }){
    return MovieWebView.create(platform: platform, doLoggingIn: doLoggingIn,);
  }
}

Future<dynamic> showMoviePicker({ required BuildContext context, required MoviePlatform platform, bool doLoggingIn = false }) async {
  final pickerView = MoviePickerView.createView(platform, doLoggingIn: doLoggingIn,);
                        
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

  return value;
}