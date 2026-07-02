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
          ),
      ),
    );
  }
}
