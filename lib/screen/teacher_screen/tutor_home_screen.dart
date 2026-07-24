import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/button.dart';
import '../../utils/text.dart';
import 'tutor_call_screen.dart';
import 'tutor_chat_screen.dart';
import 'tutor_edit_info.dart';
import 'tutor_test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController tabController;
  final supabase = Supabase.instance.client;
  RealtimeChannel? _callChannel;


  String _verificationStatus = 'unverified';
  bool _isLoadingStatus = true;

  double _profileCompletionPercentage = 0.0;
  List<String> _missingProfileFields = [];


  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    _fetchTutorData();
    _listenForIncomingCalls();
  }

  void _listenForIncomingCalls() {
    final tutorUser = Supabase.instance.client.auth.currentUser;
    if (tutorUser == null) return;

    _callChannel = Supabase.instance.client
        .channel('incoming_calls_${tutorUser.id}')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert, // Nayi call aane par
      schema: 'public',
      table: 'calls',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'receiver_id',
        value: tutorUser.id,
      ),
      callback: (payload) {
        final newRecord = payload.newRecord;

        // Check karein ke status calling hai ya nahi
        if (newRecord['status'] == 'calling' && mounted) {
          final channelId = newRecord['channel_id']?.toString() ?? '';
          final callerName = newRecord['caller_name']?.toString() ?? 'Student';
          final callId = newRecord['id']?.toString() ?? '';

          _showIncomingCallDialog(
            context: context,
            channelId: channelId,
            callerName: callerName,
            callId: callId,
          );
        }
      },
    )
        .subscribe();
  }

  Future<void> _fetchTutorData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoadingStatus = false;
          });
        }
        return;
      }

      final data = await supabase
          .from('tutors')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && mounted) {
        String status = (data['verification_status'] ?? 'unverified').toString();

        _calculateProfileCompletion(data);

        setState(() {
          _verificationStatus = status;
        });

        final prefs = await SharedPreferences.getInstance();

        if (status == 'verified' && mounted) {
          bool hasShownVerifiedPopup = prefs.getBool('has_shown_verified_dialog_${user.id}') ?? false;
          if (!hasShownVerifiedPopup) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (mounted) {
                _showVerifiedDialog(context);
                await prefs.setBool('has_shown_verified_dialog_${user.id}', true);
              }
            });
          }
        } else if (status == 'failed' && mounted) {
          bool hasShownFailedPopup = prefs.getBool('has_shown_failed_dialog_${user.id}') ?? false;
          if (!hasShownFailedPopup) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (mounted) {
                _showFailedDialog(context);
                await prefs.setBool('has_shown_failed_dialog_${user.id}', true);
              }
            });
          }
        }
      }
    } on AuthException catch (e) {
      debugPrint("Supabase Auth Error: ${e.message}");
    } catch (e) {
      debugPrint("Error fetching tutor data: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStatus = false;
        });
      }
    }
  }

  void _showIncomingCallDialog({
    required BuildContext context,
    required String channelId,
    required String callerName,
    required String callId,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) { // 👈 Renamed to dialogContext to avoid shadow conflict
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.call, color: Color(0xff0f766e)),
              SizedBox(width: 8),
              Text("Incoming Call"),
            ],
          ),
          content: Text(
            "$callerName is calling you...",
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            // ❌ DECLINE BUTTON
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await Supabase.instance.client
                    .from('calls')
                    .update({'status': 'rejected'})
                    .eq('id', callId);
              },
              child: const Text("Decline", style: TextStyle(color: Colors.red)),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0f766e),
              ),
              onPressed: () async {
                // 1. Dialog ko pehle close karein safely
                Navigator.of(dialogContext).pop();

                // 2. Database mein call status update karein
                try {
                  await Supabase.instance.client
                      .from('calls')
                      .update({'status': 'accepted'})
                      .eq('id', callId);
                } catch (e) {
                  debugPrint("Error updating call status: $e");
                }

                // 3. Main context use karke Call Screen par Navigate karein
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TutorCallScreen(
                        channelId: channelId,
                        receiverName: callerName,
                      ),
                    ),
                  );
                }
              },
              child: const Text("Accept", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _calculateProfileCompletion(Map<String, dynamic> data) {
    int totalSteps = 4;
    int completedSteps = 0;
    List<String> missing = [];

    final profileImg = data['profile_image'] ?? data['profile_image_url'] ?? data['avatar_url'];
    if (profileImg != null && profileImg.toString().trim().isNotEmpty) {
      completedSteps++;
    } else {
      missing.add("Profile Picture");
    }

    final bioText = data['bio'] ?? data['about'];
    if (bioText != null && bioText.toString().trim().isNotEmpty) {
      completedSteps++;
    } else {
      missing.add("Bio/About");
    }

    final hourlyRate = data['hourly_rate'];
    if (hourlyRate != null && (num.tryParse(hourlyRate.toString()) ?? 0) > 0) {
      completedSteps++;
    } else {
      missing.add("Hourly Rate");
    }

    final audioUrl = data['recitation_audio_url'];
    final videoUrl = data['recitation_video_url'];
    if ((audioUrl != null && audioUrl.toString().trim().isNotEmpty) ||
        (videoUrl != null && videoUrl.toString().trim().isNotEmpty)) {
      completedSteps++;
    } else {
      missing.add("Audio/Video Sample");
    }

    if (mounted) {
      setState(() {
        _profileCompletionPercentage = completedSteps / totalSteps;
        _missingProfileFields = missing;
      });
    }
  }

  void _showVerifiedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 5,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xff0f766e).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Color(0xff0f766e),
                    size: 50,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Profile Verified! 🎉",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff0f766e),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Congratulations! Your profile is verified. Students can now view your profile and send teaching requests.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0f766e),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Got It",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFailedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 5,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cancel_rounded,
                    color: Colors.redAccent,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Test Not Passed ❌",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Unfortunately, you did not meet the passing criteria. Your profile is currently hidden from students. You can retake the test.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Try Again",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    if (_callChannel != null) {
      Supabase.instance.client.removeChannel(_callChannel!); // Clean up
    }
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffd2dad2),
      appBar: AppBar(
        backgroundColor: const Color(0xff0f766e),
        foregroundColor: Colors.white,
        title: const Text("Classroom"),
        centerTitle: true,
        bottom: TabBar(
          controller: tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black,
          tabs: const [
            Tab(text: "My Students"),
            Tab(text: "Invites"),
          ],
        ),
      ),
      body: Column(
        children: [
          if (!_isLoadingStatus) ...[
            if (_verificationStatus == 'verified' && _profileCompletionPercentage < 1.0)
              Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 4.0),
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TutorEditInfo()),
                    );
                    _fetchTutorData();
                  },
                  child: Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: _buildProfileCompletionCard(),
                  ),
                ),
              ),

            if (_verificationStatus != 'verified')
              Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 12.0),
                child: Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: _buildVerificationCard(),
                ),
              ),
          ],
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: const [
                StudentsTabWidget(),
                InvitesTabWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCompletionCard() {
    int percentage = (_profileCompletionPercentage * 100).toInt();

    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Profile Completion",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff0f766e)),
              ),
              Text(
                "$percentage%",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff0f766e)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _profileCompletionPercentage,
            backgroundColor: Colors.grey.shade300,
            color: const Color(0xff0f766e),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard() {
    if (_verificationStatus == 'pending') {
      return Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            TextWidget(
              text: "⏳ Your screening test has been submitted and is currently under review. Results will be updated within 2 hours.",
            ),
            const SizedBox(height: 14),
            ElevatedButtonWidget(
              buttonText: "Under Review",
              buttonColor: Colors.grey,
              textColor: Colors.white,
              onTap: null,
            ),
          ],
        ),
      );
    } else if (_verificationStatus == 'failed') {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(14.0),
            child: TextWidget(
              text: "❌ You did not pass the screening test. Your profile is not visible to students. You can retake the test now.",
            ),
          ),
          ElevatedButtonWidget(
            buttonText: "Retake Test",
            buttonColor: Colors.redAccent,
            textColor: Colors.white,
            onTap: () async {
              final user = supabase.auth.currentUser;
              if (user != null) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('has_shown_failed_dialog_${user.id}');
              }
              if (mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TutorTestScreen()),
                );
                _fetchTutorData();
              }
            },
          ),
          const SizedBox(height: 14),
        ],
      );
    } else {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: TextWidget(
              text: "🔒 A minimum score of 50% (8/15 correct answers) is required to verify your profile. If you fail, your profile will not be visible to students, but you can retake the test for free after a 1-hour cooldown.",
            ),
          ),
          ElevatedButtonWidget(
            buttonText: "Start Test",
            buttonColor: const Color(0xff0f766e),
            textColor: Colors.white,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TutorTestScreen()),
              );
              _fetchTutorData();
            },
          ),
          const SizedBox(height: 14),
        ],
      );
    }
  }
}

