import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:quran_learning_application/utils/text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/auth_field.dart';

class TutorEditInfo extends StatefulWidget {
  const TutorEditInfo({super.key});

  @override
  State<TutorEditInfo> createState() => _TutorEditInfoState();
}

class _TutorEditInfoState extends State<TutorEditInfo> {
  File? _selectedAudioFile;
  String? _audioFileName;
  bool _isUploading = false;

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> _pickAudio() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'aac'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedAudioFile = File(result.files.single.path!);
          _audioFileName = result.files.single.name;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected: $_audioFileName'),
            backgroundColor: const Color(0xff0f766e),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error Picking Audio File: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Picker Error: $e. Please allow media permissions."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _uploadAudioToSupabase() async {
    if (_selectedAudioFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pehle koi audio file select karein!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = _audioFileName!.split('.').last;
      final uploadPath = 'audios/$timestamp.$fileExtension';

      await _supabase.storage.from('audio-uploads').upload(
        uploadPath,
        _selectedAudioFile!,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
        ),
      );

      final String publicUrl = _supabase.storage.from('audio-uploads').getPublicUrl(uploadPath);
      debugPrint("File uploaded successfully! URL: $publicUrl");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Audio successfully save ho gaya! 🎉"),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _selectedAudioFile = null;
        _audioFileName = null;
      });
    } catch (e) {
      debugPrint("Supabase Upload Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Upload failed: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xff0f766e);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        title: const Text(
          "Edit Profile Info",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
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
                    TextWidget(text: "Hourly Fee"),
                    const SizedBox(height: 10),
                    AuthField(authFieldText: "1.0"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
              child: Text(
                "Voice Introduction Sample",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),

            InkWell(
              onTap: _isUploading ? null : _pickAudio,
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
                        _selectedAudioFile != null ? Icons.audiotrack : Icons.mic_none_rounded,
                        size: 28,
                        color: _selectedAudioFile != null ? Colors.white : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _audioFileName ?? "Tap to choose audio file",
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
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_isUploading || _selectedAudioFile == null) ? null : _uploadAudioToSupabase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff16a34a),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[500],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isUploading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Save Changes",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}