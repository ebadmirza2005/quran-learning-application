import 'dart:async';
import 'package:flutter/material.dart';
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _logoOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _startLogoTimer();
    _splashToLogin();
  }

  void _startLogoTimer() async {
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _logoOpacity = 1.0;
      });
    }
  }

  void _splashToLogin() {
    Timer(Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AuthScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffd2dad2),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: AnimatedOpacity(
            opacity: _logoOpacity,
            duration: const Duration(milliseconds: 800),
            child: Image.asset("assets/logo.png"),
          ),
        ),
      ),
    );
  }
}
