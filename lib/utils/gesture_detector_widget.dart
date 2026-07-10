import 'package:flutter/material.dart';
import 'text.dart';

class GestureDetectorWidget extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const GestureDetectorWidget({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
          width: MediaQuery.of(context).size.width * 0.25,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Color(0xff0f766e),
          ),
          height: 50,
          child: Center(
              child: TextWidget(
                text: text,
                textSize: 18,
                textColor: Colors.white,
              )
          )
      ),
    );
  }
}
