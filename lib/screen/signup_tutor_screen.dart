import 'package:country_picker/country_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import '../utils/auth_field.dart';
import '../utils/text.dart';
import 'tutor_home_screen.dart';

class SignupTutorScreen extends StatefulWidget {
  const SignupTutorScreen({super.key});

  @override
  State<SignupTutorScreen> createState() => _SignupTutorScreenState();
}

class _SignupTutorScreenState extends State<SignupTutorScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _cityController = TextEditingController();

  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  String selectedValue = "Select Gender";
  String _selectedCountry = "Select Country";
  String _selectedTimeZone = "Select Timezone";

  List<String> _availableTimeZones = ["Select Timezone"];

  Map<String, bool> tutorSkills = {
    "Qaida": false,
    "Recitation": false,
    "Tajweed": false,
    "Hadith": false,
    "Masnoon Duas": false,
    "Kalmas": false,
  };

  bool _isAgree = false;

  Future<void> _signUpTutor() async {
    if (!_isAgree) {
      _showSnackBar('Please agree to the terms of use.');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar("Passwords do not match!");
      return;
    }

    if (selectedValue == "Select Gender" || _selectedCountry == "Select Country") {
      _showSnackBar("Please select gender and country");
      return;
    }

    if (_selectedTimeZone == "Select Timezone") {
      _showSnackBar("Please select your timezone");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authResponse = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        emailRedirectTo: 'com.example.quran_learning_application://login-callback/',
      );

      final user = authResponse.user;

      if (user != null) {
        List<String> selectedSkills = tutorSkills.entries
            .where((entry) => entry.value == true)
            .map((entry) => entry.key)
            .toList();

        await _supabase.from('tutors').insert({
          'id': user.id,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'gender': selectedValue,
          'phone': _phoneController.text.trim(),
          'country': _selectedCountry,
          'city': _cityController.text.trim(),
          'timezone': _selectedTimeZone,
          'skills': selectedSkills,
          'created_at': DateTime.now().toIso8601String(),
        });

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const EmailVerificationPendingScreen(),
          ),
              (Route route) => false,
        );
      }
    } on AuthException catch (e) {
      _showSnackBar(e.message);
    } catch (e) {
      _showSnackBar("An unexpected error occurred.");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
        title: const Text("Tutor Sign Up"),
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xff0f766e),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: Image.asset("assets/logo.png"),
              ),
              const SizedBox(height: 30),
              AuthField(authFieldText: "Name", controller: _nameController),
              const SizedBox(height: 10),
              AuthField(authFieldText: "Email", controller: _emailController),
              const SizedBox(height: 10),

              SizedBox(
                width: fieldWidth,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButton<String>(
                    value: selectedValue,
                    icon: const Icon(Icons.arrow_drop_down_sharp),
                    elevation: 16,
                    isExpanded: true,
                    underline: Container(
                      height: 2,
                      color: const Color(0xff0f766e),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "Select Gender",
                        child: Text("Select Gender"),
                      ),
                      DropdownMenuItem(value: "Male", child: Text("Male")),
                      DropdownMenuItem(value: "Female", child: Text("Female")),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedValue = newValue!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              AuthField(authFieldText: "Phone No", controller: _phoneController),
              const SizedBox(height: 10),

              SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: Row(
                  children: [
                    Expanded(child: AuthField(authFieldText: "Password", controller: _passwordController)),
                    const SizedBox(width: 5),
                    Expanded(child: AuthField(authFieldText: "Re-Type Password", controller: _confirmPasswordController)),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                width: fieldWidth,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
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
              const SizedBox(height: 10),
              AuthField(authFieldText: "City", controller: _cityController),
              const SizedBox(height: 10),

              SizedBox(
                width: fieldWidth,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedTimeZone,
                    icon: const Icon(
                      Icons.access_time,
                      color: Color(0xff0f766e),
                    ),
                    isExpanded: true,
                    underline: Container(
                      height: 2,
                      color: const Color(0xff0f766e),
                    ),
                    items: _availableTimeZones.map((String timezone) {
                      return DropdownMenuItem<String>(
                        value: timezone,
                        child: Text(
                          timezone,
                          style: TextStyle(
                            color: timezone == "Select Timezone"
                                ? Colors.grey[700]
                                : Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: _selectedCountry == "Select Country"
                        ? null
                        : (String? newValue) {
                      setState(() {
                        _selectedTimeZone = newValue!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),

              SizedBox(
                width: fieldWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TextWidget(
                      text: "I can teach",
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
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    activeColor: const Color(0xff0f766e),
                    value: _isAgree,
                    onChanged: (bool? value) {
                      setState(() {
                        _isAgree = value!;
                      });
                    },
                  ),
                  const Row(
                    children: [
                      TextWidget(text: "By signing up, you agree to our "),
                      TextWidget(
                        text: "terms of use",
                        textColor: Color(0xff0f766e),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
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
                  onPressed: _signUpTutor,
                  child: _isLoading
                      ? CircularProgressIndicator(
                    color: Colors.white
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
              const SizedBox(height: 30),
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

class EmailVerificationPendingScreen extends StatelessWidget {
  const EmailVerificationPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffd2dad2),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.mark_email_unread_rounded,
              size: 100,
              color: Color(0xff0f766e),
            ),
            const SizedBox(height: 30),
            const Text(
              "Verify Your Email",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xff0f766e),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "Humne aapke email address par ek confirmation link bheja hai. Please apna inbox check karein aur account verify karne ke liye link par click karein.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0f766e),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  // User ko validation ke baad wapis Login screen par le jayen
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text(
                  "Go to Login",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}