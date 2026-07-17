import 'package:flutter/material.dart';
import '../../utils/button.dart';
import '../../utils/text.dart';
import 'tutor_test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffd2dad2),
      appBar: AppBar(
        backgroundColor: const Color(0xff0f766e),
        foregroundColor: Colors.white,
        title: const Text("Classroom"),
        centerTitle: true,
        bottom: TabBar(
          controller: tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black,
          tabs: const [
            Tab(text: "My Students"),
            Tab(text: "Invites"),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: TextWidget(
                      text: "🔒 A small one-time fee is required to permanently unlock the test. If you fail, your fee is safe, and you can retake it for free after a 1-hour cooldown. A minimum score of 50% (8/15 correct answers) is required to verify your profile."
                    ),
                  ),
                  ElevatedButtonWidget(buttonText: "Pay & Take Test", buttonColor: Color(0xff0f766e), textColor: Colors.white, onTap: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TutorTestScreen()));
                  },),
                  SizedBox(height: 14),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: const [
                Center(child: Text("No Students Found!")),
                Center(child: Text("No Invitation Found!")),
              ],
            ),
          ),
        ],
      ),
    );
  }
}