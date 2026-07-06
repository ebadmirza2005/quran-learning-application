import 'package:flutter/material.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
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
