import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/auth_field.dart';
import '../../utils/button.dart';
import '../student_home_screen.dart';

class StudentChangePasswordScreen extends StatefulWidget {
  const StudentChangePasswordScreen({super.key});

  @override
  State<StudentChangePasswordScreen> createState() => _StudentChangePasswordScreenState();
}

class _StudentChangePasswordScreenState extends State<StudentChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;


  Future<void> _updatePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields')));
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New password must be at least 6 characters long')));
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New password and confirm password do not match')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xff0f766e),
        ),
      );

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentHomeScreen()));

    } on AuthException catch (e) {
      if (mounted) {
        print("Supabase Auth Error: ${e.message}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xff0f766e),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        print("General Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentHomeScreen()));
        }, icon: const Icon(Icons.arrow_back)),
        backgroundColor: const Color(0xff0f766e),
        foregroundColor: Colors.white,
        title: const Text("Change Password"),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 15,),
              AuthField(authFieldText: "Current Password", controller: _currentPasswordController,),
              const SizedBox(height: 15,),
              AuthField(authFieldText: "New Password", controller: _newPasswordController,),
              const SizedBox(height: 15,),
              AuthField(authFieldText: "Confirm Password", controller: _confirmPasswordController,),
              const SizedBox(height: 25,),
              ElevatedButtonWidget(
                buttonText: "Update Password",
                buttonColor: const Color(0xff0f766e),
                textColor: Colors.white,
                isLoading: _isLoading,
                onTap: _updatePassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}