import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart'; // Safe media picker video ke liye
import 'package:permission_handler/permission_handler.dart';
import 'package:quran_learning_application/utils/text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../tutor_home_screen.dart';

// Safe Global Lock: Multiple native threads ko overlap hone se bachata hai
bool _globalFilePickerLock = false;

class TutorEditInfo extends StatefulWidget {
  const TutorEditInfo({super.key});

  @override
  State<TutorEditInfo> createState() => _TutorEditInfoState();
}

class _TutorEditInfoState extends State<TutorEditInfo> {
  File? _selectedAudioFile;
  String? _audioFileName;

  File? _selectedVideoFile;
  String? _videoFileName;

  final TextEditingController _hourlyRateController = TextEditingController();

  List<Map<String, dynamic>> _employments = [];
  List<Map<String, dynamic>> _certifications = [];

  bool _isLoading = false;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadExistingTutorData();
  }

  @override
  void dispose() {
    _hourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingTutorData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _supabase
          .from('tutors')
          .select('hourly_rate, employments, certifications')
          .eq('id', user.id)
          .single();

      if (data != null) {
        setState(() {
          _hourlyRateController.text = (data['hourly_rate'] ?? 0.0).toString();

          if (data['employments'] != null) {
            _employments = List<Map<String, dynamic>>.from(data['employments']);
          }
          if (data['certifications'] != null) {
            _certifications = List<Map<String, dynamic>>.from(data['certifications']);
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading tutor data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _checkPermission() async {
    if (!Platform.isAndroid) return true;

    // Android 13+ par Permission.audio check karega, purane devices par storage permission
    if (await Permission.audio.isGranted || await Permission.storage.isGranted) {
      return true;
    }

    Map<Permission, PermissionStatus> statuses = await [
      Permission.audio,
      Permission.storage,
    ].request();

    return statuses[Permission.audio] == PermissionStatus.granted ||
        statuses[Permission.storage] == PermissionStatus.granted;
  }

  Future<void> _pickAudio() async {
    if (_globalFilePickerLock) {
      debugPrint("Lock is active. Bypassing request.");
      return;
    }

    bool hasPermission = await _checkPermission();
    if (!hasPermission) {
      _showSnackBar("Audio files select karne ke liye permission zaroori hai!", Colors.orange);
      return;
    }

    setState(() {
      _globalFilePickerLock = true;
    });

    // Device framework cooldown delay
    await Future.delayed(const Duration(milliseconds: 250));

    try {
      // Custom extensions ke zariye Android native file-explorer ko target kar rahe hain
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedAudioFile = File(result.files.single.path!);
          _audioFileName = result.files.single.name;
        });
      }
    } on PlatformException catch (platErr) {
      debugPrint("Main picker failed on Android thread: ${platErr.message}");
      // Fallback dynamic file selection (In case file picker channel blocks)
      try {
        FilePickerResult? fallbackResult = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
        );
        if (fallbackResult != null && fallbackResult.files.single.path != null) {
          setState(() {
            _selectedAudioFile = File(fallbackResult.files.single.path!);
            _audioFileName = fallbackResult.files.single.name;
          });
        }
      } catch (innerErr) {
        debugPrint("Fallback audio selection also failed: $innerErr");
      }
    } catch (e) {
      debugPrint("Error Picking Audio: $e");
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _globalFilePickerLock = false;
        });
      }
    }
  }

  Future<void> _pickVideo() async {
    if (_globalFilePickerLock) {
      debugPrint("Lock active. Video picker is currently running.");
      return;
    }

    bool hasPermission = await _checkPermission();
    if (!hasPermission) {
      _showSnackBar("Video select karne ke liye permission zaroori hai!", Colors.orange);
      return;
    }

    setState(() {
      _globalFilePickerLock = true;
    });

    await Future.delayed(const Duration(milliseconds: 250));

    try {
      // ImagePicker gallery videos picking ke liye highly optimized aur bug-free hai
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        setState(() {
          _selectedVideoFile = File(video.path);
          _videoFileName = video.name;
        });
      }
    } catch (e) {
      debugPrint("Error Picking Video: $e");
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _globalFilePickerLock = false;
        });
      }
    }
  }

  void _showAddEmploymentDialog() {
    final companyController = TextEditingController();
    final roleController = TextEditingController();
    final durationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Add Employment", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: companyController,
                decoration: const InputDecoration(labelText: "Organization / School", hintText: "e.g. Al-Azhar Institute"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: roleController,
                decoration: const InputDecoration(labelText: "Role / Designation", hintText: "e.g. Quran Teacher"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(labelText: "Duration", hintText: "e.g. 2022 - 2024"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (companyController.text.isNotEmpty && roleController.text.isNotEmpty) {
                setState(() {
                  _employments.add({
                    "company": companyController.text.trim(),
                    "role": roleController.text.trim(),
                    "duration": durationController.text.trim(),
                  });
                });
                Navigator.pop(context);
              } else {
                _showSnackBar("Organization aur Role zaroori hain!", Colors.redAccent);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff0f766e)),
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _showAddCertificationDialog() {
    final titleController = TextEditingController();
    final issuerController = TextEditingController();
    final yearController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Add Certificate / Ijazah", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Certificate Title", hintText: "e.g. Ijazah in Tajweed"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: issuerController,
                decoration: const InputDecoration(labelText: "Issued By", hintText: "e.g. Wifaq-ul-Madaris"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Year of Passing", hintText: "e.g. 2023"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && issuerController.text.isNotEmpty) {
                setState(() {
                  _certifications.add({
                    "title": titleController.text.trim(),
                    "issuer": issuerController.text.trim(),
                    "year": yearController.text.trim(),
                  });
                });
                Navigator.pop(context);
              } else {
                _showSnackBar("Title aur Issuer zaroori hain!", Colors.redAccent);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff0f766e)),
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<String?> _uploadFileToBucket(File file, String name, String folder) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = name.split('.').last;
      final uploadPath = '$folder/$timestamp.$fileExtension';

      await _supabase.storage.from('tutor-assets').upload(
        uploadPath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      return _supabase.storage.from('tutor-assets').getPublicUrl(uploadPath);
    } catch (e) {
      debugPrint("Upload Error in $folder: $e");
      return null;
    }
  }

  Future<void> _saveChangesToSupabase() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _showSnackBar("User logged in nahi hai!", Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? audioUrl;
      String? videoUrl;

      if (_selectedAudioFile != null && _audioFileName != null) {
        audioUrl = await _uploadFileToBucket(_selectedAudioFile!, _audioFileName!, 'audios');
      }

      if (_selectedVideoFile != null && _videoFileName != null) {
        videoUrl = await _uploadFileToBucket(_selectedVideoFile!, _videoFileName!, 'videos');
      }

      final Map<String, dynamic> updateData = {
        'hourly_rate': double.tryParse(_hourlyRateController.text) ?? 0.0,
        'employments': _employments,
        'certifications': _certifications,
      };

      if (audioUrl != null) {
        updateData['recitation_audio_url'] = audioUrl;
      }
      if (videoUrl != null) {
        updateData['recitation_video_url'] = videoUrl;
      }

      await _supabase
          .from('tutors')
          .update(updateData)
          .eq('id', user.id);

      _showSnackBar("Profile successfully updated! 🎉", Colors.green);

      setState(() {
        _selectedAudioFile = null;
        _audioFileName = null;
        _selectedVideoFile = null;
        _videoFileName = null;
      });

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TutorHomeScreen()));
      }

    } catch (e) {
      debugPrint("Database Update Error: $e");
      _showSnackBar("Save fails: $e", Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String text, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: bgColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xff0f766e);

    return Scaffold(
      backgroundColor: const Color(0xffd2dad2),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TutorHomeScreen()));
          },
        ),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        title: const Text(
          "Edit Profile Info",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading && _employments.isEmpty && _certifications.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xff0f766e)))
          : SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TextWidget(text: "Hourly Fee (\$ )"),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _hourlyRateController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: "1.0",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                child: Text(
                  "Recitation Audio",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                ),
              ),
              InkWell(
                onTap: _isLoading ? null : _pickAudio,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _selectedAudioFile != null ? themeColor.withOpacity(0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedAudioFile != null ? themeColor : Colors.grey[300]!,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: _selectedAudioFile != null ? themeColor : Colors.grey[100],
                        child: Icon(
                          Icons.audiotrack,
                          size: 28,
                          color: _selectedAudioFile != null ? Colors.white : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _audioFileName ?? "Tap To Choose Recitation Audio",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _audioFileName != null ? FontWeight.w600 : FontWeight.w500,
                          color: _audioFileName != null ? Colors.black87 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                child: Text(
                  "Recitation Video",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                ),
              ),
              InkWell(
                onTap: _isLoading ? null : _pickVideo,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _selectedVideoFile != null ? themeColor.withOpacity(0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedVideoFile != null ? themeColor : Colors.grey[300]!,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: _selectedVideoFile != null ? themeColor : Colors.grey[100],
                        child: Icon(
                          Icons.video_file,
                          size: 28,
                          color: _selectedVideoFile != null ? Colors.white : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _videoFileName ?? "Tap To Choose Recitation Video",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _videoFileName != null ? FontWeight.w600 : FontWeight.w500,
                          color: _videoFileName != null ? Colors.black87 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: themeColor.withOpacity(0.5)),
                ),
                child: ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  leading: Icon(Icons.business_center_outlined, color: themeColor),
                  title: const Text("Employment History", style: TextStyle(fontWeight: FontWeight.w500)),
                  children: [
                    if (_employments.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _employments.length,
                        itemBuilder: (context, index) {
                          final item = _employments[index];
                          return ListTile(
                            title: Text("${item['role']} at ${item['company']}", style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(item['duration'] ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _employments.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Center(
                        child: _employments.isEmpty ? const Text("No Employment History Found!") : null,
                      ),
                    ),
                    TextButton(
                      onPressed: _showAddEmploymentDialog,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 18, color: themeColor),
                          const SizedBox(width: 4),
                          TextWidget(text: "Add Employment", textColor: themeColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: themeColor.withOpacity(0.5)),
                ),
                child: ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  leading: Icon(Icons.verified_outlined, color: themeColor),
                  title: const Text("Certifications / Ijazah", style: TextStyle(fontWeight: FontWeight.w500)),
                  children: [
                    if (_certifications.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _certifications.length,
                        itemBuilder: (context, index) {
                          final item = _certifications[index];
                          return ListTile(
                            title: Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text("By ${item['issuer']} (${item['year']})"),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _certifications.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Center(
                        child: _certifications.isEmpty ? const Text("No Certification Found!") : null,
                      ),
                    ),
                    TextButton(
                      onPressed: _showAddCertificationDialog,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 18, color: themeColor),
                          const SizedBox(width: 4),
                          TextWidget(text: "Add Certification", textColor: themeColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChangesToSupabase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0f766e),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[500],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 20),
                      SizedBox(width: 8),
                      Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}