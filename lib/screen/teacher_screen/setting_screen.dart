import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/button.dart';
import '../../utils/text.dart';
import '../auth_screen.dart';
import 'tutor_personal_info.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final supabase = Supabase.instance.client;
  String tutorName = "Loading...";

  @override
  void initState() {
    super.initState();
    getTutorProfile();
  }

  Future<void> getTutorProfile() async {
    try {
      final user = supabase.auth.currentUser;

      if (user != null) {
        final data = await supabase
            .from('tutors')
            .select('name')
            .eq('id', user.id)
            .maybeSingle();

        if (!mounted) return;

        setState(() {
          if (data != null) {
            tutorName = data['name'] ?? "No Name Found";
          } else {
            tutorName = "Profile Not Found";
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        tutorName = "Error Loading Name";
      });
      print("Fetch Error: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final _height = MediaQuery.of(context).size.height;
    return Material(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Align(
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Color(0xff0f766e),
                        ),
                        Icon(
                          Icons.photo,
                          color: Colors.white,
                          size: 30,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10,),
                    TextWidget(
                      text: tutorName,
                    ),
                  ],
                ),

                SizedBox(height: _height * 0.1,),
                Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, color: Color(0xff0f766e),),
                        TextButtonWidget(buttonText: "Personal Info", onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => TutorPersonalInfo()));
                        },
                        )
                      ],
                    ),
                    const SizedBox(height: 10,),
                    const Row(
                      children: [
                        Icon(Icons.edit_square, color: Color(0xff0f766e),),
                        TextButtonWidget(buttonText: "Edit Info",)
                      ],
                    ),
                    const SizedBox(height: 10,),
                    const Row(
                      children: [
                        Icon(Icons.location_on, color: Color(0xff0f766e),),
                        TextButtonWidget(buttonText: "Location",)
                      ],
                    ),
                    const SizedBox(height: 10,),
                    const Row(
                      children: [
                        Icon(Icons.lock, color: Color(0xff0f766e),),
                        TextButtonWidget(buttonText: "Change Password",)
                      ],
                    ),
                    const SizedBox(height: 10,),
                    const Row(
                      children: [
                        Icon(Icons.laptop, color: Color(0xff0f766e),),
                        TextButtonWidget(buttonText: "Classroom Demo",)
                      ],
                    ),
                    const SizedBox(height: 10,),
                    const Row(
                      children: [
                        Icon(Icons.contact_mail, color: Color(0xff0f766e),),
                        TextButtonWidget(buttonText: "Contact Us",)
                      ],
                    ),
                  ],
                ),
                SizedBox(height: _height * 0.1,),
                Column(
                  children: [
                    ElevatedButtonWidget(
                      buttonText: "Logout",
                      buttonColor: const Color(0xff0f766e),
                      textColor: Colors.white,
                      onTap: () async {
                        try {
                          await supabase.auth.signOut();
                          if (!context.mounted) return;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                          );
                        } catch (e) {
                          print("Logout Error: $e");
                        }
                      },
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}