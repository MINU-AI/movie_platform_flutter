import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Stack(
            alignment: AlignmentDirectional.center,
            children: [
              Container(color: const Color(0x60000000),),
              // const CupertinoActivityIndicator(color: AppColors.indicatorColor, radius: 12,)
              const Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoActivityIndicator(color: Colors.white,),

                    SizedBox(height: 8,),

                    Text("Loading...", style: TextStyle(color: Colors.white, fontSize: 14, decoration: TextDecoration.none),),
                  ],
                ),
            ],
          );
  }
}