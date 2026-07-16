import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../utils/auth_field.dart';
import '../../utils/button.dart';
import '../../utils/drop_down_widget.dart';
import '../../utils/text.dart';
import '../student_home_screen.dart';

class StudentLocationScreen extends StatefulWidget {
  const StudentLocationScreen({super.key});

  @override
  State<StudentLocationScreen> createState() => _StudentLocationScreenState();
}

class _StudentLocationScreenState extends State<StudentLocationScreen> {
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();

  bool isLoading = false;

  String _selectedCountry = "Select Country";
  String? _selectedTimeZone = "Select Timezone";
  List<String> _availableTimeZones = ["Select Timezone"];

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  // --- Supabase se data fetch karne ka logic ---
  Future<void> _loadStudentData() async {
    final student = Supabase.instance.client.auth.currentUser;
    if (student != null) {
      setState(() => isLoading = true);
      try {
        final data = await Supabase.instance.client.from('students').select().eq('id', student.id).single();

        if (data != null) {
          setState(() {
            _cityController.text = data['city'] ?? '';
            _addressController.text = data['address'] ?? '';

            if (data['country'] != null && data['country'].toString().isNotEmpty) {
              _selectedCountry = data['country'];
            }

            if (data['timezone'] != null && data['timezone'].toString().isNotEmpty) {
              String savedZone = data['timezone'];
              if (!_availableTimeZones.contains(savedZone)) {
                _availableTimeZones.add(savedZone);
              }
              _selectedTimeZone = savedZone;
            }
          });
        }
      } catch(e) {
        debugPrint("Data Loading Error: $e");
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  // --- NEW: Supabase par data UPDATE karne ka logic ---
  Future<void> _updateLocation() async {
    final student = Supabase.instance.client.auth.currentUser;

    // 1. Validation checks
    if (student == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not authenticated!"), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedCountry == "Select Country" ||
        _selectedTimeZone == "Select Timezone" ||
        _cityController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields!"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 2. Supabase query to update data
      await Supabase.instance.client.from('students').update({
        'country': _selectedCountry,
        'city': _cityController.text.trim(),
        'timezone': _selectedTimeZone,
        'address': _addressController.text.trim(),
      }).eq('id', student.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location updated successfully!"), backgroundColor: Color(0xff0f766e)),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentHomeScreen()));
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update Failed: $e"), backgroundColor: Color(0xff0f766e)),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _loadTimeZone(Country country) async {
    String code = country.countryCode.toUpperCase();
    List<String> matchedZone = [];

    try {
      if(tz.timeZoneDatabase.locations.isNotEmpty) {
        matchedZone = tz.timeZoneDatabase.locations.keys.where((zoneKey) {
          final lowerKey = zoneKey.toLowerCase();
          List<String> parts = lowerKey.split('/');

          if (parts.length > 1) {
            if (code == 'US' && zoneKey.startsWith("America/")) {
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
      if (matchedZone.isNotEmpty) {
        _availableTimeZones = ["Select Timezone", ...matchedZone];
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
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffd2dad2),
      appBar: AppBar(
        backgroundColor: const Color(0xff0f766e),
        foregroundColor: Colors.white,
        leading: IconButton(onPressed: () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentHomeScreen()));
        }, icon: const Icon(Icons.arrow_back)),
        title: const Text("Location"),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 15,),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
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
                      color: const Color(0xffd2dad2),
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextWidget(text: _selectedCountry, textSize: 16, textColor: _selectedCountry == "Select Country" ? Colors.grey[600] : Colors.black,),
                        const Icon(Icons.arrow_drop_down_sharp),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AuthField(authFieldText: "City", controller: _cityController),
              const SizedBox(height: 12),
              DropdownWidget(
                hintText: "Select Timezone",
                selectedValue: _selectedTimeZone,
                items: _availableTimeZones,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTimeZone = newValue;
                  });
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: TextField(
                  controller: _addressController,
                  maxLines: null,
                  minLines: 2,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                      hintText: "Address",
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
              const SizedBox(height: 20),
              ElevatedButtonWidget(
                buttonText: "Update Location",
                textColor:  Colors.white,
                buttonColor: const Color(0xff0f766e),
                onTap: _updateLocation,
                isLoading: isLoading,
              )
            ],
          ),
        ),
      ),
    );
  }
}