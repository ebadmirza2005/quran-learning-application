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
  String? profileImageUrl; // Image URL store karne ke liye variable
  bool isLoadingImage = true; // Image loading state track karne ke liye

  @override
  void initState() {
    super.initState();
    getTutorProfile();
  }

  Future<void> getTutorProfile() async {
    try {
      final user = supabase.auth.currentUser;

      if (user != null) {
        // Yahan 'name' ke sath 'profile_image' column ko bhi select kiya hai
        final data = await supabase
            .from('tutors')
            .select('name, profile_image')
            .eq('id', user.id)
            .maybeSingle();

        if (!mounted) return;

        setState(() {
          if (data != null) {
            tutorName = data['name'] ?? "No Name Found";
            profileImageUrl = data['profile_image']; // URL state mein save kiya
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
                    // --- Profile Image Stack Section ---
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xff0f766e),
                          // Agar URL maujood ho to NetworkImage show karega, warna null
                          backgroundImage: (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                              ? NetworkImage(profileImageUrl!)
                              : null,
                          // Agar image loading mein ho ya URL na ho to default widget dikhayega
                          child: (profileImageUrl == null || profileImageUrl!.isEmpty)
                              ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 40,
                          )
                              : null,
                        ),
                        // Loading spinner agar network image fetch ho rahi ho
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
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorPersonalInfo()));
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