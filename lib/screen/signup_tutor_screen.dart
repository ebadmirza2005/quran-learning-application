import 'package:flutter/material.dart';

import '../utils/auth_field.dart';
import '../utils/text.dart';

class SignupTutorScreen extends StatefulWidget {
  const SignupTutorScreen({super.key});

  @override
  State<SignupTutorScreen> createState() => _SignupTutorScreenState();
}

class _SignupTutorScreenState extends State<SignupTutorScreen> {
  String selectedValue = "Select Gender";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextWidget(text: "Create Account")
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 30,),
              AuthField(authFieldText: "Name",),
              SizedBox(height: 10,),
              AuthField(authFieldText: "Email"),
              SizedBox(height: 10,),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: InputDecorator(
                  decoration: InputDecoration(
                    border: OutlineInputBorder()
                  ),
                  child: DropdownButton(
                      value: selectedValue,
                      icon: const Icon(Icons.arrow_downward),
                      elevation: 16,
                      isExpanded: true,
                      underline: Container(
                        height: 2,
                        color: Color(0xff0f766e),
                      ),
                      items: [
                        DropdownMenuItem(value: "Select Gender", child: Text("Select Gender")),
                        DropdownMenuItem(value: "Male", child: Text("Male")),
                        DropdownMenuItem(value: "Female", child: Text("Female"),),
                      ], onChanged: (String? newValue) {
                        setState(() {
                          selectedValue = newValue!;
                        });
                  }),
                ),
              ),
              SizedBox(height: 10,),
              AuthField(authFieldText: "Phone No"),
              SizedBox(height: 10,),
              AuthField(authFieldText: "Password"),
              SizedBox(height: 10,),
              AuthField(authFieldText: "Re-Type Password"),
              SizedBox(height: 10,),
          
          
            ],
          ),
        ),
      ),
    );
  }
}
