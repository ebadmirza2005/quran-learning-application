import 'package:country_picker/country_picker.dart';
import 'package:quran_learning_application/utils/button.dart';
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
              return zoneKey.contains("New_York") || zoneKey.contains("Chicago") ||
                  zoneKey.contains("Denver") || zoneKey.contains("Los_Angeles") ||
                  zoneKey.contains("Anchorage") || zoneKey.contains("Honolulu");
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
          _availableTimeZones = ["Select Timezone", "GMT +${country.phoneCode} (Standard Time)", "UTC"];
        }
        _selectedTimeZone = "Select Timezone";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double fieldWidth = MediaQuery.of(context).size.width * 0.85;
    List<String> skillsKeys = tutorSkills.keys.toList();

    return Scaffold(
      backgroundColor: Color(0xffd2dad2),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 50,),
              SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: Image.asset("assets/logo.png")),
              const SizedBox(height: 30,),
              const AuthField(authFieldText: "Name",),
              const SizedBox(height: 10,),
              const AuthField(authFieldText: "Email"),
              const SizedBox(height: 10,),

              SizedBox(
                width: fieldWidth,
                child: InputDecorator(
                  decoration: const InputDecoration(
                      border: OutlineInputBorder()
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
              const SizedBox(height: 10,),
              const AuthField(authFieldText: "Phone No"),
              const SizedBox(height: 10,),

              SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: Row(
                  children: const [
                    Expanded(child: AuthField(authFieldText: "Password")),
                    SizedBox(width: 5,),
                    Expanded(child: AuthField(authFieldText: "Re-Type Password")),
                  ],
                ),
              ),
              const SizedBox(height: 10,),

              SizedBox(
                width: fieldWidth,
                child: InkWell(
                  onTap: () {
                    showCountryPicker(context: context, onSelect: (Country country) {
                      setState(() {
                        _selectedCountry = "${country.name} (${country.countryCode}) ${country.flagEmoji}";
                      });
                      _loadTimeZone(country);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                              color: _selectedCountry == "Select Country" ? Colors.grey[600] : Colors.black
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_sharp),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10,),
              const AuthField(authFieldText: "City"),
              const SizedBox(height: 10,),

              SizedBox(
                width: fieldWidth,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButton<String>(
                      value: _selectedTimeZone,
                      icon: const Icon(Icons.access_time, color: Color(0xff0f766e),),
                      isExpanded: true,
                      underline: Container(height: 2, color: const Color(0xff0f766e),),
                      items: _availableTimeZones.map((String timezone) {
                        return DropdownMenuItem<String>(
                            value: timezone,
                            child: Text(
                              timezone,
                              style: TextStyle(
                                  color: timezone == "Select Timezone" ? Colors.grey[700] : Colors.black
                              ),
                            ));
                      }).toList(),
                      onChanged: _selectedCountry == "Select Country" ? null : (String? newValue) {
                        setState(() {
                          _selectedTimeZone = newValue!;
                        });
                      }
                  ),
                ),
              ),
              const SizedBox(height: 15,),

              SizedBox(
                width: fieldWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: "I can teach",
                      textColor: const Color(0xff0f766e),
                      textWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 5,),

                    for (int i = 0; i < skillsKeys.length; i += 2) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildSkillItem(skillsKeys[i]),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: (i + 1 < skillsKeys.length)
                                ? _buildSkillItem(skillsKeys[i + 1])
                                : const SizedBox(),
                          ),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 10,),
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
                  Row(
                    children: [
                      TextWidget(
                        text: "By signing up, you agree to our ",
                      ),
                      TextWidget(text: "terms of use", textColor: Color(0xff0f766e))
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10,),
              ElevatedButtonWidget(buttonText: "Sign Up", onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TutorHomeScreen()));
              }, buttonColor: Color(0xff0f766e), textColor: Colors.white,),
              SizedBox(height: 30,),
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
        Flexible(
          child: TextWidget(
            text: skillName,
          ),
        ),
      ],
    );
  }
}