class InvitesTabWidget extends StatefulWidget {
  const InvitesTabWidget({super.key});

  @override
  State<InvitesTabWidget> createState() => _InvitesTabWidgetState();
}

class _InvitesTabWidgetState extends State<InvitesTabWidget> {
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _invitesFuture;
  RealtimeChannel? _inviteChannel;

  @override
  void initState() {
    super.initState();
    _loadInvites();
    _subscribeToInviteChanges();
  }

  @override
  void dispose() {
    if (_inviteChannel != null) {
      supabase.removeChannel(_inviteChannel!);
    }
    super.dispose();
  }

  void _subscribeToInviteChanges() {
    final tutorId = supabase.auth.currentUser?.id;
    if (tutorId == null) return;

    _inviteChannel = supabase
        .channel('invites_tab_$tutorId')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'invites',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'tutor_id',
        value: tutorId,
      ),
      callback: (payload) {
        if (mounted) {
          setState(() {
            _loadInvites();
          });
        }
      },
    )
        .subscribe();
  }

  void _loadInvites() {
    final tutorId = supabase.auth.currentUser?.id;
    if (tutorId != null) {
      _invitesFuture = _fetchInvitesWithStudentProfiles(tutorId);
    } else {
      _invitesFuture = Future.value([]);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchInvitesWithStudentProfiles(String tutorId) async {
    final List<dynamic> response = await supabase
        .from('invites')
        .select('*')
        .eq('tutor_id', tutorId)
        .neq('status', 'accepted')
        .order('created_at', ascending: false);

    List<Map<String, dynamic>> invites = List<Map<String, dynamic>>.from(response);

    for (var invite in invites) {
      debugPrint("INVITE RECORD: $invite");

      final studentId = invite['student_id'] ??
          invite['sender_id'] ??
          invite['user_id'] ??
          invite['studentId'];

      if (studentId != null) {
        try {
          final studentData = await supabase
              .from('students')
              .select('*')
              .eq('id', studentId)
              .maybeSingle();

          if (studentData != null) {
            debugPrint("FETCHED STUDENT DATA: $studentData");
            invite['student_profile'] = studentData;
          } else {
            debugPrint("No student found in 'students' table with ID: $studentId");
          }
        } catch (e) {
          debugPrint("Error fetching student details: $e");
        }
      } else {
        debugPrint("No student_id column found in invite record!");
      }
    }

    return invites;
  }

  @override
  Widget build(BuildContext context) {
    final tutorId = supabase.auth.currentUser?.id;

    if (tutorId == null) {
      return const Center(child: Text("User not logged in."));
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _invitesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xff0f766e)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading invites: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final invites = snapshot.data ?? [];

        if (invites.isEmpty) {
          return const Center(
            child: Text(
              "No Invitation Found!",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (mounted) {
              setState(() {
                _loadInvites();
              });
            }
          },
          color: const Color(0xff0f766e),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: invites.length,
            itemBuilder: (context, index) {
              final invite = invites[index];

              final studentProfile = invite['student_profile'] as Map<String, dynamic>?;

              final String studentName =
                  studentProfile?['name']?.toString() ??
                      studentProfile?['full_name']?.toString() ??
                      studentProfile?['student_name']?.toString() ??
                      studentProfile?['username']?.toString() ??
                      studentProfile?['email']?.toString() ??
                      invite['student_name']?.toString() ??
                      invite['name']?.toString() ??
                      'Unknown Student';

              final List<dynamic> skills = invite['selected_skills'] ?? [];
              final String duration = invite['duration']?.toString() ?? 'N/A';
              final String status = invite['status']?.toString() ?? 'pending';
              final double rate = (invite['hourly_rate'] as num? ?? 0.0).toDouble();

              return Card(
                color: Colors.white,
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const TextWidget(
                                text: "Student: ",
                                textWeight: FontWeight.bold,
                                textColor: Color(0xff0f766e),
                              ),
                              SizedBox(width: 8,),
                              TextWidget(
                                text: studentName,
                                textWeight: FontWeight.w600,
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: status == 'pending'
                                  ? Color(0xff0f766e).withOpacity(0.15)
                                  : Color(0xffeb5757).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: status == 'pending'
                                    ? Color(0xff0f766e).withOpacity(0.8)
                                    : Color(0xffeb5757).withOpacity(0.8),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          TextWidget(text: "Duration: ", textWeight: FontWeight.bold, textColor: Color(0xff0f766e),),
                          SizedBox(width: 4,),
                          TextWidget(text: duration, textWeight: FontWeight.w600),
                        ],
                      ),
                      const SizedBox(height: 10),
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: "Skills: ",
                              style: TextStyle(color: Color(0xff0f766e), fontWeight: FontWeight.bold),
                            ),
                            WidgetSpan(child: SizedBox(width: 6,)),
                            TextSpan(
                              text: skills.isNotEmpty ? skills.join(', ') : 'None',
                              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Rate Section
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: "Rate: ",
                              style: TextStyle(color: Color(0xff0f766e), fontWeight: FontWeight.w600),
                            ),
                            WidgetSpan(child: SizedBox(width: 6,)),
                            TextSpan(
                              text: "\$$rate / hour",
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ],
                        ),
                      ),

                      // Accept / Reject Buttons
                      if (status == 'pending') ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () async {
                                try {
                                  await supabase
                                      .from('invites')
                                      .update({'status': 'rejected'})
                                      .eq('id', invite['id']);
                                  if (mounted) {
                                    setState(() {
                                      _loadInvites();
                                    });
                                  }
                                } catch (e) {
                                  debugPrint("Reject error: $e");
                                }
                              },
                              child: const Text("Reject", style: TextStyle(color: Colors.red)),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff0f766e),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () async {
                                try {
                                  await supabase
                                      .from('invites')
                                      .update({'status': 'accepted'})
                                      .eq('id', invite['id']);
                                  if (mounted) {
                                    setState(() {
                                      _loadInvites();
                                    });
                                  }
                                } catch (e) {
                                  debugPrint("Accept error: $e");
                                }
                              },
                              child: const Text("Accept", style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class StudentsTabWidget extends StatefulWidget {
  const StudentsTabWidget({super.key});

  @override
  State<StudentsTabWidget> createState() => _StudentsTabWidgetState();
}

class _StudentsTabWidgetState extends State<StudentsTabWidget> {
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _studentsFuture;
  RealtimeChannel? _inviteChannel;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _subscribeToInviteChanges();
  }

  @override
  void dispose() {
    if (_inviteChannel != null) {
      supabase.removeChannel(_inviteChannel!);
    }
    super.dispose();
  }

  void _subscribeToInviteChanges() {
    final tutorId = supabase.auth.currentUser?.id;
    if (tutorId == null) return;

    _inviteChannel = supabase
        .channel('my_students_tab_$tutorId')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'invites',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'tutor_id',
        value: tutorId,
      ),
      callback: (payload) {
        if (mounted) {
          setState(() {
            _loadStudents();
          });
        }
      },
    )
        .subscribe();
  }

  void _loadStudents() {
    _studentsFuture = _fetchAcceptedInvitesWithStudentInfo();
  }

  Future<List<Map<String, dynamic>>> _fetchAcceptedInvitesWithStudentInfo() async {
    final tutorId = supabase.auth.currentUser?.id;
    if (tutorId == null) return [];

    final acceptedInvitesRaw = await supabase
        .from('invites')
        .select()
        .eq('tutor_id', tutorId)
        .eq('status', 'accepted')
        .order('created_at', ascending: false);

    final List<Map<String, dynamic>> acceptedInvites =
    List<Map<String, dynamic>>.from(acceptedInvitesRaw);

    if (acceptedInvites.isEmpty) return acceptedInvites;

    final studentIds = acceptedInvites
        .map((invite) => invite['student_id']?.toString())
        .whereType<String>()
        .toSet()
        .toList();

    if (studentIds.isNotEmpty) {
      try {
        final studentsDataRaw = await supabase
            .from('students')
            .select()
            .inFilter('id', studentIds);

        final studentsData = List<Map<String, dynamic>>.from(studentsDataRaw);
        final Map<String, Map<String, dynamic>> studentsById = {
          for (final s in studentsData) s['id'].toString(): s,
        };

        for (final invite in acceptedInvites) {
          final sid = invite['student_id']?.toString();
          if (sid != null && studentsById.containsKey(sid)) {
            invite['student_info'] = studentsById[sid];
          }
        }
      } catch (e) {
        debugPrint("Could not fetch student profiles: $e");
      }
    }

    return acceptedInvites;
  }

  @override
  Widget build(BuildContext context) {
    final tutorId = supabase.auth.currentUser?.id;

    if (tutorId == null) {
      return const Center(child: Text("User not logged in."));
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _studentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xff0f766e)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading students: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final students = snapshot.data ?? [];

        if (students.isEmpty) {
          return const Center(
            child: Text(
              "No Students Found!",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (mounted) {
              setState(() {
                _loadStudents();
              });
            }
          },
          color: const Color(0xff0f766e),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final invite = students[index];
              final studentInfo = invite['student_info'] as Map<String, dynamic>?;
              final String studentId = invite['student_id']?.toString() ?? '';
              final String studentName =
              (studentInfo?['name'] ?? studentInfo?['full_name'] ?? 'Student').toString();
              final String? studentImage =
              (studentInfo?['profile_image'] ?? studentInfo?['avatar_url'])?.toString();
              final List<dynamic> skills = invite['selected_skills'] ?? [];
              final String duration = invite['duration']?.toString() ?? 'N/A';
              final String rate = (invite['hourly_rate'] as num? ?? 0.0).toStringAsFixed(1);

              return Stack(
                clipBehavior: Clip.none, // Cross button ko border clip hone se bachane ke liye
                children: [
                  // Main Card Component
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color(0xff0f766e).withOpacity(0.1),
                            backgroundImage: (studentImage != null && studentImage.isNotEmpty)
                                ? NetworkImage(studentImage)
                                : null,
                            child: (studentImage == null || studentImage.isEmpty)
                                ? const Icon(Icons.person, color: Color(0xff0f766e))
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  studentName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xff0f766e),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    TextWidget(
                                      text: "Learn:  ",
                                      textWeight: FontWeight.bold,
                                      textColor: const Color(0xff0f766e),
                                    ),
                                    Expanded(
                                      child: TextWidget(
                                        text: skills.isNotEmpty ? skills.join(', ') : 'None',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    TextWidget(
                                      text: "Duration:  ",
                                      textWeight: FontWeight.bold,
                                      textColor: const Color(0xff0f766e),
                                    ),
                                    TextWidget(text: duration),
                                  ],
                                ),
                                Row(
                                  children: [
                                    TextWidget(
                                      text: "Rate:  ",
                                      textWeight: FontWeight.bold,
                                      textColor: const Color(0xff0f766e),
                                    ),
                                    TextWidget(text: "\$$rate/hr"),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.message,
                              color: Color(0xff0f766e),
                            ),
                            onPressed: () {
                              if (studentId.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Student ID is missing!")),
                                );
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TutorChatScreen(
                                    receiverId: studentId,
                                    receiverName: studentName,
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.phone,
                              color: Color(0xff0f766e),
                            ),
                            onPressed: () async {
                              if (studentId.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Invalid Student ID")),
                                );
                                return;
                              }

                              try {
                                final tutorUser = supabase.auth.currentUser;

                                if (tutorUser == null) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Tutor not logged in")),
                                  );
                                  return;
                                }

                                // 🔴 1. Student Image Fallback Check
                                final studentImageUrl = studentImage ??
                                    invite['student_image'] ??
                                    invite['avatar_url'] ??
                                    invite['profile_image'] ??
                                    invite['image'];

                                final inviteId = invite['id']?.toString() ?? 'no_invite';
                                final channelId = "call_${inviteId}_${DateTime.now().millisecondsSinceEpoch}";

                                // 🔴 2. Tutor Profile Data Fetching with Column Fallbacks
                                final tutorProfile = await supabase
                                    .from('tutors')
                                    .select('*')
                                    .eq('id', tutorUser.id)
                                    .maybeSingle();

                                final String tutorName = tutorProfile?['name'] ??
                                    tutorProfile?['full_name'] ??
                                    "Tutor";

                                // Multiple fallback checks for Tutor Image column names
                                final String? tutorImage = tutorProfile?['caller_image'] ??
                                    tutorProfile?['profile_image'] ??
                                    tutorProfile?['image'] ??
                                    tutorProfile?['photo'];

                                // 🔴 3. Insert into Supabase Calls table
                                await supabase.from('calls').insert({
                                  'caller_id': tutorUser.id,
                                  'caller_name': tutorName,
                                  'caller_image': tutorImage, // 👈 Ensures image URL is passed correctly
                                  'receiver_id': studentId,
                                  'channel_id': channelId,
                                  'status': 'calling',
                                });

                                if (!context.mounted) return;

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TutorCallScreen(
                                      channelId: channelId,
                                      receiverName: studentName,
                                      receiverImage: studentImageUrl?.toString(),
                                    ),
                                  ),
                                );
                              } catch (e) {
                                debugPrint("CALL ERROR: $e");

                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Call Error: ${e.toString()}"),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    top: -2,
                    right: -2,
                    child: GestureDetector(
                      onTap: () async {
                        final bool? shouldEnd = await showDialog<bool>(
                          barrierDismissible: false,
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              title: Center(child: const TextWidget(text: "End Contract", textWeight: FontWeight.bold, textColor: Color(0xff0f766e),)),
                              content: Text(
                                "Ending this contract will terminate your teaching sessions with $studentName and remove your classroom access for this student. Do you wish to proceed?",
                              ),
                              actions: [
                                Row(
                                  children: [
                                    Expanded(child: ElevatedButtonWidget(buttonText: "No",
                                        textColor: Colors.white,
                                        buttonColor: Color(0xff0f766e),
                                        onTap: () => Navigator.of(dialogContext).pop(false))),
                                    SizedBox(width: 10,),
                                    Expanded(child: ElevatedButtonWidget(buttonText: "Yes",
                                        buttonColor: Color(0xff0f766e),
                                        textColor: Colors.white,
                                        onTap: () {
                                          Navigator.of(dialogContext).pop(true);
                                    },))
                                  ],
                                )
                              ],
                            );
                          },
                        );

                        if (shouldEnd != true) return;

                        // 2. Supabase DB update / end contract logic execute karein
                        try {
                          final inviteId = invite['id'];

                          if (inviteId == null) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Invite ID is missing!")),
                            );
                            return;
                          }

                          // Show loading dialog
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(
                                child: CircularProgressIndicator(color: Color(0xff0f766e)),
                              ),
                            );
                          }

                          // Option A: Status update karna (Recommended practice)
                          await supabase
                              .from('invites') // Aapki contract/invites table ka naam
                              .update({'status': 'ended'})
                              .eq('id', inviteId);


                          if (!context.mounted) return;
                          Navigator.pop(context); // Close loading indicator

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Contract ended successfully"),
                              backgroundColor: Color(0xff0f766e),
                            ),
                          );
                          // onRefresh();

                        } catch (e) {
                          debugPrint("END CONTRACT ERROR: $e");

                          if (!context.mounted) return;
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Error ending contract: ${e.toString()}"),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Color(0xff0f766e),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}