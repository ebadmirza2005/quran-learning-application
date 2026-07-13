import 'dart:async';
import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';
import 'student_screen/student_home_screen.dart';
import 'student_screen/student_message_screen.dart';
import 'student_screen/student_setting_screen.dart';
import 'student_screen/tutor_list_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final _drawerController = ZoomDrawerController();
  int index = 0;
  final supabase = Supabase.instance.client;
  StreamSubscription? _deleteListener;

  @override
  void initState() {
    super.initState();
    _startDeleteListener();
  }

  void _startDeleteListener() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    _deleteListener = supabase
        .from('students')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .listen((List<Map<String, dynamic>> studentData) async {

      if (studentData.isEmpty) {
        _deleteListener?.cancel();
        await supabase.auth.signOut();

        if (!mounted) return;

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
    });
  }

  @override
  void dispose() {
    _deleteListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ZoomDrawer(
      controller: _drawerController,
      menuScreenWidth: 200,
      menuScreen: const StudentSettingScreen(),
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
        return const TutorListScreen();
      case 2:
        return const StudentMessageScreen();
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
          title: const Center(child: Text('Tutors')),
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
          title: const Center(child: Text('Menu')),
          activeColor: const Color(0xff0f766e),
          inactiveColor: inactiveColor,
        ),
      ],
    );
  }
}