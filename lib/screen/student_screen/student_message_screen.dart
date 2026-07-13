import 'package:flutter/material.dart';

class StudentMessageScreen extends StatefulWidget {
  const StudentMessageScreen({super.key});

  @override
  State<StudentMessageScreen> createState() => _StudentMessageScreenState();
}

class _StudentMessageScreenState extends State<StudentMessageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff0f766e),
        foregroundColor: Colors.white,
        title: Text("Messages"),
        centerTitle: true,
      ),
      body: Center(
        child: Text("No Conversation Found!"),
      ),
    );
  }
}
