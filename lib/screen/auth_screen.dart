import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../utils/auth_field.dart';
import '../utils/button.dart';
import '../utils/text.dart';
import 'signup_auth_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late TapGestureRecognizer _tapGestureRecognizer;

  @override
  void initState() {
    super.initState();
    _tapGestureRecognizer = TapGestureRecognizer();
    _tapGestureRecognizer.onTap = () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SignupAuthScreen()));
    };

  }

  @override
  void dispose() {
    super.dispose();
    _tapGestureRecognizer.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffd2dad2),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: Image.asset("assets/logo.png")),
            Form(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(text: "Email",),
                  AuthField(authFieldText: "Email",),
                  SizedBox(height: 20,),
                  TextWidget(text: "Password"),
                  AuthField(authFieldText: "Password",),
                  TextButtonWidget(buttonText: "Forgot Password?",),
                  ElevatedButtonWidget(buttonText: "Login",),
                  RichText(text: TextSpan(
                    children: [
                      TextSpan(text: "Don't have an account?"),
                      TextSpan(text: "Signup", recognizer: _tapGestureRecognizer)

                    ]
                  ))
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
