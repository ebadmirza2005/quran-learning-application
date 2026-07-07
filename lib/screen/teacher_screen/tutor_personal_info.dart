import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/auth_field.dart';
import '../../utils/button.dart';
import '../../utils/text.dart';
import '../tutor_home_screen.dart';

class TutorPersonalInfo extends StatefulWidget {
  const TutorPersonalInfo({super.key});

  @override
  State<TutorPersonalInfo> createState() => _TutorPersonalInfoState();
}

class _TutorPersonalInfoState extends State<TutorPersonalInfo> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  List<String> _selectedLanguages = [];
  final List<String> _languagesList = [
    "Urdu",
    "English",
    "Arabic",
    "Punjabi",
    "Sindhi",
    "Pashto",
    "Balochi"
  ];

  bool _isLoading = true;

  Map<String, bool> tutorSkills = {
    "Qaida": false,
    "Recitation": false,
    "Tajweed": false,
    "Hadith": false,
    "Masnoon Duas": false,
    "Kalmas": false,
  };

  @override
  void initState() {
    super.initState();
    _fetchTutorData();
  }

  // --- Supabase Se Data Fetch Karna ---
  Future<void> _fetchTutorData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      _emailController.text = user.email ?? '';
      _nameController.text = user.userMetadata?['name'] ?? '';

      final data = await Supabase.instance.client
          .from('tutors')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        setState(() {
          if (data['name'] != null) _nameController.text = data['name'];
          if (data['email'] != null) _emailController.text = data['email'];
          _phoneController.text = data['phone'] ?? '';
          _dobController.text = data['dob'] ?? '';

          _selectedLanguages = List<String>.from(data['languages'] ?? []);

          List<dynamic> savedSkills = data['skills'] ?? [];
          for (var skill in savedSkills) {
            if (tutorSkills.containsKey(skill)) {
              tutorSkills[skill] = true;
            }
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error Fetching Data: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- Data Supabase Mein Save Karna ---
  Future<void> _saveTutorData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      List<String> selectedSkills = [];
      tutorSkills.forEach((key, value) {
        if (value) selectedSkills.add(key);
      });

      await Supabase.instance.client.from('tutors').upsert({
        'id': user.id,
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'dob': _dobController.text,
        'languages': _selectedLanguages,
        'skills': selectedSkills,
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TutorHomeScreen()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xff0f766e),
          content: Text("Profile Saved Successfully!"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error Saving data: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- Date Picker Function ---
  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      // Calendar khulega to default yeh saal samne aayega
      initialDate: DateTime(2000, 1, 1),
      // 1950 select karne ke liye firstDate bilkul theek hai
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xff0f766e),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xff0f766e),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // FIX: 'dd-mm-yyyy' ko badal kar 'dd-MM-yyyy' kiya (MM = Month)
      String formattedDate = DateFormat('dd-MM-yyyy').format(pickedDate);
      setState(() {
        _dobController.text = formattedDate;
      });
    }
  }

  // --- Multiple Languages Ki Bottom Sheet Dikhana ---
  void _showMultiSelectBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xffd2dad2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: TextWidget(
                    text: "Select Languages",
                    textWeight: FontWeight.bold,
                    textSize: 18,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _languagesList.length,
                    itemBuilder: (context, index) {
                      final lang = _languagesList[index];
                      final isChecked = _selectedLanguages.contains(lang);

                      return CheckboxListTile(
                        title: TextWidget(text: lang),
                        activeColor: const Color(0xff0f766e),
                        value: isChecked,
                        onChanged: (bool? value) {
                          setModalState(() {
                            setState(() {
                              if (value == true) {
                                _selectedLanguages.add(lang);
                              } else {
                                _selectedLanguages.remove(lang);
                              }
                            });
                          });
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff0f766e),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Update", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double fieldWidth = MediaQuery.of(context).size.width * 0.85;
    List<String> skillsKeys = tutorSkills.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xffd2dad2),
      appBar: AppBar(
        backgroundColor: const Color(0xff0f766e),
        foregroundColor: Colors.white,
        title: const TextWidget(text: 'Personal Info'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xff0f766e)))
          : Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(height: 30),
              const Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xff0f766e),
                  ),
                  Icon(Icons.photo, color: Colors.white, size: 30),
                ],
              ),
              const SizedBox(height: 20),

              // Name
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TextWidget(text: "Name", textColor: Color(0xff0f766e), textWeight: FontWeight.bold),
                  const SizedBox(height: 7),
                  AuthField(authFieldText: "Name", controller: _nameController)
                ],
              ),
              const SizedBox(height: 10),

              // Email
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TextWidget(text: "Email", textColor: Color(0xff0f766e), textWeight: FontWeight.bold),
                  const SizedBox(height: 7),
                  AuthField(authFieldText: "someone@example.com", controller: _emailController)
                ],
              ),
              const SizedBox(height: 10),

              // Phone No
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TextWidget(text: "Phone No", textColor: Color(0xff0f766e), textWeight: FontWeight.bold),
                  const SizedBox(height: 7),
                  AuthField(authFieldText: "03xxxxxxxxxx", controller: _phoneController)
                ],
              ),
              const SizedBox(height: 10),

              // --- Custom Date of Birth Picker ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TextWidget(text: "Date of Birth", textColor: Color(0xff0f766e), textWeight: FontWeight.bold),
                  const SizedBox(height: 7),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      width: fieldWidth,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _dobController.text.isEmpty ? "dd-mm-yyyy" : _dobController.text,
                            style: TextStyle(
                              color: _dobController.text.isEmpty ? Colors.grey.shade600 : Colors.black,
                              fontSize: 16,
                            ),
                          ),
                          const Icon(Icons.calendar_month, color: Color(0xff0f766e)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // --- Multi-Select Languages Field ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TextWidget(text: "Languages", textColor: Color(0xff0f766e), textWeight: FontWeight.bold),
                  const SizedBox(height: 7),
                  InkWell(
                    onTap: () => _showMultiSelectBottomSheet(context),
                    child: Container(
                      width: fieldWidth,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _selectedLanguages.isEmpty
                                  ? "Select Languages"
                                  : _selectedLanguages.join(", "),
                              style: TextStyle(
                                color: _selectedLanguages.isEmpty ? Colors.grey.shade600 : Colors.black,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Color(0xff0f766e)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Skills (I can teach)
              SizedBox(
                width: fieldWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TextWidget(text: "I can teach", textColor: Color(0xff0f766e), textWeight: FontWeight.bold),
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

              // Save Button
              SizedBox(
                width: fieldWidth,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0f766e),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isLoading ? null : _saveTutorData,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save"),
                ),
              ),
              const SizedBox(height: 20),
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