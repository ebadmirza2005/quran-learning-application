import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quran_learning_application/screen/tutor_home_screen.dart';
import 'package:quran_learning_application/screen/student_home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _logoOpacity = 0.0;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _startLogoTimer();
    _navigateToNextScreen();
  }

  void _startLogoTimer() async {
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _logoOpacity = 1.0;
      });
    }
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    final session = supabase.auth.currentSession;

    if (session == null || session.user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      return;
    }

    final userId = session.user!.id;

    try {
      final tutorData = await supabase
          .from('tutors')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (!mounted) return;

      if (tutorData != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TutorHomeScreen()),
        );
        return;
      }

      final studentData = await supabase
          .from('students')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (!mounted) return;

      if (studentData != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
        );
        return;
      }

      await supabase.auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );

    } catch (e) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffd2dad2),
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