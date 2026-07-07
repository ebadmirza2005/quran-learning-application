import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quran_learning_application/screen/tutor_home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    _navigateToNextScreen();
  }

  void _startLogoTimer() async {
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _logoOpacity = 1.0;
      });
    }
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 5));

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TutorHomeScreen()));
    }else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
    }

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
