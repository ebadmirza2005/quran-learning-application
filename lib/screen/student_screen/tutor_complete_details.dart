import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart' as ja;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../utils/button.dart';
import '../../utils/drop_down_widget.dart';
import '../../utils/text.dart';
import 'package:intl/intl.dart';

import '../teacher_screen/tutor_book_slot.dart';
import '../tutor_home_screen.dart';

class TutorCompleteDetails extends StatefulWidget {
  final String tutorId;
  const TutorCompleteDetails({super.key, required this.tutorId});

  @override
  State<TutorCompleteDetails> createState() => _TutorCompleteDetailsState();
}

class _TutorCompleteDetailsState extends State<TutorCompleteDetails> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _certifications = [];
  List<Map<String, dynamic>> _employments = [];


  List<String> _tutorSkills = [];
  Map<String, bool> selectedSkills = {};

  String selectedDuration = "30 Minutes";
  String inviteStatus = "none";
  bool checkingInvite = true;

  RealtimeChannel? _inviteChannel;

  String makeDataSafe(dynamic rawData) {
    if (rawData == null) return '-';
    if (rawData is List) {
      return rawData.isNotEmpty ? rawData.join(', ') : '-';
    }
    String str = rawData.toString().trim();
    return str.isNotEmpty ? str : '-';
  }

  String _currentTutorName = '';
  double _hourlyRate = 0.00;

  String _formatDateString(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return '';
    try {
      DateTime parsedDate = DateTime.parse(rawDate);
      const List<String> monthNames = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
      ];
      return "${monthNames[parsedDate.month - 1]} ${parsedDate.year}";
    } catch (_) {
      return rawDate;
    }
  }

  String? _getValidImageUrl(Map<String, dynamic> item) {
    dynamic rawUrl = item['image_url'] ??
        item['certificate_image'] ??
        item['certificate_url'] ??
        item['image'] ??
        item['document_url'] ??
        item['url'];

    if (rawUrl == null) return null;
    String urlStr = rawUrl.toString().trim();
    if (urlStr.isEmpty) return null;

    if (urlStr.startsWith('http://') || urlStr.startsWith('https://')) {
      return urlStr;
    }

    try {
      return supabase.storage.from('certifications').getPublicUrl(urlStr);
    } catch (_) {
      return urlStr;
    }
  }

  void _showCertificateImageDialog(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("Unable to load image"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _getTutorData() async {
    final tutorData = await supabase
        .from('tutors')
        .select()
        .eq('id', widget.tutorId)
        .maybeSingle();

    if (tutorData == null) {
      throw Exception("Tutor Details Not Found For ID: ${widget.tutorId}");
    }

    _hourlyRate = (tutorData['hourly_rate'] as num?)?.toDouble() ?? 0.0;

    _currentTutorName = tutorData['name']?.toString().trim().isNotEmpty == true
        ? tutorData['name'].toString()
        : 'Unknown Tutor';

    if (tutorData['skills'] != null) {
      if (tutorData['skills'] is List) {
        _tutorSkills = List<String>.from(tutorData['skills'].map((item) => item.toString()));
      } else if (tutorData['skills'] is String) {
        _tutorSkills = (tutorData['skills'] as String)
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    try {
      final certsResponse = await supabase
          .from('tutor_certifications')
          .select()
          .eq('tutor_id', widget.tutorId);

      _certifications = List<Map<String, dynamic>>.from(certsResponse);
    } catch (e) {
      if (tutorData['certifications'] != null && tutorData['certifications'] is List) {
        _certifications = List<Map<String, dynamic>>.from(tutorData['certifications']);
      } else {
        _certifications = [];
      }
    }

    try {
      final empResponse = await supabase
          .from('tutor_employments')
          .select()
          .eq('tutor_id', widget.tutorId);

      _employments = List<Map<String, dynamic>>.from(empResponse);
    } catch (e) {
      if (tutorData['employments'] != null && tutorData['employments'] is List) {
        _employments = List<Map<String, dynamic>>.from(tutorData['employments']);
      } else {
        _employments = [];
      }
    }

    return tutorData;
  }



  @override
  void initState() {
    super.initState();
    _checkInviteStatus();
    _subscribeToInviteUpdates();
  }

  @override
  void dispose() {
    if (_inviteChannel != null) {
      supabase.removeChannel(_inviteChannel!);
    }
    super.dispose();
  }

  void _subscribeToInviteUpdates() {
    final studentId = supabase.auth.currentUser?.id;
    if (studentId == null) return;

    _inviteChannel = supabase
        .channel('invite_status_${widget.tutorId}_$studentId')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'invites',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'tutor_id',
        value: widget.tutorId,
      ),
      callback: (payload) {
        final newRecord = payload.newRecord;
        final recordStudentId = newRecord['student_id']?.toString();

        if (recordStudentId == studentId) {
          final updatedStatus = newRecord['status']?.toString() ?? 'none';
          if (mounted) {
            setState(() {
              inviteStatus = updatedStatus;
            });
          }
        }
      },
    )
        .subscribe();
  }

  Future<void> _checkInviteStatus() async {
    final studentId = supabase.auth.currentUser?.id;

    if (studentId == null) {
      if (mounted) {
        setState(() {
          checkingInvite = false;
        });
      }
      return;
    }

    final response = await supabase
        .from('invites')
        .select('status')
        .eq('student_id', studentId)
        .eq('tutor_id', widget.tutorId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (!mounted) return;

    if (response != null) {
      setState(() {
        inviteStatus = response['status']?.toString() ?? "none";
      });
    } else {
      setState(() {
        inviteStatus = "none";
      });
    }

    setState(() {
      checkingInvite = false;
    });
  }

  String getInviteButtonText() {
    if (inviteStatus == "pending") {
      return "Hiring";
    }

    if (inviteStatus == "accepted") {
      return "Hired";
    }

    if (inviteStatus == "rejected") {
      return "Invite Again";
    }

    return "Invite To Teach";
  }

  void _showInviteDialog(BuildContext context) {

    for (var skill in _tutorSkills) {
      selectedSkills.putIfAbsent(skill, () => false);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            DateTime now = DateTime.now();
            String formattedDate = DateFormat("EEE, MMM d, yyyy").format(now);
            String formattedTime = DateFormat('hh:mm a').format(now);

            int getMinutesFromDuration(String duration) {
              switch (duration) {
                case "1 Hour":
                  return 60;
                case "1.5 Hours":
                  return 90;
                case "2 Hours":
                  return 120;
                case "30 Minutes":
                default:
                  return 30;
              }
            }

            int minutesToAdd = getMinutesFromDuration(selectedDuration);
            DateTime endTime = now.add(Duration(minutes: minutesToAdd, seconds: 30));
            String formattedEndTime = DateFormat('hh:mm a').format(endTime);

            Widget buildSkillItem(String skillName) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    activeColor: const Color(0xff0f766e),
                    value: selectedSkills[skillName] ?? false,
                    onChanged: (bool? value) {
                      setDialogState(() {
                        selectedSkills[skillName] = value ?? false;
                      });
                    },
                  ),
                  Flexible(child: TextWidget(text: skillName)),
                ],
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 5,
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidget(
                        text: "Contract of $_currentTutorName",
                        textSize: 20,
                        textWeight: FontWeight.bold,
                        textColor: const Color(0xff0f766e),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          TextWidget(text: "Date: ", textWeight: FontWeight.bold, textColor: const Color(0xff0f766e)),
                          const SizedBox(width: 3),
                          TextWidget(text: formattedDate),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          TextWidget(text: "Time: ", textWeight: FontWeight.bold, textColor: const Color(0xff0f766e)),
                          const SizedBox(width: 3),
                          TextWidget(text: formattedTime),
                          const SizedBox(width: 5),
                          TextWidget(text: "To"),
                          const SizedBox(width: 5),
                          TextWidget(text: formattedEndTime),
                        ],
                      ),
                      const SizedBox(height: 15),
                      TextWidget(text: "Duration Of Lesson", textWeight: FontWeight.bold, textColor: const Color(0xff0f766e)),
                      const SizedBox(height: 15),
                      DropdownWidget(
                        hintText: "Select Duration",
                        selectedValue: selectedDuration,
                        items: const ["30 Minutes", "1 Hour", "1.5 Hours", "2 Hours"],
                        onChanged: (newValue) {
                          setDialogState(() {
                            selectedDuration = newValue!;
                          });
                        },
                      ),
                      const SizedBox(height: 15),

                      if (_tutorSkills.isNotEmpty) ...[
                        TextWidget(
                          text: "What would you like to learn?",
                          textWeight: FontWeight.bold,
                          textColor: const Color(0xff0f766e),
                        ),
                        const SizedBox(height: 5),
                        for (int i = 0; i < _tutorSkills.length; i += 2) ...[
                          Row(
                            children: [
                              Expanded(child: buildSkillItem(_tutorSkills[i])),
                              const SizedBox(width: 10),
                              Expanded(
                                child: (i + 1 < _tutorSkills.length)
                                    ? buildSkillItem(_tutorSkills[i + 1])
                                    : const SizedBox(),
                              ),
                            ],
                          ),
                        ],
                        Row(
                          children: [
                            TextWidget(text: "Contract Rate: ", textWeight: FontWeight.bold, textColor: const Color(0xff0f766e)),
                            const SizedBox(width: 3),
                            TextWidget(text: _hourlyRate.toStringAsFixed(2)),
                            const SizedBox(width: 3),
                            TextWidget(text: "/", textSize: 23, textWeight: FontWeight.bold, textColor: const Color(0xff0f766e)),
                            const SizedBox(width: 3),
                            TextWidget(text: "hour"),
                          ],
                        )
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButtonWidget(
                              buttonText: "Cancel",
                              buttonColor: const Color(0xff0f766e),
                              textColor: Colors.white,
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButtonWidget(
                              buttonText: "Send Invite",
                              buttonColor: const Color(0xff0f766e),
                              textColor: Colors.white,
                              onTap: () => _sendInviteButton(),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _sendInviteButton() async {
    final currentStudentId = supabase.auth.currentUser?.id;
    if (currentStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to send an invite")),
      );
      return;
    }

    List<String> chosenSkills = selectedSkills.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();

    if (chosenSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one skill")),
      );
      return;
    }

    try {
      final existingInvite = await supabase
          .from('invites')
          .select('id')
          .eq('student_id', currentStudentId)
          .eq('tutor_id', widget.tutorId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (existingInvite != null) {
        await supabase.from('invites').update({
          'duration': selectedDuration,
          'selected_skills': chosenSkills,
          'hourly_rate': _hourlyRate,
          'status': 'pending',
        }).eq('id', existingInvite['id']);
      } else {
        await supabase.from('invites').insert({
          'tutor_id': widget.tutorId,
          'student_id': currentStudentId,
          'duration': selectedDuration,
          'selected_skills': chosenSkills,
          'hourly_rate': _hourlyRate,
          'status': 'pending',
        });
      }

      if (!mounted) return;

      setState(() {
        inviteStatus = "pending";
      });

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invitation sent successfully!"),
          backgroundColor: Color(0xff0f766e),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error sending invite: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isHiredOrHiring = (inviteStatus == "pending" || inviteStatus == "accepted");

    return Scaffold(
      backgroundColor: const Color(0xffd2dad2),
      appBar: AppBar(
        backgroundColor: const Color(0xff0f766e),
        foregroundColor: Colors.white,
        title: const Text("Tutor Profile"),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getTutorData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xff0f766e)),
            );
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  "Error Details:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No tutor data available"));
          }

          final tutorData = snapshot.data!;
          final String? profileImage = tutorData['profile_image']?.toString();
          final String tutorName = tutorData['name']?.toString() ?? 'Unknown Name';
          final String tutorCity = tutorData['city']?.toString() ?? 'Unknown City';
          final String tutorCountry = tutorData['country']?.toString() ?? 'Unknown Country';
          final String location = '$tutorCity, $tutorCountry';
          final double hourlyRate = (tutorData['hourly_rate'] as num? ?? 0.0).toDouble();
          final String languages = makeDataSafe(tutorData['languages']);
          final int tutorSessions = (tutorData['sessions'] as num?)?.toInt() ?? 0;
          final String? tutorVideo = tutorData['video_url']?.toString();
          final String? tutorAudio = tutorData['recitation_audio_url']?.toString();
          final String aboutTutor = (tutorData['about'] ?? tutorData['bio'])?.toString() ?? 'No bio provided.';

          return Column(
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xff0f766e),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white24,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: (profileImage != null && profileImage.isNotEmpty)
                            ? Image.network(
                          profileImage,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              size: 70,
                              color: Colors.white,
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            );
                          },
                        )
                            : const Icon(
                          Icons.person,
                          size: 70,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextWidget(
                      text: tutorName,
                      textSize: 22,
                      textWeight: FontWeight.bold,
                      textColor: Colors.white,
                    ),
                    TextWidget(
                      text: location,
                      textColor: Colors.white70,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            double rating = (tutorData['rating'] as num?)?.toDouble() ?? 0.0;
                            return Icon(
                              index < rating.floor()
                                  ? Icons.star
                                  : (index < rating ? Icons.star_half : Icons.star_border),
                              color: Colors.amber,
                              size: 20,
                            );
                          }),
                        ),
                        const SizedBox(width: 6),
                        Builder(
                          builder: (context) {
                            double ratingVal = (tutorData['rating'] as num?)?.toDouble() ?? 0.0;
                            int countVal = (tutorData['rating_count'] as num?)?.toInt() ?? 0;

                            return Text(
                              "${ratingVal.toStringAsFixed(1)} ($countVal)",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),

              // Details Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rate & Language Info Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        const TextSpan(text: "Per Hour : ", style: TextStyle(color: Colors.black)),
                                        TextSpan(
                                          text: "US\$${hourlyRate.toStringAsFixed(1)}",
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff0f766e)),
                                        )
                                      ],
                                    ),
                                  ),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        const TextSpan(text: "Sessions : ", style: TextStyle(color: Colors.black)),
                                        TextSpan(
                                          text: "$tutorSessions",
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff0f766e)),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    const TextSpan(text: "Languages : ", style: TextStyle(color: Colors.black)),
                                    TextSpan(
                                      text: languages,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff0f766e)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextWidget(
                        text: "Recitation Audio Of Tutor",
                        textSize: 18,
                        textWeight: FontWeight.bold,
                        textColor: const Color(0xff0f766e),
                      ),
                      const SizedBox(height: 10),
                      (tutorAudio != null && tutorAudio.trim().isNotEmpty)
                          ? TutorAudioPlayer(
                        key: ValueKey(tutorAudio),
                        tutorAudioUrl: tutorAudio,
                      )
                          : Container(
                        height: 80,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.audiotrack_outlined,
                              size: 30,
                              color: Colors.black38,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "No tutor audio found",
                              style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Video Player Section
                      TextWidget(
                        text: "Video Of Tutor",
                        textSize: 18,
                        textWeight: FontWeight.bold,
                        textColor: const Color(0xff0f766e),
                      ),
                      const SizedBox(height: 10),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: (tutorVideo != null && tutorVideo.trim().isNotEmpty)
                            ? TutorVideoPlayer(
                          key: ValueKey(tutorVideo),
                          tutorVideo: tutorVideo,
                          height: 300,
                        )
                            : Container(
                          height: 150,
                          width: double.infinity,
                          color: Colors.grey.shade300,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.videocam_off,
                                size: 45,
                                color: Colors.black38,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "No tutor video found",
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Employments Section
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          shape: const Border(),
                          collapsedShape: const Border(),
                          leading: const Icon(Icons.business_center_outlined, color: Color(0xff0f766e)),
                          title: const Text("Employments", style: TextStyle(fontWeight: FontWeight.w500)),
                          children: [
                            if (_employments.isNotEmpty)
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _employments.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final emp = _employments[index];
                                  final company = emp['company_name'] ?? emp['company'] ?? 'N/A';
                                  final role = emp['position'] ?? emp['role'] ?? 'N/A';
                                  final start = _formatDateString(emp['start_date']);
                                  final end = emp['is_current'] == true || emp['current'] == true
                                      ? 'Present'
                                      : _formatDateString(emp['end_date']);

                                  return ListTile(
                                    title: Text(role.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text("$company ($start - $end)"),
                                  );
                                },
                              )
                            else
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text("No employment history available.", style: TextStyle(color: Colors.grey)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Certifications Section
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          shape: const Border(),
                          collapsedShape: const Border(),
                          leading: const Icon(Icons.verified_outlined, color: Color(0xff0f766e)),
                          title: const Text("Certifications", style: TextStyle(fontWeight: FontWeight.w500)),
                          children: [
                            if (_certifications.isNotEmpty)
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _certifications.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final cert = _certifications[index];
                                  final title = cert['title'] ?? cert['certificate_name'] ?? 'Certificate';
                                  final institute = cert['issued_by'] ?? cert['institute'] ?? cert['organization'] ?? '';
                                  final imageUrl = _getValidImageUrl(cert);

                                  return ListTile(
                                    title: Text(title.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: institute.toString().isNotEmpty ? Text(institute.toString()) : null,
                                    trailing: imageUrl != null
                                        ? IconButton(
                                      icon: const Icon(Icons.image_outlined, color: Color(0xff0f766e)),
                                      onPressed: () => _showCertificateImageDialog(imageUrl, title.toString()),
                                    )
                                        : null,
                                  );
                                },
                              )
                            else
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text("No certifications available.", style: TextStyle(color: Colors.grey)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // About Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("About", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff0f766e))),
                            const SizedBox(height: 8),
                            Text(aboutTutor, style: const TextStyle(height: 1.4)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: isHiredOrHiring
            ? Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0f766e),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TutorBookSlot(
                          tutorId: widget.tutorId,
                          isAlreadyHired: true,
                        ),
                      ),
                    );
                    if (result == true) {
                      setState(() {});
                    }
                  },
                  child: const Text(
                    "Book Slot",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12,),
            Expanded(
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xff0f766e).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xff0f766e)),
                ),
                child: Text(
                  getInviteButtonText(),
                  style: const TextStyle(
                    color: Color(0xff0f766e),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        )
            : SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff0f766e),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TutorBookSlot(
                    tutorId: widget.tutorId,
                    isAlreadyHired: false,
                  ),
                ),
              );
              if (result == true) {
                setState(() {
                });
              }
            },
            child: checkingInvite
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Text(
              getInviteButtonText(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TutorAudioPlayer extends StatefulWidget {
  final String tutorAudioUrl;
  const TutorAudioPlayer({super.key, required this.tutorAudioUrl});

  @override
  State<TutorAudioPlayer> createState() => _TutorAudioPlayerState();
}

class _TutorAudioPlayerState extends State<TutorAudioPlayer> {
  final ja.AudioPlayer _audioPlayer = ja.AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = true;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setUrl(widget.tutorAudioUrl);
      _audioPlayer.durationStream.listen((d) {
        if (mounted && d != null) setState(() => _duration = d);
      });
      _audioPlayer.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            if (state.processingState == ja.ProcessingState.completed) {
              _position = Duration.zero;
              _audioPlayer.seek(Duration.zero);
              _audioPlayer.pause();
            }
          });
        }
      });
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Audio init error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              size: 40,
              color: const Color(0xff0f766e),
            ),
            onPressed: _isLoading
                ? null
                : () {
              if (_isPlaying) {
                _audioPlayer.pause();
              } else {
                _audioPlayer.play();
              }
            },
          ),
          Expanded(
            child: Slider(
              activeColor: const Color(0xff0f766e),
              inactiveColor: Colors.grey.shade300,
              min: 0.0,
              max: _duration.inMilliseconds.toDouble() > 0
                  ? _duration.inMilliseconds.toDouble()
                  : 1.0,
              value: _position.inMilliseconds.toDouble().clamp(
                0.0,
                _duration.inMilliseconds.toDouble() > 0
                    ? _duration.inMilliseconds.toDouble()
                    : 1.0,
              ),
              onChanged: (val) {
                _audioPlayer.seek(Duration(milliseconds: val.toInt()));
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Video Player Widget Helper
// ---------------------------------------------------------------------------
class TutorVideoPlayer extends StatefulWidget {
  final String tutorVideo;
  final double height;

  const TutorVideoPlayer({
    super.key,
    required this.tutorVideo,
    this.height = 250,
  });

  @override
  State<TutorVideoPlayer> createState() => _TutorVideoPlayerState();
}

class _TutorVideoPlayerState extends State<TutorVideoPlayer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.tutorVideo));
      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        autoPlay: false,
        looping: false,
        errorBuilder: (context, errorMessage) {
          return const Center(
            child: Text(
              "Error playing video",
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Video init error: $e");
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: widget.height,
        color: Colors.black12,
        child: const Center(child: Text("Could not load video")),
      );
    }

    if (_chewieController != null &&
        _chewieController!.videoPlayerController.value.isInitialized) {
      return SizedBox(
        height: widget.height,
        child: Chewie(controller: _chewieController!),
      );
    }

    return Container(
      height: widget.height,
      color: Colors.black12,
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xff0f766e)),
      ),
    );
  }
}