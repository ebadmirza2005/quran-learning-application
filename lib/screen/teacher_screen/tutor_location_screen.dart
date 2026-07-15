import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:quran_learning_application/utils/button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../utils/auth_field.dart';
import '../../utils/drop_down_widget.dart';
import '../tutor_home_screen.dart';

class TutorLocationScreen extends StatefulWidget {
  const TutorLocationScreen({super.key});

  @override
  State<TutorLocationScreen> createState() => _TutorLocationScreenState();
}

class _TutorLocationScreenState extends State<TutorLocationScreen> {
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = true;

  String _selectedCountry = "Select Country";
  String? _selectedTimeZone = "Select Timezone";
  List<String> _availableTimeZones = ["Select Timezone"];

  @override
  void initState() {
    super.initState();
    _loadTutorData();
  }

  Future<void> _loadTutorData() async {
    final tutor = Supabase.instance.client.auth.currentUser;
    if (tutor != null) {
      try {
        final data = await Supabase.instance.client.from('tutors').select().eq('id', tutor.id).single();

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

            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() => _isLoading = false);
        print("Data Loading Error: $e");
      }
    } else {
      setState(() => _isLoading = false);
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
        leading: IconButton(onPressed: () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TutorHomeScreen()));
        }, icon: const Icon(Icons.arrow_back)),
        backgroundColor: const Color(0xff0f766e),
        foregroundColor: Colors.white,
        title: const Text("Location"),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xff0f766e)))
          : SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  SizedBox(height: 15,),
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
                          color: const Color(0xffd2dad2),
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
                  const SizedBox(height: 12),
                  AuthField(authFieldText: "City", controller: _cityController),
                  const SizedBox(height: 12),
                  DropdownWidget(
                    hintText: "Select Timezone",
                    items: _availableTimeZones,
                    selectedValue: _selectedTimeZone,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedTimeZone = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  AuthField(authFieldText: "Address", controller: _addressController),
                  const SizedBox(height: 12),
                  ElevatedButtonWidget(buttonText: "Update Location", textColor:  Colors.white, buttonColor: const Color(0xff0f766e), onTap: () {}, isLoading: _isLoading,)
                ],
              ),
            ),
          ),
    );
  }
}