import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/button.dart';
import '../../utils/text.dart';
import '../auth_screen.dart';
import 'student_change_password_screen.dart';
import 'student_contact_screen.dart';
import 'student_location_screen.dart';
import 'student_personal_info.dart';

class StudentSettingScreen extends StatefulWidget {
  const StudentSettingScreen({super.key});

  @override
  State<StudentSettingScreen> createState() => _StudentSettingScreenState();
}

class _StudentSettingScreenState extends State<StudentSettingScreen> {
  final supabase = Supabase.instance.client;
  String studentName = "Loading...";
  String? profileImageUrl;
  bool isLoadingImage = true;

  @override
  void initState() {
    super.initState();
    getStudentProfile();
  }

  Future<void> getStudentProfile() async {
    try {
      final user = supabase.auth.currentUser;

      if (user != null) {
        final data = await supabase
            .from('students')
            .select('name, profile_image')
            .eq('id', user.id)
            .maybeSingle();

        if (!mounted) return;

        if (data == null) {
          await supabase.auth.signOut();
          if (!mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AuthScreen()),
                (route) => false,
          );
          return;
        }

        setState(() {
          studentName = data['name'] ?? "No Name Found";
          profileImageUrl = data['profile_image'];
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        studentName = "Error Loading Name";
      });
      print("Fetch Error: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          isLoadingImage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final _height = MediaQuery.of(context).size.height;
    return Material(
      color: Color(0xffd2dad2),
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
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xff0f766e),
                          backgroundImage: (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                              ? NetworkImage(profileImageUrl!)
                              : null,
                          child: (profileImageUrl == null || profileImageUrl!.isEmpty)
                              ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 40,
                          )
                              : null,
                        ),
                        if (isLoadingImage)
                          const SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10,),
                    TextWidget(
                      text: studentName,
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
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentPersonalInfo()));
                        })
                      ],
                    ),
                    const SizedBox(height: 10,),
                    Row(
                      children: [
                        const Icon(Icons.pin_drop, color: Color(0xff0f766e),),
                        TextButtonWidget(buttonText: "Location", onTap: () {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentLocationScreen()));
                        })
                      ],
                    ),
                    const SizedBox(height: 10,),
                    Row(
                      children: [
                        const Icon(Icons.lock, color: Color(0xff0f766e),),
                        TextButtonWidget(buttonText: "Change Password", onTap: () {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentChangePasswordScreen()));
                        },)
                      ],
                    ),
                    const SizedBox(height: 10,),
                    Row(
                      children: [
                        const Icon(Icons.share, color: Color(0xff0f766e),),
                        TextButtonWidget(buttonText: "Invite Friends",)
                      ],
                    ),
                    const SizedBox(height: 10,),
                    Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.bookQuran, color: Color(0xff0f766e),),
                        TextButtonWidget(buttonText: "Quran",)
                      ],
                    ),
                    const SizedBox(height: 10,),
                    Row(
                      children: [
                        const Icon(Icons.contact_mail, color: Color(0xff0f766e),),
                        TextButtonWidget(buttonText: "Contact Us", onTap: () {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentContactScreen()));
                        },)
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
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                                (route) => false,
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