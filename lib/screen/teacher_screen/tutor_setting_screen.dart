import 'package:flutter/material.dart';
import 'package:quran_learning_application/screen/teacher_screen/classroom_demo/classroom_demo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/button.dart';
import '../../utils/text.dart';
import '../auth_screen.dart';
import 'tutor_edit_info.dart';
import 'tutor_location_screen.dart';
import 'tutor_personal_info.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final supabase = Supabase.instance.client;
  String tutorName = "Loading...";
  String? profileImageUrl;
  bool isLoadingImage = true;

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
          tutorName = data['name'] ?? "No Name Found";
          profileImageUrl = data['profile_image'];
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        tutorName = "Error Loading Name";
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
      color: const Color(0xffd2dad2),
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
                          const Positioned.fill(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
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
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TutorPersonalInfo()));
                        },
                        )
                      ],
                    ),
                    const SizedBox(height: 10,),
                    Row(
                      children: [
                        const Icon(Icons.edit_square, color: Color(0xff0f766e),),
                        TextButtonWidget(buttonText: "Edit Info", onTap: () {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TutorEditInfo()));
                        },)
                      ],
                    ),
                    const SizedBox(height: 10,),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xff0f766e),),
                        TextButtonWidget(buttonText: "Location", onTap: () {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TutorLocationScreen()));
                        },)
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
                    Row(
                      children: [
                        const Icon(Icons.laptop, color: Color(0xff0f766e),),
                        TextButtonWidget(buttonText: "Classroom Demo", onTap: () {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ClassroomDemo()));
                        },)
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