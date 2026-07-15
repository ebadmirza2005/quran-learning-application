import 'package:flutter/material.dart';

class TextButtonWidget extends StatelessWidget {
  final String buttonText;
  final VoidCallback? onTap;

  const TextButtonWidget({super.key, required this.buttonText, this.onTap,});

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onTap, child: Text(buttonText, style: TextStyle(
      color: Colors.black
    ),));
  }
}

class ElevatedButtonWidget extends StatelessWidget {
  final String buttonText;
  final Color? buttonColor;
  final Color? textColor;
  final FontWeight? textWeight;
  final VoidCallback? onTap;
  final bool isLoading;

  const ElevatedButtonWidget({super.key, required this.buttonText, this.buttonColor, this.textColor, this.textWeight, this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        height: 50,
        child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)
              )
            ),
            onPressed: onTap, child: isLoading ? CircularProgressIndicator(color: textColor,) : Text(buttonText, style: TextStyle(
          fontWeight: textWeight,
          color: textColor
        ),)));
  }
}

