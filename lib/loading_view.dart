import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  final Color backgroundColor;

  const LoadingView({super.key, this.backgroundColor =  const Color(0x60000000) });

  
  @override
  Widget build(BuildContext context) {
    return Stack(
            alignment: AlignmentDirectional.center,
            children: [
              Container(color: backgroundColor,),
              // const CupertinoActivityIndicator(color: AppColors.indicatorColor, radius: 12,)
              Container(
                width: 120,
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(12)),
                child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CupertinoActivityIndicator(color: Colors.black,),

                          SizedBox(height: 12,),

                          Text("Loading...", style: TextStyle(color: Colors.black, fontSize: 14, decoration: TextDecoration.none),),
                        ],
                      ),
              )
            ],
          );
  }
}