import 'package:flutter/material.dart';

class TextButtonWidget extends StatelessWidget {
  final String buttonText;
  const TextButtonWidget({super.key, required this.buttonText});

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: () {}, child: Text(buttonText, style: TextStyle(
      color: Colors.black
    ),));
  }
}

class ElevatedButtonWidget extends StatelessWidget {
  final String buttonText;
  const ElevatedButtonWidget({super.key, required this.buttonText});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: 50,
        child: ElevatedButton(onPressed: () {}, child: Text(buttonText, style: TextStyle(
          color: Colors.black
        ),)));
  }
}

