import 'package:flutter/cupertino.dart';
import 'package:player/player.dart';

import 'home_screen.dart';


enum RouteNames {
  home,
  disney_web_view;

  static RouteNames fromName(String? name) {
    if (name == home.name) {
      return home;
    } else if(name == RouteNames.disney_web_view.name) {
      return RouteNames.disney_web_view;
    } else {
      throw "Unsupported route name: $name";
    }
  }
  
}

Route<dynamic> generateRoute(RouteSettings settings) {
  final name = RouteNames.fromName(settings.name);
  switch (name) {
    case RouteNames.home:
      return CupertinoPageRoute(builder: (_) => const HomeScreen());
    case RouteNames.disney_web_view:
      return CupertinoPageRoute(builder: (_) => MoviePickerView.createView(MoviePlatform.disney));  
  }
}