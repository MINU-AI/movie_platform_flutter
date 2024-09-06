import 'package:flutter/material.dart';

class SplashButton extends StatelessWidget {
  final Color? backgroundColor;
  final void Function()? onPressed;
  final Color? splashColor;
  final Widget child;
  final BorderRadius? borderRadius;

  const SplashButton({super.key, this.onPressed, this.backgroundColor, this.borderRadius, this.splashColor, required this.child });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: borderRadius,
      color: backgroundColor ?? Colors.transparent,
      child: InkWell(
        splashColor: splashColor,
        borderRadius: borderRadius,
        onTap: onPressed,
        child: child,
      ),    
    );
  }
  
}