import 'dart:ui';

import 'package:flutter/cupertino.dart';

class LoadingView extends StatelessWidget {

  const LoadingView({super.key });

  
  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
                child: const CupertinoActivityIndicator(color: Color(0xFFFFFFFF), radius: 12,)
              )
          );
  }
}