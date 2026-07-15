import 'dart:async';

import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:quran_learning_application/screen/teacher_screen/tutor_home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_screen.dart';
import 'teacher_screen/tutor_message_screen.dart';
import 'teacher_screen/tutor_setting_screen.dart';
import 'teacher_screen/students_list_screen.dart';

class TutorHomeScreen extends StatefulWidget {
  const TutorHomeScreen({super.key});

  @override
  State<TutorHomeScreen> createState() => _TutorHomeScreenState();
}

class _TutorHomeScreenState extends State<TutorHomeScreen> {
  final _drawerController = ZoomDrawerController();
  int index = 0;
  final supabase = Supabase.instance.client;
  StreamSubscription? _deleteListener;
  late final String _currentUserId;

  DateTime? _lastClearedMessageTime;

  @override
  void initState() {
    super.initState();
    _currentUserId = supabase.auth.currentUser?.id ?? '';
    _startDeleteListener();
  }

  void _startDeleteListener() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    _deleteListener = supabase
        .from('tutors')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> allTutors) async {

      final userExists = allTutors.any((tutor) => tutor['id'] == user.id);

      if (!userExists) {
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
      menuScreenWidth: 210,
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
          setState(() {
            index = newIndex;
            if (index == 2) {
              _lastClearedMessageTime = DateTime.now().toUtc();
            }
          });
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
          icon: StreamBuilder<List<Map<String, dynamic>>>(
            stream: supabase.from('messages').stream(primaryKey: ['id']),
            builder: (context, snapshot) {
              final allMessages = snapshot.data ?? [];

              final unreadMessages = allMessages.where((msg) {
                final isMyUnread = msg['receiver_id'] == _currentUserId && msg['is_read'] == false;
                if (!isMyUnread) return false;
                if (_lastClearedMessageTime != null) {
                  final msgCreatedAt = DateTime.tryParse(msg['created_at'] ?? '')?.toUtc() ?? DateTime.now().toUtc();
                  return msgCreatedAt.isAfter(_lastClearedMessageTime!);
                }

                return true;
              }).toList();

              final uniqueSenders = unreadMessages.map((msg) => msg['sender_id'] as String).toSet();
              final int peopleCount = uniqueSenders.length;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.message),
                  if (peopleCount > 0 && index != 2)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          "$peopleCount",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
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