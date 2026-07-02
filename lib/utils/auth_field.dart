import 'package:flutter/material.dart';

class AuthField extends StatelessWidget {
  final String authFieldText;
  const AuthField({super.key, required this.authFieldText});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: TextFormField(
          decoration: InputDecoration(
            hintText: "Enter Your $authFieldText",
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                width: 2.0,
                color: Color(0xff0f766e)
              )
            )
          ),
      ),
    );
  }
}
