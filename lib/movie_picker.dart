import 'package:flutter/widgets.dart';

import 'movie_platform_api.dart';
import 'movie_web_view.dart';

abstract class MoviePickerView extends StatefulWidget {
  const MoviePickerView({super.key});
  
  factory MoviePickerView.createView(MoviePlatform platformId){
    return MovieWebView.create(platform: platformId);
  }
}