import 'package:flutter/material.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff0f766e),
        foregroundColor: Colors.white,
        title: Text("Students"),
        centerTitle: true,
      ),
      body: Center(
        child: Text("No Students Available!"),
      ),
    );
  }
}
