import 'package:flutter/material.dart';

class AuthField extends StatelessWidget {
  final String authFieldText;
  final double fieldWidth;
  final Icon? authFieldIcon;
  const AuthField({super.key, required this.authFieldText, this.fieldWidth = 0.85, this.authFieldIcon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * fieldWidth,
      child: TextFormField(
          decoration: InputDecoration(
            hintText: authFieldText,
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                width: 2.0,
                color: Color(0xff0f766e)
              )
            ),
              suffixIcon: authFieldIcon
          ),
      ),
    );
  }
}
