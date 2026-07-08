import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/auth_field.dart';
import '../utils/button.dart';
import '../utils/text.dart';
import 'signup_auth_screen.dart';
import 'signup_tutor_screen.dart';
import 'tutor_home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final supabase = Supabase.instance.client;
  late TapGestureRecognizer _tapGestureRecognizer;
  bool isLoading = false;

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final result = await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text
      );

      if (!mounted) return;

      if (result.user != null && result.session != null) {
        final tutorData = await supabase
            .from('tutors')
            .select('id')
            .eq('id', result.user!.id)
            .maybeSingle();

        if (!mounted) return;

        if (tutorData == null) {
          await supabase.auth.signOut();

          setState(() {
            isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Your account doesn't exist"),
                backgroundColor: Colors.red,
              )
          );
          return;
        }
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const TutorHomeScreen()),
              (Route route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Invalid Email or Password"),
              backgroundColor: Colors.red,
            )
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tapGestureRecognizer = TapGestureRecognizer();
    _tapGestureRecognizer.onTap = () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SignupAuthScreen()),
      );
    };
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _tapGestureRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffd2dad2),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: Image.asset("assets/logo.png"),
              ),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TextWidget(
                      text: "Email",
                      textColor: Color(0xff0f766e),
                      textWeight: FontWeight.w500,
                    ),
                    const SizedBox(height: 7),
                    AuthField(
                      authFieldText: "someone@example.com",
                      controller: _emailController,
                    ),
                    const SizedBox(height: 20),
                    const TextWidget(
                      text: "Password",
                      textColor: Color(0xff0f766e),
                      textWeight: FontWeight.w500,
                    ),
                    const SizedBox(height: 7),
                    AuthField(
                      authFieldText: "••••••••",
                      controller: _passwordController,
                    ),
                    TextButtonWidget(buttonText: "Forgot Password?"),
                    const SizedBox(height: 10),
                    SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: login, child: isLoading
                            ? CircularProgressIndicator(
                          color: Color(0xff0f766e),
                        ) : Text("Login", style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xff0f766e)
                        ),
                        )
                        ))
                  ],
                ),
              ),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: "Don't have an account?",
                      style: TextStyle(color: Colors.black54),
                    ),
                    const WidgetSpan(child: SizedBox(width: 5)),
                    TextSpan(
                      text: "Signup",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xff0f766e),
                      ),
                      recognizer: _tapGestureRecognizer,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const TextWidget(
                text: "OR",
                textSize: 20.0,
                textColor: Color(0xff0f766e),
                textWeight: FontWeight.bold,
              ),
              const SizedBox(height: 20),
              ElevatedButtonWidget(
                buttonText: "Sign up as Tutor",
                buttonColor: const Color(0xff0f766e),
                textColor: Colors.white,
                textWeight: FontWeight.bold,
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupTutorScreen())
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}