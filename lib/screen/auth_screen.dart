import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../utils/auth_field.dart';
import '../utils/button.dart';
import '../utils/text.dart';
import 'signup_auth_screen.dart';
import 'signup_tutor_screen.dart';

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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SignupAuthScreen()),
      );
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: Image.asset("assets/logo.png"),
              ),
              Form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: "Email",
                      textColor: Color(0xff0f766e),
                      textWeight: FontWeight(500),
                    ),
                    SizedBox(height: 7),
                    AuthField(authFieldText: "Email", ),
                    SizedBox(height: 20),
                    TextWidget(
                      text: "Password",
                      textColor: Color(0xff0f766e),
                      textWeight: FontWeight(500),
                    ),
                    SizedBox(height: 7),
                    AuthField(authFieldText: "Password"),
                    TextButtonWidget(buttonText: "Forgot Password?"),
                    ElevatedButtonWidget(
                      buttonText: "Login",
                      textColor: Color(0xff0f766e),
                      textWeight: FontWeight.bold,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "Don't have an account?",
                      style: TextStyle(color: Colors.black54),
                    ),
                    const WidgetSpan(child: SizedBox(width: 5)),
                    TextSpan(
                      text: "Signup",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xff0f766e),
                      ),
                      recognizer: _tapGestureRecognizer,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              TextWidget(
                text: "OR",
                textSize: 20.0,
                textColor: Color(0xff0f766e),
                textWeight: FontWeight.bold,
              ),
              SizedBox(height: 20),
              ElevatedButtonWidget(
                buttonText: "Sign up as Tutor",
                buttonColor: Color(0xff0f766e),
                textColor: Colors.white,
                textWeight: FontWeight.bold,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SignupTutorScreen())
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
