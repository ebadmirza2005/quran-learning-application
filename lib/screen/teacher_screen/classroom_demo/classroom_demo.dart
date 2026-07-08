import 'package:flutter/material.dart';
import 'qaida_index_tab.dart'; // 🔥 Is file ke andar ab QaidaIndexTab aur QaidaDetailScreen dono maujood hain
import 'quran_index_tab.dart';
import 'whiteboard_tab.dart';

class ClassroomDemo extends StatefulWidget {
  const ClassroomDemo({super.key});

  @override
  State<ClassroomDemo> createState() => _ClassroomDemoState();
}

class _ClassroomDemoState extends State<ClassroomDemo> with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0f766e),
        foregroundColor: Colors.white,
        title: const Text("Classroom Demo"),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.exit_to_app)),
        ],
        bottom: TabBar(
          controller: tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black,
          tabs: const [
            Tab(text: "Quran"),
            Tab(text: "Qaida"),
            Tab(text: "Whiteboard"),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: const [
          QuranIndexTab(),
          QaidaIndexTab(),
          WhiteboardTab(),
        ],
      ),
    );
  }
}