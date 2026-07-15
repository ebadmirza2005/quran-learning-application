import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/auth_field.dart';
import '../../utils/button.dart';
import '../tutor_home_screen.dart';

class TutorChangePasswordScreen extends StatefulWidget {
  const TutorChangePasswordScreen({super.key});

  @override
  State<TutorChangePasswordScreen> createState() => _TutorChangePasswordScreenState();
}

class _TutorChangePasswordScreenState extends State<TutorChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _updatePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password must be at least 6 characters long')),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password and confirm password do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final userEmail = supabase.auth.currentUser?.email;

      if (userEmail == null) {
        throw const AuthException("User email not found. Please log in again.");
      }

      await supabase.auth.signInWithPassword(
        email: userEmail,
        password: currentPassword
      );

      await supabase.auth.updateUser(UserAttributes(password: newPassword));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully'), duration: Duration(seconds: 2), backgroundColor: Color(0xff0f766e),),
      );

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TutorHomeScreen()));
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } on AuthException catch (e) {
      if (mounted) {
        String errorMessage = e.message;
        if (e.message.toLowerCase().contains("invalid login credentials")) {
          errorMessage = "Invalid current password";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 1),
            backgroundColor: Color(0xff0f766e),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }finally {
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TutorHomeScreen()));
          },
        ),
        backgroundColor: const Color(0xff0f766e),
        foregroundColor: Colors.white,
        title: const Text("Change Password"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 15,),
            AuthField(authFieldText: "Current Password", controller: _currentPasswordController,),
            SizedBox(height: 15,),
            AuthField(authFieldText: "New Password", controller: _newPasswordController,),
            SizedBox(height: 15,),
            AuthField(authFieldText: "Confirm New Password", controller: _confirmPasswordController,),
            SizedBox(height: 15,),
            ElevatedButtonWidget(buttonText: "Update Password", buttonColor: Color(0xff0f766e), textColor: Colors.white, isLoading: _isLoading, onTap: _updatePassword,)
          ],
        ),
      ),
    );
  }
}
