import 'package:flutter/widgets.dart';

class TextView extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  final FontWeight? fontWeight;
  final int? maxLines;

  const TextView({super.key, required this.text, this.color = const Color(0xFFFFFFFF), this.fontSize = 14, this.fontWeight, this.maxLines });

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(fontFamily: "OpenSans", color: color, fontSize: fontSize, fontWeight: fontWeight, decoration: TextDecoration.none), maxLines: maxLines, overflow: maxLines != null ? TextOverflow.ellipsis : null,);
  }
  
}