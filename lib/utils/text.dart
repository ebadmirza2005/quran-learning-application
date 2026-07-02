import 'package:flutter/material.dart';

class TextWidget extends StatelessWidget {
  final String text;
  final double? textSize;
  final Color? textColor;
  final FontWeight? textWeight;
  const TextWidget({super.key, required this.text, this.textSize, this.textColor, this.textWeight});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(
      fontSize: textSize,
      fontWeight: textWeight,
      color: textColor
    ),);
  }
}
