import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart'; // Naya import
import 'package:quran_learning_application/screen/teacher_screen/home_screen.dart';

import 'teacher_screen/message_screen.dart';
import 'teacher_screen/setting_screen.dart'; // Ye ab aap ka drawer content banega
import 'teacher_screen/students_screen.dart';

class TutorHomeScreen extends StatefulWidget {
  const TutorHomeScreen({super.key});

  @override
  State<TutorHomeScreen> createState() => _TutorHomeScreenState();
}

class _TutorHomeScreenState extends State<TutorHomeScreen> {
  final _drawerController = ZoomDrawerController();
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return ZoomDrawer(
      controller: _drawerController,
      menuScreenWidth: 200,
      menuScreen: const SettingScreen(),
      mainScreen: Scaffold(
        backgroundColor: const Color(0xffd2dad2),
        body: buildPages(),
        bottomNavigationBar: buildBottomNavigation(),
      ),
      borderRadius: 24.0,
      showShadow: true,
      angle: -12.0,
      drawerShadowsBackgroundColor: Colors.grey.shade300,
      slideWidth: MediaQuery.of(context).size.width * 0.65,
    );
  }

  Widget buildPages() {
    switch (index) {
      case 1:
        return const StudentsScreen();
      case 2:
        return const MessageScreen();
      case 0:
      default:
        return const HomeScreen();
    }
  }

  Widget buildBottomNavigation() {
    final inactiveColor = Colors.grey;
    return BottomNavyBar(
      backgroundColor: const Color(0xffd2dad2),
      selectedIndex: index,
      onItemSelected: (newIndex) {
        if (newIndex == 3) {
          _drawerController.toggle?.call();
        } else {
          setState(() => index = newIndex);
        }
      },
      items: <BottomNavyBarItem>[
        BottomNavyBarItem(
          icon: const Icon(Icons.apps),
          title: const Center(child: Text('Home')),
          activeColor: const Color(0xff0f766e),
          inactiveColor: inactiveColor,
        ),
        BottomNavyBarItem(
          icon: const Icon(Icons.people),
          title: const Center(child: Text('Students')),
          activeColor: const Color(0xff0f766e),
          inactiveColor: inactiveColor,
        ),
        BottomNavyBarItem(
          icon: const Icon(Icons.message),
          title: const Center(child: Text('Messages')),
          activeColor: const Color(0xff0f766e),
          inactiveColor: inactiveColor,
        ),
        BottomNavyBarItem(
          icon: const Icon(Icons.settings),
          title: const Center(child: Text('Settings')),
          activeColor: const Color(0xff0f766e),
          inactiveColor: inactiveColor,
        ),
      ],
    );
  }
}