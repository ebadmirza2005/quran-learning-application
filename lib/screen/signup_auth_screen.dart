import 'package:flutter/material.dart';

import '../utils/auth_field.dart';
import '../utils/button.dart';
import '../utils/text.dart';
import 'tutor_home_screen.dart';

class SignupAuthScreen extends StatefulWidget {
  const SignupAuthScreen({super.key});

  @override
  State<SignupAuthScreen> createState() => _SignupAuthScreenState();
}

class _SignupAuthScreenState extends State<SignupAuthScreen> {
  bool _isAgree = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffd2dad2),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 10,),
            SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: Image.asset("assets/logo.png")),
            AuthField(authFieldText: "Name",),
            SizedBox(height: 10,),
            AuthField(authFieldText: "Email",),
            SizedBox(height: 10,),
            AuthField(authFieldText: "Password",),
            SizedBox(height: 10,),
            AuthField(authFieldText: "Re-Type Password",),
            SizedBox(height: 10,),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  activeColor: const Color(0xff0f766e),
                  value: _isAgree,
                  onChanged: (bool? value) {
                    setState(() {
                      _isAgree = value!;
                    });
                  },
                ),
                TextWidget(
                  text: "By signing up, you agree to our ",
                ),
                TextWidget(text: "terms of use", textColor: Color(0xff0f766e)),
              ],
            ),
            SizedBox(height: 20,),
            ElevatedButtonWidget(buttonText: "Sign Up", onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TutorHomeScreen()));
            }, buttonColor: Color(0xff0f766e), textColor: Colors.white,),
          ],
        ),
      ),
    );
  }
}
