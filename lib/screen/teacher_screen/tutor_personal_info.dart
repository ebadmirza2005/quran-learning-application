import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/auth_field.dart';
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

  File? _imageFile;
  String? _imageUrl;
  final ImagePicker _picker = ImagePicker();

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

          _imageUrl = data['profile_image'];

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

  Future<void> _saveTutorData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      String? finalImageUrl = _imageUrl;

      if (_imageFile != null) {
        final fileExtension = _imageFile!.path.split('.').last;
        
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = '${user.id}/profile_$timestamp.$fileExtension';

        await Supabase.instance.client.storage
            .from('avatars')
            .upload(
          path,
          _imageFile!,
          fileOptions: const FileOptions(upsert: true),
        );

        finalImageUrl = Supabase.instance.client.storage
            .from('avatars')
            .getPublicUrl(path);
      }

      List<String> selectedSkills = [];
      tutorSkills.forEach((key, value) {
        if (value) selectedSkills.add(key);
      });

      await Supabase.instance.client.from('tutors').upsert({
        'id': user.id,
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'dob': _dobController.text.isEmpty ? null : _dobController.text,
        'languages': _selectedLanguages,
        'skills': selectedSkills,
        'profile_image': finalImageUrl,
      });

      if (mounted) {
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error Saving data: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  ImageProvider? _getProfileImage() {
    if (_imageFile != null) {
      return FileImage(_imageFile!); 
    } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return NetworkImage(_imageUrl!); 
    }
    return null;
  }

  void _showImageSourceBottomSheet(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withAlpha(128), // Background dimming
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.topCenter, // Top per alignment
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20, // Status bar spacing
                bottom: 20,
                left: 10,
                right: 10,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)), // Bottom corners rounded
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TextWidget(
                    text: "Select Profile Picture",
                    textWeight: FontWeight.bold,
                    textSize: 18,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff0f766e),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.camera);
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Camera"),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff0f766e),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.gallery);
                        },
                        icon: const Icon(Icons.image),
                        label: const Text("Gallery"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
          ).animate(anim1),
          child: child,
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
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
      String formattedDate = DateFormat('dd-MM-yyyy').format(pickedDate);
      setState(() {
        _dobController.text = formattedDate;
      });
    }
  }

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
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TutorHomeScreen()));
          },
        ),
        backgroundColor: const Color(0xff0f766e),
        foregroundColor: Colors.white,
        title: const TextWidget(text: 'Personal Info'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xff0f766e)))
          : SafeArea(
            child: Center(
                    child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SizedBox(height: 30),
            
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xff0f766e),
                      backgroundImage: _getProfileImage(),
                      child: _getProfileImage() == null
                          ? const Icon(Icons.person, color: Colors.white, size: 50)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: -4,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey.shade200,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.edit, color: Color(0xff0f766e), size: 18),
                          onPressed: () => _showImageSourceBottomSheet(context),
                        ),
                      ),
                    ),
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
            
                // Date of Birth
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
                          color: Color(0xffd2dad2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _dobController.text.isEmpty ? "dd-MM-yyyy" : _dobController.text,
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
            
                // Languages
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
                          color: Color(0xffd2dad2),
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
            
                // Skills
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