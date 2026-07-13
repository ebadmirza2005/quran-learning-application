import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../utils/auth_field.dart';
import '../utils/button.dart';
import '../utils/drop_down_widget.dart';
import '../utils/text.dart';
import 'student_home_screen.dart';
import 'tutor_home_screen.dart';

class SignupStudentScreen extends StatefulWidget {
  const SignupStudentScreen({super.key});

  @override
  State<SignupStudentScreen> createState() => _SignupAuthScreenState();
}

class _SignupAuthScreenState extends State<SignupStudentScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _cityController = TextEditingController();

  final supabase = Supabase.instance.client;
  bool _isLoading = false;

  bool _isAgree = false;

  String? selectedTutorGender;
  String? selectedRate;
  String? selectedGender;

  String _selectedCountry = "Select Country";
  String? _selectedTimeZone = "Select Timezone";
  List<String> _availableTimeZones = ["Select Timezone"];

  Map<String, bool> tutorSkills = {
    "Qaida": false,
    "Recitation": false,
    "Tajweed": false,
    "Hadith": false,
    "Masnoon Duas": false,
    "Kalmas": false,
  };

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void>_signUpStudent() async {
    if (!_isAgree) {
      _showSnackBar("Please agree to the terms of use.");
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar("Passwords do not match!");
    }

    if (selectedTutorGender == null || selectedRate == null || selectedGender == null || _selectedCountry == "Select Country" || _selectedTimeZone == "Select Timezone") {
      _showSnackBar("Please fill all the required fields.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authResponse = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = authResponse.user;

      if (user != null) {
        List<String> seekingKnowledge = tutorSkills.entries
            .where((entry) => entry.value == true)
            .map((entry) => entry.key)
            .toList();

        await supabase.from('students').insert({
          'id': user.id,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'tutor_gender': selectedTutorGender,
          'rate': selectedRate,
          'student_gender': selectedGender,
          'phone': _phoneController.text.trim(),
          'password': _passwordController.text.trim(),
          'retype_password': _confirmPasswordController.text.trim(),
          'country': _selectedCountry,
          'city': _cityController.text.trim(),
          'timezone': _selectedTimeZone,
          'seeking_knowledge': seekingKnowledge,
          'created_at': DateTime.now().toIso8601String(),
        });

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
              (Route route) => false,
        );
      }
    }catch (e) {
      _showSnackBar("Error: ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadTimeZone(Country country) async {
    String code = country.countryCode.toUpperCase();
    List<String> matchedZones = [];

    try {
      if (tz.timeZoneDatabase.locations.isNotEmpty) {
        matchedZones = tz.timeZoneDatabase.locations.keys.where((zoneKey) {
          final lowerKey = zoneKey.toLowerCase();
          List<String> parts = lowerKey.split('/');

          if (parts.length > 1) {
            if (code == "US" && zoneKey.startsWith("America/")) {
              return zoneKey.contains("New_York") ||
                  zoneKey.contains("Chicago") ||
                  zoneKey.contains("Denver") ||
                  zoneKey.contains("Los_Angeles") ||
                  zoneKey.contains("Anchorage") ||
                  zoneKey.contains("Honolulu");
            }

            String searchName = country.name.toLowerCase().replaceAll(' ', '_');
            if (lowerKey.contains(searchName)) return true;
          }
          return false;
        }).toList();
      }
    } catch (e) {
      debugPrint("Timezone Filter Error: $e");
    }

    setState(() {
      if (matchedZones.isNotEmpty) {
        _availableTimeZones = ["Select Timezone", ...matchedZones];
        _selectedTimeZone = "Select Timezone";
      } else {
        if (code == "PK") _availableTimeZones = ["Select Timezone", "Asia/Karachi"];
        else if (code == "IN") _availableTimeZones = ["Select Timezone", "Asia/Kolkata"];
        else if (code == "SA") _availableTimeZones = ["Select Timezone", "Asia/Riyadh"];
        else if (code == "AE") _availableTimeZones = ["Select Timezone", "Asia/Dubai"];
        else if (code == "GB") _availableTimeZones = ["Select Timezone", "Europe/London"];
        else {
          _availableTimeZones = [
            "Select Timezone",
            "GMT +${country.phoneCode} (Standard Time)",
            "UTC",
          ];
        }
        _selectedTimeZone = "Select Timezone";
      }
    });
  }

  @override
  void initState() {
    super.initState();
    tz_data.initializeTimeZones();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double fieldWidth = MediaQuery.of(context).size.width * 0.85;
    List<String> skillsKeys = tutorSkills.keys.toList();
    return Scaffold(
      backgroundColor: const Color(0xffd2dad2),
      appBar: AppBar(
        title: const Text("Student Sign Up"),
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xff0f766e),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 10,),
              SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: Image.asset("assets/logo.png")),
              AuthField(authFieldText: "Name", controller: _nameController,),
              const SizedBox(height: 10,),
              AuthField(authFieldText: "Email", controller: _emailController),
              const SizedBox(height: 10,),
              DropdownWidget(
                hintText: "Select Preferred Tutor Gender",
                items: const ["Male", "Female", "Either"],
                selectedValue: selectedTutorGender,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedTutorGender = newValue;
                  });
                },
              ),
              const SizedBox(height: 10,),

              DropdownWidget(
                hintText: "Select Rate",
                items: const ['\$3 - \$5', '\$5 - \$10', '\$10 - \$20', '\$20+'],
                selectedValue: selectedRate,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedRate = newValue;
                  });
                },
              ),
              const SizedBox(height: 10,),

              DropdownWidget(
                hintText: "Select Your Gender",
                items: const ["Male", "Female"],
                selectedValue: selectedGender,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedGender = newValue;
                  });
                },
              ),
              const SizedBox(height: 10,),
              AuthField(authFieldText: "Phone Number", controller: _phoneController,),
              const SizedBox(height: 10,),

              // Password Row
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: Row(
                  children: [
                    Expanded(child: AuthField(authFieldText: "Password", controller: _passwordController,)),
                    SizedBox(width: 5),
                    Expanded(child: AuthField(authFieldText: "Re-Type Password", controller: _confirmPasswordController)),
                  ],
                ),
              ),
              const SizedBox(height: 10,),

              SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: InkWell(
                  onTap: () {
                    showCountryPicker(
                      context: context,
                      onSelect: (Country country) {
                        setState(() {
                          _selectedCountry = "${country.name} (${country.countryCode}) ${country.flagEmoji}";
                        });
                        _loadTimeZone(country);
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Color(0xffd2dad2),
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedCountry,
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedCountry == "Select Country"
                                ? Colors.grey[600]
                                : Colors.black,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_sharp),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10,),
              AuthField(authFieldText: "City", controller: _cityController),
              const SizedBox(height: 10),
              DropdownWidget(hintText: "Select Timezone", items: _availableTimeZones, selectedValue: _selectedTimeZone, onChanged: (String? newValue) {
                setState(() {
                  _selectedTimeZone = newValue!;
                });
              },),
              const SizedBox(height: 10),
              SizedBox(
                width: fieldWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TextWidget(
                      text: "I want to learn",
                      textColor: Color(0xff0f766e),
                      textWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 5),

                    for (int i = 0; i < skillsKeys.length; i += 2) ...[
                      Row(
                        children: [
                          Expanded(child: _buildSkillItem(skillsKeys[i])),
                          const SizedBox(width: 10),
                          Expanded(
                            child: (i + 1 < skillsKeys.length)
                                ? _buildSkillItem(skillsKeys[i + 1])
                                : const SizedBox(),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    activeColor: const Color(0xff0f766e),
                    value: _isAgree,
                    onChanged: (bool? value) {
                      setState(() {
                        _isAgree = value ?? false;
                      });
                    },
                  ),
                  const TextWidget(text: "By signing up, you agree to our "),
                  const TextWidget(text: "terms of use", textColor: Color(0xff0f766e)),
                ],
              ),
              const SizedBox(height: 20,),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0f766e),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _signUpStudent,
                  child: _isLoading
                      ? CircularProgressIndicator(
                    color: Colors.white,
                  )
                      : Text(
                    "Sign Up",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillItem(String skillName) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          activeColor: const Color(0xff0f766e),
          value: tutorSkills[skillName],
          onChanged: (bool? value) {
            setState(() {
              tutorSkills[skillName] = value!;
            });
          },
        ),
        Flexible(child: TextWidget(text: skillName)),
      ],
    );
  }
}