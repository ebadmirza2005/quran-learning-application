import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quran_learning_application/utils/text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../tutor_home_screen.dart';

// Safe Global Lock: Prevents multiple native threads from overlapping
bool _globalFilePickerLock = false;

class TutorEditInfo extends StatefulWidget {
  const TutorEditInfo({super.key});

  @override
  State<TutorEditInfo> createState() => _TutorEditInfoState();
}

class _TutorEditInfoState extends State<TutorEditInfo> {
  File? _selectedAudioFile;
  String? _audioFileName;
  String? _existingAudioUrl;

  File? _selectedVideoFile;
  String? _videoFileName;
  String? _existingVideoUrl;

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
          .select('hourly_rate, employments, certifications, recitation_audio_url, video_url')
          .eq('id', user.id)
          .single();

      if (data != null) {
        setState(() {
          _hourlyRateController.text = (data['hourly_rate'] ?? 0.0).toString();
          _existingAudioUrl = data['recitation_audio_url'];
          _existingVideoUrl = data['video_url'];

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
      _showSnackBar("Permission is required to select audio files!", Colors.orange);
      return;
    }

    setState(() {
      _globalFilePickerLock = true;
    });

    await Future.delayed(const Duration(milliseconds: 250));

    try {
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
      _showSnackBar("Permission is required to select videos!", Colors.orange);
      return;
    }

    setState(() {
      _globalFilePickerLock = true;
    });

    await Future.delayed(const Duration(milliseconds: 250));

    try {
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

  void _removeAudio() {
    setState(() {
      _selectedAudioFile = null;
      _audioFileName = null;
      _existingAudioUrl = null;
    });
    _showSnackBar("Audio removed", Colors.orange);
  }

  void _removeVideo() {
    setState(() {
      _selectedVideoFile = null;
      _videoFileName = null;
      _existingVideoUrl = null;
    });
    _showSnackBar("Video removed", Colors.orange);
  }

  void _showAddEmploymentDialog() {
    final companyController = TextEditingController();

    DateTime? startDate;
    DateTime? endDate;
    bool isCurrentlyWorking = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> selectDate(BuildContext context, bool isStart) async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1970),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xff0f766e),
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (picked != null) {
                setDialogState(() {
                  if (isStart) {
                    startDate = picked;
                    if (endDate != null && startDate!.isAfter(endDate!)) {
                      endDate = null;
                    }
                  } else {
                    endDate = picked;
                  }
                });
              }
            }

            String formatDate(DateTime? date) {
              if (date == null) return "Select Date";
              return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Add Employment", style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: companyController,
                      decoration: const InputDecoration(
                        labelText: "Employer Name *",
                        hintText: "e.g. Al-Azhar Institute",
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "From Date *",
                                style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () => selectDate(context, true),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          formatDate(startDate),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: startDate == null ? Colors.grey : Colors.black87,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(Icons.calendar_today, size: 16, color: Color(0xff0f766e)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isCurrentlyWorking) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "To Date *",
                                  style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () => selectDate(context, false),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade400),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            formatDate(endDate),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: endDate == null ? Colors.grey : Colors.black87,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(Icons.calendar_today, size: 16, color: Color(0xff0f766e)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Checkbox(
                          value: isCurrentlyWorking,
                          activeColor: const Color(0xff0f766e),
                          onChanged: (val) {
                            setDialogState(() {
                              isCurrentlyWorking = val ?? false;
                              if (isCurrentlyWorking) {
                                endDate = null;
                              }
                            });
                          },
                        ),
                        const Text(
                          "I currently work here (Present)",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
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
                    if (companyController.text.trim().isEmpty) {
                      _showSnackBar("Employer Name is required!", Colors.redAccent);
                      return;
                    }
                    if (startDate == null) {
                      _showSnackBar("Please select From Date!", Colors.redAccent);
                      return;
                    }
                    if (!isCurrentlyWorking && endDate == null) {
                      _showSnackBar("Please select To Date or check 'Present'!", Colors.redAccent);
                      return;
                    }

                    const List<String> monthNames = [
                      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
                      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
                    ];

                    String fromStr = "${startDate!.day} ${monthNames[startDate!.month - 1]} ${startDate!.year}";
                    String toStr = isCurrentlyWorking
                        ? "Present"
                        : "${endDate!.day} ${monthNames[endDate!.month - 1]} ${endDate!.year}";

                    String durationStr = "$fromStr - $toStr";

                    setState(() {
                      _employments.add({
                        "company": companyController.text.trim(),
                        "duration": durationStr,
                        "start_date": startDate!.toIso8601String(),
                        "end_date": isCurrentlyWorking ? null : endDate?.toIso8601String(),
                        "is_present": isCurrentlyWorking,
                      });
                    });

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff0f766e)),
                  child: const Text("Add", style: TextStyle(color: Colors.white)),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _showAddCertificationDialog() {
    final titleController = TextEditingController();
    final issuerController = TextEditingController();
    final yearController = TextEditingController();
    File? certImage;
    final detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickCertImage() async {
              final ImagePicker picker = ImagePicker();
              final XFile? image = await picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 85,
              );
              if (image != null) {
                setDialogState(() {
                  certImage = File(image.path);
                });
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Add Certificate / Ijazah", style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "Title",
                        hintText: "e.g. Ijazah in Tajweed",
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xff0f766e)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: issuerController,
                      decoration: const InputDecoration(
                        labelText: "Issued By",
                        hintText: "e.g. Faaz-Al-Quran",
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xff0f766e)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: yearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Year of Passing",
                        hintText: "e.g. 2026",
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xff0f766e)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    InkWell(
                      onTap: pickCertImage,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 110,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: certImage != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(certImage!, fit: BoxFit.cover),
                        )
                            : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, color: Color(0xff0f766e), size: 30),
                            SizedBox(height: 6),
                            Text("Select Certificate Image", style: TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: detailsController,
                      minLines: 3,
                      maxLines: null,
                      decoration: const InputDecoration(
                        labelText: "Details",
                        hintText: "Enter details here...",
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xff0f766e)),
                        ),
                      ),
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
                          "local_image": certImage,
                          "details": detailsController.text.trim()
                        });
                      });
                      Navigator.pop(context);
                    } else {
                      _showSnackBar("Title and Issuer are required!", Colors.redAccent);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff0f766e)),
                  child: const Text("Add", style: TextStyle(color: Colors.white)),
                )
              ],
            );
          },
        );
      },
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
      _showSnackBar("User is not logged in!", Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? audioUrl = _existingAudioUrl;
      String? videoUrl = _existingVideoUrl;

      if (_selectedAudioFile != null && _audioFileName != null) {
        audioUrl = await _uploadFileToBucket(_selectedAudioFile!, _audioFileName!, 'audios');
      }

      if (_selectedVideoFile != null && _videoFileName != null) {
        videoUrl = await _uploadFileToBucket(_selectedVideoFile!, _videoFileName!, 'videos');
      }

      List<Map<String, dynamic>> processedCertifications = [];
      for (var cert in _certifications) {
        Map<String, dynamic> certMap = Map<String, dynamic>.from(cert);

        if (certMap['local_image'] != null && certMap['local_image'] is File) {
          File localImg = certMap['local_image'];
          String? imgUrl = await _uploadFileToBucket(
            localImg,
            'cert_${DateTime.now().millisecondsSinceEpoch}.jpg',
            'certifications',
          );
          if (imgUrl != null) {
            certMap['certificate_image'] = imgUrl;
          }
        }
        certMap.remove('local_image');
        processedCertifications.add(certMap);
      }

      final Map<String, dynamic> updateData = {
        'hourly_rate': double.tryParse(_hourlyRateController.text) ?? 0.0,
        'employments': _employments,
        'certifications': processedCertifications,
        'recitation_audio_url': audioUrl, // Saves null if removed
        'video_url': videoUrl, // Saves null if removed
      };

      await _supabase.from('tutors').update(updateData).eq('id', user.id);

      _showSnackBar("Profile successfully updated! 🎉", const Color(0xff0f766e));

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TutorHomeScreen()));
      }
    } catch (e) {
      debugPrint("Database Update Error: $e");
      _showSnackBar("Save failed: $e", Colors.redAccent);
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
    const themeColor = Color(0xff0f766e);

    final bool hasAudio = _selectedAudioFile != null || (_existingAudioUrl != null && _existingAudioUrl!.isNotEmpty);
    final bool hasVideo = _selectedVideoFile != null || (_existingVideoUrl != null && _existingVideoUrl!.isNotEmpty);

    return Scaffold(
      backgroundColor: const Color(0xffd2dad2),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const TutorHomeScreen()), (Route route) => false);
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: themeColor))
          : SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TextWidget(
                    text: "Hourly Rate (\$ ) *",
                    textColor: themeColor,
                    textWeight: FontWeight.bold,
                  ),
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
              const SizedBox(height: 16),

              // Recitation Audio Field
              const Padding(
                padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
                child: TextWidget(
                  text: "Audio Of Recitation",
                  textColor: themeColor,
                  textWeight: FontWeight.bold,
                ),
              ),
              Stack(
                children: [
                  InkWell(
                    onTap: _isLoading ? null : _pickAudio,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasAudio ? themeColor : Colors.black26,
                          width: 2.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: hasAudio ? themeColor : Colors.grey[100],
                            child: Icon(
                              Icons.audiotrack,
                              size: 28,
                              color: hasAudio ? Colors.white : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _audioFileName ??
                                (_existingAudioUrl != null
                                    ? "Audio File Uploaded (Tap to change)"
                                    : "Tap To Choose Recitation Audio"),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: hasAudio ? FontWeight.w600 : FontWeight.w500,
                              color: hasAudio ? Colors.black87 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (hasAudio)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 26),
                        onPressed: _removeAudio,
                        tooltip: "Remove Audio",
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Tutor Video Field
              const Padding(
                padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
                child: TextWidget(
                  text: "Video Of Tutor",
                  textColor: themeColor,
                  textWeight: FontWeight.bold,
                ),
              ),
              Stack(
                children: [
                  InkWell(
                    onTap: _isLoading ? null : _pickVideo,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasVideo ? themeColor : Colors.black26,
                          width: 2.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: hasVideo ? themeColor : Colors.grey[100],
                            child: Icon(
                              Icons.video_file,
                              size: 28,
                              color: hasVideo ? Colors.white : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _videoFileName ??
                                (_existingVideoUrl != null
                                    ? "Video File Uploaded (Tap to change)"
                                    : "Tap To Choose Recitation Video"),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: hasVideo ? FontWeight.w600 : FontWeight.w500,
                              color: hasVideo ? Colors.black87 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (hasVideo)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 26),
                        onPressed: _removeVideo,
                        tooltip: "Remove Video",
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Employment History Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const TextWidget(
                    text: "Employment History",
                    textColor: themeColor,
                    textWeight: FontWeight.bold,
                  ),
                  IconButton(
                    onPressed: _showAddEmploymentDialog,
                    icon: const Icon(Icons.add_circle, color: themeColor, size: 28),
                  ),
                ],
              ),
              if (_employments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text("No employments added yet.", style: TextStyle(color: Colors.black54)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _employments.length,
                  itemBuilder: (context, index) {
                    final item = _employments[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(item['company'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(item['duration'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () {
                            setState(() {
                              _employments.removeAt(index);
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),

              // Certifications Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const TextWidget(
                    text: "Certifications / Ijazah",
                    textColor: themeColor,
                    textWeight: FontWeight.bold,
                  ),
                  IconButton(
                    onPressed: _showAddCertificationDialog,
                    icon: const Icon(Icons.add_circle, color: themeColor, size: 28),
                  ),
                ],
              ),
              if (_certifications.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text("No certifications added yet.", style: TextStyle(color: Colors.black54)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _certifications.length,
                  itemBuilder: (context, index) {
                    final item = _certifications[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: item['local_image'] != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(item['local_image'], width: 40, height: 40, fit: BoxFit.cover),
                        )
                            : (item['certificate_image'] != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(item['certificate_image'], width: 40, height: 40, fit: BoxFit.cover),
                        )
                            : const Icon(Icons.workspace_premium, color: themeColor, size: 32)),
                        title: Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${item['issuer'] ?? ''} ${item['year'] != null ? '(${item['year']})' : ''}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () {
                            setState(() {
                              _certifications.removeAt(index);
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChangesToSupabase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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