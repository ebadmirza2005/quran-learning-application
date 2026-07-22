import 'package:flutter/material.dart';

class AuthField extends StatefulWidget {
  final String authFieldText;
  final double fieldWidth;
  final Icon? authFieldIcon;
  final TextEditingController? controller;
  final bool isPassword;
  final String message;

  const AuthField({
    super.key,
    required this.authFieldText,
    this.fieldWidth = 0.85,
    this.authFieldIcon,
    this.controller,
    this.isPassword = false,
    this.message = "",
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * widget.fieldWidth,
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.isPassword ? _obscureText : false,
        decoration: InputDecoration(
          hintText: widget.authFieldText,
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(
              width: 2.0,
              color: Color(0xff0f766e),
            ),
          ),
          suffixIcon: widget.isPassword
              ? IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xff0f766e),
            ),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          )
              : widget.authFieldIcon,
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return "${widget.message} is required";
          return null;
        },
      ),
    );
  }
}