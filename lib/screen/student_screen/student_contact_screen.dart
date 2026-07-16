import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/auth_field.dart';
import '../../utils/button.dart';
import '../student_home_screen.dart';

class StudentContactScreen extends StatefulWidget {
  const StudentContactScreen({super.key});

  @override
  State<StudentContactScreen> createState() => _StudentContactScreenState();
}

class _StudentContactScreenState extends State<StudentContactScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    final student = Supabase.instance.client.auth.currentUser;
    if (student != null) {
      setState(() => isLoading = true);

      try {
        final data = await Supabase.instance.client.from('students').select().eq('id', student.id).single();

        if (data != null) {
          setState(() {
            _nameController.text = data['name'] ?? '';
            _emailController.text = data['email'] ?? '';
            _phoneController.text = data['phone'] ?? '';
          });
        }
      }catch (e) {
        debugPrint("Data Loading Error: $e");
      }finally {
        setState(() => isLoading = false);
      }
    }
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
        title: const Text("Contact Us"),
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 15,),
            AuthField(authFieldText: "Name", controller: _nameController,),
            SizedBox(height: 15,),
            AuthField(authFieldText: "Email", controller: _emailController,),
            SizedBox(height: 15,),
            AuthField(authFieldText: "Phone No", controller: _phoneController,),
            SizedBox(height: 15,),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: TextField(
                controller: _messageController,
                maxLines: null,
                minLines: 2,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                    hintText: "Enter Your Message...",
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        width: 2.0,
                        color: Color(0xff0f766e),
                      ),
                    )
                ),
              ),
            ),
            SizedBox(height: 15,),
            ElevatedButtonWidget(buttonText: "Submit", onTap: () {}, buttonColor: const Color(0xff0f766e), textColor: Colors.white,),
          ],
        ),
      ),
    );
  }
}
