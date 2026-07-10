import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_screen.dart';
import 'signup_student_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final supabase = Supabase.instance.client;

  StreamSubscription? _deleteListener;
  @override
  initState() {
    super.initState();
    _startDeleteListener();
  }

  void _startDeleteListener() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    _deleteListener = supabase
    .from('students')
    .stream(primaryKey: ['id'])
    .listen((List<Map<String, dynamic>> allStudents) async {
      final userExists = allStudents.any((student) => student['id'] == user.id);

      if (!userExists) {
        _deleteListener?.cancel();
        await supabase.auth.signOut();

        if(!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthScreen()),
              (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("Your account has been deleted or disabled!"),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Home Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );

            }
          )
        ]
      )
    );
  }
}
